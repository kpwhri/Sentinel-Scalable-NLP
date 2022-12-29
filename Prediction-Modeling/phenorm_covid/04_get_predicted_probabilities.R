#!/usr/local/bin/Rscript

# Obtain predicted probabilities on the entire dataset (training and testing)

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
                     default = "phase_1_enhanced_symptomatic_covid_all_mentions", help = "The name of the analysis")
parser <- add_option(parser, "--data_site", default = "kpwa", help = "The site the data to evaluate on came from")
parser <- add_option(parser, "--model_site", default = "kpwa", help = "The site the where the model was trained")                     
parser <- add_option(parser, "--study_id", default = "Studyid", help = "The study id variable")
args <- parse_args(parser)
source(here::here("phenorm_covid", "phenorm_covid_setup.R"))

fit_output_dir <- paste0(args$output_dir, "fits/")
# load in data and fitted PheNorm object ---------------------------------------
analysis_data <- readRDS(
  file = paste0(
    args$data_dir, args$analysis, "_", args$data_site, "_analysis_data.rds"
  )
)
all_data <- analysis_data$all
id_var <- which(grepl(args$study_id, names(all_data), ignore.case = TRUE))
all_minus_id <- all_data[, -id_var]
phenorm_analysis <- readRDS(
  file = paste0(
    fit_output_dir, args$analysis, "_", args$model_site, "_phenorm_output.rds"
  )
)
fit <- phenorm_analysis$fit

# make predictions on entire dataset -------------------------------------------
# get features used to train PheNorm model
model_fit_names <- gsub("SX.norm.corrupt", "", rownames(fit$betas))
model_features <- model_fit_names[!(model_fit_names %in% c(silver_labels, utilization_variable))]
set.seed(1234)
preds <- predict.PheNorm(
  phenorm_model = fit, newdata = all_minus_id, silver_labels = silver_labels,
  features = model_features,
  utilization = utilization_variable, aggregate_labels = silver_labels
)
names(preds) <- paste0("pred_prob_", names(preds))
pred_dataset <- cbind.data.frame(all_data[[id_var]], preds)
names(pred_dataset)[1] <- names(all_data)[id_var]
readr::write_csv(
  pred_dataset, file = paste0(
    fit_output_dir, args$analysis, "_", args$data_site, 
    "_phenorm_all_predicted_probabilities_using_", args$model_site, "_model.csv"
  )
)