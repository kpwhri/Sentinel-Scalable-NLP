#!/usr/local/bin/Rscript

# Obtain predicted probabilities on the entire dataset (training and testing)

# required packages and functions ---------------------------------------------
library("optparse")
library("dplyr")
library("tidyr")
library("readr")
library("stringr")
library("PheNorm")
library("ggplot2")
library("cowplot")
theme_set(theme_cowplot())
library("here")

here::i_am("README.md")

source(here::here("00_utils.R"))
# set up command-line args ----------------------------------------------------
parser <- OptionParser()
parser <- add_option(parser, "--data-dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets_negation_0_normalization_1_dimension-reduction_0_train-on-gold_0/",
                     help = "The input data directory")
parser <- add_option(parser, "--output-dir",
                     default = "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/results_negation_0_normalization_1_dimension-reduction_0_train-on-gold_0/",
                     help = "The output directory")
parser <- add_option(parser, "--analysis",
                     default = "phase_1_updated_symptomatic_covid", help = "The name of the analysis")
parser <- add_option(parser, "--weight", default = "Sampling_Weight", 
                     help = "Inverse probability of selection into gold-standard set")
parser <- add_option(parser, "--seed", type = "integer", default = 1234,
                     help = "The random number seed to use")
parser <- add_option(parser, "--data-site", default = "kpwa", help = "The site the data to evaluate on came from")
parser <- add_option(parser, "--model-site", default = "kpwa", help = "The site the where the model was trained")                     
parser <- add_option(parser, "--study-id", default = "Studyid", help = "The study id variable")
parser <- add_option(parser, "--valid-label", default = "Train_Eval_Set", 
                     help = "The name of the validation set variable")
parser <- add_option(parser, "--seed", type = "integer", default = 4747,
                     help = "The random number seed to use")
args <- parse_args(parser, convert_hyphens_to_underscores = TRUE)

fit_output_dir <- paste0(args$output_dir, "fits/")
# load in data and fitted PheNorm object ---------------------------------------
analysis_data <- readRDS(
  file = paste0(
    args$data_dir, args$analysis, "_", args$data_site, "_analysis_data.rds"
  )
)
silver_labels <- analysis_data$silver_labels
outcomes <- analysis_data$outcomes
train_data <- analysis_data$train
test_data <- analysis_data$test
all_data <- analysis_data$all
id_var <- which(grepl(args$study_id, names(all_data), ignore.case = TRUE))
valid_label <- which(grepl(args$valid_label, names(all_data), ignore.case = TRUE))
# check to see if the training data or testing has the ID variable; if so, remove it
train_id_col <- grepl(args$study_id, names(train_data), ignore.case = TRUE)
if (any(train_id_col)) {
  train_minus_id <- train_data[, !train_id_col]  
} else {
  train_minus_id <- train_data
}
test_id_col <- grepl(args$study_id, names(train_data), ignore.case = TRUE)
if (any(test_id_col)) {
  test_minus_id <- test_data[, !test_id_col]  
} else {
  test_minus_id <- test_data
}

phenorm_analysis <- readRDS(
  file = paste0(
    fit_output_dir, args$analysis, "_", args$model_site, "_phenorm_output.rds"
  )
)
fit <- phenorm_analysis$fit

# make predictions on entire dataset -------------------------------------------
# get features used to train PheNorm model
model_fit_names <- gsub("SX.norm.corrupt", "", rownames(fit$betas))
model_features <- model_fit_names[!(model_fit_names %in% c(silver_labels, args$weight))]
# get predictions among those in the test set
test_ids <- all_data[[id_var]][all_data[[valid_label]] == 1]
if (length(test_ids) > 0) {
  set.seed(args$seed)
  preds_test <- predict.PheNorm(
    phenorm_model = fit, newdata = test_minus_id, silver_labels = silver_labels,
    features = model_features,
    utilization = analysis_data$utilization_variable, aggregate_labels = silver_labels
  )
  names(preds_test) <- paste0("pred_prob_", names(preds_test))
  preds_test_df <- data.frame(test_ids, preds_test)
  names(preds_test_df)[1] <- args$study_id
} else {
  preds_test_df <- NULL
}

# get predictions among those in the training set
train_ids <- all_data[[id_var]][all_data[[valid_label]] == 0]
set.seed(args$seed)
preds_train <- predict.PheNorm(
  phenorm_model = fit, newdata = train_minus_id, silver_labels = silver_labels,
  features = model_features,
  utilization = analysis_data$utilization_variable, aggregate_labels = silver_labels
)
names(preds_train) <- paste0("pred_prob_", names(preds_train))
preds_train_df <- data.frame(train_ids, preds_train)
names(preds_train_df)[1] <- args$study_id

# set up whole vector of predictions
unordered_preds <- rbind(preds_test_df, preds_train_df)
ids_only <- data.frame(all_data[[id_var]])
names(ids_only) <- args$study_id
pred_dataset <- ids_only %>% 
  left_join(unordered_preds, by = args$study_id)
# save
readr::write_csv(
  pred_dataset, file = paste0(
    fit_output_dir, args$analysis, "_", args$data_site, 
    "_phenorm_all_predicted_probabilities_using_", args$model_site, "_model.csv"
  )
)
# create a histogram of predicted probabilities for each silver label
# first, get the base-R hist breakpoints
long_pred_dataset <- pred_dataset %>%
  pivot_longer(cols = starts_with("pred"), names_to = "model", values_to = "pred_prob") %>%
  mutate(model = gsub("pred_prob_", "", model))
breaks <- pretty(range(long_pred_dataset$pred_prob), n = nclass.Sturges(long_pred_dataset$pred_prob),
                 min.n = 1)
pred_prob_hist <- long_pred_dataset %>%
  ggplot(aes(x = pred_prob)) +
  geom_histogram(breaks = breaks) +
  labs(x = "Predicted probability", y = "Count") +
  facet_wrap(vars(model))
ggsave(filename = paste0(
    fit_output_dir, args$analysis, "_", args$data_site, 
    "_phenorm_predicted_probabilities_hist_using_", args$model_site, "_model.png"
  ), pred_prob_hist, width = 11, height = 8, units = "in", dpi = 300)
print("Predicted probabilities obtained on entire dataset.")
