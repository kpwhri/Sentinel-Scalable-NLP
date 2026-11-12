# demographics for table 1 of anaphylaxis paper

library("dplyr")
library("tidyr")
library("tibble")
library("readr")
library("here")

here::i_am("README.md")

source(here::here("Anaphylaxis", "00_utils.R"))


# set up arguments and folders -------------------------------------------------
proj_root <- "G:/CTRHS/Immu/VSD Task Order F1 PheNorm Anaphylaxis (1367)/"
train_on_gold <- 0
phenorm_folder <- paste0("negation_0_normalization_0_dimension-reduction_0_train-on-gold_", train_on_gold, "/")

args <- list()

args$data_dir <- paste0(proj_root, "Analysis/Data/")
args$output_dir <- paste0("G:/CTRHS/Immu/VSD Task Order F1 PheNorm Anaphylaxis (1367)/Analysis/PheNorm/results_negation_0_normalization_0_dimension-reduction_0_train-on-gold_", train_on_gold, "/")
args$data_name <- "phenorm_kpwa_anaphylaxis.csv"

args$analysis <- "vsd_anaphylaxis"
args$weight <- "Sampling_Weight"
args$data_site <- "kpwa"
args$model_site <- "kpwa"
args$seed <- 20231204

fit_output_dir <- paste0(args$output_dir, "fits/")
results_output_dir <- paste0(args$output_dir, "plots_and_tables/")

# read in dataset --------------------------------------------------------------
input_data <- readr::read_csv(paste0(args$data_dir, args$data_name), na = c("NA", ".", ""))  

# create descriptive table for KPWA sample -------------------------------------
studyid <- unlist(lapply(strsplit(input_data$Obs_ID, "_"), function(x) x[1]))
input_data$studyid <- studyid
n_eligible_encounters <- nrow(input_data)
data_for_summary <- input_data %>% 
  rename(sex_is_f = SEX_F, ethnicity_is_hispanic = Ethnicity,
         path = ASSIGNED_PATH) %>% 
  mutate(age_group = case_when(
           AGE_INDEX <= 29 ~ "16--29",
           30 <= AGE_INDEX & AGE_INDEX <= 49 ~ "30--49",
           50 <= AGE_INDEX & AGE_INDEX <= 69 ~ "50--69",
           70 <= AGE_INDEX ~ "70+"
         ),
         race_is_white = case_when(
           Race_AFAM > 0 ~ 0,
           Race_Asian > 0 ~ 0,
           Race_HP > 0 ~ 0,
           Race_NatAm > 0 ~ 0,
           Race_Other > 0 ~ 0,
           Race_UNKN > 0 ~ 0,
           .default = 1
         ),
         days_with_notes = case_when(
           N_CALDAYS_W_NOTES_W_SM <= 3 ~ "1--3 days",
           4 <= N_CALDAYS_W_NOTES_W_SM & N_CALDAYS_W_NOTES_W_SM <= 6 ~ "4--6 days",
           7 <= N_CALDAYS_W_NOTES_W_SM & N_CALDAYS_W_NOTES_W_SM <= 9 ~ "7--9 days",
           10 <= N_CALDAYS_W_NOTES_W_SM ~ "10+ days"
         )
         ) %>% 
  select(sex_is_f, age_group, race_is_white, ethnicity_is_hispanic, 
         path, days_with_notes, Gold_Set, studyid)

n_unique_pts <- data_for_summary %>% 
  count(studyid) %>% 
  summarize(Count = n())
n_gold <- data_for_summary %>% 
  count(Gold_Set) %>% 
  filter(Gold_Set == 1)
n_female <- data_for_summary %>% 
  count(sex_is_f) %>% 
  filter(sex_is_f == 1)
n_age_groups <- data_for_summary %>% 
  count(age_group)
n_white <- data_for_summary %>% 
  count(race_is_white) %>% 
  filter(race_is_white == 1)
n_hispanic <- data_for_summary %>% 
  count(ethnicity_is_hispanic) %>% 
  filter(ethnicity_is_hispanic == 1)
n_path <- data_for_summary %>% 
  count(path)
n_days <- data_for_summary %>% 
  count(days_with_notes)

all_descriptives <- bind_rows(
  tibble(Characteristic = "All encounters", Count = n_eligible_encounters),
  n_unique_pts %>% mutate(Characteristic = "Number of unique patients") %>% select(Characteristic, Count),
  n_gold %>% rename(Count = n) %>% mutate(Characteristic = "Number of encounters with gold-standard outcomes") %>% select(Characteristic, Count),
  n_female %>% rename(Count = n) %>% mutate(Characteristic = "Sex is female") %>% select(Characteristic, Count),
  tibble(Characteristic = "Age group", Count = NA_real_), 
  n_age_groups %>% rename(Characteristic = "age_group", Count = n),
  n_white %>% rename(Count = n) %>% mutate(Characteristic = "Race is White") %>% select(Characteristic, Count),
  n_hispanic %>% rename(Count = n) %>% mutate(Characteristic = "Ethnicity is Hispanic") %>% select(Characteristic, Count),
  tibble(Characteristic = "Walsh Path", Count = NA_real_),
  n_path %>% mutate(path = as.character(path)) %>%  rename(Characteristic = "path", Count = n),
  tibble(Characteristic = "Days with clinical notes", Count = NA_real_),
  n_days %>% rename(Characteristic = days_with_notes, Count = n)
) %>% 
  mutate(Percent = Count / n_eligible_encounters * 100,
         Count = ifelse(is.na(Count), "", Count),
         Percent = ifelse(is.na(Percent), "", as.character(round(Percent, 0))))

write.csv(all_descriptives, paste0(results_output_dir, "kpwa_descriptive_statistics.csv"))

# count the number of epi codes among the gold subset (2x2 table with case status)
gold_set <- input_data %>% 
  filter(Gold_Set == 1)
gold_set %>% 
  count(Sentinel_GS, EPIRSD) %>% 
  pivot_wider(names_from = Sentinel_GS, values_from = n, values_fill = 0) %>% 
  write.csv(paste0(results_output_dir, "kpwa_epi_vs_goldstandard.csv"))
