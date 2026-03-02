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

%% Plotting
% Plot NO Stimulation condition 
cfg = [];
cfg.toilim = [1 5];

offline_EEG_grand_avg = ft_freqgrandaverage(cfg, no_stim_dat.offline.fft{:});
offline_SO_grand_avg  = ft_timelockgrandaverage(cfg, no_stim_dat.offline.waveform{:});
offline_SO_avg_signal = offline_SO_grand_avg.avg(1,1000:5001); 

online_EEG_grand_avg = ft_freqgrandaverage(cfg, no_stim_dat.online.fft{:});
online_SO_grand_avg  = ft_timelockgrandaverage(cfg, no_stim_dat.online.waveform{:});
online_SO_avg_signal = online_SO_grand_avg.avg(1,1000:5001); 

Selected_time = offline_SO_grand_avg.time(1000:5001);

figure;
set(gcf, 'Position', [100 100 1600 600]);  % [left bottom width height] in pixels
subplot(1,2,1)
yyaxis left
imagesc(offline_EEG_grand_avg.time, offline_EEG_grand_avg.freq, squeeze(offline_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, offline_SO_avg_signal, 'Color', 'k', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-220 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to deg. peak');
title('Offline detected SO (frontal left EEG)');

subplot(1,2,2)
yyaxis left
imagesc(online_EEG_grand_avg.time, online_EEG_grand_avg.freq, squeeze(online_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, online_SO_avg_signal, 'Color', 'k', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-220 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to time of SO detection');
title('Online detected SO (frontal left EEG)');

sgtitle('No stimulation condition');

% Plot SO In Phase Stimulation Condition
cfg = [];
cfg.toilim = [1 5];

offline_EEG_grand_avg = ft_freqgrandaverage(cfg, in_phase_dat.offline.fft{:});
offline_SO_grand_avg  = ft_timelockgrandaverage(cfg, in_phase_dat.offline.waveform{:});
offline_SO_avg_signal = offline_SO_grand_avg.avg(1,1000:5001); 

online_EEG_grand_avg = ft_freqgrandaverage(cfg, in_phase_dat.online.fft{:});
online_SO_grand_avg  = ft_timelockgrandaverage(cfg, in_phase_dat.online.waveform{:});
online_SO_avg_signal = online_SO_grand_avg.avg(1,1000:5001); 

Selected_time = offline_SO_grand_avg.time(1000:5001);

figure;
set(gcf, 'Position', [100 100 1600 600]);  % [left bottom width height] in pixels
subplot(1,2,1)
yyaxis left
imagesc(offline_EEG_grand_avg.time, offline_EEG_grand_avg.freq, squeeze(offline_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, offline_SO_avg_signal, 'Color', 'k', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-220 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to neg. peak');
title('Offline detected SO (frontal left EEG)');

subplot(1,2,2)
yyaxis left
imagesc(online_EEG_grand_avg.time, online_EEG_grand_avg.freq, squeeze(online_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, online_SO_avg_signal, 'Color', 'k', 'LineWidth', 1);
xline(3, 'Color', 'r', 'LineWidth', 1);
xline(4, 'Color', 'r', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-220 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to Laser onset');
title('Online detected SO (frontal left EEG)');

sgtitle('SO in-phase stimulation condition');

% Plot Delayed stimulation condition 
cfg = [];
cfg.toilim = [1 5];

offline_EEG_grand_avg = ft_freqgrandaverage(cfg, delayed_dat.offline.fft{:});
offline_SO_grand_avg  = ft_timelockgrandaverage(cfg, delayed_dat.offline.waveform{:});
offline_SO_avg_signal = offline_SO_grand_avg.avg(1,1000:5001); 

online_EEG_grand_avg = ft_freqgrandaverage(cfg, delayed_dat.online.fft{:});
online_SO_grand_avg  = ft_timelockgrandaverage(cfg, delayed_dat.online.waveform{:});
online_SO_avg_signal = online_SO_grand_avg.avg(1,1000:5001); 

delayed_stim_EEG_grand_avg = ft_freqgrandaverage(cfg, delayed_dat.stim.fft{:});
stim_grand_avg  = ft_timelockgrandaverage(cfg, delayed_dat.stim.waveform{:});
stim_avg_signal = stim_grand_avg.avg(1,1000:5001); 

Selected_time = offline_SO_grand_avg.time(1000:5001);

figure;
set(gcf, 'Position', [100 100 2400 600]);  % [left bottom width height] in pixels
subplot(1,3,1)
yyaxis left
imagesc(offline_EEG_grand_avg.time, offline_EEG_grand_avg.freq, squeeze(offline_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, offline_SO_avg_signal, 'Color', 'k', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-220 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to neg. peak');
title('Offline detected SO (frontal left EEG)');

subplot(1,3,2)
yyaxis left
imagesc(online_EEG_grand_avg.time, online_EEG_grand_avg.freq, squeeze(online_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, online_SO_avg_signal, 'Color', 'k', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-220 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to time of SO detection');
title('Online detected SO (frontal left EEG)');

subplot(1,3,3)
yyaxis left
imagesc(delayed_stim_EEG_grand_avg.time, delayed_stim_EEG_grand_avg.freq, squeeze(delayed_stim_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, stim_avg_signal, 'Color', 'k', 'LineWidth', 1);
xline(3, 'Color', 'r', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-220 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to Laser onset');
title('Delayed stimulation (frontal left EEG)');

sgtitle('Delayed stimulation condition');


%% Plotting average 
% Plot NO Stimulation condition 
cfg = [];
cfg.toilim = [1 5];

fft_SO_online_all = [no_stim_dat.online.fft];
waveform_SO_online_all = [no_stim_dat.online.waveform];

online_EEG_grand_avg = ft_freqgrandaverage(cfg, fft_SO_online_all{:});
online_SO_grand_avg  = ft_timelockgrandaverage(cfg, waveform_SO_online_all{:});
online_SO_avg_signal = online_SO_grand_avg.avg(1,1000:5001); 

in_phase_stim_EEG_grand_avg = ft_freqgrandaverage(cfg, in_phase_dat.online.fft{:});
in_phase_stim_grand_avg  = ft_timelockgrandaverage(cfg, in_phase_dat.online.waveform{:});
in_phase_stim_avg_signal = in_phase_stim_grand_avg.avg(1,1000:5001); 

delayed_stim_EEG_grand_avg = ft_freqgrandaverage(cfg, delayed_dat.stim.fft{:});
delayed_stim_grand_avg  = ft_timelockgrandaverage(cfg, delayed_dat.stim.waveform{:});
delayed_stim_avg_signal = delayed_stim_grand_avg.avg(1,1000:5001); 

Selected_time = online_SO_grand_avg.time(1000:5001);

figure;
set(gcf, 'Position', [100 100 1600 600]);  % [left bottom width height] in pixels
subplot(1,3,3)
yyaxis left
imagesc(online_EEG_grand_avg.time, online_EEG_grand_avg.freq, squeeze(online_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, online_SO_avg_signal, 'Color', 'k', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-250 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to online detected SO');
title('No inhibition');

subplot(1,3,1)
yyaxis left
imagesc(in_phase_stim_EEG_grand_avg.time, in_phase_stim_EEG_grand_avg.freq, squeeze(in_phase_stim_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, in_phase_stim_avg_signal, 'Color', 'k', 'LineWidth', 1);
xline(3, 'Color', 'r', 'LineWidth', 1);
xline(4, 'Color', 'r', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-250 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to inhibition onset');
title('In phase inhibitions');

set(gcf, 'Position', [100 100 1600 600]);  % [left bottom width height] in pixels
subplot(1,3,2)
yyaxis left
imagesc(delayed_stim_EEG_grand_avg.time, delayed_stim_EEG_grand_avg.freq, squeeze(delayed_stim_EEG_grand_avg.powspctrm(1,:,:)));
axis xy % flip vertically
colorbar;
clim([0.75 1.5]);
ylabel('Frequency (Hz)');
hold all;
yyaxis right
line(Selected_time, delayed_stim_avg_signal, 'Color', 'k', 'LineWidth', 1);
xline(3, 'Color', 'r', 'LineWidth', 1);
xline(4, 'Color', 'r', 'LineWidth', 1);
ylabel('Amplitude (μV)');
ylim([-250 200]);
xticks([1 1.5 2 2.5 3 3.5 4 4.5 5]);
xticklabels({'-2', '-1.5', '-1', '-0.5', '0', '0.5', '1', '1.5', '2'});
xlabel('Time (s) relative to inhibition onset');
title('Delayed inhibitions');


