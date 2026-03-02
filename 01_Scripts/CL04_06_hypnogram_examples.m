% Example hypnograms for all three conditions from one animal, including
% EEG, EMG and inhibition times 
% Author: Max Harkotte (maximilian.harkotte@gmail.com)
% Date: September 2025
clear
close all
clc 

%% Paths
script_path = which('CL04_06_hypnogram_examples.m');
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

%% Read in data

fig1 = figure('Color', 'w', 'Units', 'centimeters', 'Position', [20 5 17 10]);

for iRec =  1:size(selection,1)
    rec_info = selection(iRec,:);
    recording_length = rec_info.RecLengthInMin*60; % in seconds

    % read in data and combine in one ft structure
    cfg         = [];
    cfg.dataset = strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/01_Neuralynx/', rec_info.NLX_id, '/');
    cfg.channel = {'EEG_left_frontal' 'EMG_left'};
    rec  = ft_preprocessing(cfg);

    % Cut to correct length
    fs             = rec.fsample; % in Hz
    cfg            = [];
    cfg.begsample  = 1;
    cfg.endsample  = recording_length*fs;
    rec            = ft_redefinetrial(cfg, rec);
    rec.sampleinfo = [1,recording_length*fs];

    clear cfg;

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
        
        clear trl_begin trl_end tmp_online_trials NREMBegEpisode NREMEndEpisode; 
    end

    %% Filter EEG and EMG 
    
    EEG_data = rec.trial{1,1}(1,:);
    EMG_data = rec.trial{1,1}(2,:);

    EEG_filter_order = 3;             
    EEG_filter_fcutlow = 0.1;          
    EEG_filter_fcuthigh = 20;      

    EMG_filter_order = 3;              
    EMG_filter_fcutlow = 80;  
    EMG_filter_fcuthigh = 300;   

    [EEG_FilterHigh1,EEG_FilterHigh2] = butter(EEG_filter_order,2*EEG_filter_fcutlow/fs,'high');
    [EEG_FilterLow1,EEG_FilterLow2] = butter(EEG_filter_order,2*EEG_filter_fcuthigh/fs,'low');
    EEG_dataFilt = filtfilt(EEG_FilterHigh1,EEG_FilterHigh2,EEG_data');
    EEG_dataFilt = filtfilt(EEG_FilterLow1,EEG_FilterLow2,EEG_dataFilt);

    [EMG_FilterHigh1,EMG_FilterHigh2] = butter(EMG_filter_order,2*EMG_filter_fcutlow/fs,'high');
    [EMG_FilterLow1,EMG_FilterLow2] = butter(EMG_filter_order,2*EMG_filter_fcuthigh/fs,'low');
    EMG_dataFilt = filtfilt(EMG_FilterHigh1,EMG_FilterHigh2,EMG_data');
    EMG_dataFilt = filtfilt(EMG_FilterLow1,EMG_FilterLow2,EMG_dataFilt);


    %% Recode manual states for plotting 
    hypno(hypno == 17) = 1; % messy Wake as Wake 
    hypno(hypno == 18) = 2; % messy NREM as NREM 
    hypno(hypno == 19) = 3; % messy REM as REM 
    hypno(hypno == 20) = 4; % messy preREM as preREM 
    hypno(hypno == 8)  = 1; % Artifacts as Wake 

    hypno(hypno == 3) = 9; % REM as 9 
    hypno(hypno == 4) = 3; % preREM as 3
    hypno(hypno == 9) = 4; % REM as 4 

    %% Inhibitions
    if rec_info.StimProtocol == "No_stim"
        inhibitions = [];
        panel = 3; 
    elseif rec_info.StimProtocol == "SO_up_in_phase"
        inhibitions  = online_SO(find(strcmp(online_SO.type, "StimON")),:);
        inhibitions = inhibitions.sample;
        panel = 1; 
    elseif rec_info.StimProtocol == "SO_delayed"
        inhibitions  = delayed_stim(find(strcmp(delayed_stim.type, "StimON")),:);
        inhibitions = inhibitions.sample;
        panel = 2; 
    end

    %% Plotting
    fontSize = 5;
    
    % --- Layout parameters ---
    if panel == 1
        offset = 0.72;
    elseif panel == 2
        offset = 0.41; 
    elseif panel == 3 
        offset = 0.1; 
    end
    
    if panel == 1 || panel == 2
        % --- Axes positions within one panel block (relative to yOffset) ---
        ax1_pos = [0.1, offset + 0.18, 0.85, 0.07];  % Hypnogram
        ax2_pos = [0.1, offset + 0.10, 0.85, 0.12];  % Inhibitions
        ax3_pos = [0.1, offset + 0.08, 0.85, 0.07];  % EEG
        ax4_pos = [0.1, offset, 0.85, 0.07];  % EMG
    elseif panel == 3
        % --- Axes positions within one panel block (relative to yOffset) ---
        ax1_pos = [0.1, offset + 0.19, 0.85, 0.07];  % Hypnogram
        ax3_pos = [0.1, offset + 0.11, 0.85, 0.07];  % EEG
        ax4_pos = [0.1, offset + 0.03, 0.85, 0.07];  % EMG
        ax2_pos = [0.1, offset, 0.85, 0.07];  % Time axis 
    end
    
    %% --- Hypnogram ---
    ax1 = axes('Position', ax1_pos);
    stairs(hypno, 'k', 'LineWidth', 1);
    ylim([1 4]);
    xlim([0 1080]);
    yticks(1:4);
    yticklabels({'Wake','NREM','preREM','REM'});
    set(ax1, 'YDir', 'reverse', ...
        'XTickLabel', [], 'XColor', 'none', ...
        'TickDir', 'in', 'Box', 'off', 'FontSize', fontSize);

    %% --- Inhibitions ---
    if panel == 1 || panel == 2
        ax2 = axes('Position', ax2_pos);
        hold on
        for i = 1:length(inhibitions)
            scatter(inhibitions(i), 0, 5, 'r', 'filled');
        end
        hold off
        xlim([0 1080*fs*10]);
        set(ax2, 'XTickLabel', [], 'XColor', 'none', 'YColor', 'none', ...
            'Color', 'none', 'Box', 'off', 'TickDir', 'in', 'FontSize', fontSize);
    elseif panel == 3
        ax2 = axes('Position', ax2_pos);
        
        % Just create a simple x-axis (no data)
        xlim([0 1080]);                  % 1080 bins = 180 min
        xticks(0:90:1080);               % 90 bins = 15 min
        xticklabels(0:15:180);           % show labels in minutes
        xlabel('Time (min)');
        
        % Optional formatting
        set(ax2, 'YColor', 'none', ...
            'Color', 'none', 'Box', 'off', 'TickDir', 'in', 'FontSize', fontSize);

    end
    
    %% --- EEG ---
    ax3 = axes('Position', ax3_pos);
    line(1:1080*fs*10, EEG_dataFilt, 'Color', 'k');
    xlim([0 1080*fs*10]);
    ylim([-500 500]);
    yticks(0); 
    yticklabels({'EEG'});
    set(ax3, 'XTickLabel', [], 'XColor', 'none', 'Box', 'off', ...
        'TickDir', 'in', 'FontSize', fontSize);
   
    %% --- EMG ---
    ax4 = axes('Position', ax4_pos);
    line(1:1080*fs*10, EMG_dataFilt, 'Color', 'k');
    xlim([0 1080*fs*10]);
    ylim([-1000 1000]);
    yticks(0); 
    yticklabels({'EMG'});
    set(ax4, 'XTickLabel', [], 'XColor', 'none', 'Box', 'off', ...
        'TickDir', 'in', 'FontSize', fontSize);

end

%% Saving
%exportgraphics(gcf, strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/example_hypnos_conditions.pdf'), 'ContentType', 'vector');
