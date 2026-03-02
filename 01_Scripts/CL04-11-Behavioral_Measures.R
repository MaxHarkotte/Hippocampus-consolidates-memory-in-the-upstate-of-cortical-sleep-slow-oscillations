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
  "03_Analysis/11_Behavior_Scorings/02_Tables/02_Data_Summary/CL04-TestClean.csv",
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

# Memory Performance ------------------------------------------------------
# --- 03. Reshape data ----------------------------------------------------
Cum_DR <- test_wide %>%
  pivot_longer(
    cols = starts_with("Cum_DiRa_min"),
    names_to = "Minute",
    values_to = "DR"
  ) %>%
  mutate(
    Minute = factor(Minute, levels = paste0("Cum_DiRa_min_", 1:5)),
    Condition = factor(as.character(Condition), levels = cond_levels),
    Sampling  = factor(Sampling),
    Animal    = factor(Animal)
  )

Cum_DR_no_stim <- subset(Cum_DR, Cum_DR$Condition == "No_stim")

# --- 04. Summary stats for bar plot (describeBy) -------------------------
Cum_DR_sum <- describeBy(Cum_DR$DR, list(Cum_DR$Condition, Cum_DR$Minute),
                         mat = TRUE, digits = 2) %>%
  as.data.frame() %>%
  mutate(group1 = factor(group1, levels = cond_levels))

Cum_DR_no_stim_sum <- describeBy(Cum_DR_no_stim$DR, list(Cum_DR_no_stim$Sampling, Cum_DR_no_stim$Minute),
                         mat = TRUE, digits = 2) %>%
  as.data.frame() %>%
  mutate(group1 = factor(group1))

stat.test_zero <- Cum_DR %>%
  group_by(Condition, Minute) %>%
  t_test(DR ~ 1, mu = 0) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('####', '###', '##', '#' ,  'ns')) %>%
  mutate(group1 = Condition, group2 = Minute) %>%
  add_xy_position(x = "Minute",
                  group = "Condition",
                  step.increase = 0) %>%
  mutate(y.position = 1.1)

stat.test_cond <- Cum_DR %>%
  group_by(Minute) %>%
  t_test(DR ~ Condition) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('****', '***', '**', '*' , 'ns'))  %>%
  add_xy_position(x = "Minute",
                  dodge = 0.8,
                  step.increase = 0)%>%
  mutate(y.position = 0.5)

stat.test_cond <- stat.test_cond %>%
  group_by(Minute) %>%
  mutate(y.position = y.position + 0.1 * (row_number() - 1)) %>%
  ungroup()

stat.test_no_stim_zero <- Cum_DR_no_stim %>%
  group_by(Sampling, Minute) %>%
  t_test(DR ~ 1, mu = 0) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('####', '###', '##', '#' ,  'ns')) %>%
  mutate(group1 = Sampling, group2 = Minute) %>%
  add_xy_position(x = "Minute",
                  group = "Sampling",
                  step.increase = 0) %>%
  mutate(y.position = 1.1)

stat.test_no_stim_cond <- Cum_DR_no_stim %>%
  group_by(Minute) %>%
  t_test(DR ~ Sampling) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('****', '***', '**', '*' , 'ns'))  %>%
  add_xy_position(x = "Minute",
                  dodge = 0.8,
                  step.increase = 0)%>%
  mutate(y.position = 0.5)

stat.test_no_stim_cond <- stat.test_no_stim_cond %>%
  group_by(Minute) %>%
  mutate(y.position = y.position + 0.1 * (row_number() - 1)) %>%
  ungroup()



# --- 05. Quick plotting (raw summary) -----------------------------------
dodge <- position_dodge(width = dodge_width)

