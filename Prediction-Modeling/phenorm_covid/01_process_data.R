#!/usr/local/bin/Rscript

# process the input dataset

# required packages and functions ---------------------------------------------
library("optparse")
library("tidyverse")
library("here")

here::i_am("phenorm_covid/README.md")

source(here::here("phenorm_covid", "phenorm_utils.R"))
# set up command-line args ----------------------------------------------------
parser <- OptionParser()
parser <- add_option(parser, "--data_dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PROGRAMMING/SAS Datasets/Replicate VUMC Analysis/Sampling for Chart Review/Phenorm Symptomatic Covid-19 update/",
                     help = "The input data directory")
parser <- add_option(parser, "--analysis_data_dir", 
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/",
                     help = "The analysis data directory")                     
parser <- add_option(parser, "--data_name",
                     default = "COVID_PheNorm_N8329_12DEC2022.csv", help = "The name of the dataset")
parser <- add_option(parser, "--analysis",
                     default = "phase_1_enhanced_symptomatic_covid_all_mentions", help = "The name of the analysis")
parser <- add_option(parser, "--use_afep", default = FALSE, action = "store_true",
                     help = "Should we use AFEP screening for NLP variables?")
parser <- add_option(parser, "--use_nonneg", default = FALSE, action = "store_true",
                     help = "Should we use the non-negated mentions (FALSE) or all mentions (TRUE)?")
parser <- add_option(parser, "--gold_label", default = "PTYPE_MODERATE_PLUS_POSITIVE", help = "The name of the gold label")
parser <- add_option(parser, "--valid_label", default = "Train_Eval_Set", help = "The name of the validation set variable")
parser <- add_option(parser, "--study_id", default = "Studyid", help = "The study id variable")
parser <- add_option(parser, "--utilization", default = "Utiliz", help = "The utilization variable")
parser <- add_option(parser, "--site", default = "kpwa", help = "The site from which the data come from")
parser <- add_option(parser, "--use_nonnormalized", default = FALSE, action = "store_true",
                     help = "Should we use nonnormalized features?")
parser <- add_option(parser, "--use_normalized", default = FALSE, action = "store_true",
                     help = "Should we use normalized features?")
parser <- add_option(parser, "--train_on_gold", default = FALSE, action = "store_true",
                     help = "Should we train on gold-labeled data too?")
args <- parse_args(parser)
source(here::here("phenorm_covid", "phenorm_covid_setup.R"))
if (grepl("non_negative", args$analysis) & !args$use_nonneg) {
  args$use_nonneg <- TRUE
}
if (!dir.exists(args$analysis_data_dir)) {
  dir.create(args$analysis_data_dir, recursive = TRUE)
  txt_for_readme <- "# Analysis datasets\n\nThis folder contains analysis-ready datasets, resulting from processing raw data into PheNorm-ready form."
  writeLines(txt_for_readme, con = paste0(args$analysis_data_dir, "README.md"))
}

# process the dataset ---------------------------------------------------------
input_data <- readr::read_csv(paste0(args$data_dir, args$data_name), na = na_values)
if (!is.numeric(input_data %>% pull(!!args$valid_label))) {
  valid_label_index <- which(grepl(args$valid_label, names(input_data), ignore.case = TRUE))
  input_data[[valid_label_index]] <- ifelse(input_data[[valid_label_index]] == valid_values[1], 0, 1)
}
# if we're using all mentions, drop non-negated mentions (if they exist)
if (!args$use_nonneg) {
  input_data <- input_data %>% 
    select(-contains("nonneg"))
} else {
  cui_names <- names(input_data)[grepl("C[0-9]", names(input_data))]
  names_to_keep <- rep(TRUE, length(names(input_data)))
  names_to_keep[grepl("C[0-9]", names(input_data))] <- grepl(nonneg_id, cui_names)
  input_data <- input_data[, names_to_keep]
  input_data_names <- names(input_data)
  names(input_data) <- gsub(nonneg_id, "", gsub("count", "Count", input_data_names))
}
# drop normalized (or nonnormalized) if requested

