# Data wrangling
## This script takes the output from AnyMaze and curates the data matrices for all further analyses
## maximilian.harkotte@gmail.com - September 2025


rm(list = ls()) # clear workspace
cat("/014") # clear console


# 0 - Load packages -------------------------------------------------------
library(tidyverse)

# 1 - Source file ---------------------------------------------------------
dataPath <-
  "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py"
setwd(dataPath)

test <-
  read.csv2(
    "03_Analysis/11_Behavior_Scorings/02_Tables/01_Tracking/CL04-Encoding_Scoring.csv",
    header = TRUE,
    sep = ","
  )

test_ref <-
  read.csv2(
    "02_Raw_Data/02_Video_files/04_Enc/Documentation_Encoding.csv",
    header = TRUE,
    sep = ","
  )

test <-
  merge(test_ref, test, by.x = "AnyMaze_Test", by.y = "Test")

# 3 - Data Wrangling ------------------------------------------------------

## Rename Col Names of Test table
test_clean <- test %>%
  rename(
    Cum_dist_min_1 = Cum_1..Distance..m.,
    Cum_dist_min_2 = Cum_2..Distance..m.,
    Cum_dist_min_3 = Cum_3..Distance..m.,
    Cum_dist_min_4 = Cum_4..Distance..m.,
    Cum_dist_min_5 = Cum_5..Distance..m.,
    Bin_dist_min_1 = Bin_1..Distance..m.,
    Bin_dist_min_2 = Bin_2..Distance..m.,
    Bin_dist_min_3 = Bin_3..Distance..m.,
    Bin_dist_min_4 = Bin_4..Distance..m.,
    Bin_dist_min_5 = Bin_5..Distance..m.,
    Cum_velo_min_1 = Cum_1..Mean.speed..m.s.,
    Cum_velo_min_2 = Cum_2..Mean.speed..m.s.,
    Cum_velo_min_3 = Cum_3..Mean.speed..m.s.,
    Cum_velo_min_4 = Cum_4..Mean.speed..m.s.,
    Cum_velo_min_5 = Cum_5..Mean.speed..m.s.,
    Bin_velo_min_1 = Bin_1..Mean.speed..m.s.,
    Bin_velo_min_2 = Bin_2..Mean.speed..m.s.,
    Bin_velo_min_3 = Bin_3..Mean.speed..m.s.,
    Bin_velo_min_4 = Bin_4..Mean.speed..m.s.,
    Bin_velo_min_5 = Bin_5..Mean.speed..m.s.,
    Cum_BaLe_exp_1 = Cum_1..Leftback_exploration...time.pressed..s.,
    Cum_BaLe_exp_2 = Cum_2..Leftback_exploration...time.pressed..s.,
    Cum_BaLe_exp_3 = Cum_3..Leftback_exploration...time.pressed..s.,
    Cum_BaLe_exp_4 = Cum_4..Leftback_exploration...time.pressed..s.,
    Cum_BaLe_exp_5 = Cum_5..Leftback_exploration...time.pressed..s.,
    Bin_BaLe_exp_1 = Bin_1..Leftback_exploration...time.pressed..s.,
    Bin_BaLe_exp_2 = Bin_2..Leftback_exploration...time.pressed..s.,
    Bin_BaLe_exp_3 = Bin_3..Leftback_exploration...time.pressed..s.,
    Bin_BaLe_exp_4 = Bin_4..Leftback_exploration...time.pressed..s.,
    Bin_BaLe_exp_5 = Bin_5..Leftback_exploration...time.pressed..s.,
    BaLe_exp_Latency = Leftback_exploration...latency.1st.press..s.,
    Cum_FrRi_exp_1 = Cum_1..Rightfront_exploration...time.pressed..s.,
    Cum_FrRi_exp_2 = Cum_2..Rightfront_exploration...time.pressed..s.,
    Cum_FrRi_exp_3 = Cum_3..Rightfront_exploration...time.pressed..s.,
    Cum_FrRi_exp_4 = Cum_4..Rightfront_exploration...time.pressed..s.,
    Cum_FrRi_exp_5 = Cum_5..Rightfront_exploration...time.pressed..s.,
    Bin_FrRi_exp_1 = Bin_1..Rightfront_exploration...time.pressed..s.,
    Bin_FrRi_exp_2 = Bin_2..Rightfront_exploration...time.pressed..s.,
    Bin_FrRi_exp_3 = Bin_3..Rightfront_exploration...time.pressed..s.,
    Bin_FrRi_exp_4 = Bin_4..Rightfront_exploration...time.pressed..s.,
    Bin_FrRi_exp_5 = Bin_5..Rightfront_exploration...time.pressed..s.,
    FrRi_exp_Latency = Rightfront_exploration...latency.1st.press..s.,
    Cum_BaLe_tim_1 = Cum_1..BL...time..s.,
    Cum_BaLe_tim_2 = Cum_2..BL...time..s.,
    Cum_BaLe_tim_3 = Cum_3..BL...time..s.,
    Cum_BaLe_tim_4 = Cum_4..BL...time..s.,
    Cum_BaLe_tim_5 = Cum_5..BL...time..s.,
    Bin_BaLe_tim_1 = Bin_1..BL...time..s.,
    Bin_BaLe_tim_2 = Bin_2..BL...time..s.,
    Bin_BaLe_tim_3 = Bin_3..BL...time..s.,
    Bin_BaLe_tim_4 = Bin_4..BL...time..s.,
    Bin_BaLe_tim_5 = Bin_5..BL...time..s.,
    Cum_BaRi_tim_1 = Cum_1..BR...time..s.,
    Cum_BaRi_tim_2 = Cum_2..BR...time..s.,
    Cum_BaRi_tim_3 = Cum_3..BR...time..s.,
    Cum_BaRi_tim_4 = Cum_4..BR...time..s.,
    Cum_BaRi_tim_5 = Cum_5..BR...time..s.,
    Bin_BaRi_tim_1 = Bin_1..BR...time..s.,
    Bin_BaRi_tim_2 = Bin_2..BR...time..s.,
    Bin_BaRi_tim_3 = Bin_3..BR...time..s.,
    Bin_BaRi_tim_4 = Bin_4..BR...time..s.,
    Bin_BaRi_tim_5 = Bin_5..BR...time..s.,
    Cum_FrLe_tim_1 = Cum_1..FL...time..s.,
    Cum_FrLe_tim_2 = Cum_2..FL...time..s.,
    Cum_FrLe_tim_3 = Cum_3..FL...time..s.,
    Cum_FrLe_tim_4 = Cum_4..FL...time..s.,
    Cum_FrLe_tim_5 = Cum_5..FL...time..s.,
    Bin_FrLe_tim_1 = Bin_1..FL...time..s.,
    Bin_FrLe_tim_2 = Bin_2..FL...time..s.,
    Bin_FrLe_tim_3 = Bin_3..FL...time..s.,
    Bin_FrLe_tim_4 = Bin_4..FL...time..s.,
    Bin_FrLe_tim_5 = Bin_5..FL...time..s.,
    Cum_FrRi_tim_1 = Cum_1..FR...time..s.,
    Cum_FrRi_tim_2 = Cum_2..FR...time..s.,
    Cum_FrRi_tim_3 = Cum_3..FR...time..s.,
    Cum_FrRi_tim_4 = Cum_4..FR...time..s.,
    Cum_FrRi_tim_5 = Cum_5..FR...time..s.,
    Bin_FrRi_tim_1 = Bin_1..FR...time..s.,
    Bin_FrRi_tim_2 = Bin_2..FR...time..s.,
    Bin_FrRi_tim_3 = Bin_3..FR...time..s.,
    Bin_FrRi_tim_4 = Bin_4..FR...time..s.,
    Bin_FrRi_tim_5 = Bin_5..FR...time..s.
  )

for (i in (length(test_ref) + 1):(length(test_clean))) {
  test_clean[, i]  <- as.numeric(as.character(test_clean[, i]))
}

## Total exploration time
test_clean$Total_exp_time <-
  test_clean$Cum_BaLe_exp_5 + test_clean$Cum_FrRi_exp_5


# 4 - Save csv ------------------------------------------------------------

write.csv2(
  test_clean,
  file.path(
    dataPath,
    "03_Analysis/11_Behavior_Scorings/02_Tables/02_Data_Summary/CL04-EncodingClean.csv"
  ),
  row.names = FALSE
)
