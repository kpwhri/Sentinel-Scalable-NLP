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
parser <- add_option(parser, "--data-dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/",
                     help = "The input data directory")
parser <- add_option(parser, "--output-dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/results/",
                     help = "The output directory")
parser <- add_option(parser, "--analysis",
                     default = "phase_1_updated_symptomatic_covid_all_mentions",
                     help = "The name of the analysis")
parser <- add_option(parser, "--seed", type = "integer", default = 4747,
                     help = "The random number seed to use")
parser <- add_option(parser, "--utilization", default = "Utiliz", 
                     help = "The utilization variable")
parser <- add_option(parser, "--weight", default = "weight", 
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
# note that "silver" is required to be in the variable name for all silver labels
data_names <- names(analysis_data$train)
silver_labels <- data_names[grepl("silver", data_names, ignore.case = TRUE)]
# run PheNorm on training data, predict on test data --------------------------
phenorm_analysis <- run_phenorm(
  train = analysis_data$train, test = analysis_data$test,
  silver_labels = silver_labels, aggregate_labels = silver_labels,
  features = names(analysis_data$train %>% 
                    select(-!!c(silver_labels, args$utilization, args$weight))), 
  utilization = args$utilization, seed = args$seed, 
  weight = args$weight, corrupt.rate = args$corrupt_rate, 
  train.size = args$train_size_multiplier * nrow(analysis_data$train)
)
saveRDS(
  phenorm_analysis, file = paste0(
    fit_output_dir, args$analysis, "_", args$site, "_phenorm_output.rds"
  )
)
print("PheNorm modeling complete.")