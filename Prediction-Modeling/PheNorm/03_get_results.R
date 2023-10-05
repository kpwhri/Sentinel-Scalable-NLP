#!/usr/local/bin/Rscript

# Evaluate prediction performance

# required packages and functions ---------------------------------------------
library("optparse")
library("tidyverse")
library("PheNorm")
library("ROCR")
library("WeightedROC")
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
                     default = "phase_1_updated_symptomatic_covid", help = "The name of the analysis")
parser <- add_option(parser, "--weight", default = "Sampling_Weight", 
                     help = "Inverse probability of selection into gold-standard set")
parser <- add_option(parser, "--data-site", default = "kpwa", help = "The site the data to evaluate on came from")
parser <- add_option(parser, "--model-site", default = "kpwa", help = "The site the where the model was trained")                     
args <- parse_args(parser, convert_hyphens_to_underscores = TRUE)

fit_output_dir <- paste0(args$output_dir, "fits/")
results_output_dir <- paste0(args$output_dir, "plots_and_tables/")
if (!dir.exists(results_output_dir)) {
  dir.create(results_output_dir, recursive = TRUE)
  txt_for_readme <- paste0(
    "# `plots_and_tables`\n\n", 
    "This folder contains plots and tables with results from the COVID-19 PheNorm analyses.\n\n",
    "The files follow a naming convention: <analysis name>_<phenotype>_<type of mentions>_data_<data site, i.e., where the data came from>_model_<model site, i.e., where the PheNorm model was trained>_<result description>, where text in brackets is replaced.\n\n", 
    "For example, to view the ROC curve corresponding to the moderate+ phenotype using the phase 1 enhanced dataset, and NLP variables based on all mentions, using data from KPWA and a PheNorm at KPWA, with all silver labels (and the aggregate silver label), look at `phenorm_phase_1_enhanced_moderateplus_covid_all_mentions_data_kpwa_model_kpwa_combined_roc.png`.\n\n",
    "The possible analyses are:\n",
    "* phase 1 enhanced (`phase_1_enhanced`): the original predictor set, with demographic variables and harmonized silver labels between KPWA and VUMC\n",
    "* other analyses to be filled in\n\n",
    "The possible outcomes are:\n",
    "* moderate+ (`moderateplus_covid`): COVID-19 with moderate or higher severity. Only run in the phase 1 enhanced analysis, to reproduce prior results (presented at AMIA 2022).\n",
    "* symptomatic (`symptomatic_covid`): any symptomatic COVID-19 (i.e., mild or higher severity).\n\n", 
    "The possible data and model sites are:\n",
    "* Kaiser Permanente Washington (`kpwa`)\n",
    "* Vanderbilt University Medical Center (`vumc`)\n\n",
    "The possible results are:\n",
    "* `<silver label>_combined_performance.png`: a plot showing several performance metrics (F0.5, F1, NPV, PPV, Sensitivity, Specificity) for the silver label (or aggregate, i.e., the mean of the predicted probabilities from the silver label-specific models)\n",
    "* `<silver label>_perf_table.csv`: the same results as the above bullet, but in a table\n",
    "* `<silver label>_roc.png`: a plot showing the ROC curve for the given label, plus the AUC.\n",
    "* `combined_roc.png`: ROC curves for each silver label (and the aggregate) for the given analysis, outcome, and type of NLP variables\n",
    "* `max_f1.csv`: a table showing the predicted probability cutoff (and quantile), sensitivity, specificity, NPV, F1, and F0.5 for each silver label at the cutoff that maximized the F1 score. There may be multiple rows for a given silver label; that occurs when there were muliple cutoffs that led to F1 values within 0.001 of the maximum.\n"
  )
  writeLines(txt_for_readme, con = paste0(results_output_dir, "README.md"))
}

