# Code Directory

This directory contains scripts for analyzing environmental and neural drivers of internalizing and externalizing behaviors in adolescents using ABCD Study data.

## Scripts Overview

### 1. `R21-ABCD_figure-2_behavior-adiXinternXcohesion.R`
**Purpose:** Generates visualization and analysis for the relationship between neighborhood disadvantage (ADI), social support, and internalizing symptoms.

**Key Features:**
- Filters data to extreme ADI groups (top and bottom 33%)
- Creates social support groups based on latent factor social support tertiles
- Generates bar plot with error bars showing mean internalizing symptoms by ADI level and social support group
- Produces summary statistics (n, mean, SD, SE) by group

**Output:** Figure showing internalizing symptoms (Year 4) by neighborhood disadvantage and social support levels

### 2. `R21-ABCD_figure-3_plot_aa-rpvnf-adiXinternXcohesion.R`
**Purpose:** Examines brain imaging measures across multiple grouping variables including ADI, social support, and internalizing symptoms.

**Key Features:**
- Configurable brain variable analysis (currently set to `rpvnf_aa_two`)
- Creates extreme ADI groups (top and bottom 33%)
- Generates social support groups using cohesion measure tertiles
- Creates internalizing symptom groups using median split
- Produces faceted bar plot showing brain measures across all grouping combinations

**Output:** Faceted figure displaying brain imaging measures by ADI, social support, and internalizing symptom groups

### 3. `R21-ABCD_reported-statistics.R`
**Purpose:** Performs statistical modeling for manuscript figures and generates reportable statistics.

**Key Models:**
- **Figure 2 Model:** Tests interaction between ADI percentile and latent factor social support predicting internalizing symptoms
- **Figure 3 Model:** Complex 4-way interaction model examining brain measures (rpvnf_aa_two) predicted by ADI, cohesion, internalizing symptoms, and sex

**Output:** Statistical summaries for manuscript reporting (t-values, p-values)

## Data Requirements

All scripts expect an input file named `abcdinput-pivot.csv` located in the root directory (`/abcdinput-pivot.csv`).

### Required Variables:
- `adi_ptile`: Area Deprivation Index percentile
- `intern_four`: Internalizing symptoms at Year 4
- `latent_factor_ss_social`: Latent factor for social support
- `cohesion_two`: Social cohesion measure at Year 2
- `rpvnf_aa_two`: Brain imaging measure (right posterior ventral nucleus accumbens area)
- `sex`: Participant sex

## Dependencies

The following R packages are required:
```r
library(dplyr)    # Data manipulation
library(ggplot2)  # Data visualization
library(tidyr)    # Data tidying
library(purrr)    # Functional programming tools
```

## Analysis Approach

### Grouping Strategy:
- **ADI Groups:** Extreme groups approach using top and bottom 33% of ADI distribution
- **Social Support Groups:** Tertile split (top and bottom 33%) of social support measures
- **Internalizing Groups:** Median split for brain imaging analyses

### Visualization Theme:
- Consistent color scheme: Low groups (mistyrose3), High groups (lightblue4)
- Error bars represent standard error of the mean
- Minimal theme with increased font sizes for publication quality

## Usage Notes

1. **Script Order:** Scripts can be run independently but are numbered for logical progression
2. **Variable Modification:** Brain variable in script 2 can be changed by modifying the `varname` variable
3. **Statistical Reporting:** Script 3 provides statistical model summaries

## Output Files

Scripts generate plots directly to the R graphics device. To save figures, add appropriate `ggsave()` commands to each script.