DR_raw_plot <- ggplot(Cum_DR_sum, aes(x = group2, y = mean, fill = group1)) +
  geom_col(position = dodge, width = .8, colour = "black") +
  geom_errorbar(aes(ymin = mean - se, ymax = mean + se),
                position = dodge, width = 0.3) +
  geom_dotplot(
    data = Cum_DR, aes(x = Minute, y = DR, fill = Condition),
    binaxis = 'y', stackdir = 'center', binwidth = .03,
    position = dodge,
    dotsize = 2, 
    alpha = 0.6
  ) +
  stat_pvalue_manual(
    stat.test_zero,
    label = "{p.signif}",
    x = "xmax",
    remove.bracket = TRUE,
    hide.ns = TRUE,
    size = 1) +
  stat_pvalue_manual(
    stat.test_cond,
    label = "{p.signif}",
    tip.length = 0.01,
    bracket.nudge.y = 0.8,
    hide.ns = TRUE,
    size = 1
  ) +
  theme_classic() +
  scale_y_continuous("DR", breaks = seq(-1, 1, 0.5), limits = c(-1, 1.5)) +
  scale_x_discrete("Minute", labels = 1:5) +
  scale_fill_manual(
    "Condition",
    values = c("No_stim" = "#8b1e00ff",
               "SO_up_in_phase" = "#1f8fb4ff",
               "SO_delayed" = "#b9cf3aff"),
    labels = c("NoSTIM",
               "IN",
               "OUT")
  ) +
  geom_hline(yintercept = 0, colour = "black", size = .1)

DR_raw_plot <- DR_raw_plot +   theme_classic(base_size = 7) +  # set global font and size
  theme(
    axis.title = element_text(size = 7),
    axis.text = element_text(size = 7),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    strip.text = element_text(size = 7), 
    legend.position = 'none')          
DR_raw_plot

# Save figure 
ggsave(
  file = "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/perMin_DR.svg",
  plot = DR_raw_plot,
  width = 70,
  height = 40,
  units = "mm"
)

DR_no_stim_plot <- ggplot(Cum_DR_no_stim_sum, aes(x = group2, y = mean, fill = group1)) +
  geom_col(position = dodge, width = .8, colour = "black") +
  geom_errorbar(aes(ymin = mean - se, ymax = mean + se),
                position = dodge, width = 0.3) +
  geom_dotplot(
    data = Cum_DR_no_stim, aes(x = Minute, y = DR, fill = Sampling),
    binaxis = 'y', stackdir = 'center', binwidth = .03,
    position = dodge
  ) +
  stat_pvalue_manual(
    stat.test_no_stim_zero,
    label = "{p.signif}",
    x = "xmax",
    remove.bracket = TRUE,
    hide.ns = TRUE,
    size = 4) +
  stat_pvalue_manual(
    stat.test_no_stim_cond,
    label = "{p.signif}",
    tip.length = 0.01,
    bracket.nudge.y = 0.8,
    hide.ns = TRUE,
    size = 3
  ) +
  theme_classic() +
  scale_y_continuous("DR", breaks = seq(-1, 1, 0.2), limits = c(-1, 1.5)) +
  scale_x_discrete("Minute", labels = 1:5) +
  scale_fill_manual(
    "Condition",
    values = c("1" = "#595959",
               "2" = "#d7dbdd",
               "3" = "#FFFFFF"),
    labels = c("1 (N = 5) ",
               "2 (N = 4)",
               "3 (N = 3)")
  ) +
  geom_hline(yintercept = 0, colour = "black", size = .1)

DR_no_stim_plot <- DR_no_stim_plot +   theme_classic(base_size = 12) +  # set global font and size
  theme(
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 12),
    legend.text = element_text(size = 12),
    legend.title = element_text(size = 12),
    strip.text = element_text(size = 12))          
DR_no_stim_plot

# --- 06. Statistics ------------------------------------------------------
# Base model and reduced/additional models (kept identical to your original approach)
basic_hlm   <- lmer(DR ~ Condition + Minute + Sampling + (1 | Animal),
                    data = Cum_DR, REML = FALSE)
