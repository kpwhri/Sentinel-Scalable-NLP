#!/usr/local/bin/Rscript

# install necessary packages for the COVID PheNorm analysis

package_list <- c("optparse", "here", "PheNorm", "ROCR", "WeightedROC", "tidyverse", "cowplot")
install.packages(package_list, repos = "https://cran.rstudio.com")
