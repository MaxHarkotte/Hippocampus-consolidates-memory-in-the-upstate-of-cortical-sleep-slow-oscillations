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
type = "_baseline_corr.mat";
% type = "_raw.mat";

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
        no_stim_dat.offline.fft{iNo_Stim}      = tmp_fft_offline.offline_SO_TFRhann_corr; % tmp_fft_offline.offline_SO_TFRhann_corr
        no_stim_dat.offline.waveform{iNo_Stim} = tmp_wave_offline.offline_SO_avg;
        no_stim_dat.online.fft{iNo_Stim}       = tmp_fft_online.online_SO_TFRhann_corr; % tmp_fft_online.online_SO_TFRhann_corr
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
freq_delayed_all   = delayed_dat.online.fft;  %%stim 

idx3 = contains(no_stim.Animal,"Exclude");
freq_no_stim_all   = no_stim_dat.online.fft(~idx3);

DR_no_stim_all = behavior(contains(behavior.Condition,"No_stim"), :);
DR_no_stim_all(contains(DR_no_stim_all.Animal,"CL04-07-MPV0120-BE2"), :) = [];

DR_in_phase_all = behavior(contains(behavior.Condition,"SO_up_in_phase"), :);
DR_delayed_all = behavior(contains(behavior.Condition,"SO_delayed"), :);

%% STATS
cfg = [];
cfg.method           = 'montecarlo';
cfg.statistic        = 'ft_statfun_correlationT';  
cfg.parameter        = 'powspctrm';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.numrandomization = 2000;
cfg.alpha            = 0.05;
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.neighbours       = [];
cfg.ivar   = 1;

%cfg.design = DR_no_stim_all.Cum_DiRa_min_5';   % raw values --> Pearson
cfg.design = tiedrank(DR_no_stim_all.Cum_DiRa_min_5)'; % ranked --> Spearman 
stat_no_stim_memory = ft_freqstatistics(cfg, freq_no_stim_all{:});

%cfg.design = DR_in_phase_all.Cum_DiRa_min_5';   % raw values --> Pearson
cfg.design = tiedrank(DR_in_phase_all.Cum_DiRa_min_5)'; % ranked --> Spearman 
stat_in_phase_memory = ft_freqstatistics(cfg, freq_in_phase_all{:});

%cfg.design = DR_delayed_all.Cum_DiRa_min_5';   % raw values --> Pearson
cfg.design = tiedrank(DR_delayed_all.Cum_DiRa_min_5)'; % ranked --> Spearman 
stat_delayed_memory = ft_freqstatistics(cfg, freq_delayed_all{:});

%% Plot figures 
cfg = [];
cfg.toilim = [3 7];


fft_SO_online_all = [no_stim_dat.online.fft];
waveform_SO_online_all = [no_stim_dat.online.waveform];
%waveform_SO_online_all = waveform_SO_online_all(~idx3);

online_EEG_grand_avg = ft_freqgrandaverage(cfg, fft_SO_online_all{:});
online_SO_grand_avg  = ft_timelockgrandaverage(cfg, waveform_SO_online_all{:});
online_SO_avg_signal = online_SO_grand_avg.avg(1,3000:7001); 

in_phase_stim_EEG_grand_avg = ft_freqgrandaverage(cfg, in_phase_dat.online.fft{:});
in_phase_stim_grand_avg  = ft_timelockgrandaverage(cfg, in_phase_dat.online.waveform{:});
in_phase_stim_avg_signal = in_phase_stim_grand_avg.avg(1,3000:7001); 

delayed_stim_EEG_grand_avg = ft_freqgrandaverage(cfg, delayed_dat.stim.fft{:});
delayed_stim_grand_avg  = ft_timelockgrandaverage(cfg, delayed_dat.online.waveform{:}); %% stim
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
ylim([-300 200]);

xticks([3 3.5 4 4.5 5 5.5 6 6.5 7]);
xticklabels({'-2','-1.5','-1','-0.5','0','0.5','1','1.5','2'});
xlabel('Time (s) relative to inhibition onset');
title('In phase inhibition');

% ----- CLUSTER STATISTICS (In-phase) -------------------

stat = stat_in_phase_memory;

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
ylim([-300 200]);

xticks([3 3.5 4 4.5 5 5.5 6 6.5 7]);
xticklabels({'-2','-1.5','-1','-0.5','0','0.5','1','1.5','2'});
xlabel('Time (s) relative to inhibition onset');
title('Delayed inhibition');

% ----- CLUSTER STATISTICS (Delayed) -------------------

stat = stat_delayed_memory;

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
ylim([-300 200])

xticks([3 3.5 4 4.5 5 5.5 6 6.5 7]);
xticklabels({'-2','-1.5','-1','-0.5','0','0.5','1','1.5','2'});
xlabel('Time (s) relative to online detected SO');
title('No inhibition');

% ----- CLUSTER STATISTICS (No-stim) -------------------

stat = stat_no_stim_memory;

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

%% ============================================================
%  Exploratory time–frequency correlation map (rho)
%  Power (TFR) × behavior across subjects
%  Time window: 3–7 s
% ============================================================

% -------- USER SETTINGS --------------------------------------
corr_type = 'Pearson';   % 'Pearson' or 'Spearman'
fmin = 10;
fmax = 16;
tmin = 3;
tmax = 7;
clim_rho = [-0.5 0.5];


