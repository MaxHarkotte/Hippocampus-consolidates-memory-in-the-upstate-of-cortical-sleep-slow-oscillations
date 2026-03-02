% Offline detection of SOs and spindles from surface EEG signal
% Author: Max Harkotte (maximilian.harkotte@gmail.com)
% uses detection toolbox by Niels Niethard and Jens Klinzing (2022)
% Date: September 2025
clear
close all
clc 

% Takes in raw data recorded with Neuralynx system and runs 
% event detection (SO, Spi, Ripples) on all channels

% Requirements: 
% - Signal Processing Toolbox

%% Paths
script_path = which('CL04_00_Sleep_Oscillation_Detection.m');
script_path = strrep(char(script_path), '\', '/');
file_server_path = 'Z:/'; % if run locally
%file_server_path = '/gpfs01/born/animal/'; % if run on the cluster

% Paths to toolboxes and functions
root = strsplit(char(script_path),'00_Closed_Loop_Inhibition_CA1py/');
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/event_detection/event_detector/')); 
addpath(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/00_Resources/fieldtrip-20240722/')); 
ft_defaults

clear script_path; 
%% Recording information
reference = readtable(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/02_Raw_Data/01_Electrophysiology/Documentation.xlsx'));

%% Select recordings for detection 
selection             = reference(contains(reference.Phase, 'Retention'), :);

%% Event detection parameters
cfg_det                        = [];
cfg_det.scoring_epoch_length   = 10; 
cfg_det.code_NREM              = 2;
cfg_det.code_REM               = 3;
cfg_det.code_WAKE              = 1;
cfg_det.artfctpad			   = 0;	
cfg_det.spectrum               = 1;					
cfg_det.invertdata             = 0;

% SO detection params
cfg_det.slo		               = 0;					
cfg_det.slo_dur_min		       = 0.5;			
cfg_det.slo_dur_max		       = 2.0;			
cfg_det.slo_freq			   = [0.1 4];
cfg_det.slo_filt_ord	       = 3;
cfg_det.slo_rel_thr            = 33; 
cfg_det.slo_dur_max_down       = 0.300; %in s

% Spindle detection params
cfg_det.spi					   = 0;		
cfg_det.spi_dur_min			   = [0.5 0.25];		
cfg_det.spi_dur_max			   = [2.5 2.5];
cfg_det.spi_thr(1,1)		   = 1.5;
cfg_det.spi_thr(2,1)		   = 2;
cfg_det.spi_thr(3,1)		   = 2.5;
cfg_det.spi_thr_chan		   = [];
cfg_det.spi_freq			   = [10 16];
cfg_det.spi_peakdist_max	   = 0.125;
cfg_det.spi_filt_ord	       = 6;
cfg_det.spi_indiv			   = 0;

% Ripples 
cfg_det.rip                    = 0;

%% Read in recordings and run event detection for each channel

for iRec = 1:size(selection,1)
    
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

    clear cfg;

    % Hypnogram 
    tmp_hypno       = load(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/02_Sleep_Scorings/02_Matlab_files/', ...
        char(rec_info.NLX_id), '.mat'), 'SlStNew'); 
    hypno           = double(tmp_hypno.SlStNew.codes(1:recording_length/10,1));
    cfg_det.scoring = hypno;

    clear tmp_hypno hypno;

    % Run event detection detection
    detection_output = detectEvents_V2(cfg_det, rec);

    % plotDetectedEvents(detection_output, strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/04_Figures/01_Sleep_Oscillation_Detections/', ...
    %     char(rec_info.NLX_id), '_detections.fig'))

    % Save detections
    save(strcat(char(root(1)), '00_Closed_Loop_Inhibition_CA1py/03_Analysis/03_Data/01_Sleep_Oscillation_Detections/03_Offline_NREM_preREM/', ...
        char(rec_info.NLX_id), '_events'),'detection_output','-v7.3')

end
