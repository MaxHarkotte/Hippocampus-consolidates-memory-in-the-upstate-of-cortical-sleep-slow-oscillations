% Cluster-based permutation test comparing time-frequency plots 
% Author: Max Harkotte (maximilian.harkotte@gmail.com)
% Date: December 2025
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
channel      = 'EEG_left_frontal';
channel_path = '01_EEG_left_frontal/';

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
            char(rec_info.NLX_id), '_TFR_offline_SO_baseline_corr.mat'));
        tmp_fft_online = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_online_SO_baseline_corr.mat'));;

        % store in cell array instead of dynamic fieldname
        no_stim_dat.offline.fft{iNo_Stim}      = tmp_fft_offline.offline_SO_TFRhann_corr;
        no_stim_dat.online.fft{iNo_Stim}       = tmp_fft_online.online_SO_TFRhann_corr;

        iNo_Stim = iNo_Stim +1;

        clear tmp_fft_offline  tmp_fft_online ;

    elseif rec_info.StimProtocol == "SO_up_in_phase"
        % read in data
        tmp_fft_offline = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_offline_SO_baseline_corr.mat'));
        tmp_fft_online = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_online_SO_baseline_corr.mat'));

        % store in cell array instead of dynamic fieldname
        in_phase_dat.offline.fft{iIn_Phase}      = tmp_fft_offline.offline_SO_TFRhann_corr;
        in_phase_dat.online.fft{iIn_Phase}       = tmp_fft_online.online_SO_TFRhann_corr;

        iIn_Phase = iIn_Phase +1;

        clear tmp_fft_offline tmp_fft_online;

    elseif rec_info.StimProtocol == "SO_delayed"
        % read in data
        tmp_fft_offline = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_offline_SO_baseline_corr.mat'));
        tmp_fft_online = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_online_SO_baseline_corr.mat'));
        tmp_fft_stim = load(strcat(char(root(1)), ...
            '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/02_Time_Frequency_Data/', channel_path, '01_Without_trials/', ...
            char(rec_info.NLX_id), '_TFR_delayed_stim_baseline_corr.mat'));

        % store in cell array instead of dynamic fieldname
        delayed_dat.offline.fft{iDelayed}      = tmp_fft_offline.offline_SO_TFRhann_corr;
        delayed_dat.online.fft{iDelayed}       = tmp_fft_online.online_SO_TFRhann_corr;
        delayed_dat.stim.fft{iDelayed}         = tmp_fft_stim.delayed_stim_TFRhann_corr;
        iDelayed = iDelayed +1;

        clear tmp_fft_offline tmp_fft_online tmp_fft_stim;
    end
end

%% Prepare data 
no_stim = selection(contains(selection.StimProtocol,"No_stim"), :);
in_phase = selection(contains(selection.StimProtocol,"SO_up_in_phase"), :);
delayed = selection(contains(selection.StimProtocol,"SO_delayed"), :);

% Find animal IDs 
ID1 = no_stim.Animal;
ID2 = in_phase.Animal;
ID3 = delayed.Animal;
commonIDs = intersect(intersect(ID1, ID2), ID3);

% In one animal the online SO detection during No_stim did not work
commonIDs(strcmp(commonIDs, 'CL04-07-MPV0120-BE2') ) = [];

% get indices for each table
idx1 = find(ismember(ID1, commonIDs));
idx2 = find(ismember(ID2, commonIDs));
idx3 = find(ismember(ID3, commonIDs));

freq_no_stim   = no_stim_dat.online.fft(idx1);
freq_in_phase  = in_phase_dat.online.fft(idx2);
freq_delayed   = delayed_dat.stim.fft(idx3);

%% Cluster based permutation test 
nSubj = numel(freq_no_stim);

design = zeros(2, 2*nSubj);
design(1,:) = [1:nSubj 1:nSubj];
design(2,:) = [ones(1,nSubj) 2*ones(1,nSubj)];

cfg = [];
cfg.parameter     = 'powspctrm';
cfg.method        = 'montecarlo';
cfg.statistic     = 'depsamplesT';
cfg.correctm      = 'cluster';
cfg.clusteralpha  = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.tail          = 0;     % two-sided test
cfg.alpha         = 0.05;
cfg.numrandomization = 5000;

cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;

freqAB = [freq_no_stim, freq_in_phase];
stat_AB = ft_freqstatistics(cfg, freqAB{:});

freqAC = [freq_no_stim, freq_delayed];
stat_AC = ft_freqstatistics(cfg, freqAC{:});

freqBC = [freq_in_phase, freq_delayed];
stat_BC = ft_freqstatistics(cfg, freqBC{:});

