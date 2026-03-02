% Calculates Time Frequency Analysis of offline and online detected SOs
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
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/Neuralynx_Import_MEX/')); 
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/Plotting/'));
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/fieldtrip-20240722/')); 
ft_defaults

clear script_path; 
%% Recording information
reference = readtable(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/Documentation.xlsx'));

%% Select recordings for analysis
selection = reference( contains(reference.Phase,"Retention") & reference.Exclusion == "no", :);

%% Read in preprocessed data 
iNo_Stim     = 1; 
iIn_Phase    = 1; 
iDelayed     = 1; 

for iRec = 1:size(selection,1)
    %% Read in recording and hypnogram
    % Recording information
    rec_info         = selection(iRec,:);

    %% Read in detections
    % Offline detected events
    offline_events = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/03_Offline_NREM_preREM/', ...
        char(rec_info.NLX_id), '_events.mat'));
    offline_events = offline_events.detection_output;

    if rec_info.StimProtocol == "No_stim"
        no_stim_nrem_spectra_mixed(iNo_Stim,:) = offline_events.spectrum.mix_nrem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        no_stim_rem_spectra_mixed(iNo_Stim,:) = offline_events.spectrum.mix_rem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        iNo_Stim = iNo_Stim +1;

    elseif rec_info.StimProtocol == "SO_up_in_phase"

        in_phase_nrem_spectra_mixed(iIn_Phase,:) = offline_events.spectrum.mix_nrem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        in_phase_rem_spectra_mixed(iIn_Phase,:) = offline_events.spectrum.mix_rem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        iIn_Phase = iIn_Phase +1;

    elseif rec_info.StimProtocol == "SO_delayed"

        delayed_nrem_spectra_mixed(iDelayed,:) = offline_events.spectrum.mix_nrem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        delayed_rem_spectra_mixed(iDelayed,:) = offline_events.spectrum.mix_rem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        iDelayed = iDelayed +1;
    end

     nrem_spectra_mixed_all(iRec,:) = offline_events.spectrum.mix_nrem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
     rem_spectra_mixed_all(iRec,:) = offline_events.spectrum.mix_nrem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);

end

%% Stats Prep
freqs = offline_events.spectrum.freq;      % 1 x nFreqs
AnimalID  = repmat(selection.Animal, nFreqs, 1);
Condition = repmat(selection.StimProtocol, nFreqs, 1);
Freq      = reshape(repmat(freqs, nAnimals, 1), [], 1);

%% Stats NREM 
% Omnibus Test 
NREMPower = reshape(nrem_spectra_mixed_all, [], 1);
NREM      = table(AnimalID, Condition, Freq, NREMPower);

% Make categorical
NREM.AnimalID  = categorical(NREM.AnimalID);
NREM.Condition = categorical(NREM.Condition);
NREM.NREMPower = 10*log10(NREM.NREMPower);

nrem_lme = fitlme(NREM, 'NREMPower ~ Condition + (1|AnimalID)');
nrem_lme0 = fitlme(NREM, 'NREMPower ~ 1 + (1|AnimalID)');

nrem_stats_overall = compare(nrem_lme0, nrem_lme, 'CheckNesting', true);
nrem_stats_overall


%% Stats REM
% Omnibus Test 
REMPower     = reshape(rem_spectra_mixed_all, [], 1);
REM = table(AnimalID, Condition, Freq, REMPower);

% Make categorical
REM.AnimalID  = categorical(REM.AnimalID);
REM.Condition = categorical(REM.Condition);
REM.REMPower = 10*log10(REM.REMPower);

rem_lme = fitlme(REM, 'REMPower ~ Condition + (1|AnimalID)');
rem_lme0 = fitlme(REM, 'REMPower ~ 1 + (1|AnimalID)');

rem_stats_overall = compare(rem_lme0, rem_lme, 'CheckNesting', true);
rem_stats_overall

%% Plotting 

hFig = figure;
subplot(1,2,1)
set(gcf,'PaperPositionMode','auto')
set(hFig, 'Position', [500 500 500 500])
set(gcf,'color','white')
% t = tiledlayout(1,1);
% ax1 = axes(t);
hold on
set(gca,'FontSize',8,'TickLength',[0.025 0.025])
set(gca,'TickDir','out');
set(gca, 'box', 'off')
%Labels = {'0','1','2','3','4','5','6','7','8','9','10','11','12','13','14'};
%set(gca, 'XTick', 1:12:168, 'XTickLabel', Labels);
ax1 = gca;
hold off

%ax2 = axes('Position',[0.2 0.7 0.2 0.2]);
box off
hold on
stdshade_AxisSpecific(no_stim_nrem_spectra_mixed,0.2,'b',offline_events.spectrum.freq,1,[]);
stdshade_AxisSpecific(in_phase_nrem_spectra_mixed,0.2,'r',offline_events.spectrum.freq,1,[]);
stdshade_AxisSpecific(delayed_nrem_spectra_mixed,0.2,'g',offline_events.spectrum.freq,1,[]);
xline(0,LineWidth=1, Color='k')
set(gca, 'YScale', 'log')
legend('No Stim', '', 'In Phase', '', 'Delayed', '');
title('NREM Sleep');

subplot(1,2,2)
set(gcf,'PaperPositionMode','auto')
set(hFig, 'Position', [500 500 500 500])
set(gcf,'color','white')
% t = tiledlayout(1,1);
% ax1 = axes(t);
hold on
set(gca,'FontSize',8,'TickLength',[0.025 0.025])
set(gca,'TickDir','out');
set(gca, 'box', 'off')
%Labels = {'0','1','2','3','4','5','6','7','8','9','10','11','12','13','14'};
%set(gca, 'XTick', 1:12:168, 'XTickLabel', Labels);
ax1 = gca;
hold off

%ax2 = axes('Position',[0.2 0.7 0.2 0.2]);
box off
hold on
stdshade_AxisSpecific(no_stim_rem_spectra_mixed,0.2,'b',offline_events.spectrum.freq,1,[]);
stdshade_AxisSpecific(in_phase_rem_spectra_mixed,0.2,'r',offline_events.spectrum.freq,1,[]);
stdshade_AxisSpecific(delayed_rem_spectra_mixed,0.2,'g',offline_events.spectrum.freq,1,[]);
xline(0,LineWidth=1, Color='k')
set(gca, 'YScale', 'log')
legend('No Stim', '', 'In Phase', '', 'Delayed', '');
title('preREM Sleep');

%% Saving
%exportgraphics(gcf, strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/power_spectra_sleep_conditions.pdf'), 'ContentType', 'vector');




