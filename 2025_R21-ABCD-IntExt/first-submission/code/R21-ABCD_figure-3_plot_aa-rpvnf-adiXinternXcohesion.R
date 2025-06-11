library(dplyr)
library(ggplot2)

# Load data
data <- read.csv("/abcdinput-pivot.csv")

# Choose the brain variable to plot
varname <- "rpvnf_aa_two"

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

# Step 2: Prepare data by filtering complete cases and creating social support + internalizing group
data_clean <- data %>%
  filter(
    !is.na(.data[[varname]]),
    !is.na(cohesion_two),
    !is.na(intern_four)
  ) %>%
  mutate(
    adi_level = factor(adi_level, labels = c("Low ADI", "High ADI")),
    soc_low = quantile(cohesion_two, 0.33, na.rm = TRUE),
    soc_high = quantile(cohesion_two, 0.67, na.rm = TRUE),
    soc_group = case_when(
      cohesion_two <= soc_low ~ "Low",
      cohesion_two >= soc_high ~ "High",
      TRUE ~ NA_character_
    ),
    intern_median = median(intern_four, na.rm = TRUE),
    intern_group = if_else(intern_four <= intern_median, "Low", "High")
  ) %>%
  filter(!is.na(soc_group)) %>%
  mutate(
    soc_group = factor(soc_group, levels = c("Low", "High")),
    intern_group = factor(intern_group, levels = c("Low", "High"))
  )

# Step 3: Compute group means and standard errors
plot_data <- data_clean %>%
  group_by(adi_level, intern_group, soc_group) %>%
  summarize(
    mean_value = mean(.data[[varname]], na.rm = TRUE),
    se = sd(.data[[varname]], na.rm = TRUE) / sqrt(n()),
    .groups = "drop"
  )

# Step 4: Plot
ggplot(plot_data, aes(x = adi_level, y = mean_value, fill = soc_group)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.9)) +
  geom_errorbar(
    aes(ymin = mean_value - se, ymax = mean_value + se),
    position = position_dodge(width = 0.9),
    width = 0.2
  ) +
  facet_wrap(~ intern_group) +
  scale_fill_manual(
    values = c("Low" = "mistyrose3", "High" = "lightblue4")
  ) +
  labs(
    title = paste(),
    x = "ADI",
    y = paste("Mean", varname),
    fill = "Social Support"
  ) +
  theme_minimal(base_size = 14)
