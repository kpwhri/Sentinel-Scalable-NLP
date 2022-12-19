#!/usr/local/bin/Rscript

# Run PheNorm on the training data, get predictions on the test data

# required packages and functions ---------------------------------------------
library("optparse")
library("tidyverse")
library("PheNorm")
library("here")

here::i_am("phenorm_covid/README.md")

source(here::here("phenorm_covid", "phenorm_utils.R"))
# set up command-line args ----------------------------------------------------
parser <- OptionParser()
parser <- add_option(parser, "--data_dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/",
                     help = "The input data directory")
parser <- add_option(parser, "--output_dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/results/",
                     help = "The output directory")
parser <- add_option(parser, "--analysis",
                     default = "phase_1_enhanced_symptomatic_covid_all_mentions",
                     help = "The name of the analysis")
parser <- add_option(parser, "--site", default = "kpwa", help = "The site at which the model is being developed")                     
args <- parse_args(parser)
source(here::here("phenorm_covid", "phenorm_covid_setup.R"))

# generate all necessary random number seeds (2 * n_analyses)
set.seed(4747)
seeds <- round(runif(2 * n_analyses, 1e4, 1e5))
bool <- args$analysis == analysis_names
these_seeds <- seeds[c(which(bool), n_analyses + which(bool))]

fit_output_dir <- paste0(args$output_dir, "fits/")
if (!dir.exists(fit_output_dir)) {
  dir.create(fit_output_dir, recursive = TRUE)
  txt_for_readme <- "# PheNorm output\n\nThis folder contains `R` objects (`.rds` files) holding PheNorm fits. These can be loaded in to make predictions on internal or external data."
  writeLines(txt_for_readme, con = paste0(fit_output_dir, "README.md"))
}
analysis_data <- readRDS(
  file = paste0(
    args$data_dir, args$analysis, "_", args$site, "_analysis_data.rds"
  )
)

# run PheNorm on training data, predict on test data --------------------------
phenorm_analysis <- run_phenorm(
  train = analysis_data$train, test = analysis_data$test,
  silver_labels = silver_labels, aggregate_labels = silver_labels,
  features = names(analysis_data$train %>% 
                    select(-!!c(silver_labels, utilization_variable))), 
  utilization = utilization_variable, seeds = these_seeds, 
  corrupt.rate = corrupt_rate, 
  train.size = train_size_multiplier * nrow(analysis_data$train)
)
saveRDS(
  phenorm_analysis, file = paste0(
    fit_output_dir, args$analysis, "_", args$site, "_phenorm_output.rds"
  )
)
print("PheNorm modeling complete.")