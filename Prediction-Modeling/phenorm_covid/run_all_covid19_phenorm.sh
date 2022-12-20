#!/bin/bash

# install required packages (only need to run this one time)
source phenorm_covid/install_packages.sh 

# process datasets
source phenorm_covid/process_covid19_datasets.sh

# run internal model training and evaluation
source phenorm_covid/run_covid19_phenorm_internal.sh

# run external model evaluation
source phenorm_covid/run_covid19_phenorm_external.sh