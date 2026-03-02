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
        no_stim_dat.offline.fft{iNo_Stim}      = tmp_fft_offline.offline_SO_TFRhann_corr;
        no_stim_dat.offline.waveform{iNo_Stim} = tmp_wave_offline.offline_SO_avg;
        no_stim_dat.online.fft{iNo_Stim}       = tmp_fft_online.online_SO_TFRhann_corr;
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

%% Prepare data for cluster based statistics
no_stim = selection(contains(selection.StimProtocol,"No_stim"), :);
no_stim.Animal(strcmp(no_stim.Animal, 'CL04-07-MPV0120-BE2') ) = cellstr('Exclude'); % In one animal the online SO detection during No_stim did not work
in_phase = selection(contains(selection.StimProtocol,"SO_up_in_phase"), :);
delayed = selection(contains(selection.StimProtocol,"SO_delayed"), :);

freq_in_phase_all  = in_phase_dat.online.fft;
freq_delayed_all   = delayed_dat.stim.fft;

idx3 = contains(no_stim.Animal,"Exclude");
freq_no_stim_all   = no_stim_dat.online.fft(~idx3);

% Prepare comparisons 
% No stim vs. in-phase
ID1 = no_stim.Animal;
ID2 = in_phase.Animal;

% Find common animals AND matching order
[commonIDs, idx1, idx2] = intersect(ID1, ID2, 'stable');

freq_no_stim_comp_in_phase   = no_stim_dat.online.fft(idx1);
freq_in_phase_comp_no_stim  = in_phase_dat.online.fft(idx2);

% No stim vs. delayed
ID1 = no_stim.Animal;
ID2 = delayed.Animal;

% Find common animals AND matching order
[commonIDs, idx1, idx2] = intersect(ID1, ID2, 'stable');

freq_no_stim_comp_delayed   = no_stim_dat.online.fft(idx1);
freq_delayed_comp_no_stim  = delayed_dat.online.fft(idx2);

% In-phase vs. delayed
ID1 = in_phase.Animal;
ID2 = delayed.Animal;

% Find common animals AND matching order
[commonIDs, idx1, idx2] = intersect(ID1, ID2, 'stable');

freq_in_phase_comp_delayed   = in_phase_dat.online.fft(idx1);
freq_delayed_comp_in_phase  = delayed_dat.online.fft(idx2);

%% Cluster-based permutation test against baseline (no_stim)
freq_zero_all = freq_no_stim_all;  % copy structure

baseline_win = [2.5 3.5];
nSub = numel(freq_no_stim_all);

freq_event = freq_no_stim_all;   % copy
freq_base  = cell(1, nSub);

for s = 1:nSub
    f = freq_no_stim_all{s};
    t = f.time;

    % baseline indices
    idxB = t >= baseline_win(1) & t <= baseline_win(2);

    % mean over baseline time window
    base_mean = mean(f.powspctrm(:,:, idxB), 3);    % channel × freq

    % build full-size baseline TFR
    fb = f;   % copy original structure
    fb.powspctrm = repmat(base_mean, [1 1 numel(t)]);  % reshape to match
    freq_base{s} = fb;
end


nSubj = numel(freq_no_stim_all);

design = zeros(2, 2*nSubj);
design(1,:) = [1:nSubj 1:nSubj];                 % subject index
design(2,:) = [ones(1,nSubj) 2*ones(1,nSubj)];   % condition index

cfg = [];
cfg.parameter   = 'powspctrm';
cfg.method      = 'montecarlo';
cfg.statistic   = 'depsamplesT';
cfg.correctm    = 'cluster';
cfg.clusteralpha = 0.05;
cfg.alpha        = 0.05;
cfg.numrandomization = 5000;
cfg.tail         = 0;

cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;

stat_no_vs_baseline = ft_freqstatistics(cfg, freq_no_stim_all{:},freq_base{:});

%% Cluster-based permutation test against baseline (in_phase)
freq_zero_all = freq_in_phase_all;  % copy structure

baseline_win = [2.5 3.5];
nSub = numel(freq_in_phase_all);

freq_event = freq_in_phase_all;   % copy
freq_base  = cell(1, nSub);

