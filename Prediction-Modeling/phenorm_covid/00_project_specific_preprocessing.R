# this file is specific to the COVID-19 analysis
# reads in the "raw" dataset, and creates a preliminary analytic dataset.
# important things to do here, for use in the downstream automated code:
#   (1) define outcome, features of interest (one dataset per outcome and feature set)
#   (2) recode any variables that need recoding (e.g., if they are characters and need to be binary)
# this file is run *prior* to processing data for PheNorm (making train/test datasets, etc.)

library("optparse")
library("tidyverse")
library("here")

here::i_am("phenorm_covid/README.md")

source(here::here("phenorm_covid", "phenorm_utils.R"))
parser <- OptionParser()
parser <- add_option(parser, "--data-dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PROGRAMMING/SAS Datasets/Replicate VUMC Analysis/Sampling for Chart Review/Phenorm Symptomatic Covid-19 update/",
                     help = "The input data directory")
parser <- add_option(parser, "--analysis-data-dir", 
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/",
                     help = "The analysis data directory")                     
parser <- add_option(parser, "--data-name",
                     default = "COVID_PheNorm_N8329_12DEC2022.csv", 
                     help = "The name of the dataset")
parser <- add_option(parser, "--analysis",
                     default = "phase_1_updated_symptomatic_covid_all_mentions", 
                     help = "The name of the analysis")
parser <- add_option(parser, "--gold-label", default = "PTYPE_SYMPTOMATIC_POSITIVE", 
                     help = "The name of the gold label")
parser <- add_option(parser, "--valid-label", default = "Train_Eval_Set",
                     help = "The name of the validation set variable")
parser <- add_option(parser, "--study-id", default = "Studyid", 
                     help = "The study id variable")
parser <- add_option(parser, "--utilization", default = "Utiliz", 
                     help = "The utilization variable")
parser <- add_option(parser, "--weight", default = "weight", 
                     help = "Inverse probability of selection into gold-standard set")
parser <- add_option(parser, "--site", default = "kpwa", 
                     help = "The site from which the data come from")
args <- parse_args(parser, convert_hyphens_to_underscores = TRUE)

args$analysis <- gsub("_non_negated", "", gsub("_all_mentions", "", args$analysis))
# read in the raw dataset
input_data <- readr::read_csv(paste0(args$data_dir, args$data_name), na = c("NA", ".", ""))

# pull only outcome, features of interest. EDIT IF NECESSARY
if (grepl("phase_1_updated", args$analysis)) {
  structured_features <- c("Gender_F", "Age_Index_Yrs")
}
dataset_names <- names(input_data)
cui_names <- dataset_names[grepl("C[0-9]", dataset_names)]
filtered_data <- input_data %>% 
  select(!!c(matches(args$study_id), matches(args$gold_label),
             matches(args$valid_label), matches("silver"), matches(args$utilization),
             matches(args$weight), matches(paste0("^", structured_features, "$")),
             matches(cui_names)))

# recode outcome, train/eval, gender, etc. (EDIT IF NECESSARY)
recoded_data <- filtered_data %>% 
  mutate(!!args$gold_label := ifelse(grepl("missing", !!as.name(args$gold_label), ignore.case = TRUE), 
                                     NA, ifelse(grepl("yes", !!as.name(args$gold_label), ignore.case = TRUE), 1, 0)),
         !!args$valid_label := ifelse(grepl("train", !!as.name(args$valid_label), ignore.case = TRUE), 0, 1),
         Gender_F = as.numeric(Gender_F == "F"))
# save
saveRDS(recoded_data, file = paste0(
  args$analysis_data_dir, args$analysis, "_", args$site, "_preprocessed_data.rds"
))