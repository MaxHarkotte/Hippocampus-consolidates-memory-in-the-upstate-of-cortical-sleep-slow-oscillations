# README
Analysis scripts for Harkotte et al. - Hippocampus consolidates memory in the upstates of cortical sleep slow-oscillations

## 1. System Requirements

### Operating Systems
The code has been tested on:
- Windows 10

### Software Dependencies

#### MATLAB
- MATLAB (Version R2023b)
- Signal Processing Toolbox
- FieldTrip (version 20240722)
- Circular Statistics Toolbox

#### R
- R (Version 4.4.1)
- Packages:
  - tidyverse
  - psych
  - lme4
  - emmeans
  - ggpubr
  - rstatix
  - pheatmap
  - MuMIn
  - circular
  - Directional

#### Python
- Python (version installed December 2025)
- Libraries:
  - pathlib
  - spikeinterface
  - probeinterface
  - matplotlib
  - numpy
  - neo
  - json
  - scipy

### Tested Versions
The code has been tested using:
- MATLAB R2023b
- R 4.4.1
- Python (latest version available as of December 2025)

### Hardware Requirements
- Standard desktop computer
- No non-standard hardware required

---

## 2. Installation Guide

### Instructions
The source code can be obtained by downloading or cloning the associated GitHub repository.

All required software dependencies (MATLAB toolboxes, R packages, and Python libraries) must be installed prior to running the code.

The dataset required to run the analysis is publicly available at:  
https://osf.io/mt2e3/

### Typical Install Time
Installation of dependencies typically requires a few minutes on a standard desktop computer, depending on the system configuration.

---

## 3. Demo

### Instructions to Run
All analysis scripts are located in the directory: \01_Scripts

The scripts are organized sequentially and can be executed to reproduce the analyses. Script names follow the convention: CL04_01, CL04_02, CL04_03, ...


### Expected Output
Running the scripts produces:
- Statistical analysis outputs
- Figures corresponding to the analyses described in the manuscript

### Notes
The scripts collectively reproduce the results presented in the manuscript when applied to the provided dataset.

---

## 4. Instructions for Use

### Input Data
The analysis expects input data in:
- `.mat` format
- `.csv` format

### Running the Analysis
1. Download the dataset from:  
   https://osf.io/mt2e3/

2. Update file paths in the scripts to match the local data directory.

3. Execute the scripts in the `01_Scripts/` directory in sequential order (e.g., `CL04_01`, `CL04_02`, etc.).

### Output
The scripts generate:
- Processed data
- Statistical results
- Figures for visualization

---

## Additional Information
The code is provided as used for the analyses in the manuscript.

