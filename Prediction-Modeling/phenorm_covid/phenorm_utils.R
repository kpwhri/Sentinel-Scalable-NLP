# utility functions for PheNorm modeling

# run the entire analysis for a single set of silver labels and features -------
#' @param train the training data
#' @param test the testing data
#' @param silver_labels the silver labels to use  (a character vector)
#' @param features the features (both structured and NLP) to use (a character vector)
#' @param utilization the utilization variable (a string)
#' @param seeds a vector with two random number seeds, one for the phenorm fit and one for the predictions
#' @param aggregate_labels a character vector of which labels to aggregate over
#' @param ... other arguments to pass to PheNorm
run_phenorm <- function(train = NULL, test = NULL, silver_labels = "", features = "",
                        utilization = "", seeds = c(1, 2), aggregate_labels = silver_labels,
                        ...) {
  L <- list(...)
  corrupt_rate <- ifelse(is.null(L$corrupt.rate), .3, L$corrupt.rate)
  train_size <- ifelse(is.null(L$train.size), 10 * nrow(train), L$train.size)
  set.seed(seeds[1])
  phenorm_fit <- PheNorm::PheNorm.Prob(
    nm.logS.ori = silver_labels, nm.utl = utilization, dat = train,
    nm.X = features, corrupt.rate = corrupt_rate, train.size = train_size
  )
  set.seed(seeds[2])
  phenorm_preds <- predict.PheNorm(
    phenorm_model = phenorm_fit, newdata = test, silver_labels = silver_labels,
    features = features, utilization = utilization, aggregate_labels = aggregate_labels
  )
  return(list("fit" = phenorm_fit, "preds" = phenorm_preds))
}


# process a dataset ------------------------------------------------------------
# process the structured data to make it nice
# @param data the dataset
# @param vars_to_process a vector of variable names to process from strings to binary
# @param values the value to use for each variable to define a 1
process_structured_data <- function(data, vars_to_process, values) {
  for (i in seq_len(length(vars_to_process))) {
    var <- vars_to_process[i]
    val <- values[i]
    indx <- which(grepl(var, names(data), ignore.case = TRUE))
    data[[indx]] <- ifelse(data[[indx]] == val, 1, 0)
  }
  return(data)
}

#' @param dataset the original dataset
#' @param structured_data_names a character vector specifying the names 
#'   of the structured data
#' @param nlp_data_names a character vector specifying the names 
#'   of the nlp data (including CUIs)
#' @param study_id the name of the study id variable
#' @param validation_name a string specifying which variable name implies 
#'   that the observation was validated
#' @param gold_label a string specifying the gold label variable name
#' @param utilization_variable a string specifying the name of the utilization 
#'   variable (if empty, a vector of 1s will be created [i.e., no normalization])
#' @return a list, with nlp and structured data (both training and testing sets)
process_data <- function(dataset = NULL, structured_data_names = "AGE",
                         nlp_data_names = "C", study_id = "STUDYID",
                         validation_name = "GOLD_STANDARD_VALIDATION",
                         gold_label = "AP_GOLD_LABEL",
                         utilization_variable = "") {
  if (!any(grepl(utilization_variable, names(dataset)))) {
    dataset[[utilization_variable]] <- 1
  }
  all_data <- dplyr::select(dataset, !!c(matches(study_id),
                                         matches(validation_name),
                                         matches(gold_label),
                                         matches(paste0("^", structured_data_names, "$")), 
                                         matches(nlp_data_names)))
  outcome_indx <- which(grepl(gold_label, names(all_data), ignore.case = TRUE))
  valid_indx <- which(grepl(validation_name, names(all_data), ignore.case = TRUE))
  outcomes <- all_data[[outcome_indx]]
  if (!is.numeric(outcomes)) {
    if (any(grepl("yes", outcomes, ignore.case = TRUE))) {
      outcomes <- ifelse(grepl("yes", outcomes, ignore.case = TRUE), 1, 0)
      outcomes[all_data[[valid_indx]] == 0] <- NA
    } else {
      stop("Outcome is not in a recognized format (numeric, binary, or 'yes'/'no'). Please use an outcome variable that is in one of these formats.")
    }
    all_data[[outcome_indx]] <- outcomes
  }
  train <- dplyr::select(dplyr::filter(all_data, !!rlang::sym(names(all_data)[valid_indx]) == 0),
                         -!!matches(gold_label))
  test <- dplyr::filter(all_data, !!rlang::sym(names(all_data)[valid_indx]) == 1)
  train_cc <- train[complete.cases(train), ]
  test_cc <- test[complete.cases(test), ]
  outcome_indx <- which(grepl(gold_label, names(test_cc), ignore.case = TRUE))
  outcomes <- test_cc[[outcome_indx]]
  train_structured <- dplyr::select(train_cc, !!c(matches(study_id), 
                                                  matches(paste0("^", structured_data_names, "$"))))
  test_structured <- dplyr::select(test_cc, !!c(matches(study_id), 
                                                matches(paste0("^", structured_data_names, "$"))))
  train_nlp <- dplyr::select(train_cc, !!c(matches(study_id), matches(nlp_data_names)))
  test_nlp <- dplyr::select(test_cc, !!c(matches(study_id), matches(nlp_data_names)))
  return(list("outcome" = outcomes, "train_structured" = train_structured,
              "train_nlp" = train_nlp, "test_structured" = test_structured,
              "test_nlp" = test_nlp, "all" = all_data))
}

