library(dplyr)
library(ggplot2)
library(tidyr)

# Load data
data <- read.csv("/abcdinput-pivot.csv")

# Step 1: Keep only top and bottom 33% for ADI
data <- data %>%
  filter(!is.na(adi_ptile)) %>%
  mutate(
    adi_level = case_when(
      adi_ptile <= 33 ~ 0,
      adi_ptile >= 67 ~ 1,
      TRUE ~ NA_real_
    )
  ) %>%
  filter(!is.na(adi_level))

# Step 2: Prepare data for intern_four
intern_data <- data %>%
  filter(
    !is.na(intern_four),
    !is.na(latent_factor_ss_social)
  ) %>%
  mutate(
    adi_level = factor(adi_level, labels = c("Low ADI", "High ADI")),
    soc_low = quantile(latent_factor_ss_social, 0.33, na.rm = TRUE),
    soc_high = quantile(latent_factor_ss_social, 0.67, na.rm = TRUE),
    soc_group = case_when(
      latent_factor_ss_social <= soc_low ~ "Low",
      latent_factor_ss_social >= soc_high ~ "High",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(soc_group)) %>%
  mutate(soc_group = factor(soc_group, levels = c("Low", "High")))

# Step 3: Summary statistics
intern_summary <- intern_data %>%
  group_by(adi_level, soc_group) %>%
  summarise(
    n = n(),
    mean = mean(intern_four, na.rm = TRUE),
    sd = sd(intern_four, na.rm = TRUE),
    se = sd / sqrt(n),
    .groups = "drop"
  )
print(intern_summary)

# Step 4: Plot
p <- ggplot(intern_summary, aes(x = adi_level, y = mean, fill = soc_group)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.7) +
  geom_errorbar(
    aes(ymin = mean - se, ymax = mean + se),
    position = position_dodge(width = 0.7), width = 0.2
  ) +
  labs(
    title = "",
    x = "\nNeighborhood Disadvantage (ADI)",
    y = "Internalizing Symptoms (Year 4)",
    fill = "Latent Factor Social Support"
  ) +
  scale_fill_manual(values = c("Low" = "mistyrose3", "High" = "lightblue4")) +
  theme_minimal(base_size = 16) +
  theme(
    legend.position = "top",
    plot.title = element_text(hjust = 0.5, size = 24, face = "bold"),
    axis.text = element_text(size = 20)
  ) +
  coord_cartesian(ylim = c(30, NA))

print(p)
