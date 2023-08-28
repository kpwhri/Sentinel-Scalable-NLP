#!/bin/bash

# install required packages (only need to run this one time)
source 00_install_packages.sh 

# setup
source 00_setup.sh

# process datasets
source 01_process_datasets.sh

# run internal model training and evaluation
source 02_run_phenorm_internal.sh

# run external model evaluation
source 03_run_phenorm_external.sh