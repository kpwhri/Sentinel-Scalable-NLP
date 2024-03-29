#!/usr/local/bin/Rscript

# process the input dataset

# required packages and functions ---------------------------------------------
library("optparse")
library("dplyr")
library("readr")
library("stringr")
library("here")

here::i_am("README.md")

source(here::here("00_utils.R"))
# set up command-line args ----------------------------------------------------
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
parser <- add_option(parser, "--cui", default = "C5203670", 
                     help = "The CUI of interest (for the outcome of interest)")
parser <- add_option(parser, "--train-value", default = "Training",
                     help = "The value of the validation variable that designates the training set")
parser <- add_option(parser, "--use-afep", default = FALSE, action = "store_true",
                     help = "Should we use AFEP screening for NLP variables?")
parser <- add_option(parser, "--no-afep", action = "store_false",
                     dest = "use_afep")
parser <- add_option(parser, "--use-nonneg", default = TRUE, action = "store_true",
                     help = "Should we use the non-negated mentions (TRUE) or all mentions (FALSE)?")
parser <- add_option(parser, "--no-nonneg", action = "store_false",
                     dest = "use-nonneg")
parser <- add_option(parser, "--nonneg-label", default = "_nonneg",
                     help = "Identifier for non-negated CUIs")
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
parser <- add_option(parser, "--site", default = "kpwa", 
                     help = "The site from which the data come from")
parser <- add_option(parser, "--use-nonnormalized", default = TRUE, action = "store_true",
                     help = "Should we use nonnormalized features?")
parser <- add_option(parser, "--no-nonnormalized", action = "store_false",
                     dest = "use-nonnormalized")
parser <- add_option(parser, "--use-normalized", default = FALSE, action = "store_true",
                     help = "Should we use normalized features?")
parser <- add_option(parser, "--no-normalized", action = "store_false",
                     dest = "use-normalized")
parser <- add_option(parser, "--train-on-gold", default = FALSE, action = "store_true",
                     help = "Should we train on gold-labeled data too?")
parser <- add_option(parser, "--chart-reviewed", default = TRUE, 
                     help = "Have we already performed chart review?")
args <- parse_args(parser, convert_hyphens_to_underscores = TRUE)

if (!dir.exists(args$analysis_data_dir)) {
  dir.create(args$analysis_data_dir, recursive = TRUE)
  txt_for_readme <- "# Analysis datasets\n\nThis folder contains analysis-ready datasets, resulting from processing raw data into PheNorm-ready form."
  writeLines(txt_for_readme, con = paste0(args$analysis_data_dir, "README.md"))
}

# process the dataset ---------------------------------------------------------
# read in the data
if (grepl(".rds", args$data_name)) {
  input_data <- readRDS(paste0(args$data_dir, args$data_name)) 
} else {
  input_data <- readr::read_csv(paste0(args$data_dir, args$data_name), na = c("NA", ".", ""))  
}
if (!any(grepl(args$valid_label, names(input_data)))) {
  input_data[[args$valid_label]] <- rep(0, nrow(input_data))
}
if (!is.numeric(input_data %>% pull(!!args$valid_label))) {
  valid_label_index <- which(grepl(args$valid_label, names(input_data), ignore.case = TRUE))
  input_data[[valid_label_index]] <- ifelse(input_data[[valid_label_index]] == args$train_value, 0, 1)
}
# get to the correct set of CUI variables:
#   if we're using all mentions, drop non-negated mentions (if they exist)
#   drop normalized (or nonnormalized) if requested
only_cuis_of_interest <- filter_cui_variables(dataset = input_data, use_nonnegated = args$use_nonneg,
                                              use_normalized = args$use_normalized,
                                              use_nonnormalized = args$use_nonnormalized,
                                              nonneg_id = args$nonneg_label)

data_names <- names(only_cuis_of_interest)
cui_names <- data_names[grepl("C[0-9]", data_names, ignore.case = TRUE)]
# note that "silver" is required to be in the variable name for all silver labels
silver_labels <- data_names[grepl("silver", data_names, ignore.case = TRUE)]
nlp_names <- c(silver_labels, args$utilization, cui_names)
# structured data: *not* silver labels, utilization, CUIs, or weights!
structured_data_names <- data_names[!(data_names %in% c(args$study_id,
                                                        args$gold_label,
                                                        args$valid_label,
                                                        nlp_names, args$weight))]

# if requested to train on gold-labeled data (as well as non-gold-labeled data),
# change training/testing split
processed_data <- process_data(dataset = only_cuis_of_interest,
                               structured_data_names = structured_data_names,
                               nlp_data_names = nlp_names,
                               study_id = args$study_id,
                               validation_name = args$valid_label,
                               gold_label = args$gold_label,
                               utilization_variable = args$utilization,
                               weight = args$weight,
                               train_on_gold_data = args$train_on_gold,
                               chart_reviewed = args$chart_reviewed)
