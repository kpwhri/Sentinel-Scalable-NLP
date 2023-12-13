#!/bin/bash

# install required packages (only need to run this one time)
source COVID/00_install_packages.sh 

# preprocess datasets (uses analysis-specific code); wouldn't need this if input
# data met the requirements for downstream code, namely, that:
# 1. input data for an analysis consist of only the relevant variables for that analysis (studyid, outcome, train/eval set designation, utilization (if any), weight (if any), silver labels, structured data features, NLP features)
# 2. all data are of the correct format (e.g., for binary variables, 0/1 [not characters])
# only have to run this code one time per combination of (outcome, silver labels, all possible structured data features, NLP features)
source COVID/00_preprocess_covid19_datasets.sh

# Re-run these when you make changes in 00_covid19_phenorm_setup.sh

# process datasets
source COVID/01_process_datasets.sh

# run internal model training and evaluation
source COVID/02_run_phenorm_internal.sh

# run external model evaluation
source COVID/03_run_phenorm_external.sh