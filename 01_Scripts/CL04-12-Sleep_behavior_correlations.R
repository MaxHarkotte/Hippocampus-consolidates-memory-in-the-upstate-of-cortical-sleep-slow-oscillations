# Behavioral statistics analyses
# last modified: Sept 2025
# maximilian.harkotte@gmail.com

rm(list = ls()) ; cat("\014")

# --- 00. Load packages ---------------------------------------------------
library(tidyverse)  
library(psych)
library(lme4)
library(emmeans)
library(ggpubr)
library(rstatix)
library(pheatmap)
library(circular)
library(Directional)

# --- parameters ---------------------------------------------------------
dataPath   <- "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py"
cond_levels <- c("No_stim", "SO_up_in_phase", "SO_delayed")
dodge_width <- 0.8
bracket_gap <- 0.08

# --- 01. Paths -----------------------------------------------------------
setwd(dataPath)

# --- 02. Import & clean --------------------------------------------------
test_wide <- read.csv2(
  "03_Analysis/11_Behavior_Scorings/02_Tables/02_Data_Summary/CL04-TestClean.csv",
  header = TRUE, sep = ";", stringsAsFactors = TRUE
)

# Exclusions (apply before reshaping/analysis)
exclude <- c("CL04-02-MPV0120-RD1", "CL04-04-MPV0120-BE1",
             "CL04-06-MPV0120-RD1", "CL04-11-MPV0120-RD1")
test_wide <- test_wide %>% filter(!Animal %in% exclude)


sleep_param <- read.csv2(
  "03_Analysis/03_Data/03_Sleep_parameters/Sleep_event_parameters.csv",
  header = TRUE, sep = ",", stringsAsFactors = TRUE
)

sleep_arch <- read.csv2(
  "03_Analysis/03_Data/03_Sleep_parameters/Sleep_architecture.csv",
  header = TRUE, sep = ",", stringsAsFactors = TRUE
)

phase_amp <- read.csv2(
  "03_Analysis/03_Data/03_Sleep_parameters/PhaseAmpCoupling.csv",
  header = TRUE, sep = ",", stringsAsFactors = TRUE
)

# Convert numeric columns
for (i in 5:ncol(sleep_param)) {
  sleep_param[, i]  <- as.numeric(as.character(sleep_param[, i]))
}

for (i in 5:ncol(sleep_arch)) {
  sleep_arch[, i]  <- as.numeric(as.character(sleep_arch[, i]))
}

for (i in 6:ncol(phase_amp)) {
  phase_amp[, i]  <- as.numeric(as.character(phase_amp[, i]))
}

# Subset relevant data 
sleep_arch <- subset(sleep_arch, select = c("Animal", "StimProtocol", "NREM_time", "REM_time"))
phase_amp <- subset(phase_amp, select = c("Animal", "StimProtocol", "LF_mean_phase_spi_events", 
                                          "RF_mean_phase_spi_events", "LP_mean_phase_spi_events",
                                          "RP_mean_phase_spi_events"))

# Merge datasets
dat_all <- merge(
  test_wide,
  sleep_param,
  by.x = c("Animal", "Condition"),
  by.y = c("Animal", "StimProtocol")
)

dat_all <- merge(
  dat_all,
  sleep_arch,
  by.x = c("Animal", "Condition"),
  by.y = c("Animal", "StimProtocol")
)

dat_all <- merge(
  dat_all,
  phase_amp,
  by.x = c("Animal", "Condition"),
  by.y = c("Animal", "StimProtocol")
)

dat_all$Order <- as.factor(dat_all$Order)

# Restrict data to stimulation conditions only
#dat <- subset(dat_all, Condition != "No_stim")
#dat <- subset(dat_all, Condition == "SO_up_in_phase")
dat <- subset(dat_all, Condition == "SO_delayed")
#dat <- subset(dat_all, Condition == "No_stim")
nostim = FALSE

dat$inhibited_AVG_Spi_fration = (dat$inhibited_LF_Spi_fraction + dat$inhibited_RF_Spi_fraction + dat$inhibited_LP_Spi_fraction + dat$inhibited_RP_Spi_fraction)/4

# --- 03. Define variables -------------------------------------------------

