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
                     default = "G:/CTRHS/Sentinel/Innovation_Center/DI7_Assisted_Review/PROGRAMMING/SAS Datasets/05_Silver_Labels_and_Analytic_File_for _BrianW/",
                     help = "The input data directory")
parser <- add_option(parser, "--analysis-data-dir", 
                     default = "G:/CTRHS/Sentinel/Innovation_Center/DI7_Assisted_Review/PROGRAMMING/SAS Datasets/05_Silver_Labels_and_Analytic_File_for _BrianW/",
                     help = "The analysis data directory")                     
parser <- add_option(parser, "--data-name",
                     default = ".rds", 
                     help = "The name of the dataset")
parser <- add_option(parser, "--analysis",
                     default = "sentinel_anaphylaxis", 
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
if (grepl(".csv", args$data_name)) {
  input_data <- readr::read_csv(paste0(args$data_dir, args$data_name), na = c("NA", ".", ""))    
} else {
  input_data <- haven::read_sas(paste0(args$data_dir, args$data_name))
}

if (is.null(input_data[[args$weight]])) {
  input_data[[args$weight]] <- 1
}

# # remove any columns with 0 variance/only one unique value, outside of the special columns
# all_num_unique <- lapply(input_data, function(x) length(unique(x)))
# is_zero_one <- (all_num_unique == 0) | (all_num_unique == 1)
# removed_zero_variance <- input_data %>%
#   select(!!args$study_id, !!args$weight, (1:ncol(input_data))[!is_zero_one])  

# remove columns that we don't want to use in modeling
# removed_unneccessary_cols <- removed_zero_variance %>%
removed_unneccessary_cols <- input_data %>% 
  select(-starts_with("Assigned_Path"), 
         # -starts_with("HOI_2_0"), 
         -starts_with("filter_group"), -starts_with("n_cal"), 
         -starts_with("n_notes"), -starts_with("tot_notes"))

if (grepl("hoi_20", args$analysis) | grepl("hoi20", args$analysis)) {
  removed_unneccessary_cols <- removed_unneccessary_cols %>%
    select(-starts_with("DI7"))
  # change HOI 2.0 gold case status to 0/1
  binary_outcome <- removed_unneccessary_cols %>% 
    mutate(HOI_2_0_Gold_Case = as.numeric(HOI_2_0_Gold_Case == "Yes"))
} else {
  removed_unneccessary_cols <- removed_unneccessary_cols %>%
    select(-starts_with("HOI_2_0"))
  binary_outcome <- removed_unneccessary_cols
}


saveRDS(binary_outcome, paste0(args$data_dir, gsub(".sas7bdat", ".rds", gsub(".csv", ".rds", args$data_name))))
print("Data preprocessing complete")