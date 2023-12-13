# this file is specific to the COVID-19 analysis
# reads in the "raw" dataset, and creates a preliminary analytic dataset.
# important things to do here, for use in the downstream automated code:
#   (1) define outcome, features of interest (one dataset per outcome and feature set)
#   (2) recode any variables that need recoding (e.g., if they are characters and need to be binary)
# this file is run *prior* to processing data for PheNorm (making train/test datasets, etc.)

library("optparse")
library("tidyverse")
library("here")

here::i_am("COVID/README.md")

source(here::here("COVID", "phenorm_utils.R"))
parser <- OptionParser()
parser <- add_option(parser, "--data-dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PROGRAMMING/SAS Datasets/Replicate VUMC Analysis/Sampling for Chart Review/Severity-specific silver-standard surrogates/",
                     help = "The input data directory")
parser <- add_option(parser, "--analysis-data-dir", 
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PROGRAMMING/SAS Datasets/Replicate VUMC Analysis/Sampling for Chart Review/Severity-specific silver-standard surrogates/",
                     help = "The analysis data directory")                     
parser <- add_option(parser, "--data-name",
                     default = "full_analysis_dataset_n8329.csv", 
                     help = "The name of the dataset")
parser <- add_option(parser, "--analysis",
                     default = "phase_1_updated_symptomatic_covid", 
                     help = "The name of the analysis")
parser <- add_option(parser, "--gold-label", default = "PTYPE_SYMPTOMATIC_POSITIVE", 
                     help = "The name of the gold label")
parser <- add_option(parser, "--valid-label", default = "Train_Eval_Set",
                     help = "The name of the validation set variable")
parser <- add_option(parser, "--study-id", default = "Studyid", 
                     help = "The study id variable")
parser <- add_option(parser, "--utilization", default = "Utiliz", 
                     help = "The utilization variable")
parser <- add_option(parser, "--weight", default = "Sampling_Weight", 
                     help = "Inverse probability of selection into gold-standard set")
parser <- add_option(parser, "--site", default = "kpwa", 
                     help = "The site from which the data come from")
args <- parse_args(parser, convert_hyphens_to_underscores = TRUE)

args$analysis <- gsub("_non_negated", "", gsub("_all_mentions", "", args$analysis))
# read in the raw dataset
input_data <- readr::read_csv(paste0(args$data_dir, args$data_name), na = c("NA", ".", ""))

# pull only outcome, silver labels, features of interest. EDIT IF NECESSARY
structured_demographic_features <- c("Gender_F", "Age_Index_Yrs")
# if doing an "enhanced" analysis, use a different set of structured predictors
# note that these need to match the names of the enhanced feature list *exactly* (minus case)
if (grepl("phase_2_enhanced", args$analysis)) {
  # aggregate HSF features
  other_structured_features <- c("hsfdx", "hsfpx", "hsfpl", "hsfrx")
  # VUMC-only features (inpatient)
  if (grepl("vumc", args$site)) {
    other_structured_features <- c(other_structured_features, "respiratory_support",
                                   paste0("rs_days_", c("vent", "hfnc", "o2", "nicpap", "bcpap")), 
                                   paste0("rx_", c("bivalirudin", "tocilizumab", "baricitinib",
                                                   "remdesivir")),
                                   paste0("sp02_", c("recorded", "lt_94_ever", "min")),
                                   paste0("pa02_", c("recorded", "lt_300_ever", "min")),
                                   paste0("resp_freq_", c("recorded", "lt_30_ever", "min")))
  }
  # other_structured_features <- names(input_data %>% 
  #   select(!!matches(other_structured_feature_prefix)))
  # manual NLP variables (at KPWA, located in a different folder/file)
  manual_nlp_features <- paste0(
    "n_ments_nn_", c(
      "fever", "cough", "sore_throat", "headache", "muscle_pain",
      "nausea", "losstastesmell", "diarrhea", "dyspnea_sob", "vomiting"
    ), "_nlp"
  )
} else if (grepl("phase_2_severity-specific", args$analysis)) {
  other_structured_features <- NULL
  manual_nlp_features <- NULL
} else {
  other_structured_features <- NULL
  manual_nlp_features <- NULL
}
structured_features <- c(structured_demographic_features, other_structured_features)
if (grepl("severity-specific", args$analysis)) {
  silver_label_string <- "severity_specific_silver"
} else {
  silver_label_string <- "silver"
}
dataset_names <- names(input_data)
cui_names <- dataset_names[grepl("C[0-9]", dataset_names)]
# if doing a severity-specific analysis, use only a subset of CUIs that have been reviewed for being severity-specific
if (grepl("severity-specific", args$analysis)) {
  # filter the CUI variables
  severity_specific_cuis <- c(
    "C0010340", "C1306577", "C0042491", "C0015357", "C0018801", "C0700292",
    "C0242184", "C0199470", "C0042497", "C0026766", "C1997883", "C0184633",
    "C0701159", "C0476273", "C1145670", "C0036983", "C0205082", "C1175175",
    "C4740692", "C4534306", "C0001617", "C4044947", "C1535502", "C0878544",
    "C0202823", "C0009566", "C1705232", "C1551396", "C0011777", "C0015879",
    "C0060323", "C0017710", "C0020268", "C0021747", "C0021760", "C0022917",
    "C0024312", "C0025815", "C0027059", "C0029216", "C4521445", "C0032285",
    "C0032310", "C4726677", "C0035222", "C0036974", "C0038317", "C0436345", 
    "C0010957", "C1609165", "C5244048"
  )
  cui_names_stripped <- gsub("_Count", "", gsub("_nonneg", "", gsub("_normalized", "", cui_names)))
  # need to keep C5203670 for dimension reduction
  cui_names <- cui_names[cui_names_stripped %in% severity_specific_cuis | cui_names_stripped == "C5203670"]
}
filtered_data <- input_data %>% 
  select(!!c(matches(args$study_id), matches(args$gold_label),
             matches(args$valid_label), matches(silver_label_string), matches(args$utilization),
             matches(paste0("^", args$weight, "$")), 
             matches(paste0("^", structured_features, "$")),
             matches(paste0("^", manual_nlp_features, "$")),
             matches(cui_names))) 
if (any(grepl("Silver_NLP_2_COVID19_CUI_Days", names(filtered_data), ignore.case = TRUE))) {
  filtered_data <- filtered_data %>% 
    select(-Silver_NLP_2_COVID19_CUI_Days)
}
if (any(grepl("severity", names(filtered_data), ignore.case = TRUE)) & !grepl("severity", args$analysis)) {
  filtered_data <- filtered_data %>% 
    select(-starts_with("severity"))
}

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