for s = 1:nSub
    f = freq_in_phase_all{s};
    t = f.time;

    % baseline indices
    idxB = t >= baseline_win(1) & t <= baseline_win(2);

    % mean over baseline time window
    base_mean = mean(f.powspctrm(:,:, idxB), 3);    % channel × freq

    % build full-size baseline TFR
    fb = f;   % copy original structure
    fb.powspctrm = repmat(base_mean, [1 1 numel(t)]);  % reshape to match
    freq_base{s} = fb;
end

nSubj = numel(freq_in_phase_all);

design = zeros(2, 2*nSubj);
design(1,:) = [1:nSubj 1:nSubj];                 % subject index
design(2,:) = [ones(1,nSubj) 2*ones(1,nSubj)];   % condition index

cfg = [];
cfg.parameter   = 'powspctrm';
cfg.method      = 'montecarlo';
cfg.statistic   = 'depsamplesT';
cfg.correctm    = 'cluster';
cfg.clusteralpha = 0.05;
cfg.alpha        = 0.05;
cfg.numrandomization = 5000;
cfg.tail         = 0;

cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;

stat_in_phase_vs_baseline = ft_freqstatistics(cfg, freq_in_phase_all{:},freq_base{:});

%% Cluster-based permutation test against baseline (delayed)
freq_zero_all = freq_delayed_all;  % copy structure

baseline_win = [4 5];
nSub = numel(freq_delayed_all);

freq_event = freq_delayed_all;   % copy
freq_base  = cell(1, nSub);

for s = 1:nSub
    f = freq_delayed_all{s};
    t = f.time;

    % baseline indices
    idxB = t >= baseline_win(1) & t <= baseline_win(2);

    % mean over baseline time window
    base_mean = mean(f.powspctrm(:,:, idxB), 3);    % channel × freq

    % build full-size baseline TFR
    fb = f;   % copy original structure
    fb.powspctrm = repmat(base_mean, [1 1 numel(t)]);  % reshape to match
    freq_base{s} = fb;
end

nSubj = numel(freq_delayed_all);

design = zeros(2, 2*nSubj);
design(1,:) = [1:nSubj 1:nSubj];                 % subject index
design(2,:) = [ones(1,nSubj) 2*ones(1,nSubj)];   % condition index

cfg = [];
cfg.parameter   = 'powspctrm';
cfg.method      = 'montecarlo';
cfg.statistic   = 'depsamplesT';
cfg.correctm    = 'cluster';
cfg.clusteralpha = 0.05;
cfg.alpha        = 0.05;
cfg.numrandomization = 5000;
cfg.tail         = 0;

cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;

stat_delayed_vs_baseline = ft_freqstatistics(cfg, freq_delayed_all{:},freq_base{:});

%% Cluster based permutation test No Stim against In_Phase Stim 
nSubj = numel(freq_no_stim_comp_in_phase);

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

stat_no_vs_in = ft_freqstatistics(cfg, freq_no_stim_comp_in_phase{:}, freq_in_phase_comp_no_stim{:});

%% Cluster based permutation test No Stim versus delayed
nSubj = numel(freq_no_stim_comp_delayed);

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

stat_no_vs_delayed = ft_freqstatistics(cfg, freq_no_stim_comp_delayed{:}, freq_delayed_comp_no_stim{:});

%% Cluster based permutation test In_Phase Stim versus delayed
nSubj = numel(freq_in_phase_comp_delayed);

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

stat_in_vs_delayed = ft_freqstatistics(cfg, freq_in_phase_comp_delayed{:}, freq_delayed_comp_in_phase{:});


%% Plot figures 
cfg = [];
cfg.toilim = [3 7];

fft_SO_online_all = [no_stim_dat.online.fft];
waveform_SO_online_all = [no_stim_dat.online.waveform];

online_EEG_grand_avg = ft_freqgrandaverage(cfg, fft_SO_online_all{:});
online_SO_grand_avg  = ft_timelockgrandaverage(cfg, waveform_SO_online_all{:});
online_SO_avg_signal = online_SO_grand_avg.avg(1,3000:7001); 

in_phase_stim_EEG_grand_avg = ft_freqgrandaverage(cfg, in_phase_dat.online.fft{:});
in_phase_stim_grand_avg  = ft_timelockgrandaverage(cfg, in_phase_dat.online.waveform{:});
in_phase_stim_avg_signal = in_phase_stim_grand_avg.avg(1,3000:7001); 