brain_vars <- c(
  "EEG_LF_Spi_density", 
  "EEG_RF_Spi_density",
  "EEG_LP_Spi_density", 
  "EEG_RP_Spi_density",
  "EEG_LF_solitary_Spi_density", 
  "EEG_RF_solitary_Spi_density",
  "EEG_LP_solitary_Spi_density", 
  "EEG_RP_solitary_Spi_density",
  "EEG_LF_coupled_Spi_density", 
  "EEG_RF_coupled_Spi_density",
  "EEG_LP_coupled_Spi_density", 
  "EEG_RP_coupled_Spi_density",
  "inhibited_LF_Spi_density", 
  "inhibited_RF_Spi_density",
  "inhibited_LP_Spi_density", 
  "inhibited_RP_Spi_density",
  "online_SO_density",
  "EEG_LF_solitary_online_SO_density", 
  "EEG_RF_solitary_online_SO_density",
  "EEG_LP_solitary_online_SO_density", 
  "EEG_RP_solitary_online_SO_density",
  "EEG_LF_coupled_online_SO_density", 
  "EEG_RF_coupled_online_SO_density",
  "EEG_LP_coupled_online_SO_density", 
  "EEG_RP_coupled_online_SO_density",
  "inhibition_density",
  "NREM_time", 
  "REM_time",
  "inhibition_total_dur",
  "inhibited_LF_Spi_fraction", 
  "inhibited_RF_Spi_fraction",
  "inhibited_LP_Spi_fraction", 
  "inhibited_RP_Spi_fraction",
  "inhibited_AVG_Spi_fration"
)

if (nostim) {
  brain_vars <- c(
    "EEG_LF_Spi_density", 
    "EEG_RF_Spi_density",
    "EEG_LP_Spi_density", 
    "EEG_RP_Spi_density",
    "EEG_LF_solitary_Spi_density", 
    "EEG_RF_solitary_Spi_density",
    "EEG_LP_solitary_Spi_density", 
    "EEG_RP_solitary_Spi_density",
    "EEG_LF_coupled_Spi_density", 
    "EEG_RF_coupled_Spi_density",
    "EEG_LP_coupled_Spi_density", 
    "EEG_RP_coupled_Spi_density",
    "online_SO_density",
    "EEG_LF_solitary_online_SO_density", 
    "EEG_RF_solitary_online_SO_density",
    "EEG_LP_solitary_online_SO_density", 
    "EEG_RP_solitary_online_SO_density",
    "EEG_LF_coupled_online_SO_density", 
    "EEG_RF_coupled_online_SO_density",
    "EEG_LP_coupled_online_SO_density", 
    "EEG_RP_coupled_online_SO_density",
    "NREM_time", 
    "REM_time"
  )
}


behavior_var <- "Cum_DiRa_min_5"


# --- 04. Correlation analyses --------------------------------------------

cor_results <- map_df(brain_vars, function(v) {
  
  if (!v %in% names(dat)) return(NULL)
  
  x <- dat[[v]]
  y <- dat[[behavior_var]]
  
  ok <- complete.cases(x, y)
  x <- x[ok]; y <- y[ok]
  
  ct <- suppressWarnings(cor.test(x, y, method = "spearman"))
  
  tibble(
    measure = v,
    rho = as.numeric(ct$estimate),
    p_uncorrected = ct$p.value
  )
}) %>%
  mutate(
    p_FDR = p.adjust(p_uncorrected, method = "BH"),
    sig_raw = p_uncorrected < 0.05,
    sig_fdr = p_FDR < 0.05
  )


# --- 05. Identify significant variables -----------------------------------

sig_uncorrected <- cor_results %>% filter(sig_raw) %>% pull(measure)
sig_corrected   <- cor_results %>% filter(sig_fdr) %>% pull(measure)

cat("\nSignificant correlations (uncorrected p<0.05):\n")
print(sig_uncorrected)

cat("\nSignificant correlations (FDR corrected p<0.05):\n")
print(sig_corrected)


# --- 06. Plot scatterplots for significant correlations -------------------
make_scatter <- function(dat, var, behavior_var) {
  ggscatter(
    dat,
    x = var,
    y = behavior_var,
    color = "Condition",
    size = 3,
    add = "reg.line",                 # pooled regression line
    add.params = list(color = "black", size = 0.7),
    conf.int = TRUE,
    cor.method = "spearman",
    cor.coef = TRUE
  ) +
    labs(
      title = var,
      x = var,
      y = behavior_var
    ) +
    theme_bw(base_size = 12)
}