compute_rho_tfr = @(freq_all, behav) ...
    cell2mat(arrayfun(@(f) ...
        arrayfun(@(t) ...
            corr(cellfun(@(x) x.powspctrm(1,f,t), freq_all)', ...
                 behav, 'type','Pearson','rows','complete'), ...
        1:numel(freq_all{1}.time)), ...
    (1:numel(freq_all{1}.freq))','UniformOutput',false));



figure;
set(gcf,'Position',[100 100 1600 600]);

conds = { ...
    struct('name','In-phase inhibition', ...
           'freq_all',{freq_in_phase_all}, ...
           'behav',DR_in_phase_all.Cum_DiRa_min_5(:), ...
           'stat',stat_in_phase_memory, ...
           'wave',in_phase_stim_avg_signal), ...
    struct('name','Delayed inhibition', ...
           'freq_all',{freq_delayed_all}, ...
           'behav',DR_delayed_all.Cum_DiRa_min_5(:), ...
           'stat',stat_delayed_memory, ...
           'wave',delayed_stim_avg_signal), ...
    struct('name','No inhibition', ...
           'freq_all',{freq_no_stim_all}, ...
           'behav',DR_no_stim_all.Cum_DiRa_min_5(:), ...
           'stat',stat_no_stim_memory, ...
           'wave',online_SO_avg_signal) ...
};

for c = 1:3
    subplot(1,3,c)

    % ---------- Compute rho ----------------------------------
    freq_all = conds{c}.freq_all;
    behav    = conds{c}.behav;
    stat     = conds{c}.stat;

    freqs = freq_all{1}.freq;
    times = freq_all{1}.time;

    rho = compute_rho_tfr(freq_all, behav);

    % ---------- Restrict freq & time -------------------------
    f_idx = freqs >= fmin & freqs <= fmax;
    t_idx = times >= tmin & times <= tmax;

    rho   = rho(f_idx, t_idx);
    freqs = freqs(f_idx);
    times = times(t_idx);

    % ---------- Plot rho TFR ---------------------------------
    yyaxis left
    imagesc(times, freqs, rho);
    axis xy
    ylabel('Frequency (Hz)')
    clim([-0.5 0.5])
    hold on

    % ---------- Cluster contours -----------------------------
    full_t = stat.time;
    full_f = stat.freq;

    t_idx_stat = full_t >= tmin & full_t <= tmax;
    f_idx_stat = full_f >= fmin & full_f <= fmax;

    poslab = squeeze(stat.posclusterslabelmat(1,f_idx_stat,t_idx_stat));
    neglab = squeeze(stat.negclusterslabelmat(1,f_idx_stat,t_idx_stat));

    sigpos = find([stat.posclusters.prob] < 0.05);
    signeg = find([stat.negclusters.prob] < 0.05);

    if ~isempty(sigpos)
        contour(times, freqs, ismember(poslab,sigpos), [1 1], ...
            'LineColor','k','LineWidth',1.2);
    end
    if ~isempty(signeg)
        contour(times, freqs, ismember(neglab,signeg), [1 1], ...
            'LineStyle','--','LineColor','k','LineWidth',1.2);
    end

    % ---------- Waveform overlay ------------------------------
    yyaxis right
    plot(Selected_time, conds{c}.wave, 'k','LineWidth',2)
    ylim([-300 200])
    ylabel('Amplitude (μV)')

    % ---------- Axes cosmetics --------------------------------
    xticks([3 3.5 4 4.5 5 5.5 6 6.5 7])
    xticklabels({'-2','-1.5','-1','-0.5','0','0.5','1','1.5','2'})
    xlabel('Time (s)')
    title(conds{c}.name)

    hold off
end

% ---------- Shared colormap & colorbar ------------------------
colormap(jet)

cax = axes('Position',[0.93 0.15 0.01 0.7],'Visible','off');
cb  = colorbar(cax,'Position',[0.93 0.15 0.015 0.7]);
cb.Label.String = 'Correlation coefficient (\rho)';
cb.Label.FontSize = 12;
clim([-0.5 0.5])

%% 
% ============================================================
%  Exploratory spindle-band (10–16 Hz) rho across time
%  Conditions: No-stim, In-phase, Delayed
%  Time window: 4–6 s
% ============================================================

% --- settings ---
fband = [10 16];
twin  = [3 7];

% --- helper function ----------------------------------------
get_spindle_rho = @(stat) ...
    mean( ...
        squeeze(stat.rho(1, ...
            stat.freq >= fband(1) & stat.freq <= fband(2), ...
            : ...
        )), ...
        1, 'omitnan' ...
    );

% --- extract time axis (same for all) ---
time = stat_no_stim_memory.time;
t_idx = time >= twin(1) & time <= twin(2);
time_plot = time(t_idx);

% --- compute spindle-band rho time courses ---
rho_no_stim  = get_spindle_rho(stat_no_stim_memory);
rho_in_phase = get_spindle_rho(stat_in_phase_memory);
rho_delayed  = get_spindle_rho(stat_delayed_memory);

% --- restrict to time window ---
rho_no_stim  = rho_no_stim(t_idx);
rho_in_phase = rho_in_phase(t_idx);
rho_delayed  = rho_delayed(t_idx);

% --- plot ---------------------------------------------------
figure; hold on
plot(time_plot, rho_no_stim,  'k', 'LineWidth', 2)
plot(time_plot, rho_in_phase,'r', 'LineWidth', 2)
plot(time_plot, rho_delayed, 'b', 'LineWidth', 2)
xticks([3 3.5 4 4.5 5 5.5 6 6.5 7])
xticklabels({'-2','-1.5','-1','-0.5','0','0.5','1','1.5','2'})

xlabel('Time (s)')
ylabel('Mean \rho (10–16 Hz)')
title('Exploratory spindle-band power–behavior correlation')
legend({'No stim','In-phase','Delayed'}, 'Location','best')
grid on
hold off