delayed_stim_EEG_grand_avg = ft_freqgrandaverage(cfg, delayed_dat.stim.fft{:});
delayed_stim_grand_avg  = ft_timelockgrandaverage(cfg, delayed_dat.stim.waveform{:});
delayed_stim_avg_signal = delayed_stim_grand_avg.avg(1,3000:7001); 

Selected_time = online_SO_grand_avg.time(3000:7001);

% ---- Restrict TFRs to 5–20 Hz ----------------------------------------
fmin = 5; % 20 
fmax = 20; % 40

trim_idx = @(f) (f >= fmin & f <= fmax);

% --- In-phase ---
idx = trim_idx(in_phase_stim_EEG_grand_avg.freq);
in_phase_stim_EEG_grand_avg.freq = in_phase_stim_EEG_grand_avg.freq(idx);
in_phase_stim_EEG_grand_avg.powspctrm = in_phase_stim_EEG_grand_avg.powspctrm(:,idx,:);

% --- Delayed ---
idx = trim_idx(delayed_stim_EEG_grand_avg.freq);
delayed_stim_EEG_grand_avg.freq = delayed_stim_EEG_grand_avg.freq(idx);
delayed_stim_EEG_grand_avg.powspctrm = delayed_stim_EEG_grand_avg.powspctrm(:,idx,:);

% --- No-stim ---
idx = trim_idx(online_EEG_grand_avg.freq);
online_EEG_grand_avg.freq = online_EEG_grand_avg.freq(idx);
online_EEG_grand_avg.powspctrm = online_EEG_grand_avg.powspctrm(:,idx,:);


% ========================  IN-PHASE PANEL  ============================

figure;
set(gcf, 'Position', [100 100 1600 600]);
subplot(1,3,1)

yyaxis left
imagesc(in_phase_stim_EEG_grand_avg.time, ...
        in_phase_stim_EEG_grand_avg.freq, ...
        squeeze(in_phase_stim_EEG_grand_avg.powspctrm(1,:,:)));
axis xy;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold on;

yyaxis right
line(Selected_time, in_phase_stim_avg_signal, 'Color','k','LineWidth',2);
xline(5,'Color','r','LineWidth',1.5);
xline(6,'Color','r','LineWidth',1.5);
ylabel('Amplitude (μV)');
ylim([-350 200]);

xticks([3 3.5 4 4.5 5 5.5 6 6.5 7]);
xticklabels({'-2','-1.5','-1','-0.5','0','0.5','1','1.5','2'});
xlabel('Time (s) relative to inhibition onset');
title('In phase inhibition');

% ----- CLUSTER STATISTICS (In-phase) -------------------

stat = stat_in_phase_vs_baseline;

plot_t = in_phase_stim_EEG_grand_avg.time;
full_t = stat.time;

t_idx = full_t >= plot_t(1) & full_t <= plot_t(end);

% Extract labels
poslab_full = squeeze(stat.posclusterslabelmat(1,:,:));
neglab_full = squeeze(stat.negclusterslabelmat(1,:,:));

% ---- Restrict clusters to 5–20 Hz ----
freq_idx_stat = trim_idx(stat.freq);
poslab_full = poslab_full(freq_idx_stat,:);
neglab_full = neglab_full(freq_idx_stat,:);

% Crop to time
poslab = poslab_full(:, t_idx);
neglab = neglab_full(:, t_idx);

sigpos_idx = find([stat.posclusters.prob] < 0.05);
signeg_idx = find([stat.negclusters.prob] < 0.05);

sig_pos = ismember(poslab, sigpos_idx);
sig_neg = ismember(neglab, signeg_idx);

yyaxis left
if any(sig_pos(:))
    contour(plot_t, in_phase_stim_EEG_grand_avg.freq, sig_pos, [1 1], ...
            'LineColor','r','LineWidth',1.2);
end
if any(sig_neg(:))
    contour(plot_t, in_phase_stim_EEG_grand_avg.freq, sig_neg, [1 1], ...
            'LineColor','b','LineWidth',1.2);
end

hold off;


% ========================  DELAYED PANEL  ==============================

