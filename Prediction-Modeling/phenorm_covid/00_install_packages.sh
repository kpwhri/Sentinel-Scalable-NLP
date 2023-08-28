#!/bin/bash

# Install required packages ----------------------------------------------------

# project-specific setup
source phenorm_covid/00_covid19_phenorm_setup.sh

# install packages
Rscript phenorm_covid/00_install_packages.R > "${io_dir}/00_install_packages.out" 2>&1
