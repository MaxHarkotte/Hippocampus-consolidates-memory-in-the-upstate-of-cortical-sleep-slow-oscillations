% Extracts and exports various measures to comapare conditions
% Author: Max Harkotte (maximilian.harkotte@gmail.com)
% Date: December 2025
clear
close all
clc 

%% General measures per condition 
% - Time in NREM, preREM, REM sleep and WAKE 
% - Epoch count and average epoch length for each state 
% - NREM sleep latency (from begin) 
% - REM sleep latency (from begin) 
% - Total number and density of online detected SOs 
% - Total number and density of inhibitions
% - Total duration of inhibitions 
% - Mean duration of inhibitions 
% - Total number and density of offline detected SOs
% - Total number and density of offline detected spindles 

%% Overlap of inhibition with offline detected events 
% - Total number of offline SOs during inhibition (neg. peak) 
% - Total number of offline Spis during inhibition (either fully, or only
%   end or start during inhibition) 

%% SO - Spi coupling
% - SO - spindle coupling for offline and online detected SOs: spindle
% start within 1 seconds after neg2pos crossing (detection onset) 
% - Phase amplitude coupling (spi speak and inhibition relative to SO
% phase)

%% Optional additions
% - Quantification of online detected SOs: Peak2Peak amplitude, neg
%   amplitude, total duration

