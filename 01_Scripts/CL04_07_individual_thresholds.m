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

%% Read in recordings and extract online detected thresholds

for iRec = 39 :size(selection,1)
    %% Read in recording and hypnogram
    % Recording information
    rec_info         = selection(iRec,:);
    recording_length = rec_info.RecLengthInMin*60; % in seconds

    % read in data and combine in one ft structure
    cfg         = [];
    cfg.dataset = strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/01_Neuralynx/', rec_info.NLX_id, '/');
    cfg.channel = {'EEG_left_frontal'};
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
    online_SO = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/02_Online/', ...
        char(rec_info.NLX_id), '_online_SOs.mat'));
    online_SO = online_SO.online_SO;


    online_SO = online_SO(find(strcmp(online_SO.type, "SO_rising_flank")),:);


    %% Filter data similar to online filtering       
    filter_order = 1;             
    filter_fcutlow = 0.1;          
    filter_fcuthigh = 4;      

    % 1st-order Butterworth bandpass filter
    [b, a] = butter(1, [filter_fcutlow filter_fcuthigh] / (fs/2), 'bandpass');
    
    % Apply forward-only filtering
    EEG_filt = filter(b, a, rec.trial{1,1});

    %% 
    for iSO = 1:size(online_SO, 1)
        EEG_filt(online_SO.sample(iSO))
        subplot(2,1,2)
        plot(EEG_filt(online_SO.sample(iSO)-2000:online_SO.sample(iSO)+2000))
        xline(2000)
        [minimum_2, idx_2] = min(EEG_filt(online_SO.sample(iSO)-2000:online_SO.sample(iSO)+2000))
        xline(idx_2, 'r')

    end

   
end

factor = minimum_2/minimum

minimum*factor

thresholds = 
