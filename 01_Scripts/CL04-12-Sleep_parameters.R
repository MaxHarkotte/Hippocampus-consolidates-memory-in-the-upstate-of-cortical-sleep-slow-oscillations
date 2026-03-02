# Sleep parameters statistics analyses
# last modified: Dec 2025
# maximilian.harkotte@gmail.com

rm(list = ls()) ; cat("\014")

# --- 00. Load packages ---------------------------------------------------
library(tidyverse)  
library(psych)
library(lme4)
library(emmeans)
library(ggpubr)
library(rstatix)

# --- parameters ---------------------------------------------------------
dataPath   <- "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py"
cond_levels <- c("No_stim", "SO_up_in_phase", "SO_delayed")
dodge_width <- 0.8
bracket_gap <- 0.08

# --- 01. Paths -----------------------------------------------------------
setwd(dataPath)

# --- 02. Import & clean --------------------------------------------------

sleep_param <- read.csv2(
  "03_Analysis/03_Data/03_Sleep_parameters/Sleep_event_parameters.csv",
  header = TRUE, sep = ",", stringsAsFactors = TRUE
)

# ensure Condition ordering in source table
sleep_param <- sleep_param %>%
  mutate(
    StimProtocol = factor(as.character(StimProtocol), levels = cond_levels),
    Animal    = factor(Animal),
    Order  = factor(Order)
  )

for (i in 5:(length(sleep_param)-1)) {
  sleep_param[, i]  <- as.numeric(as.character(sleep_param[, i]))
}


## if only inhibition condition: 
cond_levels <- c("SO_up_in_phase", "SO_delayed")
sleep_param = subset(sleep_param, sleep_param$StimProtocol !=  "No_stim")

sleep_param <- sleep_param %>%
  mutate(
    StimProtocol = factor(as.character(StimProtocol), levels = cond_levels),
    Animal    = factor(Animal),
    Order  = factor(Order)
  )

sleep_param$inhibition_total_dur <- sleep_param$inhibition_total_dur/60

sleep_param$EEG_LF_fraction_coupled_SOs <- (sleep_param$EEG_RF_coupled_online_SO_count  / sleep_param$online_SO_count)*100
sleep_param$EEG_LF_fraction_coupled_Spis <- (sleep_param$EEG_LF_coupled_Spi_count / sleep_param$EEG_LF_Spi_count)*100

sleep_param$inhibited_LF_Spi_fraction <-  sleep_param$inhibited_LF_Spi_fraction*100

# 03. Plotting and statistics ---------------------------------------------
limits = aes(ymax = mean + (se), ymin = mean - (se)) # (1.96*se) for confidence intervals
dodge = position_dodge(width = 0.8)

# ===============================================================
#                 SETTINGS (change only this block)
# ===============================================================
measure    <- "inhibited_LP_Spi_fraction"             # column name in sleep_param
y_label    <- "Avg. inhibition duration (s)"             # y-axis label for the plot
file_name  <- paste0(measure, ".svg")            # output filename
# ===============================================================


# 1) Summary statistics ----------------------------------------------------

summary_df <- describeBy(
  sleep_param[[measure]],
  list(sleep_param$StimProtocol),
  mat = TRUE,
  digits = 2
)


# 2) Statistical test ------------------------------------------------------

stat_test <- sleep_param %>%
  t_test(as.formula(paste(measure, "~ StimProtocol"))) %>%
  add_significance(
    "p",
    cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1),
    symbols   = c("****", "***", "**", "*", "ns")
  ) %>%
  add_xy_position(x = "StimProtocol") %>%
  mutate(y.position = y.position)


# 3) Plot ------------------------------------------------------------------

dodge <- position_dodge(width = .8)

limits <- aes(
  ymin = mean - se,
  ymax = mean + se
)

p <- ggplot(data = summary_df,
            aes(x = group1, y = mean, fill = group1)) +
  geom_bar(
    stat = 'identity',
    position = dodge,
    width = .8,
    colour = "black"
  ) +
  geom_errorbar(limits, position = dodge, width = 0.3) +
  geom_point(
    data = sleep_param,
    aes(x = StimProtocol, y = !!sym(measure), fill = StimProtocol),
    shape = 21,
    size = 1,
    alpha = 0.6
  ) +
  stat_pvalue_manual(
    stat_test,
    label = "{p.signif}",
    tip.length = 0.01,
    bracket.nudge.y = 0.8,
    hide.ns = TRUE,
    size = 1
  ) +
  theme_classic() +
  scale_y_continuous(name = y_label) +
  scale_x_discrete(name = NULL, labels = NULL) +
  scale_fill_manual(
    "Condition",
    values = c(
      "No_stim"        = "#595959",
      "SO_up_in_phase" = "#d7dbdd",
      "SO_delayed"     = "#FFFFFF"
    ),
    labels = c(
      "No inhibition (n = 12)",
      "Inhibition during SO peak (n = 12)",
      "Inhibition outside SO (n = 9)"
    )
  ) +
  theme_classic(base_size = 7) +
  theme(
    axis.title = element_text(size = 7),
    axis.text = element_text(size = 6),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    strip.text = element_text(size = 7),
    legend.position = 'none'
  )


# 4) Output ----------------------------------------------------------------

print(p)


ggsave(
  file = file.path(
    "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures",
    file_name
  ),
  plot = p,
  width = 25,
  height = 35,
  units = "mm"
)