rm_condition <- update(basic_hlm, . ~ . - Condition)
rm_min       <- update(basic_hlm, . ~ . - Minute)
rm_samp      <- update(basic_hlm, . ~ . - Sampling)
cond_min     <- update(basic_hlm, . ~ . + Condition:Minute)
cond_samp    <- update(basic_hlm, . ~ . + Condition:Sampling)
min_samp     <- update(basic_hlm, . ~ . + Minute:Sampling)
all_2way <- lmer(DR ~ Condition + Minute + Sampling +
                   Condition:Minute + Condition:Sampling + Minute:Sampling +
                   (1 | Animal),
                 data = Cum_DR, REML = FALSE)
complete_hlm <- lmer(DR ~ Condition * Minute * Sampling + (1 | Animal),
                     data = Cum_DR, REML = FALSE)  # explicit full interaction

# ANOVAs (same calls)
anova(rm_condition, basic_hlm) # significant 
anova(rm_min, basic_hlm) # not significant 
anova(rm_samp, basic_hlm) # significant 
anova(basic_hlm, cond_min) # not significant 
anova(basic_hlm, cond_samp) # significant 
anova(basic_hlm, min_samp) # not significant

anova(cond_samp, all_2way) # not significant 
anova(all_2way, complete_hlm) # not significant 

# --> best model fit: DR ~ Condition + Minute + Sampling + (1 | Animal) + Condition:Sampling
library(MuMIn)

# Fit your final model
final_hlm <- lmer(
  DR ~ Condition + Minute + Sampling + Condition:Sampling + (1 | Animal),
  data = Cum_DR, REML = FALSE
)

# R-squared
r.squaredGLMM(final_hlm)


# --- 07. Estimated marginal means & contrasts ----------------------------
emm <- emmeans(final_hlm, ~ Condition | Minute)
emm_df <- as.data.frame(emm)

# Get adjusted values per subject
Cum_DR$predicted <- predict(final_hlm, re.form = NULL)  # includes Animal random intercept

pairs_cond <- contrast(emm, method = "pairwise", adjust = "bonferroni") %>%
  as.data.frame()

# One-sample tests: is emmean > 0?
emm_vs0 <- emmeans(final_hlm, ~ Condition | Minute) %>%
  test(mu = 0) %>%
  as.data.frame()

# --- 08. Build stat.test for brackets -----------------------------------
stat.test <- pairs_cond %>%
  separate(contrast, into = c("group1", "group2"), sep = " - ") %>%
  mutate(
    .y. = "DR",
    Minute = factor(Minute, levels = levels(emm_df$Minute)),   # ensure identical factor
    p = p.value,
    p.signif = case_when(
      p <= 0.001 ~ "***",
      p <= 0.01  ~ "**",
      p <= 0.05  ~ "*",
      TRUE       ~ "ns"
    ),
    statistic = t.ratio,
    group1_num = match(group1, cond_levels),
    group2_num = match(group2, cond_levels),
    xmin = as.numeric(Minute) + (group1_num - (length(cond_levels) + 1) / 2) * (dodge_width / length(cond_levels)),
    xmax = as.numeric(Minute) + (group2_num - (length(cond_levels) + 1) / 2) * (dodge_width / length(cond_levels)),
    y.base = map_dbl(Minute, ~ max(emm_df$emmean[emm_df$Minute == .x] + emm_df$SE[emm_df$Minute == .x]) + 0.1)
  ) %>%
  group_by(Minute) %>%
  mutate(y.position = pmax(y.base, 1.1) + row_number() * bracket_gap) %>%
  ungroup() %>%
  select(Minute, .y., group1, group2, df, statistic, p, p.signif,
         y.position, xmin, xmax)

# Find highest raw point per Condition × Minute
ymax_df <- Cum_DR %>%
  group_by(Condition, Minute) %>%
  summarise(ymax = max(DR, na.rm = TRUE), .groups = "drop")