subplot(1,3,2)
yyaxis left
imagesc(delayed_stim_EEG_grand_avg.time, delayed_stim_EEG_grand_avg.freq, ...
        squeeze(delayed_stim_EEG_grand_avg.powspctrm(1,:,:)));
axis xy;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold on;

yyaxis right
line(Selected_time, delayed_stim_avg_signal,'Color','k','LineWidth',2);
xline(5,'Color','r','LineWidth',1.5);
xline(6,'Color','r','LineWidth',1.5);
ylabel('Amplitude (μV)');
ylim([-350 200]);

xticks([3 3.5 4 4.5 5 5.5 6 6.5 7]);
xticklabels({'-2','-1.5','-1','-0.5','0','0.5','1','1.5','2'});
xlabel('Time (s) relative to inhibition onset');
title('Delayed inhibition');

% ----- CLUSTER STATISTICS (Delayed) -------------------

stat = stat_delayed_vs_baseline;

plot_t = delayed_stim_EEG_grand_avg.time;
full_t = stat.time;

t_idx = full_t >= plot_t(1) & full_t <= plot_t(end);

poslab_full = squeeze(stat.posclusterslabelmat(1,:,:));
neglab_full = squeeze(stat.negclusterslabelmat(1,:,:));

% Restrict freq
freq_idx_stat = trim_idx(stat.freq);
poslab_full = poslab_full(freq_idx_stat,:);
neglab_full = neglab_full(freq_idx_stat,:);

poslab = poslab_full(:, t_idx);
neglab = neglab_full(:, t_idx);

sigpos_idx = find([stat.posclusters.prob] < 0.05);
signeg_idx = find([stat.negclusters.prob] < 0.05);

sig_pos = ismember(poslab, sigpos_idx);
sig_neg = ismember(neglab, signeg_idx);

yyaxis left
if any(sig_pos(:))
    contour(plot_t, delayed_stim_EEG_grand_avg.freq, sig_pos, [1 1], ...
            'LineColor','r','LineWidth',1.2);
end
if any(sig_neg(:))
    contour(plot_t, delayed_stim_EEG_grand_avg.freq, sig_neg, [1 1], ...
            'LineColor','b','LineWidth',1.2);
end

hold off;


% ==========================  NO-STIM PANEL  ============================

subplot(1,3,3)
yyaxis left
imagesc(online_EEG_grand_avg.time, online_EEG_grand_avg.freq, ...
        squeeze(online_EEG_grand_avg.powspctrm(1,:,:)));
axis xy
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold on;

yyaxis right
line(Selected_time, online_SO_avg_signal, 'Color','k','LineWidth',2);
ylabel('Amplitude (μV)')
ylim([-350 200])

xticks([3 3.5 4 4.5 5 5.5 6 6.5 7]);
xticklabels({'-2','-1.5','-1','-0.5','0','0.5','1','1.5','2'});
xlabel('Time (s) relative to online detected SO');
title('No inhibition');

% ----- CLUSTER STATISTICS (No-stim) -------------------

stat = stat_no_vs_baseline;

plot_t = online_EEG_grand_avg.time;
full_t = stat.time;
t_idx = full_t >= plot_t(1) & full_t <= plot_t(end);

poslab_full = squeeze(stat.posclusterslabelmat(1,:,:));
neglab_full = squeeze(stat.negclusterslabelmat(1,:,:));

% Restrict freq
freq_idx_stat = trim_idx(stat.freq);
poslab_full = poslab_full(freq_idx_stat,:);
neglab_full = neglab_full(freq_idx_stat,:);

poslab = poslab_full(:, t_idx);
neglab = neglab_full(:, t_idx);

sigpos_idx = find([stat.posclusters.prob] < 0.05);
signeg_idx = find([stat.negclusters.prob] < 0.05);

sig_pos = ismember(poslab, sigpos_idx);
sig_neg = ismember(neglab, signeg_idx);

yyaxis left
if any(sig_pos(:))
    contour(plot_t, online_EEG_grand_avg.freq, sig_pos, [1 1], ...
            'LineColor','r','LineWidth',1.2);
end
if any(sig_neg(:))
    contour(plot_t, online_EEG_grand_avg.freq, sig_neg, [1 1], ...
            'LineColor','b','LineWidth',1.2);
