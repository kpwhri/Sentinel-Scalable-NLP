# set up variables that will be used throughout the COVID PheNorm analysis
# EDIT THIS FILE IF VARIABLE NAMES CHANGE ACROSS SITES

# The number of analyses and analysis names
all_analyses <- expand.grid(overall = c("phase_1_enhanced_moderateplus_covid",
                                        "phase_1_enhanced_symptomatic_covid", 
                                        "phase_2_enhanced_symptomatic_covid", 
                                        "symptomatic", "moderate"),
                            mentions = c("all_mentions", "non_negated"))
n_analyses <- nrow(all_analyses)
analysis_names <- paste0(all_analyses$overall, "_", all_analyses$mentions)
# Names of structured data and silver labels, case-insensitive
silver_labels <- c("Silver_Struct_1", "Silver_Struct_2",
                   "Silver_NLP_1_COVID19_Hits", 
                   "Silver_NLP_2_COVID19_CUI_Notes")
# utilization variable, case-insensitive (if it doesn't exist, it will be created as a vector of all 1s)
utilization_variable <- "Utiliz" 
# study id variable, case-insensitive
studyid <- "Studyid"
# structured data, case-insensitive
structured_data_names <- c("Gender_F", "Age_Index_Yrs")
structured_data_vars_to_binary <- "Gender_F"
structured_data_vals_to_binary <- "F"
# validation variable (identifies which set the observation is in), case-insensitive
valid_values <- c("Training", "Evaluation")
na_values <- c("NA", ".", "")
# variable specifiying the CUI of interest
if (args$use_nonnormalized) {
  cui_of_interest <- "C5203670_Count"  
} else {
  cui_of_interest <- "C5203670_normalized"
}
# tuning parameters for PheNorm. note we're setting "recommended" values.
corrupt_rate <- 0.3
train_size_multiplier <- 13 # to match Jing's analysis
# non-negative mention identifier
nonneg_id <- "_nonneg"

# extra variables to add in phase 2 modeling
if (grepl("phase_2", args$analysis)) {
  # Edit the next line if there are additional variables to add. Replace "NULL" with c(<put comma-separated variable names here, like on line 21 above>)
  structured_data_names <- c(structured_data_names, NULL)
} else {
  structured_data_names <- c(structured_data_names, NULL)
}