# Join to the emmeans table
bar.test <- emm_vs0 %>%
  left_join(ymax_df, by = c("Condition", "Minute")) %>%
  mutate(
    .y. = "DR",
    p.signif = case_when(
      p.value <= 0.001 ~ "###",
      p.value <= 0.01  ~ "##",
      p.value <= 0.05  ~ "#",
      TRUE             ~ "ns"
    ),
    group1 = Condition,
    group2 = Condition,
    
    group_num = match(Condition, cond_levels),
    x.pos = as.numeric(Minute) +
      (group_num - (length(cond_levels)+1)/2) * (dodge_width / length(cond_levels)),
    
    xmin = x.pos, xmax = x.pos,
    # now relative to highest observed dot
    y.position = ymax + 0.04
  ) %>%
  select(Minute, .y., group1, group2, df, t.ratio, p.value, p.signif,
         y.position, xmin, xmax)


# --- 09. Final plot with adjusted means + brackets -----------------------
DR_adjusted <- ggplot(emm_df, aes(x = Minute, y = emmean, fill = Condition)) +
  geom_col(position = dodge, width = dodge_width, colour = "black") +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL),
                width = 0.3, position = dodge) +
  geom_dotplot(
    data = Cum_DR, aes(x = Minute, y = predicted, fill = Condition),
    binaxis = "y", stackdir = "center", binwidth = .03,
    position = dodge, alpha = 0.5,    shape = 21,
    size = 1,
  ) +
  stat_pvalue_manual(stat.test, label = "p.signif", y.position = "y.position",
                     xmin = "xmin", xmax = "xmax",
                     tip.length = 0.01, hide.ns = TRUE, size = 1,
                     inherit.aes = FALSE) +
  stat_pvalue_manual(bar.test, label = "p.signif",
                     y.position = "y.position", x = "xmax",
                     tip.length = 0, hide.ns = TRUE,
                     size = 1, inherit.aes = FALSE) +
  theme_classic() +
  scale_y_continuous("DR (adjusted)",
                     breaks = seq(-1, 1, 0.2), limits = c(-1, 1.4)) +
  scale_x_discrete("Minute", labels = 1:5) +
  scale_fill_manual("Condition",
                    values = c("No_stim"        = "#595959",
                               "SO_up_in_phase" = "#d7dbdd",
                               "SO_delayed"     = "#FFFFFF"),
                    labels = c("No inhibition (n = 12)",
                               "Inhibition during SO peak (n = 12)",
                               "Inhibition outside SO (n = 9)")) +
  geom_hline(yintercept = 0, colour = "black", size = .1)

DR_adjusted <- DR_adjusted +   theme_classic(base_size = 7) +  # set global font and size
  theme(
    axis.title = element_text(size = 7),
    axis.text = element_text(size = 6),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    strip.text = element_text(size = 7), 
    legend.position = "none")          
DR_adjusted


DR_adjusted <- ggplot(emm_df, aes(x = Minute, y = emmean, fill = Condition)) +
  geom_col(position = dodge, width = dodge_width, colour = "black") +
  geom_errorbar(aes(ymin = lower.CL, ymax = upper.CL),
                width = 0.3, position = dodge) +
  stat_pvalue_manual(stat.test, label = "p.signif", y.position = "y.position",
                     xmin = "xmin", xmax = "xmax",
                     tip.length = 0.01, hide.ns = TRUE, size = 1,
                     inherit.aes = FALSE) +
  stat_pvalue_manual(bar.test, label = "p.signif",
                     y.position = "y.position", x = "xmax",
                     tip.length = 0, hide.ns = TRUE,
                     size = 1, inherit.aes = FALSE) +
  theme_classic() +
  scale_y_continuous("DR (estimated marginal means)",
                     breaks = seq(-0.5, 1, 0.5), limits = c(-0.5, 1.4)) +
  scale_x_discrete("Minute", labels = 1:5) +
  scale_fill_manual(    "Condition",
                        values = c("No_stim" = "#8b1e00ff",
                                   "SO_up_in_phase" = "#1f8fb4ff",
                                   "SO_delayed" = "#b9cf3aff"),
                        labels = c("NoSTIM",
                                   "IN",
                                   "OUT")) +
  geom_hline(yintercept = 0, colour = "black", size = .1)