# apply log transformation to structured, NLP variables ------------------------
#' @param dataset the dataset
#' @param varnames the variable names to log-transform
#' @return a dataset with the appropriate columns log-transformed
apply_log_transformation <- function(dataset = NULL, varnames = NULL,
                                     utilization_var = NULL) {
  log_transformed_data <- dataset
  log_transformed_data[, varnames] <- log(dataset[, varnames] + 1)
  if (all(dataset[[utilization_var]] == 1)) {
    log_transformed_data[[utilization_var]] <- 1
  }
  return(log_transformed_data)
}

# apply AFEP -------------------------------------------------------------------
#' @param train the training dataset
#' @param test the testing dataset
#' @param study_id the study id
#' @param cui_of_interest a string specifying the cui of interest
#' @param utilization_variable a string specifying the utilization variable
#' @param cui_cols a numeric vector specifying which columns of the NLP dataset correspond to CUIs
#' @param threshold the threshold for AFEP
#' @return train and test datasets screened by AFEP
phenorm_afep <- function(train = NULL, test = NULL, study_id = "Studyid", cui_of_interest = "C",
                         utilization_variable = "Utiliz",
                         cui_cols = (1:ncol(train))[grepl("C[0-9]", names(train))],
                         threshold = 0.15) {
  cui_col_of_interest <- cui_cols[grepl(cui_of_interest, names(train[, cui_cols]))]
  other_cui_cols <- cui_cols[!grepl(cui_of_interest[1], names(train[, cui_cols]))]
  train_selected <- afep(dataset = train %>% select(-!!study_id), nlp_label = cui_of_interest,
                         features = names(train[, other_cui_cols]),
                         threshold = threshold)
  train_afep_plus <- rep(TRUE, ncol(train_nlp))
  train_afep_plus[other_cui_cols] <- train_selected
  train_afep_plus[cui_col_of_interest] <- TRUE
  train_screened <- train[, train_afep_plus]
  test_screened <- test[, train_afep_plus]
  return(list("train" = train_screened, "test" = test_screened))
}
get_f_score <- function(precision, recall, beta) {
  (1 + beta ^ 2) * precision * recall / (beta ^ 2 * precision + recall)
}

