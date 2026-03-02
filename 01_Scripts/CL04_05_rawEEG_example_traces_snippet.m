% Plot EEG traces with LED bar for all three conditions
% Author: Max Harkotte (maximilian.harkotte@gmail.com)
% Date: September 2025
clear
close all
clc 

%% Paths
script_path = which('CL04_05_rawEEG_example_traces.m');
script_path = strrep(char(script_path), '\', '/');
file_server_path = 'Z:/'; % if run locally

% Paths to toolboxes and functions
root = strsplit(char(script_path),'00_Closed_Loop_Inhibition_CA1py/');
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/fieldtrip-20240722/')); 
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/Neuralynx_Import_MEX/')); 
ft_defaults

clear script_path; 

%% Recording information
reference = readtable(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/Documentation.xlsx'));

%% Select recordings for analysis
selection = reference( contains(reference.Phase,"Retention") & reference.Exclusion == "no", :);

% select channels 
channel      = 'EEG_left_frontal';
channel_path = '01_EEG_left_frontal/';

% select animal for illustrative examples 
anima_id = 'CL04-10-MPV0120-BE1'; 
selection = selection(contains(selection.Animal, anima_id),:);

% selected SO for illustrations
no_stim_SO_idx = 17;
in_phase_SO_idx = 39;
delayed_SO_idx = 115;
%delayed_SO_idx = 116;

%% Read in data

for iRec =  1 :size(selection,1)
    rec_info = selection(iRec,:);
    recording_length = rec_info.RecLengthInMin*60; % in seconds

    % read in data and combine in one ft structure
    cfg         = [];
    cfg.dataset = strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/01_Neuralynx/', rec_info.NLX_id, '/');
    cfg.channel = {channel};
    rec  = ft_preprocessing(cfg);

    % Cut to correct length
    fs             = rec.fsample; % in Hz
    cfg            = [];
    cfg.begsample  = 1;
    cfg.endsample  = recording_length*fs;
    rec            = ft_redefinetrial(cfg, rec);
    rec.sampleinfo = [1,recording_length*fs];

    clear cfg;

    rec_filtered = rec; 

    filter_order = 3;              % order of butterworth filter 
    filter_fcutlow = 0.1;          % low cut frequency in Hz
    filter_fcuthigh = 20;           % high cut frequency in Hz

    [FilterHigh1,FilterHigh2] = butter(filter_order,2*filter_fcutlow/fs,'high');
    [FilterLow1,FilterLow2] = butter(filter_order,2*filter_fcuthigh/fs,'low');
    dataFilt = filtfilt(FilterHigh1,FilterHigh2,rec_filtered.trial{1,1}');
    dataFilt = filtfilt(FilterLow1,FilterLow2,dataFilt);

    rec_filtered.trial{1,1} = dataFilt;


    % Hypnogram 
    tmp_hypno       = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/02_Sleep_Scorings/02_Matlab_files/', ...
        char(rec_info.NLX_id), '.mat'), 'SlStNew'); 
    hypno           = double(tmp_hypno.SlStNew.codes(1:recording_length/10,1));

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

    % Select snippets 
    
    if rec_info.StimProtocol == "No_stim"
        no_stim_snippet = rec_filtered.trial{1,1}(online_SO.sample(no_stim_SO_idx)-1*fs:online_SO.sample(no_stim_SO_idx +1)+2.5*fs);

        SO_times  = online_SO(find(strcmp(online_SO.type, "StimON")),:);
        inBetween = SO_times.sample(SO_times.sample >= online_SO.sample(no_stim_SO_idx)-1*fs & SO_times.sample<= online_SO.sample(no_stim_SO_idx +1)+2.5*fs);
        no_stim_SOs = inBetween - (online_SO.sample(no_stim_SO_idx) - 1*fs);

    elseif rec_info.StimProtocol == "SO_up_in_phase"
        in_phase_snippet = rec_filtered.trial{1,1}(online_SO.sample(in_phase_SO_idx)-1*fs:online_SO.sample(in_phase_SO_idx +1)+2.5*fs);

        SO_times  = online_SO(find(strcmp(online_SO.type, "StimON")),:);
        inBetween = SO_times.sample(SO_times.sample >= online_SO.sample(in_phase_SO_idx)-1*fs & SO_times.sample<= online_SO.sample(in_phase_SO_idx +1)+2.5*fs);
        in_phase_SOs = inBetween - (online_SO.sample(in_phase_SO_idx) - 1*fs);

    elseif rec_info.StimProtocol == "SO_delayed"
        delayed_snippet = rec_filtered.trial{1,1}(online_SO.sample(delayed_SO_idx)-1*fs:online_SO.sample(delayed_SO_idx +1)+2.5*fs);
        
        on_times  = delayed_stim(find(strcmp(delayed_stim.type, "StimON")),:);
        inBetween = on_times.sample(on_times.sample >= online_SO.sample(delayed_SO_idx)-1*fs & on_times.sample<= online_SO.sample(delayed_SO_idx +1)+2.5*fs);
        delayed_stims = inBetween - (online_SO.sample(delayed_SO_idx) -1*fs);
       
        SO_times  = online_SO(find(strcmp(online_SO.type, "SO_rising_flank")),:);
        inBetween = SO_times.sample(SO_times.sample >= online_SO.sample(delayed_SO_idx)-1*fs & SO_times.sample<= online_SO.sample(delayed_SO_idx +1)+2.5*fs);
        delayed_SOs = inBetween - (online_SO.sample(delayed_SO_idx) - 1*fs);
    end


    % for delayed_SO_idx = 1:size(online_SO,1)
    % 
    %     delayed_snippet = rec_filtered.trial{1,1}(online_SO.sample(delayed_SO_idx)-5*fs:online_SO.sample(delayed_SO_idx +1)+5*fs);
    %     on_times  = delayed_stim(find(strcmp(delayed_stim.type, "StimON")),:);
    %     inBetween = on_times.sample(on_times.sample >= online_SO.sample(delayed_SO_idx)-5*fs & on_times.sample<= online_SO.sample(delayed_SO_idx +1)+5*fs);
    %     delayed_stims = inBetween - (online_SO.sample(delayed_SO_idx) - 5*fs);
    % 
    %     off_times  = delayed_stim(find(strcmp(delayed_stim.type, "StimOFF")),:);
    %     inBetween = off_times.sample(off_times.sample >= online_SO.sample(delayed_SO_idx)-5*fs & off_times.sample<= online_SO.sample(delayed_SO_idx +1)+5*fs);
    %     delayed_stims_off = inBetween - (online_SO.sample(delayed_SO_idx) - 5*fs);
    % 
    %     SO_times  = online_SO(find(strcmp(online_SO.type, "SO_rising_flank")),:);
    %     inBetween = SO_times.sample(SO_times.sample >= online_SO.sample(delayed_SO_idx)-5*fs & SO_times.sample<= online_SO.sample(delayed_SO_idx +1)+5*fs);
    %     delayed_SOs = inBetween - (online_SO.sample(delayed_SO_idx) - 5*fs);
    % 
    %     plot(delayed_snippet)
    %     for i = 1:length(delayed_stims)
    %         xline(delayed_stims(i), 'r--', 'LineWidth', 1);
    %     end
    % 
    %     for i = 1:length(delayed_stims_off)
    %         xline(delayed_stims_off(i), 'b--', 'LineWidth', 1);
    %     end
    % 
    %     for i = 1:length(delayed_SOs)
    %         xline(delayed_SOs(i), '--', 'LineWidth', 1);
    %     end
    %     ylim([-500 500])
    %     xlim([0 10*fs])
    %     title(delayed_SO_idx)
    %     waitforbuttonpress
    % end

end

%% Look for additional SO within the window 
delayed_SOs 
no_stim_SOs 
in_phase_SOs 

%% Find detection threshold (from second habituation recording) 
offline_events = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/01_Offline/2025-04-16_08-59-18_events.mat'));
offline_events = offline_events.detection_output;
threshold = cell2mat(offline_events.slo.thr(1,1));

%% Plotting

fig1 = figure('Color','w','Position',[200 200 300 250]);

ax1 = subplot(3,1,1);
plot(in_phase_snippet)
hold on
for i = 1:length(in_phase_SOs)
    rectangle('Position', [in_phase_SOs(i) 400 1*fs 30], 'FaceColor', 'r', 'EdgeColor', 'none');
end
for i = 1:length(in_phase_SOs)
    xline(in_phase_SOs(i), '--', 'LineWidth', 1);
end
ylim([-500 500])
xlim([0 3.5*fs]) 
ylabel('\muV')

set(gca, ...
    'XTickLabel', [], ...                       
    'YTick', [-500  0  500], ...
    'YTickLabel', {'-500', '0','500'}, ...
    'TickDir', 'out', ...                        
    'Box', 'off', ...                            
    'XAxisLocation', 'bottom', ...                
    'YAxisLocation', 'left');                    

ax2 = subplot(3,1,2);
plot(delayed_snippet)
hold on
rectangle('Position', [2500 400 1*fs 30], 'FaceColor', 'r', 'EdgeColor', 'none');
for i = 1:length(delayed_SOs)
    xline(delayed_SOs(i), '--', 'LineWidth', 1);
end
ylim([-500 500])
xlim([0 3.5*fs])
ylabel('\muV')
set(gca, ...
    'XTickLabel', [], ...
    'YTick', [-500  0  500], ...
    'YTickLabel', {'-500', '0','500'}, ...
    'TickDir', 'out', ...
    'Box', 'off', ...
    'XAxisLocation', 'bottom', ...
    'YAxisLocation', 'left');

ax3 = subplot(3,1,3);
plot(no_stim_snippet)
for i = 1:length(no_stim_SOs)
    xline(no_stim_SOs(i), '--', 'LineWidth', 1);
end
ylim([-500 500])
xlim([0 3.5*fs])
ylabel('\muV')
xlabel('Time from online detected SO (s)')
set(gca, ...
   'XTickLabel', [-1, -0.5, 0, 0.5, 1, 1.5, 2, 2.5], ...
    'YTick', [-500  0  500], ...
    'YTickLabel', {'-500', '0','500'}, ...
    'TickDir', 'out', ...
    'Box', 'off', ...
    'XAxisLocation', 'bottom', ...
    'YAxisLocation', 'left');

