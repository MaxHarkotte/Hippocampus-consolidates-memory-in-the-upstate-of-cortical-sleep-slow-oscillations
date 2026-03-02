% Extracts stimulation parameters and relates them to memory performance 
% Author: Max Harkotte (maximilian.harkotte@gmail.com)
% Date: September 2025
clear
close all
clc 

%% Paths
script_path = which('CL04_00_Sleep_Oscillation_Detection.m');
script_path = strrep(char(script_path), '\', '/');
file_server_path = 'Z:/'; % if run locally
% file_server_path = '/gpfs01/born/animal/'; % if run on the cluster

% Paths to toolboxes and functions
root = strsplit(char(script_path),'00_Closed_Loop_Inhibition_CA1py/');
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/Neuralynx_Import_MEX/')); 
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/fieldtrip-20240722/')); 
ft_defaults

clear script_path; 
%% Recording information
reference = readtable(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/Documentation.xlsx'));

%% Select recordings for analysis
selection = reference( contains(reference.Phase,"Retention") & reference.Exclusion == "no", :);

%% Read in recordings and run event detection for each channel
stimulations = table('Size',[size(selection,1) 5], ...
            'VariableTypes', ["string","string", "double","double","double"], ...
            'VariableNames', ["Animal", "Condition" , "Stim_count", "Stim_density", "Stim_duration"]);


for iRec = 1 :size(selection,1)
    %% Read in recording and hypnogram
    % Recording information
    rec_info         = selection(iRec,:);
    recording_length = rec_info.RecLengthInMin*60; % in seconds

    hdr = ft_read_header(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/01_Neuralynx/', rec_info.NLX_id, '/'));

    % Cut to correct length
    fs             = hdr.Fs; % in Hz
    clear cfg;

    % Hypnogram 
    tmp_hypno       = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/02_Sleep_Scorings/02_Matlab_files/', ...
        char(rec_info.NLX_id), '.mat'), 'SlStNew'); 
    hypno           = double(tmp_hypno.SlStNew.codes(1:recording_length/10,1));
    cfg_det.scoring = hypno;

    clear tmp_hypno;

    %% Read in online detections
    [TimeStamps, ~, TTLs, ~, EventStrings, ~] = Nlx2MatEV(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/01_Neuralynx/', char(rec_info.NLX_id), '/Events.nev'),...
    [1 1 1 1 1], 1, 1, 1);

    if any(strcmp(EventStrings, 'TTL Input on AcqSystem1_0 board 0 port 2 value (0x0001).')) % animals that also underwent delayed condition have multiple event strings
        EventStrings = strrep(EventStrings, 'TTL Input on AcqSystem1_0 board 0 port 0 value (0x0001).', 'SO_rising_flank');
        EventStrings = strrep(EventStrings, 'TTL Input on AcqSystem1_0 board 0 port 0 value (0x0000).', 'SO_end');
        EventStrings = strrep(EventStrings, 'TTL Input on AcqSystem1_0 board 0 port 2 value (0x0001).', 'StimON');
        EventStrings = strrep(EventStrings, 'TTL Input on AcqSystem1_0 board 0 port 2 value (0x0000).', 'StimOFF');
    else % animals that did only undergo no_stim and stim conditions 
        EventStrings = strrep(EventStrings, 'TTL Input on AcqSystem1_0 board 0 port 0 value (0x0001).', 'StimON');
        EventStrings = strrep(EventStrings, 'TTL Input on AcqSystem1_0 board 0 port 0 value (0x0000).', 'StimOFF');
    end

    event = struct(type = EventStrings');

    for i = 1:numel(event)
        event(i).value = TTLs(i);
        event(i).timestamp = TimeStamps(i);
    end

    % Construct new samples from timestamp data 
    TimeStampPerSample = 1000000/fs; % Timestamps (in microseconds) per sample (sampling freq in Hz)  
    
    for i=1:length(event)
      event(i).sample = (event(i).timestamp-double(hdr.FirstTimeStamp))./TimeStampPerSample + 1;
    end
    
    event_table = struct2table(event);
    event_table([1,],:) = []; % First TTL is triggered by Acquisition system, NOT a detected event 

    clear EventStrings TimeStamps TimeStampPerSample TTLs event;

    %% Handle online detections 
    % Delayed condition has offline, online AND stim events 
    if rec_info.StimProtocol == "SO_delayed"
        online_SO           = event_table(startsWith(event_table.type, "SO"), :);
        online_SO.sample    = round(online_SO.sample);
        delayed_stim        = event_table(startsWith(event_table.type, "Stim"), :);
        delayed_stim.sample = round(delayed_stim.sample);
        clear event_table;
    else
        online_SO        = event_table(startsWith(event_table.type, "Stim"), :);
        online_SO.sample = round(online_SO.sample);
        clear event_table;
    end

    % No stim condition had no online sleep scoring --> discard online SOs
    % outside of sleep 
    if rec_info.StimProtocol == "No_stim"
        cfg                      = [];
        cfg.scoring              = hypno; 
        cfg.code_NREM            = [2 4];
        cfg.scoring_epoch_length = 10;
    
        NREMBegEpisode = strfind(any(cfg.scoring(:,1)==cfg.code_NREM,2)',[0 1]); % where does scoring flip to NREM
        NREMEndEpisode = strfind(any(cfg.scoring(:,1)==cfg.code_NREM,2)',[1 0]); % where does scoring flip from NREM to something else
        NREMBegEpisode = NREMBegEpisode+1; % because it always finds the epoch before
    
        if any(cfg.scoring(1,1)==cfg.code_NREM,2)
	        NREMBegEpisode = [1 NREMBegEpisode];
        end
        if any(cfg.scoring(end,1)==cfg.code_NREM,2)
	        NREMEndEpisode = [NREMEndEpisode length(cfg.scoring)];
        end
    
        NREMEpisodes = [(NREMBegEpisode-1)*cfg.scoring_epoch_length+1; NREMEndEpisode*cfg.scoring_epoch_length]; %create Matrix with NRem on and offset time in sec
        NREMEpisodes = NREMEpisodes*fs; % sec to sample points 
    
        idx = [];
        
        for iEpisode = 1:size(NREMEpisodes,2)
            tmp_idx  = find(online_SO.sample > NREMEpisodes(1,iEpisode) & online_SO.sample < NREMEpisodes(2,iEpisode));
            idx      = [idx; tmp_idx];
        end
        
        online_SO        = online_SO(idx,:);
        online_SO.sample = round(online_SO.sample);
        
        clear trl_begin trl_end tmp_online_trials NREMBegEpisode hypno NREMEndEpisode; 
    end

    % Store in table 
    stimulations.Animal(iRec) = string(rec_info.Animal); 
    stimulations.Condition(iRec) = string(rec_info.StimProtocol); 

    % Number of stimulations, denstity and duration
    if rec_info.StimProtocol == "SO_delayed"
        stimulations.Stim_count(iRec) = sum(strcmp(delayed_stim.type, "StimON"));

    elseif rec_info.StimProtocol == "SO_up_in_phase"
        stimulations.Stim_count(iRec) = sum(strcmp(online_SO.type, "StimON"));

    elseif rec_info.StimProtocol == "No_stim"

    end
  

end

%% Read in behavior 
behavior = readtable(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/11_Behavior_Scorings/02_Tables/02_Data_Summary/CL04-TestClean.csv'));

exclude = { ...
    'CL04-02-MPV0120-RD1', ... % no expression in right HC
    'CL04-04-MPV0120-BE1', ... % recording issues during retention interval
    'CL04-06-MPV0120-RD1', ... % abnormal histology (enlarged ventricles)
    'CL04-11-MPV0120-RD1'};    % no expression in left HC

behavior = behavior(~ismember(behavior.Animal, exclude), :);

%% Merge tables and run correlation analysis 
all_data = innerjoin(behavior, stimulations, ...
    'Keys', {'Animal','Condition'});

all_data.Cum_DiRa_min_1 = str2double(strrep(all_data.Cum_DiRa_min_1, ',', '.'));

in_phase_dat = all_data( contains(all_data.Condition,"SO_up_in_phase"), :);

[r, p] = corr(in_phase_dat.Cum_DiRa_min_1, in_phase_dat.Stim_count, 'Rows','complete');

figure;
grid on
hold on
mdl = fitlm(in_phase_dat.Cum_DiRa_min_1, in_phase_dat.Stim_count);           
plot(mdl)         
xlabel('DR first minute')
ylabel('Stim count')
title(sprintf('r = %.2f, p = %.3f', r, p))
hold off