%% Paths
script_path = which('CL04_07_export_measures_for_condition_comparison.m');
script_path = strrep(char(script_path), '\', '/');
file_server_path = 'Z:/'; % if run locally
% file_server_path = '/gpfs01/born/animal/'; % if run on the cluster

% Paths to toolboxes and functions
root = strsplit(char(script_path),'00_Closed_Loop_Inhibition_CA1py/');
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/CircStat2012a/')); 
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/Neuralynx_Import_MEX/')); 
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/fieldtrip-20240722/')); 
ft_defaults

clear script_path; 
%% Recording information
reference = readtable(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/Documentation.xlsx'));

%% Select recordings for analysis
selection = reference( contains(reference.Phase,"Retention") & reference.Exclusion == "no", :);

%% Prepare tables 

arch_column_names = {'NLX_id', 'Animal', 'Phase', 'StimProtocol', 'WAKE_time', 'NREM_time', 'REM_time', 'preREM_time', ...
    'NREM_latency', 'REM_latency', 'preREM_latency', 'WAKE_epoch_number', 'NREM_epoch_number', ...
    'REM_epoch_number', 'preREM_epoch_number', 'WAKE_epoch_mean_dur', 'NREM_epoch_mean_dur', ...
    'REM_epoch_mean_dur', 'preREM_epoch_mean_dur', 'WAKE_epoch_sd_dur', 'NREM_epoch_sd_dur', ...
    'REM_epoch_sd_dur', 'preREM_epoch_dur', 'Order' };

events_column_names = { ...
    'NLX_id', 'Animal', 'Phase', 'StimProtocol', 'online_SO_count', 'online_SO_density', ...
    'inhibition_count', 'inhibition_density', 'inhibition_total_dur', 'mean_dur_inhibition', 'sd_dur_inhibition', ...
    'EEG_LF_offline_SO_count', 'EEG_RF_offline_SO_count', 'EEG_LP_offline_SO_count', 'EEG_RP_offline_SO_count', ...
    'EEG_LF_offline_SO_density', 'EEG_RF_offline_SO_density', 'EEG_LP_offline_SO_density', 'EEG_RP_offline_SO_density', ...
    'EEG_LF_offline_SO_amplitude', 'EEG_RF_offline_SO_amplitude', 'EEG_LP_offline_SO_amplitude', 'EEG_RP_offline_SO_amplitude', ...
    'EEG_LF_Spi_count', 'EEG_RF_Spi_count', 'EEG_LP_Spi_count', 'EEG_RP_Spi_count', ...
    'EEG_LF_Spi_density', 'EEG_RF_Spi_density', 'EEG_LP_Spi_density', 'EEG_RP_Spi_density', ...
    'EEG_LF_Spi_amplitude', 'EEG_RF_Spi_amplitude', 'EEG_LP_Spi_amplitude', 'EEG_RP_Spi_amplitude', ...
    'inhibited_LF_Spi_count', 'inhibited_RF_Spi_count', 'inhibited_LP_Spi_count', 'inhibited_RP_Spi_count', ...
    'inhibited_offline_LF_SOs_count', 'inhibited_offline_RF_SOs_count', 'inhibited_offline_LP_SOs_count', 'inhibited_offline_RP_SOs_count', ...
    'inhibited_LF_Spi_density', 'inhibited_RF_Spi_density', 'inhibited_LP_Spi_density', 'inhibited_RP_Spi_density', ...
    'inhibited_offline_LF_SOs_density', 'inhibited_offline_RF_SOs_density', 'inhibited_offline_LP_SOs_density', 'inhibited_offline_RP_SOs_density', ...
    'inhibited_LF_Spi_fraction', 'inhibited_RF_Spi_fraction', 'inhibited_LP_Spi_fraction', 'inhibited_RP_Spi_fraction', ...
    'inhibited_offline_LF_SOs_fraction', 'inhibited_offline_RF_SOs_fraction', 'inhibited_offline_LP_SOs_fraction', 'inhibited_offline_RP_SOs_fraction', ...
    'Order', ...
    'EEG_LF_solitary_online_SO_count', 'EEG_RF_solitary_online_SO_count', ...
    'EEG_LP_solitary_online_SO_count', 'EEG_RP_solitary_online_SO_count', ...
    'EEG_LF_solitary_online_SO_density', 'EEG_RF_solitary_online_SO_density', ...
    'EEG_LP_solitary_online_SO_density', 'EEG_RP_solitary_online_SO_density', ...
    'EEG_LF_coupled_online_SO_count', 'EEG_RF_coupled_online_SO_count', ...
    'EEG_LP_coupled_online_SO_count', 'EEG_RP_coupled_online_SO_count', ...
    'EEG_LF_coupled_online_SO_density', 'EEG_RF_coupled_online_SO_density', ...
    'EEG_LP_coupled_online_SO_density', 'EEG_RP_coupled_online_SO_density', ...
    'EEG_LF_solitary_Spi_count', 'EEG_RF_solitary_Spi_count', 'EEG_LP_solitary_Spi_count', 'EEG_RP_solitary_Spi_count', ...
    'EEG_LF_solitary_Spi_density', 'EEG_RF_solitary_Spi_density', ...
    'EEG_LP_solitary_Spi_density', 'EEG_RP_solitary_Spi_density', ...
    'EEG_LF_coupled_Spi_count', 'EEG_RF_coupled_Spi_count', 'EEG_LP_coupled_Spi_count', 'EEG_RP_coupled_Spi_count', ...
    'EEG_LF_coupled_Spi_density', 'EEG_RF_coupled_Spi_density', ...
    'EEG_LP_coupled_Spi_density', 'EEG_RP_coupled_Spi_density', ...
    'EEG_LF_online_SO_neg_amplitude', 'EEG_RF_online_SO_neg_amplitude', 'EEG_LP_online_SO_neg_amplitude', 'EEG_RP_online_SO_neg_amplitude', ...
    'EEG_LF_online_SO_peak2peak_amplitude', 'EEG_RF_online_SO_peak2peak_amplitude', 'EEG_LP_online_SO_peak2peak_amplitude', 'EEG_RP_online_SO_peak2peak_amplitude' ...
};

SOSpi_coupling_column_names = {'NLX_id', 'Animal', 'Phase', 'StimProtocol', 'Order', ...
    'LF_mean_phase_spi_band', 'RF_mean_phase_spi_band', 'LP_mean_phase_spi_band', 'RP_mean_phase_spi_band', ...
    'LF_mvl_spi_band', 'RF_mvl_spi_band', 'LP_mvl_spi_band', 'RP_mvl_spi_band', ...
    'LF_mean_phase_spi_events', 'RF_mean_phase_spi_events', 'LP_mean_phase_spi_events', 'RP_mean_phase_spi_events', ...
    'LF_mvl_spi_events', 'RF_mvl_spi_events', 'LP_mvl_spi_events', 'RP_mvl_spi_events', ...
    'LF_spi_events_count', 'RF_spi_events_count', 'LP_spi_events_count', 'RP_spi_events_count', ...
    'LF_spi_events_density', 'RF_spi_events_density', 'LP_spi_events_density', 'RP_spi_events_density', ...
    'LF_mean_phase_inh_onset', 'RF_mean_phase_inh_onset', 'LP_mean_phase_inh_onset', 'RP_mean_phase_inh_onset', ...
    'LF_mvl_inh_onset', 'RF_mvl_inh_onset', 'LP_mvl_inh_onset', 'RP_mvl_inh_onset', ...
    'LF_mean_phase_inh_offset', 'RF_mean_phase_inh_offset', 'LP_mean_phase_inh_offset', 'RP_mean_phase_inh_offset', ...
    'LF_mvl_inh_offset', 'RF_mvl_inh_offset', 'LP_mvl_inh_offset', 'RP_mvl_inh_offset'};

% Create a table with empty cells
SleepArch   = cell(size(selection,1), numel(arch_column_names)); 
SleepEvents = cell(size(selection,1), numel(events_column_names)); 
PhaseAmpCoupling = cell(size(selection,1), numel(SOSpi_coupling_column_names)); 

delayed_inhibited_spindle_dur = cell(4,1);
in_phase_inhibited_spindle_dur = cell(4,1);

%% Extract measures 
for iRec = 1:size(selection,1)
    %% Read in hypnogram
    % Recording information
    rec_info         = selection(iRec,:);
    recording_length = rec_info.RecLengthInMin*60; % in seconds

    % read in data and combine in one ft structure
    cfg         = [];
    cfg.dataset = strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/01_Neuralynx/', rec_info.NLX_id, '/');
    cfg.channel = {'EEG_left_frontal', 'EEG_right_frontal', 'EEG_left_parietal', 'EEG_right_parietal'};
    rec  = ft_preprocessing(cfg);

    % Cut to correct length
    fs             = rec.fsample; % in Hz
    cfg            = [];
    cfg.begsample  = 1;
    cfg.endsample  = recording_length*fs;
    rec            = ft_redefinetrial(cfg, rec);
    rec.sampleinfo = [1,recording_length*fs];

    % Store
    SleepArch(iRec,1) = rec_info.NLX_id; 
    SleepArch(iRec,2) = rec_info.Animal; 
    SleepArch(iRec,3) = rec_info.Phase;
    SleepArch(iRec,4) = rec_info.StimProtocol;
    SleepArch(iRec,24) = cellstr(num2str(rec_info.Order));

    SleepEvents(iRec,1) = rec_info.NLX_id; 
    SleepEvents(iRec,2) = rec_info.Animal; 
    SleepEvents(iRec,3) = rec_info.Phase;
    SleepEvents(iRec,4) = rec_info.StimProtocol;
    SleepEvents(iRec,60) = cellstr(num2str(rec_info.Order));

    PhaseAmpCoupling(iRec,1) = rec_info.NLX_id;
    PhaseAmpCoupling(iRec,2) = rec_info.Animal; 
    PhaseAmpCoupling(iRec,3) = rec_info.Phase;
    PhaseAmpCoupling(iRec,4) = rec_info.StimProtocol;
    PhaseAmpCoupling(iRec,5) = cellstr(num2str(rec_info.Order));

    % Hypnogram 
    tmp_hypno       = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/02_Sleep_Scorings/02_Matlab_files/', ...
        char(rec_info.NLX_id), '.mat'), 'SlStNew'); 
    hypno           = double(tmp_hypno.SlStNew.codes(1:recording_length/10,1));
    true_hypno = hypno;

    clear tmp_hypno;

    %% Read in detections
    % Offline detected events
    offline_events = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/01_Offline/', ...
        char(rec_info.NLX_id), '_events.mat'));
    offline_events = offline_events.detection_output;

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

    %% Hypnogram measures 
    % - Time in NREM, preREM, REM sleep and WAKE 
    % Discard artefact markers for architecture analysis
    hypno(hypno == 17) = 1; % messy Wake as Wake 
    hypno(hypno == 18) = 2; % messy NREM as NREM 
    hypno(hypno == 19) = 3; % messy REM as REM 
    hypno(hypno == 20) = 4; % messy preREM as preREM 

    % Total time per brain state in minutes
    WAKE_time   = (sum(hypno == 1 )*10)/60;
    NREM_time   = (sum(hypno == 2 )*10)/60;
    REM_time    = (sum(hypno == 3 )*10)/60;
    preREM_time = (sum(hypno == 4 )*10)/60;

    % Store
    SleepArch(iRec,5) = num2cell(WAKE_time); 
    SleepArch(iRec,6) = num2cell(NREM_time); 
    SleepArch(iRec,7) = num2cell(REM_time); 
    SleepArch(iRec,8) = num2cell(preREM_time); 
    
    % - NREM sleep latency (from begin) 
    % - REM sleep latency (from begin) 
    if any(hypno == 2)  
        NREM_latency   = (find(hypno == 2, 1)*10)/60;
    else
        NREM_latency = NaN; 
    end

    if any(hypno == 3)  
        REM_latency   = (find(hypno == 3, 1)*10)/60;
    else
        REM_latency = NaN; 
    end

    if any(hypno == 4)  
        preREM_latency   = (find(hypno == 4, 1)*10)/60;
    else
        preREM_latency = NaN; 
    end
    
    % Store
    SleepArch(iRec,9) = num2cell(NREM_latency); 
    SleepArch(iRec,10) = num2cell(REM_latency); 
    SleepArch(iRec,11) = num2cell(preREM_latency); 

    % - Epoch count and average epoch length for each state 
    for iState = 1:4

        % Extract epochs
        tmp_state = (hypno == iState);
        start_indices = find(diff(tmp_state) == 1) + 1;
        end_indices = find(diff(tmp_state) == -1) ;

        if tmp_state(1)
            start_indices = vertcat(0,start_indices);             
        end

        if tmp_state(end)
            end_indices = vertcat(end_indices, size(hypno,1));             
        end

        % Number of epochs 
        epochs = horzcat(start_indices, end_indices);
        epoch_number = size(epochs, 1);

        % Average epoch length [in seconds]
        mean_epoch_dur   = mean((end_indices-start_indices + 1)*10);
        sd_epoch_dur     = std((end_indices-start_indices + 1)*10);

        % Store 
        SleepArch(iRec,11+iState) = num2cell(epoch_number); 
        SleepArch(iRec,15+iState) = num2cell(mean_epoch_dur); 
        SleepArch(iRec,19+iState) = num2cell(sd_epoch_dur); 

    end

    %% Online detected SOs
    % - Total number and density of online detected SOs 
    online_SO_count = size(online_SO,1)/2; 
    SWS_epochs = sum(hypno == 2 | hypno == 4);
    SWS_time_min = SWS_epochs * 10 /60;

    SleepEvents(iRec,5) = num2cell(online_SO_count); % online SO count 
    SleepEvents(iRec,6) = num2cell(online_SO_count/SWS_time_min); % online SO count 

    %% Inhibition times 
    if rec_info.StimProtocol == "SO_delayed"
        % Identify ON and OFF indices
        onIdx  = find(delayed_stim.type == "StimON");
        offIdx = find(delayed_stim.type == "StimOFF");
        
        % Sanity check: make sure we have equal numbers
        nPairs = min(length(onIdx), length(offIdx));
        
        % Compute durations in seconds
        durations = (delayed_stim.sample(offIdx(1:nPairs)) - delayed_stim.sample(onIdx(1:nPairs))) / fs;
        
        % Basic stats
        totalDuration = sum(durations);          % total time of all events (s)
        meanDuration  = mean(durations);         % mean duration (s)
        stdDuration   = std(durations);          % standard deviation (s)

        SleepEvents(iRec,7) = num2cell(nPairs); % inhibitions count 
        SleepEvents(iRec,8) = num2cell(nPairs/SWS_time_min); % inhibitions density
        SleepEvents(iRec,9) = num2cell(totalDuration); % inhibitions total duration 
        SleepEvents(iRec,10) = num2cell(meanDuration); % inhibitions mean duration 
        SleepEvents(iRec,11) = num2cell(stdDuration); % inhibitions sd duration 
    elseif rec_info.StimProtocol == "SO_up_in_phase"
        % Identify ON and OFF indices
        onIdx  = find(online_SO.type == "SO_rising_flank");
        offIdx = find(online_SO.type == "SO_end");
        
        % Sanity check: make sure we have equal numbers
        nPairs = min(length(onIdx), length(offIdx));
        
        % Compute durations in seconds
        durations = (online_SO.sample(offIdx(1:nPairs)) - online_SO.sample(onIdx(1:nPairs))) / fs;
        
        % Basic stats
        totalDuration = sum(durations);          % total time of all events (s)
        meanDuration  = mean(durations);         % mean duration (s)
        stdDuration   = std(durations);          % standard deviation (s)

        SleepEvents(iRec,7) = num2cell(nPairs); % inhibitions count 
        SleepEvents(iRec,8) = num2cell(nPairs/SWS_time_min); % inhibitions density
        SleepEvents(iRec,9) = num2cell(totalDuration); % inhibitions total duration 
        SleepEvents(iRec,10) = num2cell(meanDuration); % inhibitions mean duration 
        SleepEvents(iRec,11) = num2cell(stdDuration); % inhibitions sd duration 
    end
    
    %% Offline detected events (SOs and spindles) for all four channels 
    % Define canonical order (must match your actual labels exactly)
    canonicalOrder = ["EEG_left_frontal", "EEG_left_parietal", ...
                      "EEG_right_frontal", "EEG_right_parietal"];
    
    % Get actual channel labels from your structure (convert to string for safety)
    availableChannels = string(offline_events.info.channel);

    % Initialize empty containers
    SO_count      = nan(1, numel(canonicalOrder));
    Spi_count      = nan(1, numel(canonicalOrder));
    SO_density    = nan(1, numel(canonicalOrder));
    SO_amplitude  = nan(1, numel(canonicalOrder));
    Spi_density   = nan(1, numel(canonicalOrder));
    Spi_amplitude = nan(1, numel(canonicalOrder));
    
    % Loop in the defined order
    for c = 1:numel(canonicalOrder)
        chanName = canonicalOrder(c);
        idx = find(availableChannels == chanName);
    
        if isempty(idx)
            warning('Channel "%s" not found in offline_events.info.channel.', chanName);
            continue
        end
    
        % Extract metrics
        SO_count(c)      = size(offline_events.slo.events{idx,1}, 2);
        SO_density(c)    = offline_events.slo.density(idx);
        SO_amplitude(c)  = mean(offline_events.slo.Peak2PeakAmp{idx,1});
        Spi_count(c)     = size(offline_events.spi.events{idx,1}, 2);
        Spi_density(c)   = offline_events.spi.density(idx);
        Spi_amplitude(c) = offline_events.spi.amp_mean(idx);
    end

    SleepEvents(iRec,12:15) = num2cell(SO_count); % offline SO count 
    SleepEvents(iRec,16:19) = num2cell(SO_density); % offline SO_density 
    SleepEvents(iRec,20:23) = num2cell(SO_amplitude); % offline SO_amplitude
    SleepEvents(iRec,24:27) = num2cell(Spi_count); % Spi count
    SleepEvents(iRec,28:31) = num2cell(Spi_density); % Spi_density
    SleepEvents(iRec,32:35) = num2cell(Spi_amplitude); % Spi_amplitude

    %% Overlap of inhibition with offline detected events (only for conditions where inhibition was applied)
    if rec_info.StimProtocol == "SO_delayed"
        onTimes  = delayed_stim.sample(find(delayed_stim.type == "StimON"));
        offTimes = delayed_stim.sample(find(delayed_stim.type == "StimOFF"));
        onTimes(offTimes > recording_length*fs) = [];
        offTimes(offTimes > recording_length*fs) = [];
    elseif rec_info.StimProtocol == "SO_up_in_phase"
        onTimes  = online_SO.sample(find(online_SO.type == "SO_rising_flank"));
        offTimes = online_SO.sample(find(online_SO.type == "SO_end"));
        onTimes(offTimes > recording_length*fs) = [];
        offTimes(offTimes > recording_length*fs) = [];
    end
        
    if rec_info.StimProtocol ~= "No_stim"
        for c = 1:numel(canonicalOrder)
            chanName = canonicalOrder{c};
            idx = find(strcmp(availableChannels, chanName));
        
            if isempty(idx)
                warning('Channel "%s" not found in offline_events.info.channel.', chanName);
                continue
            end
        
            spindles   = offline_events.spi.events{idx,1};   
            offline_SO = offline_events.slo.events{idx,1};   
        
            spiStart = spindles(1,:);
            spiEnd   = spindles(2,:);
            nSpindles = numel(spiStart);
        
            spi_overlapCount = 0;
            slo_overlapCount = 0;
        
            % Loop over inhibition windows
            for iInhibition = 1:numel(onTimes)
        
                tOn  = onTimes(iInhibition);
                tOff = offTimes(iInhibition);
        
                % ---------- Loop over spindles ----------
                for iSpi = 1:nSpindles
        
                    s = spiStart(iSpi);
                    e = spiEnd(iSpi);
        
                    % Overlap logic:
                    startInside      = (s >= tOn) && (s <= tOff);
                    endInside        = (e >= tOn) && (e <= tOff);
                    fullyInside      = (s >= tOn) && (e <= tOff);
                    aroundInhibition = (s <= tOn) && (e >= tOff);

                    if startInside || endInside || fullyInside || aroundInhibition
                        if startInside || endInside 
                            % Compute actual overlap duration
                            overlapStart_i = max(s, tOn);
                            overlapEnd_i   = min(e, tOff);
                            overlapDur_i   = overlapEnd_i - overlapStart_i;   % in samples
                        elseif fullyInside 
                            overlapDur_i =  spiEnd(iSpi) - spiStart(iSpi); 
                        elseif aroundInhibition
                            overlapDur_i =  tOff - tOn; 
                        end

                        % Store overlap duration
                        if rec_info.StimProtocol == "SO_delayed"
                            delayed_inhibited_spindle_dur{c} = ...
                                [delayed_inhibited_spindle_dur{c}, overlapDur_i];
                        elseif rec_info.StimProtocol == "SO_up_in_phase"
                            in_phase_inhibited_spindle_dur{c} = ...
                                [in_phase_inhibited_spindle_dur{c}, overlapDur_i];
                        end
                                
                        % Count inhibited spindles (≥500 samples)
                        if overlapDur_i >= 500
                            spi_overlapCount = spi_overlapCount + 1;
                        end
                    else

                    end
                end
        
                % Count SOs (neg2pos crossing) within window
                if any((offline_SO(2,:) >= tOn) & (offline_SO(2,:) <= tOff))
                    slo_overlapCount = slo_overlapCount + 1;
                end
        
            end
        
            % Store results
            SleepEvents(iRec,35+c) = num2cell(spi_overlapCount); % inhibited spindles count
            SleepEvents(iRec,39+c) = num2cell(slo_overlapCount); % inhibited SOs count 

            SleepEvents(iRec,43+c) = num2cell(spi_overlapCount/SWS_time_min); % inhibited spindles density
            SleepEvents(iRec,47+c) = num2cell(slo_overlapCount/SWS_time_min); % inhibited SOs density 

            SleepEvents(iRec,51+c) = num2cell(spi_overlapCount/nSpindles); % fraction inhibited spindles/all spindles
            SleepEvents(iRec,55+c) = num2cell(slo_overlapCount/size(offline_SO, 2)); % fraction inhibited SOs/all SOs

        end
    end

    %% SO (online) - Spindle (offline) coupling 
    % extract coupled versus solitary SOs/Spindles
    SO_rising_flank = online_SO.sample(online_SO.type == "SO_rising_flank");
    SO_times = SO_rising_flank(:);
    nSO = numel(SO_times);
    
    % Output per channel
    coupled_SO   = cell(numel(canonicalOrder),1);
    solitary_SO  = cell(numel(canonicalOrder),1);
    spindle_coupled = cell(numel(canonicalOrder),1);
    spindle_solitary = cell(numel(canonicalOrder),1);
    SO_index_for_spindle = cell(numel(canonicalOrder),1);
    
    coupling_window = 1000; % 1500 samples = 1.5 s at 1 kHz
    
    for c = 1:numel(canonicalOrder)
    
        chanName = canonicalOrder{c};
        idx = strcmp(availableChannels, chanName);
    
        % Extract spindles 
        spindles     = offline_events.spi.events{idx,1};
        sp_onset     = spindles(1,:)';
        nSp          = numel(sp_onset);
    
        % Initialize output for this channel
        sp_cpl       = false(nSp,1);
        so_idx_sp    = nan(nSp,1);
        so_has_sp    = false(nSO,1);
    
        for iSO = 1:nSO
            tSO = SO_times(iSO);
    
            % Spindles starting within 1.5 s after SO
            idxSp = find(sp_onset - tSO > 0 & sp_onset - tSO <= coupling_window);
    
            if ~isempty(idxSp)
                sp_cpl(idxSp) = true;
                so_idx_sp(idxSp) = iSO;
                so_has_sp(iSO) = true;
            end
        end
    
        % Store results for phase amplitude coupling
        spindle_coupled{c}        = sp_cpl;
        spindle_solitary{c}        = ~sp_cpl;
        SO_index_for_spindle{c}   = so_idx_sp;
        coupled_SO{c}             = so_has_sp;
        solitary_SO{c}            = ~so_has_sp;

        % Store summary of results
        SleepEvents(iRec,60+c) = num2cell(sum(~so_has_sp)); % solitary SOs count
        SleepEvents(iRec,64+c) = num2cell(sum(~so_has_sp)/SWS_time_min); % solitary SOs density
        SleepEvents(iRec,68+c) = num2cell(sum(so_has_sp)); % coupled SOs count
        SleepEvents(iRec,72+c) = num2cell(sum(so_has_sp)/SWS_time_min); % coupled SOs density        

        SleepEvents(iRec,76+c) = num2cell(sum(~sp_cpl)); % solitary Spis count
        SleepEvents(iRec,80+c) = num2cell(sum(~sp_cpl)/SWS_time_min); % solitary Spis density
        SleepEvents(iRec,84+c) = num2cell(sum(sp_cpl)); % coupled Spis count
        SleepEvents(iRec,88+c) = num2cell(sum(sp_cpl)/SWS_time_min); % coupled Spis density    
        
    end
    
    %% Phase-Amplitude coupling of coupled SOs/spindles 
    % Parameters
    SO_order = 3;              % order of butterworth filter 
    SO_fcutlow = 0.95;          % low cut frequency in Hz
    SO_fcuthigh = 1.05;           % high cut frequency in Hz

    Spi_order = 6;              % order of butterworth filter 
    Spi_fcutlow = 10;          % low cut frequency in Hz
    Spi_fcuthigh = 16;           % high cut frequency in Hz

    win_sec = 1;
    win_samps = round(win_sec * fs);
    coupling_window = win_samps;     % ±coupling_window around SO

    % Design filters
    [SOFilterHigh1,SOFilterHigh2] = butter(SO_order,2*SO_fcutlow/fs,'high');
    [SOFilterLow1,SOFilterLow2] = butter(SO_order,2*SO_fcuthigh/fs,'low');

    [SpiFilterHigh1,SpiFilterHigh2] = butter(Spi_order,2*Spi_fcutlow/fs,'high');
    [SpiFilterLow1,SpiFilterLow2] = butter(Spi_order,2*Spi_fcuthigh/fs,'low');

    % SOs are only detected in frontal channel 
    SO_rising_flank = online_SO.sample(online_SO.type == "SO_rising_flank");
    SO_times = SO_rising_flank(:);
    nSO = numel(SO_times);

    for c = 1:numel(canonicalOrder)

        chanName = canonicalOrder{c};
        idx = strcmp(availableChannels, chanName);

        cfg         = [];
        cfg.channel = {canonicalOrder{c}};
        raw         = ft_selectdata(cfg, rec);

        raw = raw.trial{1,1};
    
        % Filter and analytic signals (use filtfilt)
        so_filt = filtfilt(SOFilterHigh1,SOFilterHigh2,raw);
        so_filt = filtfilt(SOFilterLow1,SOFilterLow2,so_filt);
        so_hilb = hilbert(so_filt);
        so_phase = angle(so_hilb);       % radians
        
        spi_filt = filtfilt(SpiFilterHigh1,SpiFilterHigh2,raw);
        spi_filt = filtfilt(SpiFilterLow1,SpiFilterLow2,spi_filt);
        spi_env  = abs(hilbert(spi_filt));  % amplitude envelope
        
        % Find spindle peak amplitudes and times (in samples)
        spindles   = offline_events.spi.events{idx,1};
        sp_on = spindles(1,:);   % 1 x N
        sp_off = spindles(2,:);
        nSp = numel(sp_on);

        % Initialize spindle peaks 
        sp_peak = NaN(nSp,2);
        
        for iSpi = 1:nSp
            [amp, idx] = max(spi_env(sp_on(iSpi):sp_off(iSpi)));
            sp_peak(iSpi,1) = sp_on(iSpi) + idx -1;
            sp_peak(iSpi,2) = amp;            
        end
        
        % Collect spindle peaks that fall within ±coupling_window around each SO
        all_phases = NaN(nSO,3); % phase of peak in spindle band 
        spindle_phases = []; % phase of peak of detected spindles  
        spindle_amps   = []; % peak of detected spindles 

        for iSO = 1:nSO
            so_samp = SO_times(iSO);

            % window bounds
            lb = so_samp - coupling_window;
            ub = so_samp + coupling_window;

            if ub > recording_length*fs
                continue
            end

            % Extract peaks (and their phase) in spindle band around SO
            [amp, idx] = max(spi_env(lb:ub));
            all_phases(iSO,1) = lb + idx -1;
            all_phases(iSO,2) = amp;  
            all_phases(iSO,3) = so_phase(lb+idx-1);  

            % find spindle-peak times within window (on detected spindles)
            sel = find(sp_peak(:,1) >= lb & sp_peak(:,1) <= ub);

            if ~isempty(sel)
                % collect phases at those peak times
                phases_here = so_phase(sp_peak(sel,1));
                amps_here   = sp_peak(sel,2);
                spindle_phases = [spindle_phases; phases_here(:)];
                spindle_amps = [spindle_amps; amps_here(:)];
            end
        end

        valid = ~isnan(all_phases(:,3)); % identify SOs which window bounderies were not outside the rec

        % Find phase of inhibition onset and offset for inhibition
        % condition 
        if rec_info.StimProtocol == "SO_delayed"
            onTimes  = delayed_stim.sample(find(delayed_stim.type == "StimON"));
            offTimes = delayed_stim.sample(find(delayed_stim.type == "StimOFF"));
            onTimes(offTimes > recording_length*fs) = [];
            offTimes(offTimes > recording_length*fs) = [];
            inhibition_onset_phases = so_phase(onTimes);
            inhibition_offset_phases = so_phase(offTimes);

            PhaseAmpCoupling(iRec,29+c) = num2cell(circ_mean(inhibition_onset_phases')); % mean phase inhibition onset
            PhaseAmpCoupling(iRec,33+c) = num2cell(circ_r(inhibition_onset_phases')); % mean vector length inhibition onset
            PhaseAmpCoupling(iRec,37+c) = num2cell(circ_mean(inhibition_offset_phases')); % mean phase inhibition offset
            PhaseAmpCoupling(iRec,41+c) = num2cell(circ_r(inhibition_offset_phases')); % mean vector length inhibition offset
        elseif rec_info.StimProtocol == "SO_up_in_phase"
            onTimes  = online_SO.sample(find(online_SO.type == "SO_rising_flank"));
            offTimes = online_SO.sample(find(online_SO.type == "SO_end"));
            onTimes(onTimes > recording_length*fs) = [];
            offTimes(offTimes > recording_length*fs) = [];
            inhibition_onset_phases = so_phase(onTimes);
            inhibition_offset_phases = so_phase(offTimes);

            PhaseAmpCoupling(iRec,29+c) = num2cell(circ_mean(inhibition_onset_phases')); % mean phase inhibition onset
            PhaseAmpCoupling(iRec,33+c) = num2cell(circ_r(inhibition_onset_phases')); % mean vector length inhibition onset
            PhaseAmpCoupling(iRec,37+c) = num2cell(circ_mean(inhibition_offset_phases')); % mean phase inhibition offset
            PhaseAmpCoupling(iRec,41+c) = num2cell(circ_r(inhibition_offset_phases')); % mean vector length inhibition offset
        end

 
        % Store results 
        PhaseAmpCoupling(iRec,5+c) = num2cell(circ_mean(all_phases(valid,3))); % mean phase spindle band 
        PhaseAmpCoupling(iRec,9+c) = num2cell(circ_r(all_phases(valid,3))); % mean vector length spindle band 

        if ~isempty(spindle_phases) 
            PhaseAmpCoupling(iRec,13+c) = num2cell(circ_mean(spindle_phases)); % mean phase spindle events
            PhaseAmpCoupling(iRec,17+c) = num2cell(circ_r(spindle_phases)); % mean vector length spindle events
        end

        PhaseAmpCoupling(iRec,21+c) = num2cell(length(spindle_phases)); % number of spindle events
        PhaseAmpCoupling(iRec,25+c) = num2cell(length(spindle_phases)/SWS_time_min); % density of spindle events
        
    end

    %% Amplitude measures for online detected SOs 
    SO_order = 3;              % order of butterworth filter 
    SO_fcutlow = 0.1;          % low cut frequency in Hz
    SO_fcuthigh = 4;           % high cut frequency in Hz

    win_sec = 0.5;
    win_samps = round(win_sec * fs);
    SO_window = win_samps;     % ±coupling_window around SO

    % Design filters
    [SOFilterHigh1,SOFilterHigh2] = butter(SO_order,2*SO_fcutlow/fs,'high');
    [SOFilterLow1,SOFilterLow2] = butter(SO_order,2*SO_fcuthigh/fs,'low');

    % SOs are only detected in frontal channel 
    SO_rising_flank = online_SO.sample(online_SO.type == "SO_rising_flank");
    SO_times = SO_rising_flank(:);
    nSO = numel(SO_times);

    for c = 1:numel(canonicalOrder)

        chanName = canonicalOrder{c};
        idx = strcmp(availableChannels, chanName);

        cfg         = [];
        cfg.channel = {canonicalOrder{c}};
        raw         = ft_selectdata(cfg, rec);

        raw = raw.trial{1,1};
    
        % Filter and analytic signals (use filtfilt)
        so_filt = filtfilt(SOFilterHigh1,SOFilterHigh2,raw);
        so_filt = filtfilt(SOFilterLow1,SOFilterLow2,so_filt);

        all_amps = NaN(nSO,3); % phase of peak in spindle band 

        for iSO = 1:nSO
            so_samp = SO_times(iSO);

            if so_samp + SO_window > recording_length*fs
                continue
            end


            % Extract peaks (and their phase) in spindle band around SO
            [amp, idx] = min(so_filt(so_samp - SO_window:so_samp));
            [P2P_amp, idx2] = max(so_filt(so_samp:so_samp + SO_window));

            all_amps(iSO,1) = lb + idx -1;
            all_amps(iSO,2) = amp;    % neg peak
            all_amps(iSO,3) = abs(amp) + P2P_amp;    % Peak2Peak amp


        end

        % Store results 
        SleepEvents(iRec,92+c) = num2cell(mean(all_amps(:,2),'omitnan')); % mean phase spindle band 
        SleepEvents(iRec,96+c) = num2cell(mean(all_amps(:,3),'omitnan')); % mean vector length spindle band 
        
    end


end

%% Store output
SleepArch = cell2table(SleepArch, 'VariableNames', arch_column_names);
SleepEvents = cell2table(SleepEvents, 'VariableNames', events_column_names);
PhaseAmpCoupling = cell2table(PhaseAmpCoupling, 'VariableNames', SOSpi_coupling_column_names);

% In one animal the online SO detection did not work during no_stim
ix = SleepEvents.Animal == "CL04-07-MPV0120-BE2" & ...
     SleepEvents.StimProtocol == "No_stim";
SleepEvents{ix, {'online_SO_count','online_SO_density'}} = NaN;

ix = PhaseAmpCoupling.Animal == "CL04-07-MPV0120-BE2" & ...
     PhaseAmpCoupling.StimProtocol == "No_stim";
PhaseAmpCoupling(ix , :) = [];

% Store 
file_path = strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/03_Sleep_parameters/');

writetable(SleepArch, strcat(file_path, 'Sleep_architecture.csv'));
writetable(SleepEvents, strcat(file_path, 'Sleep_event_parameters.csv'));
writetable(PhaseAmpCoupling, strcat(file_path, 'PhaseAmpCoupling.csv'));

%% Plot inhibited spindles duration as histogram 
figure;
subplot(1,2,1)
histogram(delayed_inhibited_spindle_dur{3} / 1000, 60);
xlabel('Overlap duration (s)');
xline(0.5,'r')
ylabel('Count');
title('Delayed: spindle inhibition duration');

subplot(1,2,2)
histogram(in_phase_inhibited_spindle_dur{3} / 1000, 60);
xlabel('Overlap duration (s)');
xline(0.5,'r')
ylabel('Count');
title('In Phase: spindle inhibition duration');

%% Circular plots for SO-Spi coupling

%% Overall
figure;
subplot(1,2,1)
circ_plot(PhaseAmpCoupling.LF_mean_phase_spi_events, 'pretty');
t1 = title('Spindle peak (events) relative to SO phase');
t1.Position(2) = t1.Position(2) + 0.15; 
subplot(1,2,2)
circ_plot(PhaseAmpCoupling.LF_mean_phase_spi_band, 'pretty');
t2 = title('Spindle band peak relative to SO phase');
t2.Position(2) = t2.Position(2) + 0.15; 

%% Per condition 

% Per condition 
idx_in_phase = find(PhaseAmpCoupling.StimProtocol == "SO_up_in_phase");
idx_delayed = find(PhaseAmpCoupling.StimProtocol == "SO_delayed");
idx_no_stim = find(PhaseAmpCoupling.StimProtocol == "No_stim");

figure;

% In Phase 
subplot(1,3,1)
circ_plot(PhaseAmpCoupling.LF_mean_phase_spi_events(idx_in_phase), 'pretty');
hold on;

r = 1;  % unit radius used by CircStat plots

% --- inhibition onset ---
a_on = cell2mat(PhaseAmpCoupling.LF_mean_phase_inh_onset(idx_in_phase));
mu_on = circ_mean(a_on);
sd_on = circ_std(a_on);
sem_on = sd_on / sqrt(length(a_on));

% wrap angles (important for ± crossing)
upper_on = angle(exp(1i*(mu_on + sem_on)));
lower_on = angle(exp(1i*(mu_on - sem_on)));

% --- inhibition offset ---
a_off = cell2mat(PhaseAmpCoupling.LF_mean_phase_inh_offset(idx_in_phase));
mu_off = circ_mean(a_off);
sd_off = circ_std(a_off);
sem_off = sd_off / sqrt(length(a_off));

upper_off = angle(exp(1i*(mu_off + sem_off)));
lower_off = angle(exp(1i*(mu_off - sem_off)));

% === plot mean rays ===
plot([0 r*cos(mu_on)],  [0 r*sin(mu_on)],  'r-', 'LineWidth', 2);
plot([0 r*cos(mu_off)], [0 r*sin(mu_off)], 'b-', 'LineWidth', 2);

% === plot SEM rays ===
plot([0 r*cos(upper_on)],  [0 r*sin(upper_on)],  'r--', 'LineWidth', 1);
plot([0 r*cos(lower_on)],  [0 r*sin(lower_on)],  'r--', 'LineWidth', 1);

plot([0 r*cos(upper_off)], [0 r*sin(upper_off)], 'b--', 'LineWidth', 1);
plot([0 r*cos(lower_off)], [0 r*sin(lower_off)], 'b--', 'LineWidth', 1);

t1 = title('In-Phase');

t1.Position(2) = t1.Position(2) + 0.15; 

% Delayed 
subplot(1,3,2)
circ_plot(PhaseAmpCoupling.LF_mean_phase_spi_events(idx_delayed), 'pretty');
hold on;

% --- inhibition onset ---
a_on = cell2mat(PhaseAmpCoupling.LF_mean_phase_inh_onset(idx_delayed));
mu_on = circ_mean(a_on);
sd_on = circ_std(a_on);
sem_on = sd_on / sqrt(length(a_on));

% wrap angles (important for ± crossing)
upper_on = angle(exp(1i*(mu_on + sem_on)));
lower_on = angle(exp(1i*(mu_on - sem_on)));

% --- inhibition offset ---
a_off = cell2mat(PhaseAmpCoupling.LF_mean_phase_inh_offset(idx_delayed));
mu_off = circ_mean(a_off);
sd_off = circ_std(a_off);
sem_off = sd_off / sqrt(length(a_off));

upper_off = angle(exp(1i*(mu_off + sem_off)));
lower_off = angle(exp(1i*(mu_off - sem_off)));

% === plot mean rays ===
plot([0 r*cos(mu_on)],  [0 r*sin(mu_on)],  'r-', 'LineWidth', 2);
plot([0 r*cos(mu_off)], [0 r*sin(mu_off)], 'b-', 'LineWidth', 2);

% === plot SEM rays ===
plot([0 r*cos(upper_on)],  [0 r*sin(upper_on)],  'r--', 'LineWidth', 1);
plot([0 r*cos(lower_on)],  [0 r*sin(lower_on)],  'r--', 'LineWidth', 1);

plot([0 r*cos(upper_off)], [0 r*sin(upper_off)], 'b--', 'LineWidth', 1);
plot([0 r*cos(lower_off)], [0 r*sin(lower_off)], 'b--', 'LineWidth', 1);

t2 = title('Delayed');
t2.Position(2) = t2.Position(2) + 0.15; 

% No stim 
subplot(1,3,3)
circ_plot(PhaseAmpCoupling.LF_mean_phase_spi_events(idx_no_stim ), 'pretty');
t3 = title('No stim');

t3.Position(2) = t3.Position(2) + 0.15; 

%% Statistics
% Extract phases
phi_in   = PhaseAmpCoupling.LF_mean_phase_spi_events(idx_in_phase);
phi_del  = PhaseAmpCoupling.LF_mean_phase_spi_events(idx_delayed);
phi_no   = PhaseAmpCoupling.LF_mean_phase_spi_events(idx_no_stim);

% Concatenate
phi_all = [phi_in; phi_del; phi_no];

% Group labels
grp = [ ...
    ones(numel(phi_in),1); ...
    2*ones(numel(phi_del),1); ...
    3*ones(numel(phi_no),1) ];

% Watson–Williams test
[p, table] = circ_wwtest(phi_all, grp);

fprintf('Watson–Williams p = %.4f\n', p)

%%
animals = unique(PhaseAmpCoupling.AnimalID);

mu_in  = nan(numel(animals),1);
mu_del = nan(numel(animals),1);
mu_no  = nan(numel(animals),1);

for a = 1:numel(animals)
    iA = PhaseAmpCoupling.AnimalID == animals(a);

    mu_in(a)  = circ_mean(PhaseAmpCoupling.LP_mean_phase_spi_events(iA & idx_in_phase));
    mu_del(a) = circ_mean(PhaseAmpCoupling.LP_mean_phase_spi_events(iA & idx_delayed));
    mu_no(a)  = circ_mean(PhaseAmpCoupling.LP_mean_phase_spi_events(iA & idx_no_stim));
end

[p1,~] = circ_wwtest([mu_in; mu_del], [ones(size(mu_in)); 2*ones(size(mu_del))]);
[p2,~] = circ_wwtest([mu_in; mu_no ], [ones(size(mu_in)); 2*ones(size(mu_no ))]);
[p3,~] = circ_wwtest([mu_del;mu_no ], [ones(size(mu_del));2*ones(size(mu_no ))]);



