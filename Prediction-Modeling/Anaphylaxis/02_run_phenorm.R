#!/usr/local/bin/Rscript

# Run PheNorm on the training data, get predictions on the test data

# required packages and functions ---------------------------------------------
library("optparse")
library("dplyr")
library("readr")
library("stringr")
library("PheNorm")
library("here")

here::i_am("README.md")

source(here::here("00_utils.R"))
# set up command-line args ----------------------------------------------------
parser <- OptionParser()
parser <- add_option(parser, "--data-dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets_negation_0_normalization_0_dimension-reduction_0_train-on-gold_0/",
                     help = "The input data directory")
parser <- add_option(parser, "--output-dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/results_negation_0_normalization_0_dimension-reduction_0_train-on-gold_0/",
                     help = "The output directory")
parser <- add_option(parser, "--analysis",
                     default = "phase_1_updated_symptomatic_covid",
                     help = "The name of the analysis")
parser <- add_option(parser, "--seed", type = "integer", default = 4747,
                     help = "The random number seed to use")
parser <- add_option(parser, "--utilization", default = "Utiliz", 
                     help = "The utilization variable")
parser <- add_option(parser, "--weight", default = "Sampling_Weight", 
                     help = "Inverse probability of selection into gold-standard set")
parser <- add_option(parser, "--corrupt-rate", type = "double", default = 0.3,
                     help = "The 'corruption rate' for PheNorm 'denoising'")
parser <- add_option(parser, "--train-size-multiplier", type = "integer", default = 13,
                     help = "The multiplier to use for inflating training set size")
parser <- add_option(parser, "--site", default = "kpwa", help = "The site at which the model is being developed")                     
args <- parse_args(parser, convert_hyphens_to_underscores = TRUE)

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
silver_labels <- analysis_data$silver_labels
# run PheNorm on training data, predict on test data --------------------------
set.seed(args$seed)
phenorm_analysis <- run_phenorm(
  data = analysis_data$data,
  train_ids = analysis_data$train_ids, test_ids = analysis_data$test_ids,
  silver_labels = silver_labels, aggregate_labels = silver_labels,
  features = names(analysis_data$data %>% 
                    select(-!!c(silver_labels, args$utilization, args$weight))), 
  utilization = args$utilization, weight = args$weight, corrupt.rate = args$corrupt_rate, 
  train.size = max(args$train_size_multiplier * nrow(analysis_data$train), 1e5)
)
saveRDS(
  phenorm_analysis, file = paste0(
    fit_output_dir, args$analysis, "_", args$site, "_phenorm_output.rds"
  )
)
print("PheNorm modeling complete.")