DR_adjusted <- DR_adjusted +   theme_classic(base_size = 7) +  # set global font and size
  theme(
    axis.title = element_text(size = 7),
    axis.text = element_text(size = 6),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    strip.text = element_text(size = 7), 
    legend.position = "none")          
DR_adjusted

# Save figure 
ggsave(
  file = "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/adjusted_DR.svg",
  plot = DR_adjusted,
  width = 70,
  height = 40,
  units = "mm"
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

sampling_test_expl_time_sum = describeBy(
  test_expl_time$Total_exp_time,
  list(test_expl_time$Sampling),
  mat = TRUE,
  digits = 2
)

test_dist_sum = describeBy(
  test_dist$Cum_dist_min_5,
  list(test_dist$Condition),
  mat = TRUE,
  digits = 2
)

sampling_test_dist_sum = describeBy(
  test_dist$Cum_dist_min_5,
  list(test_dist$Sampling),
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

stat.test_expl_samp <- test_expl_time %>%
  t_test(Total_exp_time ~ Sampling) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('****', '***', '**', '*' , 'ns'))  %>%
  add_xy_position(x = "Sampling",
                  step.increase = 0)%>%
  mutate(y.position = y.position )

stat.test_dist_samp <- test_dist %>%
  t_test(Cum_dist_min_5 ~ Sampling) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('****', '***', '**', '*' , 'ns'))  %>%
  add_xy_position(x = "Sampling",
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

test_expl_samp <- ggplot(data = sampling_test_expl_time_sum, aes(x = group1, y = mean, fill = group1)) +
  geom_bar(
    stat = 'identity',
    position = dodge,
    width = .8,
    colour = "black"
  ) +
  geom_errorbar(limits, position = dodge, width = 0.3) +
  geom_point(
    data = test_expl_time,
    aes(x = Sampling, y = Total_exp_time, fill = Sampling),
    shape = 21,
    size = 1,
    alpha = 0.6
  ) +
  stat_pvalue_manual(
    stat.test_expl_samp,
    label = "{p.signif}",
    tip.length = 0.01,
    bracket.nudge.y = 0.8,
    hide.ns = TRUE,
    size = 1
  ) +
  theme_classic() +
  scale_y_continuous(name = "Exploration time (s)") +
  scale_x_discrete(name = NULL, labels = NULL) +
  scale_fill_manual(
    "Encoding trial",
    values = c(
      "1"        = "#595959",
      "2" = "#d7dbdd",
      "3"     = "#FFFFFF"
    ),
    labels = c(
      "1 (N = 12)",
      "2 (N = 12)",
      "3 (N = 9)"
    )
  )


test_dist_samp <- ggplot(data = sampling_test_dist_sum, aes(x = group1, y = mean, fill = group1)) +
  geom_bar(
    stat = 'identity',
    position = dodge,
    width = .8,
    colour = "black"
  ) +
  geom_errorbar(limits, position = dodge, width = 0.3) +
  geom_point(
    data = test_dist,
    aes(x = Sampling, y = Cum_dist_min_5, fill = Sampling),
    shape = 21,
    size = 1,
    alpha = 0.6
  ) +
  stat_pvalue_manual(
    stat.test_dist_samp,
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
    "Encoding trial",
    values = c(
      "1"        = "#595959",
      "2" = "#d7dbdd",
      "3"     = "#FFFFFF"
    ),
    labels = c(
      "1 (N = 12)",
      "2 (N = 12)",
      "3 (N = 9)"
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

test_expl_samp  <- test_expl_samp +   theme_classic(base_size = 7) +  
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

test_dist_samp  <- test_dist_samp  +   theme_classic(base_size = 7) +  
  theme(
    axis.title = element_text(size = 7),
    axis.text = element_text(size = 6),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    strip.text = element_text(size = 7), 
    legend.position = 'none') 


test_expl_cond
test_expl_samp
test_dist_cond
test_dist_samp

ggsave(
  file = "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/expl.svg",
  plot = test_expl_cond,
  width = 22,
  height = 22,
  units = "mm"
)


ggsave(
  file = "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/dist.svg",
  plot = test_dist_cond,
  width = 22,
  height = 22,
  units = "mm"
)





##

total_DR_sum = describeBy(
  test_wide$Cum_DiRa_min_5,
  list(test_wide$Condition),
  mat = TRUE,
  digits = 2
)


stat.test_zero <- test_wide %>%
  group_by(Condition) %>%
  t_test(Cum_DiRa_min_5 ~ 1, mu = 0) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('####', '###', '##', '#' ,  'ns')) %>%
  mutate(group1 = Condition) %>%
  add_xy_position(x = "Condition",
                  group = "Condition",
                  step.increase = 0) %>%
  mutate(y.position = 1.1)

stat.test_total_DR <- test_wide %>%
  t_test(Cum_DiRa_min_5 ~ Condition) %>%
  add_significance("p", cutpoints = c(0, 1e-04, 0.001, 0.01, 0.05, 1), symbols =  c('****', '***', '**', '*' , 'ns'))  %>%
  add_xy_position(x = "Condition",
                  dodge = 0.8,
                  step.increase = 0)%>%
  mutate(y.position = 0.5)

stat.test_total_DR <- stat.test_total_DR %>%
  mutate(y.position = y.position + 0.15 * (row_number() - 1)) %>%
  ungroup()


total_DR_plot <- ggplot(data = total_DR_sum, aes(x = group1, y = mean, fill = group1)) +
  geom_bar(
    stat = 'identity',
    position = dodge,
    width = .8,
    colour = "black"
  ) +
  geom_errorbar(limits, position = dodge, width = 0.3) +
  geom_point(
    data = test_wide,
    aes(x = Condition, y = Cum_DiRa_min_5, fill =  Condition),
    shape = 21,
    size = 1,
    alpha = 0.6
  ) +
  stat_pvalue_manual(
    stat.test_zero,
    label = "{p.signif}",
    x = "xmin",
    remove.bracket = TRUE,
    hide.ns = TRUE,
    size = 1) +
  stat_pvalue_manual(
    stat.test_total_DR,
    label = "{p.signif}",
    tip.length = 0.01,
    bracket.nudge.y = 0.8,
    hide.ns = TRUE,
    size = 1
  ) +
  theme_classic() +
  scale_x_discrete(name = NULL, labels = NULL) +
  scale_y_continuous("Discrimination ratio", breaks = seq(-1, 1, 0.5), limits = c(-1, 2)) +
  scale_fill_manual(
    "Condition",
    values = c("No_stim" = "#595959",
               "SO_up_in_phase" = "#d7dbdd",
               "SO_delayed" = "#FFFFFF"),
    labels = c("No inhibition (n = 12)",
               "In phase inhibition (n = 12)",
               "Delayed inhibition (n = 9)")
  ) +
  geom_hline(yintercept = 0, colour = "black", size = .1)



total_DR_plot

total_DR_plot  <- total_DR_plot  +   theme_classic(base_size = 7) +  
  theme(
    axis.title = element_text(size = 7),
    axis.text = element_text(size = 6),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    strip.text = element_text(size = 7), 
    legend.position = 'none') 


total_DR_plot

ggsave(
  file = "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/total_DR.svg",
  plot = total_DR_plot,
  width = 42,
  height = 60,
  units = "mm"
)
