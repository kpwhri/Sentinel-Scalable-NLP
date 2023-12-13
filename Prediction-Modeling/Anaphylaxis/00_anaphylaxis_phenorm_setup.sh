#!/bin/bash

# Project-specific setup

# mount the G: drive (in /mnt/g); modify this line if you are using a different system (or if you don't have to mount drives)
sudo mkdir -p /mnt/g
sudo mount -t drvfs G: /mnt/g

# edit the following lines based on the analysis and directory structure -------
# CUI of interest
cui_of_interest="C0002792"
# model development site and external validation site
site="kpwa"
# external_site="<replace with the external validation site, if any>"
# dataset name
raw_data_name="di7_phenorm_modeling_file_brian.csv"
data_name="di7_phenorm_modeling_file_brian.rds"
# analysis name
analysis_name="sentinel_anaphylaxis"
# directory
# dir_prefix="/mnt/c/Users/L107067/OneDrive - Kaiser Permanente/Code/Sentinel-Scalable-NLP/Prediction-Modeling/"
dir_prefix="/mnt/g/"
top_dir="${dir_prefix}CTRHS/Sentinel/Innovation_Center/DI7_Assisted_Review/"
dir="${top_dir}ANALYSIS/"
# dataset directory
# data_dir="${dir_prefix}sandbox/"
data_dir="${top_dir}"PROGRAMMING/SAS\ Datasets/05_Silver_Labels_and_Analytic_File_for\ _BrianW/
# random number seed, can be edited
rng_seeds=20231204
# set up analysis options ------------------------------------------------------
# set to the defaults
# toggle negation on/off, defaults to TRUE
use_negation=0
# toggle dimension reduction on/off, defaults to FALSE
use_dimension_reduction=0
# should we use non-normalized, normalized NLP variables? nonnormalized defaults to TRUE, normalized defaults to FALSE
use_nonnormalized_data=1
use_normalized_data=0
# should we train on gold-labeled data as well? defaults to FALSE
train_on_gold_data=0
# tuning parameters for PheNorm, also set to the defaults
corrupt_rate=0.3
train_size_mult=13
# Variable names and helpful values
valid_label="Train_Eval_Set"
train_value="1"
nonneg_label="_nonneg"
study_id="obs_id"
util_var="utiliz"
weight_var="sampling_weight"
gold_label="PTYPE_POSITIVE"
chart_reviewed=FALSE

# directory setup, based on entries above --------------------------------------
# these directories are specified by the directories above
analysis_data_dir="${dir}PheNorm/analysis_datasets_negation_${use_negation}_normalization_${use_normalized_data}_dimension-reduction_${use_dimension_reduction}_train-on-gold_${train_on_gold_data}/"
output_dir="${dir}PheNorm/results_negation_${use_negation}_normalization_${use_normalized_data}_dimension-reduction_${use_dimension_reduction}_train-on-gold_${train_on_gold_data}/"

mkdir -p "${dir}PheNorm"
# set up i/o output directory 
io_dir="phenorm_io_files_negation_${use_negation}_normalization_${use_normalized_data}_dimension-reduction_${use_dimension_reduction}_train-on-gold_${train_on_gold_data}"
mkdir -p ${io_dir}

gold_label_arry=(${gold_label})
analyses=(${analysis_name})
data_names=(${data_name})
n_analyses=${#analyses[@]}
n_datasets=${#data_names[@]}
