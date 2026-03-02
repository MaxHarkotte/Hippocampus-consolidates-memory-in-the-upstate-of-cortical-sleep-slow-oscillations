Cum_DR <- subset(Cum_DR, Cum_DR$Minute == "Cum_DiRa_min_5")

ctrl_hlm <- lmer(
  DR ~ Condition + Sampling + (1 | Animal),
  data = Cum_DR, REML = FALSE
)

emm_ctrl <- emmeans(ctrl_hlm, ~ Condition, weights = "equal")
emm_ctrl_df <- as.data.frame(emm_ctrl)

emm_vs0 <- test(
  emm_ctrl,
  mu = 0,
) %>%
  as.data.frame() %>%
  mutate(
    p.signif = case_when(
      p.value <= 0.001 ~ "###",
      p.value <= 0.01  ~ "##",
      p.value <= 0.05  ~ "#",
      TRUE             ~ "ns"
    )
  )%>%
  mutate(y.position = 1.1)

pairs_cond <- pairs(
  emm_ctrl,
) %>%
  as.data.frame() %>%
  separate(contrast, into = c("group1", "group2"), sep = " - ") %>%
  mutate(
    p.signif = case_when(
      p.value <= 0.001 ~ "***",
      p.value <= 0.01  ~ "**",
      p.value <= 0.05  ~ "*",
      TRUE             ~ "ns"
    )
  )

vs0_plot <- emm_ctrl_df %>%
  left_join(emm_vs0, by = "Condition") %>%
  mutate(
    x = as.numeric(factor(Condition, levels = levels(Condition))),
    y.position = upper.CL + 0.05
  )%>%
  mutate(y.position = 0.8)

cond_levels <- levels(emm_ctrl_df$Condition)

pairs_plot <- pairs_cond %>%
  mutate(
    xmin = match(group1, cond_levels),
    xmax = match(group2, cond_levels),
    y.position =
      max(emm_ctrl_df$upper.CL) + 0.1 +
      row_number() * 0.05
  )%>%
  mutate(y.position = 1)

pairs_plot <- pairs_plot %>%
  mutate(y.position = y.position + 0.15 * (row_number() - 1)) %>%
  ungroup()



DR_adjusted <- ggplot(emm_ctrl_df,
       aes(x = Condition, y = emmean, fill = Condition)) +
  
  geom_col(width = 0.7, colour = "black") +
  
  geom_errorbar(
    aes(
      ymin = emmean - SE,
      ymax = emmean + SE
    ),
    width = 0.25
  ) +
  
  # ---- vs-zero significance ----
geom_text(
  data = vs0_plot,
  aes(x = Condition, y = y.position, label = p.signif),
  vjust = 0, size = 1,
  inherit.aes = FALSE
) +
  
  # ---- between-condition brackets ----
stat_pvalue_manual(
  pairs_plot,
  label = "p.signif",
  xmin = "xmin",
  xmax = "xmax",
  y.position = "y.position",
  tip.length = 0.01,
  hide.ns = TRUE,
  size = 1,
  inherit.aes = FALSE   # 👈 THIS is the key
)+
  
  geom_hline(yintercept = 0, linewidth = 0.2) +
  
  scale_y_continuous("DR (estimated marginal mean)", breaks = seq(-0.5, 0.7, 0.2), limits = c(-0.5, 1.4)) +
  
  scale_fill_manual(
    "Condition",
    values = c(
      "No_stim"        = "#8b1e00ff",
      "SO_up_in_phase" = "#1f8fb4ff",
      "SO_delayed"     = "#b9cf3aff"
    )
  ) +
  
  theme_classic()


DR_adjusted <- DR_adjusted  +   theme_classic(base_size = 7) +  
  theme(
    axis.title = element_text(size = 7),
    axis.text = element_text(size = 6),
    legend.text = element_text(size = 7),
    legend.title = element_text(size = 7),
    strip.text = element_text(size = 7), 
    legend.position = 'none') 


DR_adjusted

ggsave(
  file = "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/04_Manuscript/01_Figures/total_DR_mmeans.svg",
  plot = DR_adjusted,
  width = 42,
  height = 60,
  units = "mm"
)

