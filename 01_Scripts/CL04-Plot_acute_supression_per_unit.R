# Plot spiking rate comparison 
# last modified: January 2026
# maximilian.harkotte@gmail.com

rm(list = ls()) ; cat("\014")

# --- 00. Load packages ---------------------------------------------------
library(ggplot2)
library(gridExtra)
library(dplyr)

# --- parameters ---------------------------------------------------------
dataPath   <- "Z:/Max/01_SysCons_optogenetics/00_Closed_Loop_Inhibition_CA1py/"

# --- 01. Paths -----------------------------------------------------------
setwd(dataPath)

# --- 02. Import & clean --------------------------------------------------
acute_1 <- read.csv2(
  "03_Analysis/03_Data/04_Acute_units/Acute_supression_1.csv",
  header = TRUE, sep = ",", stringsAsFactors = FALSE
)

acute_2 <- read.csv2(
  "03_Analysis/03_Data/04_Acute_units/Acute_supression_3.csv",
  header = TRUE, sep = ",", stringsAsFactors = FALSE
)

acute_3 <- read.csv2(
  "03_Analysis/03_Data/04_Acute_units/Acute_supression_4.csv",
  header = TRUE, sep = ",", stringsAsFactors = FALSE
)

acute_all = rbind(acute_1, acute_2, acute_3)

acute_all$Baseline_rate = as.numeric(acute_all$Baseline_rate)
acute_all$Inhibitin_rate= as.numeric(acute_all$Inhibitin_rate)
acute_all$Supression_index = as.numeric(acute_all$Supression_index)

# Panel 1: Pie chart
# Categorize units based on Supression_index
acute_all_categorized <- acute_all %>%
  mutate(category = case_when(
    Supression_index < -0.2 ~ "Inhibited",
    Supression_index > 0.2 ~ "Increased firing",
    TRUE ~ "Unaltered"
  ))

# Count units in each category
category_counts <- acute_all_categorized %>%
  group_by(category) %>%
  summarise(count = n()) %>%
  mutate(percentage = count / sum(count) * 100,
         label = paste0(category, "\n", count, " (", round(percentage, 1), "%)"))

# Create pie chart
pie_plot <- ggplot(category_counts, aes(x = "", y = count, fill = category)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y", start = 0) +
  scale_fill_manual(values = c("Inhibited" = "#4169e1ff", 
                               "Unaltered" = "#ff8c00ff", 
                               "Increased firing" = "#3498DB")) +
  geom_text(aes(label = label), 
            position = position_stack(vjust = 0.5), 
            size = 5 / .pt) +  
  theme_void() +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 5 / .pt)) 

# Panel 2: Bar plot with Wilcoxon test
# Prepare data for bar plot
firing_rates <- data.frame(
  condition = c("Baseline", "Inhibition"),
  mean_rate = c(mean(acute_all$Baseline_rate, na.rm = TRUE), 
                mean(acute_all$Inhibitin_rate, na.rm = TRUE)),
  se = c(sd(acute_all$Baseline_rate, na.rm = TRUE) / sqrt(sum(!is.na(acute_all$Baseline_rate))),
         sd(acute_all$Inhibitin_rate, na.rm = TRUE) / sqrt(sum(!is.na(acute_all$Inhibitin_rate))))
)

# Perform Wilcoxon signed-rank test
wilcox_result <- wilcox.test(acute_all$Baseline_rate, acute_all$Inhibitin_rate, paired = TRUE)

# Create significance label
if (wilcox_result$p.value < 0.001) {
  sig_label <- "***"
} else if (wilcox_result$p.value < 0.01) {
  sig_label <- "**"
} else if (wilcox_result$p.value < 0.05) {
  sig_label <- "*"
} else {
  sig_label <- "ns"
}

# Create bar plot
bar_plot <- ggplot(firing_rates, aes(x = condition, y = mean_rate, fill = condition)) +
  geom_bar(stat = "identity", width = 0.6, alpha = 0.8, 
           color = "black", size = 0.3)  +
  geom_errorbar(aes(ymin = mean_rate - se, ymax = mean_rate + se), 
                width = 0.2, size = 0.3) +
  scale_fill_manual(values = c("Baseline" = "#d7dbdd", "Inhibition" = "#d7dbdd")) +
  labs(y = "Firing Rate (Hz)", x = "") +
  theme_classic() +
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5, size = 7 / .pt, face = "bold"),
        axis.text.x = element_text(size = 7 / .pt),
        axis.text.y = element_text(size = 7 / .pt),
        axis.title.y = element_text(size = 7 / .pt),
        axis.line = element_line(size = 0.3)) +
  # Add significance bar
  annotate("segment", x = 1, xend = 2, 
           y = max(firing_rates$mean_rate + firing_rates$se) * 1.1,
           yend = max(firing_rates$mean_rate + firing_rates$se) * 1.1,
           size = 0.3) +
  annotate("segment", x = 1, xend = 1, 
           y = max(firing_rates$mean_rate + firing_rates$se) * 1.1,
           yend = max(firing_rates$mean_rate + firing_rates$se) * 1.08,
           size = 0.3) +
  annotate("segment", x = 2, xend = 2, 
           y = max(firing_rates$mean_rate + firing_rates$se) * 1.1,
           yend = max(firing_rates$mean_rate + firing_rates$se) * 1.08,
           size = 0.3) +
  annotate("text", x = 1.5, y = max(firing_rates$mean_rate + firing_rates$se) * 1.15,
           label = sig_label, size = 7 / .pt) +  # Changed from size = 6
  ylim(0, max(firing_rates$mean_rate + firing_rates$se) * 1.2)

# Combine both panels
combined_plot <- grid.arrange(bar_plot, pie_plot, nrow = 2, heights = c(1.7, 1.3))
# Print p-value
cat("Wilcoxon signed-rank test p-value:", wilcox_result$p.value, "\n")

# Save the plot 
ggsave("two_panel_figure.svg", combined_plot, width = 1.2, height = 2)

