# Smith Lab Grant Submission Code

This repository houses organized grant submission materials and code for the Smith Lab research projects.

Participant-level source and analytic data are maintained in approved private
storage and are not committed here. Project `sourcedata/README.md` files describe
how private inputs are supplied to the preserved analysis code.

## Repository Structure

The repository follows a standardized directory structure to maintain organization and consistency across all grant submissions:

```
grant-submissions/
├── README.md
├── 2025_R21-ABCD-IntExt/
│   ├── README.md
│   ├── first-submission/
│   │   ├── code/
│   |       └── README.md
│   │   ├── derivatives/
│   |       └── README.md
│   |       └── figures
│   │   └── sourcedata/
│   │       └── README.md
│   ├── second-submission/
│   │   ├── code/
│   |        └── README.md
│   │   ├── derivatives/
│   |        └── README.md
│   |       └── figures
│   │   └── sourcedata/
│   │       └── README.md
│   └── third-submission/
│       ├── code/
│           └── README.md
│       ├── derivatives/
│           └── README.md
│           └── figures
│       └── sourcedata/
│           └── README.md
```

## Naming Conventions

### Grant Folder Names
Format: `YYYY_GrantType-ProjectDataSource-Theme`

**Example:** `2025_R21-ABCD-IntExt`
- `YYYY`: Year of submission
- `GrantType`: Type of grant (R21, R01, K01, etc.)
- `ProjectDataSource`: Primary data source or study
- `Theme`: Brief descriptor of the research focus

### Submission Folder Names
Format: `[sequence]-submission`

Submissions are numbered sequentially:
- `first-submission/`
- `second-submission/`
- `third-submission/`
- etc.

## Directory Contents

### Root Level (`grant-submissions/`)
- Main repository README (this file)
- Individual grant folders

### Grant Level (`YYYY_GrantType-ProjectDataSource-Theme/`)
- Grant-specific README with project details
- Submission folders for each version/attempt

### Submission Level (`[sequence]-submission/`)
Each submission contains three standardized folders:

- **`code/`**: Analysis scripts, preprocessing pipelines, and/or computational methods
- **`derivatives/`**: Processed data, results, figures, and output files
- **`sourcedata/`**: Raw data files and original materials
  - Contains its own README with data descriptions and metadata

## Current Projects

### 2025_R03-SDOH
Public files are limited to code, documentation, and aggregate outputs reviewed
for absence of participant identifiers. See the project privacy protections and
release guidance.

### 2025_R21-ABCD-IntExt
**Environmental and Neural Drivers of Internalizing and Externalizing Behaviors in Adolescents**
- Grant Type: R21
- Grant Number: R21-MH##### (to be updated)
- Status: In preparation

## Getting Started

1. Navigate to the relevant grant folder
2. Check the grant-level README for project-specific information
3. Review submission folders in chronological order
4. Refer to `sourcedata/README.md` for data documentation

## Contribution Guidelines

When adding new submissions:
1. Follow the established naming conventions
2. Include all three required subdirectories (`code/`, `derivatives/`, `sourcedata/`)
3. Add a README to the `sourcedata/` and `derivatives/` folders with appropriate metadata
4. Update the grant-level README if needed