# Compute performance metrics on gold-standard data ----------------------------
get_performance_metrics <- function(predictions = NULL, labels = NULL, identifier = "model 1") {
  pred_obj <- ROCR::prediction(
    predictions = predictions, labels = labels
  )
  auc <- unlist(ROCR::performance(
    prediction.obj = pred_obj, measure = "auc"
  )@y.values)
  sens_spec <- ROCR::performance(
    prediction.obj = pred_obj, measure = "tpr", x.measure = "fpr"
  )
  prec_rec <- ROCR::performance(
    prediction.obj = pred_obj, measure = "prec", x.measure = "rec"
  )
  # could also use ROCR, with alpha = 1 / (1 + beta ^ 2)
  f1_score <- get_f_score(unlist(prec_rec@y.values), unlist(prec_rec@x.values), beta = 1)
  f05_score <- get_f_score(unlist(prec_rec@y.values), unlist(prec_rec@x.values), beta = 0.5)
  spec <- 1 - unlist(sens_spec@x.values)
  sens <- unlist(sens_spec@y.values)
  ppv <- unlist(ROCR::performance(
    prediction.obj = pred_obj, measure = "ppv"
  )@y.values)
  npv <- unlist(ROCR::performance(
    prediction.obj = pred_obj, measure = "npv"
  )@y.values)
  perf <- list("Sensitivity" = sens, "Specificity" = spec,
               "PPV" = ppv, "NPV" = npv, "F1" = f1_score, "F0.5" = f05_score)
  cutoff_dependent <- do.call(rbind.data.frame,
    lapply(as.list(seq_len(length(perf))),
    function(l) cbind.data.frame("measure" = names(perf)[l],
                                 "perf" = perf[[l]],
                                 "cutoff" = unlist(sens_spec@alpha.values)))
  )
  percentile_function <- ecdf(predictions)
  cutoff_dependent$quantile <- percentile_function(cutoff_dependent$cutoff)
  output_tibble <- tibble::tibble("id" = identifier, "auc" = auc, cutoff_dependent)
  return(output_tibble)
}

# nice plots of phenorm results ------------------------------------------------
#' @param performance_object a resulting performance object from get_performance_metrics
#' @return an ROC curve for the phenorm predictions
phenorm_roc <- function(performance_object = NULL, analysis_name = "Primary 1",
                        n_legend_rows = 3, title_length = 80) {
  the_title <- paste0("Receiver operating characteristic curve: ", analysis_name)
  aucs <- performance_object %>%
    group_by(id) %>%
    slice(n = 1) %>%
    select(id, auc)
  if (nrow(aucs) > 1) {
    roc_curve <- performance_object %>%
      pivot_wider(names_from = measure, values_from = perf) %>%
      ggplot(aes(x = 1 - Specificity, y = Sensitivity, color = id)) +
      geom_line(size = 1) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
      labs(x = "1 - Specificity", y = "Sensitivity", color = "Silver Label") +
      ggtitle(stringr::str_wrap(the_title, title_length)) +
      scale_color_viridis_d(labels = paste0(aucs$id, ", AUC = ", round(aucs$auc, 3)),
                            begin = 0, end = 0.8) +
      guides(color = guide_legend(nrow = n_legend_rows)) +
      theme(legend.position = "bottom", legend.direction = "horizontal")
  } else {
    the_title <- paste0("Receiver operating characteristic curve: ", analysis_name, ", ",
                     aucs$id)
    roc_curve <- performance_object %>%
      pivot_wider(names_from = measure, values_from = perf) %>%
      ggplot(aes(x = 1 - Specificity, y = Sensitivity)) +
      geom_line(size = 1) +
      geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
      labs(x = "1 - Specificity", y = "Sensitivity") +
      ggtitle(stringr::str_wrap(the_title, title_length)) +
      annotate(geom = "text", x = 0.75, y = 0.25, size = 8,
               label = paste0("AUC = ", round(aucs$auc, 3)))
  }
  return(roc_curve)
}

#' @param performance_object a resulting performance object from get_performance_metrics
#' @return the combined performance plot for the phenorm predictions
phenorm_combined <- function(performance_object = NULL, analysis_name = "Primary 1",
                             title_length = 80) {
  the_title <- paste0("Performance metrics at different cutpoints: ", analysis_name)
  combined_plot <- performance_object %>%
    ggplot(aes(x = quantile, y = perf, color = measure)) +
    geom_line(size = 1) +
    labs(x = "Percentile Cutpoint", y = "Percent", color = "Performance metric") +
    ggtitle(stringr::str_wrap(the_title, title_length)) +
    scale_y_continuous(minor_breaks = seq(0, 1, 0.05)) +
    scale_x_continuous(minor_breaks = seq(0, 1, 0.05)) +
    theme(panel.grid.minor = element_line(color = "grey"),
          panel.grid.major = element_line(color = "grey"))
  return(combined_plot)
}

