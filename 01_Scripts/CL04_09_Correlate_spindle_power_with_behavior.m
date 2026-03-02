% Plot Time Frequency Plots (baseline corrected) of offline and online detected SOs
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
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/fieldtrip-20240722/')); 
ft_defaults

clear script_path; 

%% Recording information
reference = readtable(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/Documentation.xlsx'));

%% Select recordings for analysis
selection = reference( contains(reference.Phase,"Retention") & reference.Exclusion == "no", :);

% select channels 
channel      = 'EEG_left_parietal/';
channel_path = '03_EEG_left_parietal/';

% raw or baseline corrected TFR
%type = "_baseline_corr.mat";
type = "_raw.mat";

%% read in Behavior data 
behavior = readtable(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/11_Behavior_Scorings/02_Tables/02_Data_Summary/CL04-TestClean.csv'));

exclude = { ...
    'CL04-02-MPV0120-RD1', ... % no expression in right HC
    'CL04-04-MPV0120-BE1', ... % recording issues during retention interval
    'CL04-06-MPV0120-RD1', ... % abnormal histology (enlarged ventricles)
    'CL04-11-MPV0120-RD1'};    % no expression in left HC

behavior = behavior(~ismember(behavior.Animal, exclude), :);
behavior.Cum_DiRa_min_5 = str2double(strrep(behavior.Cum_DiRa_min_5, ',', '.'));

%% Read in preprocessed data
no_stim_dat  = struct();
in_phase_dat = struct();
delayed_dat  = struct();
iNo_Stim     = 1; 
iIn_Phase    = 1; 
iDelayed     = 1; 

for iRec = 1 :size(selection,1)
    rec_info = selection(iRec,:);

    if rec_info.StimProtocol == "No_stim"
        % read in data
        tmp_fft_offline = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_offline_SO', type));
        tmp_wave_offline = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_avg_wave_offline_SO.mat'));
        tmp_fft_online = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_online_SO', type));
        tmp_wave_online = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_avg_wave_online_SO.mat'));

        % store in cell array instead of dynamic fieldname
        no_stim_dat.offline.fft{iNo_Stim}      = tmp_fft_offline.offline_SO_TFRhann; % tmp_fft_offline.offline_SO_TFRhann_corr
        no_stim_dat.offline.waveform{iNo_Stim} = tmp_wave_offline.offline_SO_avg;
        no_stim_dat.online.fft{iNo_Stim}       = tmp_fft_online.online_SO_TFRhann; % tmp_fft_online.online_SO_TFRhann_corr
        no_stim_dat.online.waveform{iNo_Stim}  = tmp_wave_online.online_SO_avg;

        iNo_Stim = iNo_Stim +1;

        clear tmp_fft_offline tmp_wave_offline tmp_fft_online tmp_wave_online;

    elseif rec_info.StimProtocol == "SO_up_in_phase"
        % read in data
        tmp_fft_offline = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_offline_SO_baseline_corr.mat'));
        tmp_wave_offline = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_avg_wave_offline_SO.mat'));
        tmp_fft_online = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_online_SO_baseline_corr.mat'));
        tmp_wave_online = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_avg_wave_online_SO.mat'));

        % store in cell array instead of dynamic fieldname
        in_phase_dat.offline.fft{iIn_Phase}      = tmp_fft_offline.offline_SO_TFRhann_corr;
        in_phase_dat.offline.waveform{iIn_Phase} = tmp_wave_offline.offline_SO_avg;
        in_phase_dat.online.fft{iIn_Phase}       = tmp_fft_online.online_SO_TFRhann_corr;
        in_phase_dat.online.waveform{iIn_Phase}  = tmp_wave_online.online_SO_avg;

        iIn_Phase = iIn_Phase +1;

        clear tmp_fft_offline tmp_wave_offline tmp_fft_online tmp_wave_online;

    elseif rec_info.StimProtocol == "SO_delayed"
        % read in data
        tmp_fft_offline = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_offline_SO_baseline_corr.mat'));
        tmp_wave_offline = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_avg_wave_offline_SO.mat'));
        tmp_fft_online = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_online_SO_baseline_corr.mat'));
        tmp_wave_online = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_avg_wave_online_SO.mat'));
        tmp_fft_stim = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_delayed_stim_baseline_corr.mat'));
        tmp_wave_stim = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_avg_wave_delayed_stim.mat'));

        % store in cell array instead of dynamic fieldname
        delayed_dat.offline.fft{iDelayed}      = tmp_fft_offline.offline_SO_TFRhann_corr;
        delayed_dat.offline.waveform{iDelayed} = tmp_wave_offline.offline_SO_avg;
        delayed_dat.online.fft{iDelayed}       = tmp_fft_online.online_SO_TFRhann_corr;
        delayed_dat.online.waveform{iDelayed}  = tmp_wave_online.online_SO_avg;
        delayed_dat.stim.fft{iDelayed}         = tmp_fft_stim.delayed_stim_TFRhann_corr;
        delayed_dat.stim.waveform{iDelayed}    = tmp_wave_stim.delayed_stim_avg;
        iDelayed = iDelayed +1;

        clear tmp_fft_offline tmp_wave_offline tmp_fft_online tmp_wave_online tmp_fft_stim tmp_wave_stim;
    end
end

%% Prepare data for correlations 
no_stim = selection(contains(selection.StimProtocol,"No_stim"), :);
no_stim.Animal(strcmp(no_stim.Animal, 'CL04-07-MPV0120-BE2') ) = cellstr('Exclude'); % In one animal the online SO detection during No_stim did not work
in_phase = selection(contains(selection.StimProtocol,"SO_up_in_phase"), :);
delayed = selection(contains(selection.StimProtocol,"SO_delayed"), :);

freq_in_phase_all  = in_phase_dat.online.fft;
freq_delayed_all   = delayed_dat.online.fft;

idx3 = contains(no_stim.Animal,"Exclude");
freq_no_stim_all   = no_stim_dat.online.fft(~idx3);

DR_no_stim_all = behavior(contains(behavior.Condition,"No_stim"), :);
DR_no_stim_all(contains(DR_no_stim_all.Animal,"CL04-07-MPV0120-BE2"), :) = [];

DR_in_phase_all = behavior(contains(behavior.Condition,"SO_up_in_phase"), :);
DR_delayed_all = behavior(contains(behavior.Condition,"SO_delayed"), :);

%% Extract average power in the spindle band during the 1 second after online detected SOs 

freq_band = [10 16];   % spindle band
time_win  = [5 6];     % 1 s after event
ctrl_win  = [2.5 3.5];

nSubj = numel(freq_no_stim_all);
spindle_power_no_stim = nan(nSubj,1);

for s = 1:nSubj

    freq = freq_no_stim_all{s};

    % --- select freq × time window ---
    f_idx = freq.freq >= freq_band(1) & freq.freq <= freq_band(2);
    t_idx = freq.time >= time_win(1) & freq.time <= time_win(2);
    t_idx_ctrl = freq.time >= ctrl_win(1) & freq.time <= ctrl_win(2);

    % --- extract power ---
    pow = freq.powspctrm(1, f_idx, t_idx);   % chan × freq × time
    pow_ctrl = freq.powspctrm(1, f_idx, t_idx_ctrl);   % chan × freq × time
    

    % --- average over freq and time ---
    spindle_power_no_stim(s) = max(pow(:))/max(pow_ctrl(:));
end


behav = DR_no_stim_all.Cum_DiRa_min_5(:);

[r,p] = corr(spindle_power_no_stim, behav, ...
             'type','Pearson','rows','complete');

fprintf('Spearman rho = %.3f, p = %.4f\n', r, p);

figure;
scatter(spindle_power_no_stim, behav, 60, 'filled')
xlabel('10–16 Hz power (5–6 s)')
ylabel('Behavior')
lsline
title(sprintf('Spindle band correlation (\\rho = %.2f)', r))

