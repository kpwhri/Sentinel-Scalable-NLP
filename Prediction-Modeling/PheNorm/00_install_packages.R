#!/usr/local/bin/Rscript

# install necessary packages for the COVID PheNorm analysis

package_list <- c("optparse", "here", "PheNorm", "ROCR", "WeightedROC", "cvAUC", "vimp")
tidy_package_list <- c("ggplot2", "dplyr", "tidyr", "readr", "stringr", "purrr", "cowplot", "haven")
# check to make sure each package is installed; if not, install it
lapply(as.list(c(package_list, tidy_package_list)), function(package) {
  is_package_avail <- require(package, character.only = TRUE)
  if (!is_package_avail) {
    install.packages(package, repos = "https://cran.rstudio.com", INSTALL_opts = "--no-lock")
  }
})

