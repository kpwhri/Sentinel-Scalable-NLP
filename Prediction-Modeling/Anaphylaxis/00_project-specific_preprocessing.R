# project-specific preprocessing for Sentinel/VSD anaphylaxis analysis

# required packages and functions ---------------------------------------------
library("optparse")
library("dplyr")
library("readr")
library("stringr")
library("here")

here::i_am("README.md")

source(here::here("00_utils.R"))
parser <- OptionParser()
parser <- add_option(parser, "--data-dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PROGRAMMING/SAS Datasets/Replicate VUMC Analysis/Sampling for Chart Review/Severity-specific silver-standard surrogates/",
                     help = "The input data directory")
parser <- add_option(parser, "--analysis-data-dir", 
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets_negation_0_normalization_0_dimension-reduction_0_train-on-gold_0/",
                     help = "The analysis data directory")                     
parser <- add_option(parser, "--data-name",
                     default = "phase_1_updated_symptomatic_covid_kpwa_preprocessed_data.rds", 
                     help = "The name of the dataset")
parser <- add_option(parser, "--analysis",
                     default = "phase_1_updated_symptomatic_covid", 
                     help = "The name of the analysis")
parser <- add_option(parser, "--gold-label", default = "PTYPE_POSITIVE", 
                     help = "The name of the gold label")
parser <- add_option(parser, "--valid-label", default = "Train_Eval_Set", 
                     help = "The name of the validation set variable")
parser <- add_option(parser, "--study-id", default = "Studyid", 
                     help = "The study id variable")
parser <- add_option(parser, "--utilization", default = "Utiliz", 
                     help = "The utilization variable")
parser <- add_option(parser, "--weight", default = "Sampling_Weight", 
                     help = "Inverse probability of selection into gold-standard set")
args <- parse_args(parser, convert_hyphens_to_underscores = TRUE)

if (!dir.exists(args$analysis_data_dir)) {
  dir.create(args$analysis_data_dir, recursive = TRUE)
  txt_for_readme <- "# Analysis datasets\n\nThis folder contains analysis-ready datasets, resulting from processing raw data into PheNorm-ready form."
  writeLines(txt_for_readme, con = paste0(args$analysis_data_dir, "README.md"))
}

# read in the dataset
input_data <- readr::read_csv(paste0(args$data_dir, args$data_name), na = c("NA", ".", ""))  

# remove any columns with 0 variance/only one unique value, outside of the special columns
all_num_unique <- lapply(input_data, function(x) length(unique(x)))
is_zero <- (all_num_unique == 0)
removed_zero_variance <- input_data %>%
  select(!!args$study_id, !!args$weight, (1:ncol(input_data))[!is_zero])  

# remove columns that we don't want to use in modeling
removed_unneccessary_cols <- removed_zero_variance %>%
  select(-starts_with("Assigned_Path"), -starts_with("HOI_2_0"), -starts_with("filter_group"), -starts_with("n_cal"), -starts_with("n_notes"), -starts_with("tot_notes"))

saveRDS(removed_unneccessary_cols, paste0(args$data_dir, gsub(".csv", ".rds", args$data_name)))
print("Data preprocessing complete")