# merge dataset containing silver labels, raw NLP variables, structured variables
# with the dataset containing the manually-curated NLP variables

# load required functions and packages -----------------------------------------
library("readr")
library("dplyr")
library("tidyselect")

# read in the datasets ---------------------------------------------------------
# top-level data directory
data_dir <- "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PROGRAMMING/SAS Datasets/Replicate VUMC Analysis/Sampling for Chart Review/"
final_data_dir <- paste0(data_dir, "Severity-specific silver-standard surrogates/")

silver_label_data_name <- "SevSpecSlvStdSur_N8329_23JAN2023.csv"
manual_nlp_data_name <- "Tp_vst_caldays_per_feature_n8329.csv"

# dataset with silver labels, raw NLP variables, structured variables
initial_dataset <- readr::read_csv(paste0(data_dir, "Severity-specific silver-standard surrogates/", silver_label_data_name))

# dataset with manually-curated NLP variables
manual_nlp_dataset <- readr::read_csv(paste0(data_dir, "Per Member Per Dx within 61 days/", manual_nlp_data_name))

# select only the n_ments variables
manual_nlp_vars_of_interest <- manual_nlp_dataset %>% 
  select(Studyid, starts_with("n_ments_nn"))
# do the merge -----------------------------------------------------------------
final_dataset <- initial_dataset %>% 
  left_join(manual_nlp_vars_of_interest, by = "Studyid")

# save off as a .csv -----------------------------------------------------------
readr::write_csv(final_dataset, paste0(final_data_dir, "full_analysis_dataset_n8329.csv"))