end

hold off;

colormap(jet)

% === Create ONE shared colorbar outside all three subplots ===

% Create invisible axes spanning the whole figure
cax = axes('Position',[0.93 0.15 0.01 0.7],'Visible','off');

% Create colorbar in that axes
cb = colorbar(cax,'Position',[0.93 0.15 0.015 0.7]);
clim([0.75 1.5]);

cb.Label.String = 'Relative power to baseline [%]';
cb.Label.FontSize = 12;


%% Comparisons
fmin = 5;
fmax = 20;

trim_f_idx = @(f) (f >= fmin & f <= fmax);

figure;
set(gcf, 'Position', [100 100 1600 600]);

%% ========================  NoSTIM - IN PANEL  ============================

subplot(1,3,1)

nSubj = numel(freq_no_stim_comp_in_phase);

% ---------- Compute subject-wise differences ----------
diff_all = cell(1,nSubj);
for s = 1:nSubj
    diff_all{s} = freq_no_stim_comp_in_phase{s};
    diff_all{s}.powspctrm = ...
        freq_no_stim_comp_in_phase{s}.powspctrm - ...
        freq_in_phase_comp_no_stim{s}.powspctrm;
end

% ---------- Grand average FOR PLOTTING ONLY ----------
cfg = [];
ref = ft_freqgrandaverage(cfg, diff_all{:});

% ---------- Restrict frequency ----------
idx_f = trim_f_idx(ref.freq);
ref.freq = ref.freq(idx_f);
ref.powspctrm = ref.powspctrm(:,idx_f,:);

% ---------- Plot ----------
imagesc(ref.time, ref.freq, squeeze(ref.powspctrm(1,:,:)));
axis xy
xlim([3 7])
ylabel('Frequency (Hz)')
xlabel('Time (s) relative to inhibition onset')
title('Difference [NoStim - IN]')
hold on

xticks([3 3.5 4 4.5 5 5.5 6 6.5 7])
xticklabels({'-2','-1.5','-1','-0.5','0','0.5','1','1.5','2'})

% ---------- Overlay clusters ----------
stat = stat_no_vs_in;

plot_t = ref.time;
t_idx  = stat.time >= plot_t(1) & stat.time <= plot_t(end);
f_idx  = trim_f_idx(stat.freq);

if isfield(stat,'posclusterslabelmat')
    poslab = squeeze(stat.posclusterslabelmat(1,f_idx,t_idx));
else
    poslab = zeros(sum(f_idx), sum(t_idx));
end

if isfield(stat,'negclusterslabelmat')
    neglab = squeeze(stat.negclusterslabelmat(1,f_idx,t_idx));
else
    neglab = zeros(sum(f_idx), sum(t_idx));
end

sigpos_idx = [];
signeg_idx = [];

if isfield(stat,'posclusters')
    sigpos_idx = find([stat.posclusters.prob] < 0.05);
end
if isfield(stat,'negclusters')
    signeg_idx = find([stat.negclusters.prob] < 0.05);
end

sig_pos = ismember(poslab, sigpos_idx);
sig_neg = ismember(neglab, signeg_idx);

if any(sig_pos(:))
    contour(plot_t, ref.freq, sig_pos, [1 1], ...
        'LineColor','r','LineWidth',1.2);
end
if any(sig_neg(:))
    contour(plot_t, ref.freq, sig_neg, [1 1], ...
        'LineColor','b','LineWidth',1.2);
end

hold off


%% ========================  NoSTIM - OUT PANEL  =============================

subplot(1,3,2)

nSubj = numel(freq_no_stim_comp_delayed);

diff_all = cell(1,nSubj);
for s = 1:nSubj
    diff_all{s} = freq_no_stim_comp_delayed{s};
    diff_all{s}.powspctrm = ...
        freq_no_stim_comp_delayed{s}.powspctrm - ...
        freq_delayed_comp_no_stim{s}.powspctrm;
end

cfg = [];
ref = ft_freqgrandaverage(cfg, diff_all{:});

idx_f = trim_f_idx(ref.freq);
ref.freq = ref.freq(idx_f);
ref.powspctrm = ref.powspctrm(:,idx_f,:);