# do any minor preprocessing we need to; process_structured_data defined specific to each problem
input_data <- process_structured_data(input_data, vars_to_process = structured_data_vars_to_binary,
                                      values = structured_data_vals_to_binary)
data_names <- names(input_data)
cui_names <- data_names[grepl("C[0-9]", data_names)]
nlp_names <- c(silver_labels, args$utilization, cui_names)

# if requested to train on gold-labeled data (as well as non-gold-labeled data),
# change training/testing split
processed_data <- process_data(dataset = input_data,
                               structured_data_names = structured_data_names,
                               nlp_data_names = nlp_names,
                               study_id = args$study_id,
                               validation_name = args$valid_label,
                               gold_label = args$gold_label,
                               utilization_variable = args$utilization)
train_structured <- processed_data$train_structured
test_structured <- processed_data$test_structured
train_nlp <- processed_data$train_nlp
test_nlp <- processed_data$test_nlp
outcomes <- processed_data$outcome
all_data <- processed_data$all

# apply AFEP screen to NLP variables ------------------------------------------
if (args$use_afep) {
  afep_screened_data <- phenorm_afep(
    train = train_nlp, test = test_nlp, study_id = args$study_id,
    cui_of_interest = cui_of_interest,
    cui_cols = (1:ncol(train_nlp))[grepl("C[0-9]", names(train_nlp))],
    threshold = 0.15
  )
  train_nlp_screened <- afep_screened_data$train
  test_nlp_screened <- afep_screened_data$test
} else {
  train_nlp_screened <- train_nlp
  test_nlp_screened <- test_nlp
}

# combine and log-transform ---------------------------------------------------
train_all <- dplyr::left_join(train_structured, train_nlp, 
                              by = args$study_id) %>%
  select(-!!args$study_id)
train_screened <- dplyr::left_join(train_structured, train_nlp_screened, 
                              by = args$study_id) %>%
  select(-!!args$study_id)  
test_all <- dplyr::left_join(test_structured, test_nlp, 
                             by = args$study_id) %>%
  select(-!!args$study_id)
test_screened <- dplyr::left_join(test_structured, test_nlp_screened, 
                             by = args$study_id) %>%
  select(-!!args$study_id)

train_all_cc <- train_all[complete.cases(train_all), ]
test_all_cc <- test_all[complete.cases(test_all), ]
train_screened_cc <- train_screened[complete.cases(train_screened), ]
test_screened_cc <- test_screened[complete.cases(test_screened), ]

# log transform
log_train_all <- apply_log_transformation(dataset = train_all_cc, 
                                          varnames = names(train_all_cc), 
                                          utilization_var = args$utilization)
log_test_all <- apply_log_transformation(dataset = test_all_cc, 
                                          varnames = names(test_all_cc), 
                                          utilization_var = args$utilization)
log_train_screened <- apply_log_transformation(dataset = train_screened_cc, 
                                          varnames = names(train_screened_cc), 
                                          utilization_var = args$utilization)
log_test_screened <- apply_log_transformation(dataset = test_screened_cc, 
                                          varnames = names(test_screened_cc), 
                                          utilization_var = args$utilization)
log_all <- apply_log_transformation(dataset = all_data,
                                    varnames = names(all_data)[!(names(all_data) %in% c(args$gold_label,
                                                                  args$valid_label,
                                                                  args$study_id))],
                                    utilization_var = args$utilization)

analysis_data <- list(
  "train" = log_train_screened, "test" = log_test_screened, "outcomes" = outcomes,
  "train_all" = log_train_all, "test_all" = log_test_all, "all" = log_all
)
saveRDS(
  analysis_data, file = paste0(
    args$analysis_data_dir, args$analysis, "_", args$site, "_analysis_data.rds"
  )
)
print("Data processing complete.")