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
selection = reference( contains(reference.Phase,"Habituation"), :);

%% Read in preprocessed data 
iFirst     = 1; 
iSecond    = 1; 
iThird     = 1; 

for iRec = 1:size(selection,1)
    %% Read in recording and hypnogram
    % Recording information
    rec_info         = selection(iRec,:);

    %% Read in detections
    % Offline detected events
    offline_events = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/01_Offline/', ...
        char(rec_info.NLX_id), '_events.mat'));
    offline_events = offline_events.detection_output;

    if rec_info.Order == 1
        first_hab_nrem_spectra_mixed(iFirst,:) = offline_events.spectrum.mix_nrem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        first_hab_rem_spectra_mixed(iFirst,:) = offline_events.spectrum.mix_rem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        iFirst = iFirst +1;

    elseif rec_info.Order == 2

        second_hab_nrem_spectra_mixed(iSecond,:) = offline_events.spectrum.mix_nrem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        second_hab_rem_spectra_mixed(iSecond,:) = offline_events.spectrum.mix_rem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        iSecond = iSecond +1;

    elseif rec_info.Order == 3

        third_hab_nrem_spectra_mixed(iThird,:) = offline_events.spectrum.mix_nrem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        third_hab_rem_spectra_mixed(iThird,:) = offline_events.spectrum.mix_rem(find(strcmp(offline_events.info.channel, "EEG_left_frontal")),:);
        iThird = iThird +1;
    end

end

%% Calculate means over spectra
first_hab_mean_nrem_spectra_mixed = mean(first_hab_nrem_spectra_mixed,1);
first_hab_mean_rem_spectra_mixed = mean(first_hab_rem_spectra_mixed,1);

second_hab_mean_nrem_spectra_mixed = mean(second_hab_nrem_spectra_mixed,1);
second_hab_mean_rem_spectra_mixed = mean(second_hab_rem_spectra_mixed,1);

third_hab_mean_nrem_spectra_mixed = mean(third_hab_nrem_spectra_mixed,1);
third_hab_mean_rem_spectra_mixed = mean(third_hab_rem_spectra_mixed,1);

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
stdshade_AxisSpecific(first_hab_nrem_spectra_mixed,0.2,'b',offline_events.spectrum.freq,1,[]);
stdshade_AxisSpecific(second_hab_nrem_spectra_mixed,0.2,'r',offline_events.spectrum.freq,1,[]);
stdshade_AxisSpecific(third_hab_nrem_spectra_mixed,0.2,'g',offline_events.spectrum.freq,1,[]);
xline(0,LineWidth=1, Color='k')
set(gca, 'YScale', 'log')
legend('First', '', 'Second', '', 'Third', '');
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
stdshade_AxisSpecific(first_hab_rem_spectra_mixed,0.2,'b',offline_events.spectrum.freq,1,[]);
stdshade_AxisSpecific(second_hab_rem_spectra_mixed,0.2,'r',offline_events.spectrum.freq,1,[]);
stdshade_AxisSpecific(third_hab_rem_spectra_mixed,0.2,'g',offline_events.spectrum.freq,1,[]);
xline(0,LineWidth=1, Color='k')
set(gca, 'YScale', 'log')
legend('First', '', 'Second', '', 'Third', '');
title('REM Sleep');