imagesc(ref.time, ref.freq, squeeze(ref.powspctrm(1,:,:)));
axis xy
xlim([3 7])
xlabel('Time (s) relative to inhibition onset')
title('Difference [NoStim - OUT]')
hold on

stat = stat_no_vs_delayed;

plot_t = ref.time;
t_idx  = stat.time >= plot_t(1) & stat.time <= plot_t(end);
f_idx  = trim_f_idx(stat.freq);

if isfield(stat,'posclusterslabelmat')
    poslab = squeeze(stat.posclusterslabelmat(1,f_idx,t_idx));
else
    poslab = zeros(sum(f_idx), sum(t_idx));
end

if isfield(stat,'negclusterslabelmat')
    neglab = squeeze(stat.negclusterslabelmat(1,f_idx,t_idx));
else
    neglab = zeros(sum(f_idx), sum(t_idx));
end

sigpos_idx = [];
signeg_idx = [];

if isfield(stat,'posclusters')
    sigpos_idx = find([stat.posclusters.prob] < 0.05);
end
if isfield(stat,'negclusters')
    signeg_idx = find([stat.negclusters.prob] < 0.05);
end

sig_pos = ismember(poslab, sigpos_idx);
sig_neg = ismember(neglab, signeg_idx);

if any(sig_pos(:))
    contour(plot_t, ref.freq, sig_pos, [1 1], ...
        'LineColor','r','LineWidth',1.2);
end
if any(sig_neg(:))
    contour(plot_t, ref.freq, sig_neg, [1 1], ...
        'LineColor','b','LineWidth',1.2);
end

hold off


%% ==========================  IN - OUT PANEL  ===================================

subplot(1,3,3)

nSubj = numel(freq_in_phase_comp_delayed);

diff_all = cell(1,nSubj);
for s = 1:nSubj
    diff_all{s} = freq_in_phase_comp_delayed{s};
    diff_all{s}.powspctrm = ...
        freq_in_phase_comp_delayed{s}.powspctrm - ...
        freq_delayed_comp_in_phase{s}.powspctrm;
end

cfg = [];
ref = ft_freqgrandaverage(cfg, diff_all{:});

idx_f = trim_f_idx(ref.freq);
ref.freq = ref.freq(idx_f);
ref.powspctrm = ref.powspctrm(:,idx_f,:);

imagesc(ref.time, ref.freq, squeeze(ref.powspctrm(1,:,:)));
axis xy
xlim([3 7])
xlabel('Time (s) relative to inhibition onset')
title('Difference [IN - OUT]')
hold on

stat = stat_in_vs_delayed;

plot_t = ref.time;
t_idx  = stat.time >= plot_t(1) & stat.time <= plot_t(end);
f_idx  = trim_f_idx(stat.freq);

if isfield(stat,'posclusterslabelmat')
    poslab = squeeze(stat.posclusterslabelmat(1,f_idx,t_idx));
else
    poslab = zeros(sum(f_idx), sum(t_idx));
end

if isfield(stat,'negclusterslabelmat')
    neglab = squeeze(stat.negclusterslabelmat(1,f_idx,t_idx));
else
    neglab = zeros(sum(f_idx), sum(t_idx));
end

sigpos_idx = [];
signeg_idx = [];

if isfield(stat,'posclusters')
    sigpos_idx = find([stat.posclusters.prob] < 0.05);
end
if isfield(stat,'negclusters')
    signeg_idx = find([stat.negclusters.prob] < 0.05);
end

sig_pos = ismember(poslab, sigpos_idx);
sig_neg = ismember(neglab, signeg_idx);

if any(sig_pos(:))
    contour(plot_t, ref.freq, sig_pos, [1 1], ...
        'LineColor','r','LineWidth',1.2);
end
if any(sig_neg(:))
    contour(plot_t, ref.freq, sig_neg, [1 1], ...
        'LineColor','b','LineWidth',1.2);
end

hold off

%% ==========================  COLORBAR  =========================================

colormap(jet)

cax = axes('Position',[0.93 0.15 0.01 0.7],'Visible','off');
cb = colorbar(cax,'Position',[0.93 0.15 0.015 0.7]);
clim([0.75 1.5]);

cb.Label.String = '\Delta power';
cb.Label.FontSize = 12;
