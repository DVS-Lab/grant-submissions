library(dplyr)
library(ggplot2)
library(tidyr)
library(purrr)

# Load data
data <- read.csv("/abcdinput-pivot.csv")

# Figure 2 Statistics -- reported in section _____ as (t = XX, p = XX)
model_figure_two <- lm(intern_four ~ adi_ptile * latent_factor_ss_social, data = data)
summary(model_figure_two)

# Figure 3 Statistics -- reported in section _____ as (t = XX, p = XX)
model_figure_three <- lm(rpvnf_aa_two ~ adi_ptile * cohesion_two * intern_four * sex, data = data)
summary(model_figure_three)