analysis_data <- readRDS(
  file = paste0(
    args$data_dir, args$analysis, "_", args$data_site, "_analysis_data.rds"
  )
)
# note that "silver" is required to be in the variable name for all silver labels
silver_labels <- analysis_data$silver_labels
outcomes <- analysis_data$outcomes
phenorm_analysis <- readRDS(
  file = paste0(
    fit_output_dir, args$analysis, "_", args$model_site, "_phenorm_output.rds"
  )
)
fit <- phenorm_analysis$fit
model_fit_names <- gsub("SX.norm.corrupt", "", rownames(fit$betas))
model_features <- model_fit_names[!(model_fit_names %in% c(silver_labels))]
if (args$model_site == args$data_site) {
  preds <- phenorm_analysis$preds
} else {
  # get features used to train external PheNorm model
  set.seed(1234)
  preds <- predict.PheNorm(
    phenorm_model = fit, newdata = analysis_data$test_all, silver_labels = silver_labels,
    features = model_features,
    utilization = analysis_data$utilization_variable, aggregate_labels = silver_labels
  )
  saveRDS(
    preds, file = paste0(
      fit_output_dir, args$analysis, "_", args$data_site, 
      "_phenorm_preds_using_", args$model_site, "_model.rds"
    )
  )
}
# evaluate performance --------------------------------------------------------
perf_names <- names(preds)
perf_list <- lapply(as.list(1:ncol(preds)), function(k) {
  get_performance_metrics(predictions = preds[[k]], labels = outcomes,
                          weights = analysis_data$test[[args$weight]],
                          identifier = perf_names[k])
})
perf <- map_dfr(perf_list, bind_rows)
perf_wide <- perf %>%
  pivot_wider(names_from = measure, values_from = perf) %>%
  select(-auc)
# create plots and tables -----------------------------------------------------
result_prefix <- paste0(
  results_output_dir, "phenorm_", args$analysis, "_data_", args$data_site,
  "_model_", args$model_site
)
combined_roc_curve <- phenorm_roc(performance_object = perf,
                                  analysis_name = args$analysis,
                                  n_legend_rows = 3)
ggsave(
  filename = paste0(result_prefix, "_combined_roc.png"), 
  plot = combined_roc_curve, width = 12, height = 5, units = "in"
)
silver_labels_plus_voting <- c(silver_labels, "Aggregate")
# ROC curves, performance plots, performance table
for (i in seq_len(length(silver_labels_plus_voting))) {
  this_silver_label <- silver_labels_plus_voting[i]
  this_perf <- perf %>%
    filter(id == this_silver_label)
  this_roc_curve <- phenorm_roc(performance_object = this_perf,
                                analysis_name = args$analysis,
                                n_legend_rows = 3)
  file_prefix <- paste0(result_prefix, "_", tolower(this_silver_label))
  ggsave(
    filename = paste0(file_prefix, "_roc.png"),
    plot = this_roc_curve, width = 12, height = 5, units = "in"
  )
  this_combined_perf <- phenorm_combined(
    performance_object = this_perf,
    analysis_name = paste0(args$analysis, ", ", this_silver_label)
  )
  ggsave(
    filename = paste0(file_prefix, "_combined_performance.png"),
    plot = this_combined_perf, width = 12, height = 5, units = "in"
  )
  this_wide_perf <- perf_wide %>%
    filter(id == this_silver_label)
  this_wide_perf %>%
    mutate(across(3:9, round, 3)) %>%
    write_csv(file = paste0(file_prefix, "_perf_table.csv"))
}
# Maximum F1 score
perf_wide %>%
  group_by(id) %>%
  filter(abs(F1 - max(F1, na.rm = TRUE)) < 0.0005) %>%
  write_csv(file = paste0(result_prefix, "_max_f1.csv"))
# print out the final model (covariates, coefficients)
final_model <- fit$betas
rownames(final_model) <- model_fit_names
readr::write_csv(
  as.data.frame(final_model) %>%
    rownames_to_column("Variable Name"), file = paste0(
    result_prefix, "_coefficients.csv"
  )
)
# variable importance
set.seed(5678)
est_vim <- get_vimp(phenorm_model = fit, preds = preds,
                    newdata = analysis_data$test_all, 
                    silver_labels = silver_labels,
                    features = model_features,
                    utilization = analysis_data$utilization_variable, aggregate_labels = silver_labels,
                    outcomes = outcomes,
                    measure = "permute")
readr::write_csv(
  est_vim, file = paste0(
    result_prefix, "_vim.csv"
  )
)
print("Results complete.")