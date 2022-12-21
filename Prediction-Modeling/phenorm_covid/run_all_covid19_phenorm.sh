#!/bin/bash

# install required packages (only need to run this one time)
source phenorm_covid/00_install_packages.sh 

# process datasets
source phenorm_covid/01_process_covid19_datasets.sh

# run internal model training and evaluation
source phenorm_covid/02_run_covid19_phenorm_internal.sh

# run external model evaluation
source phenorm_covid/03_run_covid19_phenorm_external.sh