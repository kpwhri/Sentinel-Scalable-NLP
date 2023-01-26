#!/bin/bash

# Project-specific setup
# This is the only file that should have to be edited!

# set up analyses to run: ------------------------------------------------------
# Model set 1: use_negation=0, use_dimension_reduction=0, use_nonnormalized_data=1, use_normalized_data=0, train_on_gold_data=0
# Model set 2: use_negation=1, use_dimension_reduction=0, use_nonnormalized_data=1, use_normalized_data=0, train_on_gold_data=0
# Model set 3: use_negation=0, use_dimension_reduction=0, use_nonnormalized_data=0, use_normalized_data=1, train_on_gold_data=0
# Model set 4: use_negation=0, use_dimension_reduction=1, use_nonnormalized_data=1, use_normalized_data=0, train_on_gold_data=0
# Model set 5: use_negation=1, use_dimension_reduction=1, use_nonnormalized_data=0, use_normalized_data=1, train_on_gold_data=0
# toggle negation on/off, defaults to FALSE
use_negation=0
# toggle dimension reduction on/off, defaults to TRUE
use_dimension_reduction=0
# should we use non-normalized, normalized NLP variables? both default to TRUE
use_nonnormalized_data=1
use_normalized_data=0
# should we train on gold-labeled data as well? defaults to FALSE
train_on_gold_data=0
# run phase 1 analyses
run_phase_1=0
# run phase 2 analyses
run_phase_2=1
# specify the outcome/feature sets, note that each corresponds to a specific dataset name below
phase_1_analyses=("phase_1_updated_moderateplus_covid" \
                  "phase_1_updated_symptomatic_covid")
phase_1_gold_labels=("PTYPE_MODERATE_PLUS_POSITIVE" "PTYPE_SYMPTOMATIC_POSITIVE")
# random number seeds: must be the same length as the analyses to run
# note that if this wasn't set, the same seed would be set for each analysis
phase_1_rng_seeds=(1234 5678)
phase_2_analyses=("phase_2_enhanced_symptomatic_covid" \
                  "phase_2_severity-specific_covid")
phase_2_gold_labels=("PTYPE_SYMPTOMATIC_POSITIVE" "PTYPE_SEVERE_PLUS_POSITIVE")
phase_2_rng_seeds=(91011 121314)
# dataset name; only include raw_data_name if you need to do project-specific preprocessing 
# raw_data_name=("SevSpecSlvStdSur_N8329_05JAN2023.csv") # used this name prior to "enhanced" analyses, which require a merged dataset
raw_data_name=("full_analysis_dataset_n8329.csv")
# arguments to pass to PheNorm, overrides defaults
corrupt_rate=0.3
train_size_mult=13
# Variable names and helpful values
valid_label="Train_Eval_Set"
train_value="Training"
nonneg_label="_nonneg"
study_id="Studyid"
util_var="Utiliz"
weight_var="Sampling_Weight"
# CUI of interest
cui_of_interest="C5203670"
# model development site and external validation site
site="kpwa"
external_site="vumc"
# edit the following directories to correspond to the filesystem on *your* computer
# dir_prefix: the main directory (at KPWHRI, a network drive called "G:")
# dir: the main directory for the scalable NLP project (where data, etc. live)
# raw_data_dir: where the raw data live; may differ for the different analyses
# analysis_data_dir: where we should put analysis datasets (constant)
# output_dir: where we should save results (constant)
dir_prefix="/mnt/g"
dir="${dir_prefix}/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell"
# raw_data_dir="${dir}"/PROGRAMMING/SAS\ Datasets/Replicate\ VUMC\ analysis/Sampling\ for\ Chart\ Review/Phenorm\ Symptomatic\ Covid-19\ update/
raw_data_dir="${dir}"/PROGRAMMING/SAS\ Datasets/Replicate\ VUMC\ analysis/Sampling\ for\ Chart\ Review/Severity-specific\ silver-standard\ surrogates/

# these directories are specified by the directories above
analysis_data_dir="${dir}/PheNorm/analysis_datasets_negation_${use_negation}_normalization_${use_normalized_data}_dimension-reduction_${use_dimension_reduction}_train-on-gold_${train_on_gold_data}/"
output_dir="${dir}/PheNorm/results_negation_${use_negation}_normalization_${use_normalized_data}_dimension-reduction_${use_dimension_reduction}_train-on-gold_${train_on_gold_data}/"

# determine which analyses to run, gold labels to use
if [ "${run_phase_1}" -ge 1 ] && [ "${run_phase_2}" -ge 1 ]; then 
  analyses=("${phase_1_analyses[@]}" "${phase_2_analyses[@]}")
  gold_label=("${phase_1_gold_labels[@]}" "${phase_2_gold_labels[@]}")
  rng_seeds=("${phase_1_rng_seeds[@]}" "${phase_2_rng_seeds[@]}")
elif [ "${run_phase_1}" -ge 1 ]; then
  analyses=("${phase_1_analyses[@]}")
  gold_label=("${phase_1_gold_labels[@]}")
  rng_seeds=("${phase_1_rng_seeds[@]}")
else 
  analyses=("${phase_2_analyses[@]}")
  gold_label=("${phase_2_gold_labels[@]}")
  rng_seeds=("${phase_2_rng_seeds[@]}")
fi
n_analyses=${#analyses[@]}
# processed dataset names are specified by the arguments above
data_names=( "${analyses[@]/%/_${site}_preprocessed_data.rds}" )
# data_names=("phase_1_updated_moderateplus_covid_${site}_preprocessed_data.rds" \
#             "phase_1_updated_symptomatic_covid_${site}_preprocessed_data.rds" \
#             "phase_2_enhanced_symptomatic_covid_${site}_preprocessed_data.rds" \
#             "phase_2_severity-specific_covid_${site}_preprocessed_data.rds")
n_datasets=${#data_names[@]}

# mount the G: drive (in /mnt/g); modify this line if you are using a different system (or if you don't have to mount drives)
sudo mount -t drvfs G: /mnt/g
mkdir -p "${dir}/PheNorm"
# set up i/o output directory 
io_dir="phenorm_covid_io_files_negation_${use_negation}_normalization_${use_normalized_data}_dimension-reduction_${use_dimension_reduction}_train-on-gold_${train_on_gold_data}"
mkdir -p ${io_dir}
