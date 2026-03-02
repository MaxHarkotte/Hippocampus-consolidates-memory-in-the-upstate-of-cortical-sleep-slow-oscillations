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

# --- parameters ---------------------------------------------------------
dataPath   <- "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py"
cond_levels <- c("No_stim", "SO_up_in_phase", "SO_delayed")
dodge_width <- 0.8
bracket_gap <- 0.08

# --- 01. Paths -----------------------------------------------------------
setwd(dataPath)

# --- 02. Import & clean --------------------------------------------------
test_wide <- read.csv2(
  "03_Analysis/11_Behavior_Scorings/02_Tables/02_Data_Summary/CL04-EncodingClean.csv",
  header = TRUE, sep = ";", stringsAsFactors = TRUE
)

# Exclusions (apply before reshaping/analysis)
exclude <- c("CL04-02-MPV0120-RD1", "CL04-04-MPV0120-BE1",
             "CL04-06-MPV0120-RD1", "CL04-11-MPV0120-RD1")
test_wide <- test_wide %>% filter(!Animal %in% exclude)

# ensure Condition ordering in source table
test_wide <- test_wide %>%
  mutate(
    Condition = factor(as.character(Condition), levels = cond_levels),
    Animal    = factor(Animal),
    Sampling  = factor(Sampling)
  )



# Control params (distance and encoding time)  ----------------------------
# --- 10. Reshape data ----------------------------------------------------
test_expl_time <-
  subset(
    test_wide,
    select = c(
      "Animal",
      "Condition",
      "Sampling",
      "Total_exp_time"
    )
  )

test_dist <-
  subset(
    test_wide,
    select = c(
      "Animal",
      "Condition",
      "Sampling",
      "Cum_dist_min_5"
    )
  )

# --- 11. Summary stats for bar plot (describeBy) -------------------------
test_expl_time_sum = describeBy(
  test_expl_time$Total_exp_time,
  list(test_expl_time$Condition),
  mat = TRUE,
  digits = 2
)


test_dist_sum = describeBy(
  test_dist$Cum_dist_min_5,
  list(test_dist$Condition),
  mat = TRUE,
  digits = 2
)


# --- 12. Statistics  -----------------------------------
stat.test_expl <- test_expl_time %>%
  t_test(Total_exp_time ~ Condition) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('****', '***', '**', '*' , 'ns'))  %>%
  add_xy_position(x = "Condition",
                  step.increase = 0)%>%
  mutate(y.position = y.position )

stat.test_dist <- test_dist %>%
  t_test(Cum_dist_min_5 ~ Condition) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('****', '***', '**', '*' , 'ns'))  %>%
  add_xy_position(x = "Condition",
                  step.increase = 0)%>%
  mutate(y.position = y.position )



# --- 12. Plotting -----------------------------------
limits = aes(ymax = mean + (se), ymin = mean - (se)) # (1.96*se) for confidence intervals
dodge = position_dodge(width = 0.8)

test_expl_cond <- ggplot(data = test_expl_time_sum, aes(x = group1, y = mean, fill = group1)) +
  geom_bar(
    stat = 'identity',
    position = dodge,
    width = .8,
    colour = "black"
  ) +
  geom_errorbar(limits, position = dodge, width = 0.3) +
  geom_point(
    data = test_expl_time,
    aes(x = Condition, y = Total_exp_time, fill = Condition),
    shape = 21,
    size = 1,
    alpha = 0.6
  ) +
  stat_pvalue_manual(
    stat.test_expl,
    label = "{p.signif}",
    tip.length = 0.01,
    bracket.nudge.y = 0.8,
    hide.ns = TRUE,
    size = 2.5
  ) +
  theme_classic() +
  scale_y_continuous(name = "Exploration time (s)") +
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
  )


test_dist_cond <- ggplot(data = test_dist_sum, aes(x = group1, y = mean, fill = group1)) +
  geom_bar(
    stat = 'identity',
    position = dodge,
    width = .8,
    colour = "black"
  ) +
  geom_errorbar(limits, position = dodge, width = 0.3) +
  geom_point(
    data = test_dist,
    aes(x = Condition, y = Cum_dist_min_5, fill = Condition),
    shape = 21,
    size = 1,
    alpha = 0.6
  ) +
  stat_pvalue_manual(
    stat.test_dist,
    label = "{p.signif}",
    tip.length = 0.01,
    bracket.nudge.y = 0.8,
    hide.ns = TRUE,
    size = 1
  ) +
  theme_classic() +
  scale_y_continuous(name = "Distance (m)") +
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
  )


test_expl_cond  <- test_expl_cond +   theme_classic(base_size = 7) +  
  theme(
    axis.title = element_text(size = 7),
    axis.text = element_text(size = 6),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    strip.text = element_text(size = 7), 
    legend.position = 'none')   


test_dist_cond  <- test_dist_cond +   theme_classic(base_size = 7) +  
  theme(
    axis.title = element_text(size = 7),
    axis.text = element_text(size = 6),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    strip.text = element_text(size = 7), 
    legend.position = 'none')   



test_expl_cond
test_dist_cond

ggsave(
  file = "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/expl_enc.svg",
  plot = test_expl_cond,
  width = 22,
  height = 22,
  units = "mm"
)


ggsave(
  file = "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/dist_enc.svg",
  plot = test_dist_cond,
  width = 22,
  height = 22,
  units = "mm"
)



