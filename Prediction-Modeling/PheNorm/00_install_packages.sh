#!/usr/bin/env bash

# Install required packages ----------------------------------------------------

# install packages
Rscript 00_install_packages.R > "./${io_dir}/00_install_packages.out" 2>&1
