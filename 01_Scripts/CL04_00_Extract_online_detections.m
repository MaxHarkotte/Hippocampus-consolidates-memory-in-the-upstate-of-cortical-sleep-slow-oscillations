% Extract online events
% Author: Max Harkotte (maximilian.harkotte@gmail.com)
% Date: December 2025
clear
close all
clc 

%% Paths
script_path = which('CL04_00_extract_online_detections.m');
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
selection    = reference(contains(reference.Phase, "Retention"), :);

%% Extract measures 
for iRec = 1:size(selection,1)
    %% Read in hypnogram
    % Recording information
    rec_info         = selection(iRec,:);
    recording_length = rec_info.RecLengthInMin*60; % in seconds

    % Cut to correct length
    fs             = 1000; % in Hz

    % Hypnogram 
    tmp_hypno       = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/02_Sleep_Scorings/02_Matlab_files/', ...
        char(rec_info.NLX_id), '.mat'), 'SlStNew'); 
    hypno           = double(tmp_hypno.SlStNew.codes(1:recording_length/10,1));
    true_hypno = hypno;

    clear tmp_hypno;

    %% Read in detections
    % Online detected SOs from frontal EEG
    hdr = ft_read_header(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/01_Neuralynx/', rec_info.NLX_id, '/'));

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
    elseif rec_info.StimProtocol == "SO_up_in_phase"
        online_SO        = event_table(startsWith(event_table.type, "Stim"), :);     
        online_SO.sample = round(online_SO.sample);

        tmp_start_idx = strcmp(online_SO.type, 'StimON');     
        online_SO.type(tmp_start_idx) = {'SO_rising_flank'};  

        tmp_end_idx = strcmp(online_SO.type, 'StimOFF');     
        online_SO.type(tmp_end_idx) = {'SO_end'};   
             
        clear event_table tmp_start_idx tmp_end_idx;

    elseif rec_info.StimProtocol == "No_stim"
         if any(strcmp(event_table.type, 'SO_rising_flank'))
             online_SO        = event_table(startsWith(event_table.type, "SO"), :);     
             online_SO.sample = round(online_SO.sample);
             clear event_table;
         else
             online_SO        = event_table(startsWith(event_table.type, "Stim"), :);     
             online_SO.sample = round(online_SO.sample);

             tmp_start_idx = strcmp(online_SO.type, 'StimON');     
             online_SO.type(tmp_start_idx) = {'SO_rising_flank'};  

             tmp_end_idx = strcmp(online_SO.type, 'StimOFF');     
             online_SO.type(tmp_end_idx) = {'SO_end'};   
             
             clear event_table tmp_start_idx tmp_end_idx;

         end
    end

    %% Clean TTL log files
    fprintf('Cleaned Recording:  %d', iRec);

    if rec_info.StimProtocol == "SO_delayed"
        % Online SOs (expected duration ≈ 1 s)
        online_SO = cleanAndRepairTTL(online_SO, 'SO_rising_flank', 'SO_end', [995 1005]);
        % Inhibitions (any TTL ≤ 2 s)
        delayed_stim = cleanAndRepairTTL(delayed_stim, 'StimON', 'StimOFF', [0 2005]);
    elseif rec_info.StimProtocol == "SO_up_in_phase"
        online_SO = cleanAndRepairTTL(online_SO, 'SO_rising_flank', 'SO_end', [995 1005]);
    elseif rec_info.StimProtocol == "No_stim"
        online_SO = cleanAndRepairTTL(online_SO, 'SO_rising_flank', 'SO_end', [995 1005]);
    end

    %% No stim condition had no online sleep scoring --> discard online SOs
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
        SO_detected = online_SO.sample(online_SO.value == 1);
  
        for iEpisode = 1:size(NREMEpisodes,2)
            tmp_idx  = find(SO_detected > NREMEpisodes(1,iEpisode) & SO_detected < NREMEpisodes(2,iEpisode));
            idx      = [idx; tmp_idx];
        end

        allIdx = 1:numel(SO_detected);
        discardIdx = setdiff(allIdx, idx);       
        SO_outside_NREM = SO_detected(discardIdx);
        % rows where value == 1 (start events)
        start_rows = find(online_SO.value == 1);

        % keep only the start rows that match SO_outside_NREM
        rows_to_remove_starts = start_rows(ismember(online_SO.sample(start_rows), SO_outside_NREM));
        rows_to_remove = sort([rows_to_remove_starts; rows_to_remove_starts + 1]);
        online_SO(rows_to_remove, :) = [];
        
        clear trl_begin trl_end tmp_online_trials NREMBegEpisode NREMEndEpisode; 
    end

    %% Store online detected SOs and stimulation times 
    if rec_info.StimProtocol == "SO_delayed"
        save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/02_Online/', char(rec_info.NLX_id), '_online_SOs.mat'), "online_SO")
        save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/02_Online/', char(rec_info.NLX_id), '_online_stims.mat'), "delayed_stim")
  
    else
        save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/02_Online/', char(rec_info.NLX_id), '_online_SOs.mat'), "online_SO")
    end
end


