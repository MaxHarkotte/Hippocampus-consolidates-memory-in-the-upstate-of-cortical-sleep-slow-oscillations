% Calculates Time Frequency Analysis of offline and online detected SOs
% Author: Max Harkotte (maximilian.harkotte@gmail.com)
% Date: December 2025
clear
close all
clc 

%% Paths
script_path = which('CL04_01_Sleep_Oscillation_TFR.m');
script_path = strrep(char(script_path), '\', '/');
file_server_path = 'X:/'; % if run locally
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

% select channels and whether trials should be kept for the TFR struct
channels      = {'EEG_left_frontal', 'EEG_right_frontal', 'EEG_left_parietal', 'EEG_right_parietal'};
channel_paths = {'01_EEG_left_frontal/', '02_EEG_right_frontal/', '03_EEG_left_parietal/', '04_EEG_right_parietal/'};
choice_keep_trials  = {'yes', 'no'};

%% Read in recordings and run event detection for each channel


for iCh = 1: size(channels, 2)
    channel = char(channels(iCh));
    channel_path = char(channel_paths(iCh));

    for iTrials = 1:2
        keep_trials = char(choice_keep_trials(iTrials));
        for iRec = 1 :size(selection,1)
            %% Read in recording and hypnogram
            % Recording information
            rec_info         = selection(iRec,:);
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
        
            %% Read in detections
            % Offline detected events
            offline_events = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/01_Offline/', ...
                char(rec_info.NLX_id), '_events.mat'));
            offline_events = offline_events.detection_output;
        
            % Offline detected SOs from selected EEG channel (negative peak)
            offline_SO = offline_events.slo.neg_peaks{find(strcmp(offline_events.info.channel, channel)),1};
        
            % Online detected SOs from frontal EEG
            online_SO = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/02_Online/', ...
                char(rec_info.NLX_id), '_online_SOs.mat'));
            online_SO = online_SO.online_SO;
        
            % Delayed condition inhibition times 
            if rec_info.StimProtocol == "SO_delayed"
                delayed_stim = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/02_Online/', ...
                char(rec_info.NLX_id), '_online_stims.mat'));
                delayed_stim = delayed_stim.delayed_stim;
            end
        
            %% Run event_locked TFR-Analysis 
            % create segment around offline and online detected SOs 
            trl_begin = offline_SO - 5*fs;
            trl_end = trl_begin + 10*fs;
            offline_SO_trl = horzcat(trl_begin, trl_end, zeros(size(trl_begin,1),1));
            offline_SO_trl = offline_SO_trl(offline_SO_trl(:,2) < recording_length*fs, :); % if last SO is too close to the end of the recording
            clear trl_begin trl_end ;
        
            cfg = [];
            cfg.trl = offline_SO_trl;
            offline_SO_segments = ft_redefinetrial(cfg, rec);
            clear offline_SO_trl;
        
            if rec_info.StimProtocol == "SO_delayed"
                trl_begin = delayed_stim(find(strcmp(delayed_stim.type, "StimON")),:);
                trl_begin = trl_begin.sample - 5*fs;
                trl_end = trl_begin + 10*fs;
                delayed_stim_trl = horzcat(trl_begin, trl_end, zeros(size(trl_begin,1),1));
                delayed_stim_trl = delayed_stim_trl(delayed_stim_trl(:,2) < recording_length*fs, :);
                clear trl_begin trl_end ;
        
                cfg = [];
                cfg.trl = delayed_stim_trl;
                delayed_stim_segments = ft_redefinetrial(cfg, rec);
        
                trl_begin = online_SO(find(strcmp(online_SO.type, "SO_rising_flank")),:);
                trl_begin = trl_begin.sample - 5*fs;
                trl_end = trl_begin + 10*fs;
                online_SO_trl = horzcat(trl_begin, trl_end, zeros(size(trl_begin,1),1));
                online_SO_trl = online_SO_trl(online_SO_trl(:,2) < recording_length*fs, :);
                clear trl_begin trl_end ;
        
                cfg = [];
                cfg.trl = online_SO_trl;
                online_SO_segments = ft_redefinetrial(cfg, rec);
                clear online_SO_trl delayed_stim_trl;
        
            else
          
                trl_begin = online_SO(find(strcmp(online_SO.type, "SO_rising_flank")),:);
                trl_begin = trl_begin.sample - 5*fs;
                trl_end = trl_begin + 10*fs;
                online_SO_trl = horzcat(trl_begin, trl_end, zeros(size(trl_begin,1),1));
                online_SO_trl = online_SO_trl(online_SO_trl(:,2) < recording_length*fs, :);
                clear trl_begin trl_end ;
        
                cfg = [];
                cfg.trl = online_SO_trl;
                online_SO_segments = ft_redefinetrial(cfg, rec);
        
               clear online_SO_trl;
        
            end
        
            % create grand average waveforms 
            cfg = [];
            offline_SO_avg = ft_timelockanalysis(cfg, offline_SO_segments);
            online_SO_avg  = ft_timelockanalysis(cfg, online_SO_segments);
        
            if rec_info.StimProtocol == "SO_delayed"
                delayed_stim_avg  = ft_timelockanalysis(cfg, delayed_stim_segments);
            end
        
            % run TFR analysis  
            cfg              = [];
            cfg.output       = 'pow';
            cfg.method       = 'mtmconvol';
            cfg.taper        = 'hanning';
            cfg.foi          = 5:0.5:40;
            cfg.keeptrials   = keep_trials;
            cfg.t_ftimwin    = 7./cfg.foi;            
            cfg.toi          = 0:0.05:10;
            
            offline_SO_TFRhann = ft_freqanalysis(cfg, offline_SO_segments);
            online_SO_TFRhann = ft_freqanalysis(cfg, online_SO_segments);
        
            if rec_info.StimProtocol == "SO_delayed"
                delayed_stim_TFRhann = ft_freqanalysis(cfg, delayed_stim_segments);
            end
            
            % Baseline normalization of TFR
            cfg              = [];
            cfg.baseline     = [2.5 3.5];
            cfg.baselinetype = 'relative';
        
            offline_SO_TFRhann_corr = ft_freqbaseline(cfg, offline_SO_TFRhann); 
            online_SO_TFRhann_corr = ft_freqbaseline(cfg, online_SO_TFRhann); 
        
            if rec_info.StimProtocol == "SO_delayed"
                cfg.baseline     = [4.0 5.0];
                delayed_stim_TFRhann_corr = ft_freqbaseline(cfg, delayed_stim_TFRhann); 
            end
        
            %% Store analysis 
            % Select path
            if strcmp(keep_trials, 'yes')
                store_path = strcat(channel_path, '02_With_trials/');
            else
                store_path = strcat(channel_path, '01_Without_trials/');
            end
            
            % Store 
            save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', store_path, ...
                char(rec_info.NLX_id), '_avg_wave_offline_SO'),'offline_SO_avg')
        
            save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', store_path,...
                char(rec_info.NLX_id), '_TFR_offline_SO_raw'),'offline_SO_TFRhann')
        
            save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', store_path,...
                char(rec_info.NLX_id), '_TFR_offline_SO_baseline_corr'),'offline_SO_TFRhann_corr')
        
            save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', store_path,...
                char(rec_info.NLX_id), '_avg_wave_online_SO'),'online_SO_avg')
        
            save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', store_path,...
                char(rec_info.NLX_id), '_TFR_online_SO_raw'),'online_SO_TFRhann')
        
            save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', store_path,...
                char(rec_info.NLX_id), '_TFR_online_SO_baseline_corr'),'online_SO_TFRhann_corr')
        
            if rec_info.StimProtocol == "SO_delayed"
                save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', store_path,...
                    char(rec_info.NLX_id), '_avg_wave_delayed_stim'),'delayed_stim_avg')
        
                save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', store_path,...
                    char(rec_info.NLX_id), '_TFR_delayed_stim_raw'),'delayed_stim_TFRhann')
        
                save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', store_path,...
                    char(rec_info.NLX_id), '_TFR_delayed_stim_baseline_corr'),'delayed_stim_TFRhann_corr')
            end
        
        end
        
    end 

end
