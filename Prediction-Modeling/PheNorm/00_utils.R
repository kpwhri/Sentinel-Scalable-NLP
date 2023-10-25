# utility functions for PheNorm modeling

# run the entire analysis for a single set of silver labels and features -------
#' @param train the training data
#' @param test the testing data
#' @param silver_labels the silver labels to use  (a character vector)
#' @param features the features (both structured and NLP) to use (a character vector)
#' @param utilization the utilization variable (a string)
#' @param seed a random number seed
#' @param aggregate_labels a character vector of which labels to aggregate over
#' @param ... other arguments to pass to PheNorm
run_phenorm <- function(train = NULL, test = NULL, silver_labels = "", features = "",
                        utilization = "", weight = "", seed = 1234, 
                        aggregate_labels = silver_labels, ...) {
  L <- list(...)
  corrupt_rate <- ifelse(is.null(L$corrupt.rate), .3, L$corrupt.rate)
  train_size <- ifelse(is.null(L$train.size), 10 * nrow(train), L$train.size)
  set.seed(seed)
  phenorm_fit <- phenorm_prob(
    nm.logS.ori = silver_labels, nm.utl = utilization, nm.wt = weight, dat = train,
    nm.X = features, corrupt.rate = corrupt_rate, train.size = train_size
  )
  set.seed(seed)
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
  # is_chr <- 
  is_chr_bin <- apply(data, 2, function(x) length(unique(x)) == 2 & !is.numeric(x))
  bin_names <- names(data)[is_chr_bin]
  for (i in seq_len(length(bin_names))) {
    var <- bin_names[i]
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
#'   variable (if this variable name doesn't exist in the dataset, a vector of 1s will be created and used [i.e., no normalization])
#' @param weight a string specifying the name of the inverse probability weights
#'   (if this variable name doesn't exist in the dataset, a vector of 1s will be created [i.e., no weighting])
#' @param train_on_gold_data should we train on gold data? defaults to FALSE (i.e., train/test split)
#' @param chart_reviewed logical; is gold-labeled data available (i.e., have we run chart review already?)? defaults to \code{TRUE}
#' @return a list, with nlp and structured data (both training and testing sets)
process_data <- function(dataset = NULL, structured_data_names = "AGE",
                         nlp_data_names = "C", study_id = "STUDYID",
                         validation_name = "GOLD_STANDARD_VALIDATION",
                         gold_label = "AP_GOLD_LABEL",
                         utilization_variable = "Utiliz",
                         weight = "weight",
                         train_on_gold_data = FALSE,
                         chart_reviewed = TRUE) {
  if (!any(grepl(utilization_variable, names(dataset)))) {
    dataset[[utilization_variable]] <- 1
  }
  if (!any(grepl(weight, names(dataset)))) {
    dataset[[weight]] <- 1
  }
  if (chart_reviewed) {
    all_data <- dplyr::select(
      dataset, !!c(matches(study_id), matches(validation_name), 
                   matches(gold_label), matches(weight),
                   matches(paste0("^", structured_data_names, "$")), 
                   matches(unique(c(nlp_data_names, utilization_variable))))
    ) 
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
    if (train_on_gold_data) {
      train <- dplyr::select(all_data, -!!matches(gold_label))
    } else {
      train <- dplyr::select(dplyr::filter(all_data, !!rlang::sym(names(all_data)[valid_indx]) == 0),
                             -!!matches(gold_label))
    }
    test <- dplyr::filter(all_data, !!rlang::sym(names(all_data)[valid_indx]) == 1)
  } else {
    all_data <- dplyr::select(
      dataset, !!c(matches(study_id), matches(weight),
                   matches(paste0("^", structured_data_names, "$")), 
                   matches(unique(c(nlp_data_names, utilization_variable))))
    ) 
    train <- all_data
    test <- all_data
  }
  train_cc <- train[complete.cases(train), ]
  test_cc <- test[complete.cases(test), ]
  if (chart_reviewed) {
    outcome_indx <- which(grepl(gold_label, names(test_cc), ignore.case = TRUE))
    outcomes <- test_cc[[outcome_indx]]
  } else {
    outcomes <- rep(NA, nrow(test_cc))
  }
  return(list("outcome" = outcomes, "train" = train_cc, "test" = test_cc,
              "all" = all_data))
}

# remove CUI variables based on flags ------------------------------------------
#' @param dataset the input data
#' @param use_nonnegative should we use non-negated mentions? or not?
#' @param use_normalized should we include normalized version of CUIs? or not?
#' @param use_normalized should we include non-normalized counts of CUIs? or not?
#' @param nonneg_id regular expression designating non-negated CUIs
#' @return the dataset with correct CUI variables of interest
filter_cui_variables <- function(dataset = NULL, use_nonnegated = TRUE,
                                 use_normalized = TRUE, use_nonnormalized = TRUE,
                                 nonneg_id = "_nonneg") {
  if (use_nonnegated) {
    cui_names <- names(dataset)[grepl("C[0-9]", names(dataset))]
    names_to_keep <- rep(TRUE, length(names(dataset)))
    names_to_keep[grepl("C[0-9]", names(dataset))] <- grepl(nonneg_id, cui_names)
    dataset <- dataset[, names_to_keep]
    dataset_names <- names(dataset)
    names(dataset) <- gsub(nonneg_id, "", gsub("count", "Count", dataset_names))
  } else {
    dataset <- dataset %>% 
      select(-contains("nonneg"))
  }
  if (!use_normalized) {
    dataset <- dataset %>% 
      select(-contains("normalized"))
  }
  if (!use_nonnormalized) {
    cui_names <- names(dataset)[grepl("C[0-9]", names(dataset))]
    names_to_keep <- rep(TRUE, length(names(dataset)))
    names_to_keep[grepl("C[0-9]", names(dataset))] <- !grepl("count", cui_names, ignore.case = TRUE)
    dataset <- dataset[, names_to_keep]
  }
  return(dataset)
}

# apply log transformation to structured, NLP variables ------------------------
#' @param dataset the dataset
#' @param varnames the variable names to log-transform
#' @param utilization_var the utilization variable
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
                         train_cui_cols = (1:ncol(train))[grepl("C[0-9]", names(train))],
                         test_cui_cols = (1:ncol(test))[grepl("C[0-9]", names(test))],
                         threshold = 0.15) {
  cui_col_of_interest <- train_cui_cols[grepl(cui_of_interest, names(train[, train_cui_cols]))][1]
  test_cui_col_of_interest <- test_cui_cols[grepl(cui_of_interest, names(test[, test_cui_cols]))][1]
  other_cui_cols <- train_cui_cols[!grepl(cui_of_interest[1], names(train[, train_cui_cols]))]
  test_other_cui_cols <- test_cui_cols[!grepl(cui_of_interest[1], names(test[, test_cui_cols]))]
  train_selected <- afep(dataset = train %>% select(-!!study_id), nlp_label = cui_of_interest,
                         features = names(train[, other_cui_cols]),
                         threshold = threshold)
  train_afep_plus <- rep(TRUE, ncol(train))
  test_afep_plus <- rep(TRUE, ncol(test))
  train_afep_plus[other_cui_cols] <- train_selected
  test_afep_plus[test_other_cui_cols] <- train_selected
  train_afep_plus[cui_col_of_interest] <- TRUE
  test_afep_plus[test_cui_col_of_interest] <- TRUE
  train_screened <- train[, train_afep_plus]
  test_screened <- test[, test_afep_plus]
  return(list("train" = train_screened, "test" = test_screened))
}
get_f_score <- function(precision, recall, beta) {
  (1 + beta ^ 2) * precision * recall / (beta ^ 2 * precision + recall)
}

# Compute performance metrics on gold-standard data ----------------------------
# @param predictions the predictions on test data
# @param labels the true outcome labels from test data
# @param weights the inverse probability of sampling weights into the test data
# @param identifier the silver label that we're computing performance for
get_performance_metrics <- function(predictions = NULL, labels = NULL, 
                                    weights = rep(1, length(predictions)), 
                                    identifier = "model 1") {
  if (isTRUE(all.equal(weights, rep(1, length(predictions))))) {
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
    cutoffs <- unlist(sens_spec@alpha.values)
  } else {
    pred_obj_init <- WeightedROC::WeightedROC(guess = predictions, label = labels,
                                              weight = weights)
    # flip around to match ROCR (decreasing cutoff)
    pred_obj <- pred_obj_init[order(pred_obj_init$threshold, decreasing = TRUE), ] 
    auc <- WeightedROC::WeightedAUC(tpr.fpr = pred_obj_init)
    sens <- pred_obj$TPR
    spec <- 1 - pred_obj$FPR
    tp <- apply(as.matrix(pred_obj$threshold), 1, 
                function(x) sum(weights * ((labels == 1) * (predictions >= x))))
    # tp <- sum(labels) - pred_obj$FN
    fp <- apply(as.matrix(pred_obj$threshold), 1, 
                function(x) sum(weights * ((labels == 0) * (predictions >= x))))
    tn <- apply(as.matrix(pred_obj$threshold), 1, 
                function(x) sum(weights * ((labels == 0) * (predictions < x))))
    fn <- apply(as.matrix(pred_obj$threshold), 1, 
                function(x) sum(weights * ((labels == 1) * (predictions < x))))
    # tn <- sum(labels == 0) - pred_obj$FP
    ppv <- tp / (tp + fp)
    npv <- tn / (tn + fn)
    f1_score <- get_f_score(ppv, sens, beta = 1)
    f05_score <- get_f_score(ppv, sens, beta = 0.5)
    cutoffs <- pred_obj$threshold
  }
  perf <- list("Sensitivity" = sens, "Specificity" = spec,
               "PPV" = ppv, "NPV" = npv, "F1" = f1_score, "F0.5" = f05_score)
  cutoff_dependent <- do.call(rbind.data.frame,
                              lapply(as.list(seq_len(length(perf))),
                                     function(l) cbind.data.frame("measure" = names(perf)[l],
                                                                  "perf" = perf[[l]],
                                                                  "cutoff" = cutoffs))
  )
  percentile_function <- ecdf(predictions)
  cutoff_dependent$quantile <- percentile_function(cutoff_dependent$cutoff) 
  output_tibble <- tibble::tibble("id" = identifier, "auc" = auc, cutoff_dependent)
  return(output_tibble)
}

# variable importance for the fitted model -------------------------------------
#' @inheritParams predict.PheNorm
#' @param preds the predictions using the test data
#' @param measure the variable importance measure to use, currently only "ate" is implemented
#' @param outcomes the labels
#' @return the estimated variable importance for each variable in the model
get_vimp <- function(phenorm_model = NULL, preds = NULL,
                     newdata = NULL, silver_labels = NULL, features = NULL,
                     utilization = NULL, use_empirical_sd = TRUE,
                     aggregate_labels = silver_labels,
                     outcomes = NULL,
                     na.rm = TRUE, measure = "ate") {
  X <- as.matrix(newdata)
  eval(parse(text = paste0("est_vim <- data.frame(var = colnames(X), ",
                           paste(paste0("est_", silver_labels, " = NA"), collapse = ", "), ")")))
  est_vim$est_Aggregate <- NA
  if (grepl("ate", measure)) {
    # for the ATE vim, treat binary and continuous features differently
    is_binary <- apply(X, 2, function(x) length(unique(x)) == 2)
    # binary features: compare predictions when X is 1 vs 0 for everyone
    for (i in which(is_binary)) {
      newX_0 <- newX_1 <- X
      newX_0[, i] <- 0
      newX_1[, i] <- 1
      preds_0 <- predict.PheNorm(phenorm_model = phenorm_model, newdata = newX_0,
                                 silver_labels = silver_labels, features = features,
                                 utilization = utilization, use_empirical_sd = use_empirical_sd,
                                 aggregate_labels = aggregate_labels, na.rm = na.rm)
      preds_1 <- predict.PheNorm(phenorm_model = phenorm_model, newdata = newX_1,
                                 silver_labels = silver_labels, features = features,
                                 utilization = utilization, use_empirical_sd = use_empirical_sd,
                                 aggregate_labels = aggregate_labels, na.rm = na.rm)
      est_vim[i, 2:ncol(est_vim)] <- colMeans(preds_1 - preds_0)
    }
    # continuous features: compare predictions on original x vs x + sd(x)
    for (i in which(!is_binary)) {
      newX <- X
      newX[, i] <- X[, i] + sd(X[, i])
      new_preds <- predict.PheNorm(phenorm_model = phenorm_model, newdata = newX,
                                   silver_labels = silver_labels, features = features,
                                   utilization = utilization, use_empirical_sd = use_empirical_sd,
                                   aggregate_labels = aggregate_labels, na.rm = na.rm)
      est_vim[i, 2:ncol(est_vim)] <- colMeans(preds - new_preds)
    }
  } else if (grepl("permute", measure)) {
    # return permutation-based difference in AUC
    orig_auc <- unlist(lapply(as.list(1:ncol(preds)), function(i) {
      cvAUC::AUC(predictions = preds[, i], labels = outcomes)
    }))
    for (i in 1:ncol(X)) {
      newX <- X
      newX[, i] <- X[sample(nrow(X), replace = FALSE), i]
      shuffle_preds <- predict.PheNorm(phenorm_model = phenorm_model, newdata = newX,
                                       silver_labels = silver_labels, features = features,
                                       utilization = utilization, use_empirical_sd = use_empirical_sd,
                                       aggregate_labels = aggregate_labels, na.rm = na.rm)
      shuffle_aucs <- unlist(lapply(as.list(1:ncol(shuffle_preds)), function(k) {
        cvAUC::AUC(predictions = shuffle_preds[, k], labels = outcomes)
      }))
      est_vim[i, 2:ncol(est_vim)] <- orig_auc - shuffle_aucs
    }
  } else {
    stop("The entered variable importance measure is not currently supported. Please enter one of 'ate' or 'permute'.")
  }
  return(est_vim)
}

# nice plots of phenorm results ------------------------------------------------
#' @param performance_object a resulting performance object from get_performance_metrics
#' @return an ROC curve for the phenorm predictions
phenorm_roc <- function(performance_object = NULL, analysis_name = "Primary 1",
                        n_legend_rows = 3, title_length = 80) {
  the_title <- paste0("Receiver operating characteristic curve: ", analysis_name)
  aucs <- performance_object %>%
    group_by(id) %>%
    slice(1) %>%
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
  all_measures <- c("Sensitivity", "Specificity", "PPV", "NPV", "F1", "F0.5")
  combined_plot <- performance_object %>%
    ggplot(aes(x = quantile, y = perf, color = factor(measure, levels = all_measures))) +
    geom_line(size = 1) +
    labs(x = "Percentile Cutpoint", y = "Percent", color = "Performance metric") +
    ggtitle(stringr::str_wrap(the_title, title_length)) +
    scale_y_continuous(minor_breaks = seq(0, 1, 0.05)) +
    scale_x_continuous(minor_breaks = seq(0, 1, 0.05)) +
    theme(panel.grid.minor = element_line(color = "grey"),
          panel.grid.major = element_line(color = "grey"))
  return(combined_plot)
}

# PheNorm implementations ------------------------------------------------------
# implementation of PheNorm.Prob that returns the normalization constant and the phenorm scores
#' Fit the phenotyping algorithm PheNorm using EHR features
#'
#' @description
#' The function requires as input:
#' * a surrogate, such as the ICD code
#' * the healthcare utilization
#' It can leverage other EHR features (optional) to assist risk prediction.
#'
#' @param nm.logS.ori name of the surrogates (log(ICD+1), log(NLP+1) and log(ICD+NLP+1))
#' @param nm.utl name of healthcare utilization (e.g. note count, encounter_num etc)
#' @param nm.wt name of the weighting variable
#' @param dat all data columns need to be log-transformed and need column names
#' @param nm.X additional features other than the main ICD and NLP
#' @param corrupt.rate rate for random corruption denoising, between 0 and 1, default value=0.3
#' @param train.size size of training sample, default value 10 * nrow(dat)
#' @return list containing probability and beta coefficient
#' @examples
#' \dontrun{
#' set.seed(1234)
#' fit.dat <- read.csv("https://raw.githubusercontent.com/celehs/PheNorm/master/data-raw/data.csv")
#' fit.phenorm=PheNorm.Prob("ICD", "utl", fit.dat, nm.X = NULL,
#'                           corrupt.rate=0.3, train.size=nrow(fit.dat));
#' head(fit.phenorm$probs)
#' }
#' @export
phenorm_prob <- function(nm.logS.ori, nm.utl, nm.wt, dat, nm.X = NULL, corrupt.rate = 0.3, train.size = 10 * nrow(dat)) {
  dat <- as.matrix(dat)
  S.ori <- dat[, nm.logS.ori, drop = FALSE]
  utl <- dat[, nm.utl, drop = FALSE]
  if (nm.wt == "") {
    wt <- NULL
  } else {
    wt <- dat[, nm.wt, drop = FALSE]  
  }
  a.hat <- apply(S.ori, 2, function(S) {PheNorm:::findMagicNumber(S, utl)$coef})
  S.norm <- S.ori - PheNorm:::VTM(a.hat, nrow(dat)) * as.vector(utl)
  if (!is.null(nm.X)) {
    X <- as.matrix(dat[, nm.X, drop = FALSE])
    if (length(unique(utl)) == 1) {
      SX.norm <- cbind(S.norm, X, wt)
    } else {
      SX.norm <- cbind(S.norm, X, utl, wt) 
    }
    id <- sample(1:nrow(dat), train.size, replace = TRUE)
    SX.norm.corrupt <- apply(SX.norm[id, ], 2,
                             function(x) {ifelse(rbinom(length(id), 1, corrupt.rate), mean(x), x)}
    )
    sx_norm_df <- as.data.frame(SX.norm.corrupt)
    if (nm.wt == "") {
      weights <- rep(1, nrow(sx_norm_df))
    } else {
      weights <- sx_norm_df[[nm.wt]]
    }
    b.all <- apply(S.norm, 2, function(ss) {
      lm(ss[id] ~ . - 1, data = sx_norm_df[, !(names(sx_norm_df) %in% nm.wt)], 
         weights = weights)$coef
    })
    b.all[is.na(b.all)] <- 0
    S.norm <- as.matrix(SX.norm[, !(colnames(SX.norm) %in% nm.wt)]) %*% b.all
    if (length(unique(utl)) > 1) {
      b.all <- b.all[-dim(b.all)[1], ] 
    }
  } else {
    b.all <- NULL
  }
  if (length(nm.logS.ori) > 1) {
    postprob <- apply(S.norm, 2,
                      function(x) {
                        fit = PheNorm:::normalmixEM2comp2(x, lambda = 0.5,
                                                mu = quantile(x, probs=c(1/3, 2/3)), sigsqrd = 1
                        )
                        fit$posterior[, 2]
                      }
    )
    list("probs" = rowMeans(postprob, na.rm = TRUE), "betas" = b.all, "scores" = S.norm,
         "alpha" = a.hat)
    
  } else {
    fit <- PheNorm:::normalmixEM2comp2(unlist(S.norm), lambda = 0.5,
                             mu = quantile(S.norm, probs=c(1/3, 2/3)), sigsqrd = 1
    )
    list("probs" = fit$posterior[,2], "betas" = b.all, "scores" = S.norm,
         "alpha" = a.hat)
  }
}

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
  normalized_silver_labels <- silver_label_data -
    PheNorm:::VTM(phenorm_model$alpha, nrow(newdata)) * util
  # also add features if we used them
  if (!is.null(features)) {
    feature_data <- newmat[, features, drop = FALSE]
    normalized_data <- cbind(normalized_silver_labels, feature_data)
  } else {
    normalized_data <- normalized_silver_labels
  }
  # predict, for each silver label separately and overall ("voting")
  phenorm_score <- normalized_data %*% as.matrix(phenorm_model$betas)
  original_phenorm_score <- phenorm_model$scores
  posterior_probs <- do.call(cbind, sapply(1:ncol(phenorm_score), function(i) {
    fit <- PheNorm:::normalmixEM2comp2(phenorm_score[, i], lambda = 0.5,
                                       mu = quantile(original_phenorm_score[, i], probs = c(1/3, 2/3), na.rm = na.rm),
                                       sigsqrd = ifelse(use_empirical_sd, sd(original_phenorm_score[, i], na.rm = na.rm) / 2, 1))
    fit$posterior[, 2]
  }, simplify = FALSE))
  colnames(posterior_probs) <- colnames(phenorm_score)
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
  if (inherits(dataset, "data.frame")) {
    nms <- names(dataset)
  } else {
    nms <- colnames(dataset)
  }
  nlp_label_indx <- which(grepl(nlp_label, nms))[1]
  nlp_label_data <- mat[, nlp_label_indx, drop = FALSE]
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