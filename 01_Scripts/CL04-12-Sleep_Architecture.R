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
sleep_arch <- read.csv2(
  "03_Analysis/03_Data/03_Sleep_parameters/Sleep_architecture.csv",
  header = TRUE, sep = ",", stringsAsFactors = TRUE
)

# ensure Condition ordering in source table
sleep_arch <- sleep_arch %>%
  mutate(
    StimProtocol = factor(as.character(StimProtocol), levels = cond_levels),
    Animal    = factor(Animal),
    Order  = factor(Order)
  )

for (i in 5:(length(sleep_arch)-1)) {
  sleep_arch[, i]  <- as.numeric(as.character(sleep_arch[, i]))
}

sleep_arch$NREM_incl_preREM_time <- sleep_arch$NREM_time + sleep_arch$preREM_time

# 03. Plotting and statistics ---------------------------------------------
limits = aes(ymax = mean + (se), ymin = mean - (se)) # (1.96*se) for confidence intervals
dodge = position_dodge(width = 0.8)

# Total sleep duration
sleep_arch$total_sleep_duration <- rowSums(sleep_arch[, c("NREM_time", "REM_time", "preREM_time")], na.rm = FALSE)

sleep_arch$NREM_incl_preREM_time <- rowSums(sleep_arch[, c("NREM_time", "preREM_time")], na.rm = FALSE)


# Means -------------------------------------------------------------------
mean(sleep_arch$REM_epoch_mean_dur)
sd(sleep_arch$REM_epoch_mean_dur)


# ===============================================================
#                 SETTINGS (change only this block)
# ===============================================================
measure    <- "WAKE_time"             # column name in sleep_arch
y_label    <- "Duration (min)"             # y-axis label for the plot
file_name  <- paste0(measure, ".svg")            # output filename
# ===============================================================


# 1) Summary statistics ----------------------------------------------------

summary_df <- describeBy(
  sleep_arch[[measure]],
  list(sleep_arch$StimProtocol),
  mat = TRUE,
  digits = 2
)


# 2) Statistical test ------------------------------------------------------

stat_test <- sleep_arch %>%
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
    data = sleep_arch,
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
  theme_classic(base_size = 6) +
  theme(
    axis.title = element_text(size = 6),
    axis.text = element_text(size = 6),
    legend.text = element_text(size = 6),
    legend.title = element_text(size = 6),
    strip.text = element_text(size = 6),
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
  width = 24,
  height = 20,
  units = "mm"
)


# Pie charts --------------------------------------------------------------
library(forcats)

sleep_summary <- sleep_summary %>%
  mutate(
    # Rename conditions
    StimProtocol = recode(StimProtocol,
                          "No_stim" = "NoSTIM",
                          "SO_up_in_phase" = "IN",
                          "SO_delayed" = "OUT"),
    
    # Set state order (clockwise)
    State = recode(State,
                   "WAKE_time" = "Wake",
                   "NREM_incl_preREM_time" = "NonREM",
                   "REM_time" = "REM")
  ) %>%
  mutate(
    State = factor(State, levels = c("Wake", "NonREM", "REM")),
    StimProtocol = factor(StimProtocol, levels = c("NoSTIM", "IN", "OUT"))
  ) %>%
  group_by(StimProtocol) %>%
  arrange(State, .by_group = TRUE) %>%
  mutate(
    percent = mean_time / sum(mean_time),
    ypos = cumsum(percent) - 0.5 * percent,
    label = paste0(
      scales::percent(percent, accuracy = 0.1),
      "\n",
      round(mean_time, 2), " ± ", round(sem_time, 2), " min"
    )
  ) %>%
  ungroup()

sleep_colors <- c(
  "Wake"   = "#0072B2",  # blue
  "NonREM" = "#009E73",  # green
  "REM"    = "#D55E00"   # vermillion
)


pie_chart <- ggplot(sleep_summary, aes(x = "", y = percent, fill = State)) +
  geom_col(width = 0.2, color = "grey30", linewidth = 0.6) +
  geom_text(aes(y = ypos, label = label),
            color = "white",
            size = 5 / .pt,
            lineheight = 0.9) +
  coord_polar(theta = "y", direction = -1)+
  facet_wrap(~ StimProtocol, nrow = 3) +
  scale_fill_manual(values = sleep_colors) +
  theme_void() +
  labs(fill = "State") +
  theme(
    strip.text = element_text(size = 7),
    legend.text = element_text(size = 5),
    legend.title = element_text(size = 5),
    legend.position = "none",
  )

pie_chart

ggsave(
  file = file.path(
    "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/sleep_arch_pie.svg"
  ),
  plot = pie_chart,
  width = 32,
  height = 90,
  units = "mm"
)

## Stats

basic   <- lmer(REM_time ~ StimProtocol + (1 | Animal),
                         data = sleep_arch, REML = FALSE)

rm_time   <- lmer(REM_time ~ 1 + (1 | Animal),
                data = sleep_arch, REML = FALSE)

anova(rm_time, basic) # significant 