# PheNorm-based predictions on new data ----------------------------------------
# get predicted probabilities based on PheNorm model and new data
#' @param phenorm_model the fitted PheNorm model
#' @param newdata the new dataset
#' @param silver_labels the names of the silver labels (i.e., surrogates); a character vector.
#' @param features the names of the additional features to use; a character vector.
#' @param utilization the name of the healthcare utilization variable; a string.
#'   passed to original PheNorm model
#' @param use_empirical_sd should we use the empirical standard deviation of the
#'   normalized silver label when obtaining predicted probabilities of the phenotype
#'   \code{TRUE}; the default), or not (\code{FALSE})?
#' @param aggregate_labels the names of the silver lables used in the aggregate predictions
#'   (i.e., which silver label predicted probabilities to average for the aggregate approach)
#' @return a data.frame with each column representing a predicted posterior probability,
#'   and \code{Aggregate} denoting the voting model (i.e., the mean of the other predicted probabilities)
predict.PheNorm <- function(phenorm_model = NULL, newdata = NULL,
                            silver_labels = NULL, features = NULL,
                            utilization = NULL, use_empirical_sd = TRUE,
                            aggregate_labels = silver_labels,
                            na.rm = TRUE) {
  if (is.null(phenorm_model)) {
    stop("Please enter a fitted PheNorm model.")
  }
  if (is.null(newdata)) {
    stop("Please enter a new dataset to get PheNorm predictions on.")
  }
  # normal mixture normalization on the new dataset
  newmat <- as.matrix(newdata)
  silver_label_data <- newmat[, silver_labels, drop = FALSE]
  util <- newmat[, utilization]
  normal_approximation_minimizer <- apply(silver_label_data, 2, function(s) {
    PheNorm:::findMagicNumber(s, util)$coef
  })
  normalized_silver_labels <- silver_label_data -
    PheNorm:::VTM(normal_approximation_minimizer, nrow(newdata)) * util
  # also add features if we used them
  if (!is.null(features)) {
    feature_data <- newmat[, features, drop = FALSE]
    normalized_data <- cbind(normalized_silver_labels, feature_data)
  } else {
    normalized_data <- normalized_silver_labels
  }
  # predict, for each silver label separately and overall ("voting")
  phenorm_score <- normalized_data %*% as.matrix(phenorm_model$betas)
  posterior_probs <- apply(phenorm_score, 2, function(x) {
    fit <- PheNorm:::normalmixEM2comp2(x, lambda = 0.5,
                                       mu = quantile(x, probs = c(1/3, 2/3), na.rm = na.rm),
                                       sigsqrd = ifelse(use_empirical_sd, sd(x, na.rm = na.rm) / 2, 1))
    fit$posterior[, 2]
  })
  posterior_probs_vote <- rowMeans(posterior_probs[, aggregate_labels])
  all_posterior_probs <- cbind.data.frame(posterior_probs, "Aggregate" = posterior_probs_vote)
  return(all_posterior_probs)
}

# implement AFEP for feature selection -----------------------------------------
# AFEP procedure for feature selection; from Gronsbell et al. (2019) supplement
# [Automated feature selection of predictors in electronic medical records data, Biometrics, 2019]
#' @param dataset the data
#' @param nlp_label the name of the variable corresponding to the NLP concept; a string.
#' @param features the names of the additional features to use; a character vector.
#' @param threshold a threshold for the correlation; values above the threshold are selected.
#'  Defaults to 0.15, the value proposed in Yu et al. (2015).
afep <- function(dataset = NULL, nlp_label = NULL, features = NULL, threshold = 0.15) {
  mat <- as.matrix(dataset)
  nlp_label_data <- mat[, nlp_label, drop = FALSE]
  feature_data <- mat[, features, drop = FALSE]
  corrs <- apply(nlp_label_data, 2, function(x) {
    abs(cor(x, feature_data, method = "spearman"))
  })
  corrs[is.na(corrs)] <- 0
  return(as.vector(corrs > threshold))
}

#' screen based on high correlation between variables (outcome-blind)
#' @param x the dataset
#' @param vars_to_keep variables to keep 
screen_highcor <- function(x, vars_to_keep, threshold = 0.95) {
  vars <- rep(FALSE, ncol(x))
  cors <- cor(x, method = "spearman")
  cors[upper.tri(cors)] <- 0
  diag(cors) <- 0
  vars <- !apply(cors, 2, function(z) any(abs(z) > threshold, na.rm = TRUE))
  vars[names(x) %in% vars_to_keep] <- TRUE
  vars
}