# --- Plotting function for each dataset ---------------------------------

plot_significant_scatterpanels <- function(dat, sig_raw_vars, sig_fdr_vars, behavior_var) {
  
  # ---- Uncorrected significant plots ----
  if (length(sig_raw_vars) > 0) {
    message("Plotting uncorrected significant correlations...")
    
    scatter_raw <- map(sig_raw_vars, ~ make_scatter(dat, .x, behavior_var))
    
    print(
      ggarrange(
        plotlist = scatter_raw,
        ncol = 3,
        nrow = ceiling(length(scatter_raw) / 3),
        common.legend = TRUE,
        legend = "right"
      )
    )
  } else {
    message("No uncorrected significant correlations.")
  }
  
  # ---- FDR-corrected significant plots ----
  if (length(sig_fdr_vars) > 0) {
    message("Plotting FDR-corrected significant correlations...")
    
    scatter_fdr <- map(sig_fdr_vars, ~ make_scatter(dat, .x, behavior_var))
    
    print(
      ggarrange(
        plotlist = scatter_fdr,
        ncol = 3,
        nrow = ceiling(length(scatter_fdr) / 3),
        common.legend = TRUE,
        legend = "right"
      )
    )
  } else {
    message("No FDR-corrected significant correlations.")
  }
}


plot_significant_scatterpanels(dat, sig_uncorrected, sig_corrected, behavior_var)


# Linear to circular correlation ------------------------------------------
# list of angle-variable names
angle_vars <- c(
  "LF_mean_phase_spi_events",
  "RF_mean_phase_spi_events",
  "LP_mean_phase_spi_events",
  "RP_mean_phase_spi_events"
)

behavior <- dat$Cum_DiRa_min_5

# initialize result storage
results <- data.frame(
  angle_var = angle_vars,
  r = NA,
  R2 = NA,
  p = NA
)

# loop
for (i in seq_along(angle_vars)) {
  
  theta <- dat[[angle_vars[i]]]     # numeric radians
  res <- circlin.cor(theta, behavior)
  
  R2 <- res[1, "R-squared"]
  p  <- res[1, "p-value"]
  r  <- sqrt(R2)
  
  results$r[i]  <- r
  results$R2[i] <- R2
  results$p[i]  <- p
}

results$p_fdr <- p.adjust(results$p, method = "fdr")
results


# Mediation analysis ------------------------------------------------------

dat <- subset(dat_all, Condition != "No_stim")
dat$Condition <- factor(dat$Condition)
dat$Animal <- factor(dat$Animal)

m_total <- lmer(Cum_DiRa_min_5 ~ Condition + (1 | Animal),
                data = dat, REML = FALSE)

m_a <- lmer(inhibited_LF_Spi_fraction ~ Condition + (1 | Animal),
            data = dat, REML = FALSE)

m_b <- lmer(Cum_DiRa_min_5 ~ Condition + inhibited_LF_Spi_fraction + (1 | Animal),
            data = dat, REML = FALSE)

library(mediation)
library(mediation)

med <- mediate(
  model.m  = m_a,
  model.y  = m_b,
  treat    = "Condition",
  mediator = "inhibited_LF_Spi_fraction",
  control.value = "SO_delayed",
  treat.value   = "SO_up_in_phase",
  boot     = FALSE
)

summary(med)

summary(m_a)  # path a
summary(m_b)  # path b and c'




dat <- subset(dat_all, Condition != "No_stim")
dat$Condition <- factor(dat$Condition)
dat$Animal <- factor(dat$Animal)

m_total <- lmer(Cum_DiRa_min_5 ~ Condition + (1 | Animal),
                data = dat, REML = FALSE)

m_a <- lmer(inhibited_LP_Spi_fraction ~ Condition + (1 | Animal),
            data = dat, REML = FALSE)

m_b <- lmer(Cum_DiRa_min_5 ~ Condition + inhibited_LP_Spi_fraction + (1 | Animal),
            data = dat, REML = FALSE)

library(mediation)
library(mediation)

med <- mediate(
  model.m  = m_a,
  model.y  = m_b,
  treat    = "Condition",
  mediator = "inhibited_LP_Spi_fraction",
  control.value = "SO_delayed",
  treat.value   = "SO_up_in_phase",
  boot     = FALSE
)

summary(med)

summary(m_a)  # path a
summary(m_b)  # path b and c'