# drop variables in the training data with 0 variance/only one unique value, outside of the special columns
all_num_unique <- lapply(processed_data$train, function(x) length(unique(x)))
is_zero_one <- (all_num_unique == 0) | (all_num_unique == 1)
train <- processed_data$train %>% 
  select(!!args$study_id, all_of(silver_labels), !!args$weight, !!args$utilization,
         !!args$valid_label, (1:ncol(processed_data$train))[!is_zero_one])
test <- processed_data$test
outcomes <- processed_data$outcome
all_data <- processed_data$all

# apply AFEP screen to NLP variables ------------------------------------------
if (args$use_afep) {
  afep_screened_data <- phenorm_afep(
    train = train, test = test, study_id = args$study_id,
    cui_of_interest = args$cui,
    train_cui_cols = (1:ncol(train))[grepl("C[0-9]", names(train), ignore.case = TRUE)],
    test_cui_cols = (1:ncol(test))[grepl("C[0-9]", names(test), ignore.case = TRUE)],
    threshold = 0.15
  )
  train_screened <- afep_screened_data$train
  test_screened <- afep_screened_data$test
} else {
  train_screened <- train
  test_screened <- test
}

# combine and log-transform ---------------------------------------------------
train_all_cc <- train %>% 
  filter(complete.cases(train)) %>% 
  select(-!!args$study_id, -!!args$valid_label)
train_screened_cc <- train_screened %>% 
  filter(complete.cases(train_screened)) %>% 
  select(-!!args$study_id, -!!args$valid_label)
if (args$chart_reviewed) {
  test_all_cc <- test %>% 
    filter(complete.cases(test)) %>% 
    select(-!!args$study_id, -!!args$valid_label, -!!args$gold_label)
  test_screened_cc <- test_screened %>% 
    filter(complete.cases(test_screened)) %>%
    select(-!!args$study_id, -!!args$valid_label, -!!args$gold_label)
} else {
  test_all_cc <- test %>% 
    filter(complete.cases(test)) %>% 
    select(-!!args$study_id, -!!args$valid_label)
  test_screened_cc <- test_screened %>% 
    filter(complete.cases(test_screened)) %>%
    select(-!!args$study_id, -!!args$valid_label)
}

# log transform
log_train_all <- apply_log_transformation(
  dataset = train_all_cc, 
  varnames = names(train_all_cc)[!grepl(args$weight, names(train_all_cc))], 
  utilization_var = args$utilization
)
log_test_all <- apply_log_transformation(
  dataset = test_all_cc, 
  varnames = names(test_all_cc)[!grepl(args$weight, names(test_all_cc))], 
  utilization_var = args$utilization
)
log_train_screened <- apply_log_transformation(
  dataset = train_screened_cc, 
  varnames = names(train_screened_cc)[!grepl(args$weight, names(train_screened_cc))], 
  utilization_var = args$utilization
)
log_test_screened <- apply_log_transformation(
  dataset = test_screened_cc, 
  varnames = names(test_screened_cc)[!grepl(args$weight, names(test_screened_cc))], 
  utilization_var = args$utilization
)
log_all <- apply_log_transformation(
  dataset = all_data,
  varnames = names(all_data)[!(
    names(all_data) %in% c(args$gold_label, args$valid_label, args$study_id, args$weight)
  )],
  utilization_var = args$utilization
)

analysis_data <- list(
  "train" = log_train_screened, "test" = log_test_screened, "outcomes" = outcomes,
  "train_all" = log_train_all, "test_all" = log_test_all, "all" = log_all,
  "utilization_variable" = args$utilization, "silver_labels" = silver_labels
)
# save analysis dataset and some data summary statistics -----------------------
saveRDS(
  analysis_data, file = paste0(
    args$analysis_data_dir, args$analysis, "_", args$site, "_analysis_data.rds"
  )
)
summary_stats <- tibble::tibble(
  `Summary Statistic` = c("Sample size (total)", "Sample size (completely-observed)",
                          "Sample size (chart reviewed)", "Number of events",
                          "Number of NLP features", "Number of NLP features after screen"),
  `Value` = c(nrow(input_data), 
              ifelse(args$chart_reviewed, nrow(train_all_cc) + nrow(test_all_cc), nrow(train_all_cc)),
              ifelse(args$chart_reviewed, nrow(test_all_cc), 0), 
              sum(outcomes),
              length(cui_names), # need to account for study id, utilization
              sum(grepl("C[0-9]", names(test_screened_cc), ignore.case = TRUE)))
)
readr::write_csv(
  summary_stats, file = paste0(
    args$analysis_data_dir, args$analysis, "_", args$site, "_summary_statistics.csv"
  ) 
)
print("Data processing complete.")