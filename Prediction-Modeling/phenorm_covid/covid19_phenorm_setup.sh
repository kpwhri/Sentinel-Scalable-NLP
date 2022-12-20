#!/bin/bash

# Project-specific setup

# set up i/o output directory
mkdir -p ./phenorm_covid_io_files
io_dir="phenorm_covid_io_files"

# set up analyses, dataset names, etc.
# note that the analyses correspond to a specific dataset name
# analyses=("phase_1_enhanced_symptomatic_covid" "phase_2_enhanced_symptomatic_covid" \
#           "covid_severity")
analyses=("phase_1_enhanced_moderateplus_covid_all_mentions" "phase_1_enhanced_moderateplus_covid_non_negated" \
          "phase_1_enhanced_symptomatic_covid_all_mentions" "phase_1_enhanced_symptomatic_covid_non_negated")
n_analyses=${#analyses[@]}
data_names=("COVID_PheNorm_N8329_12DEC2022.csv")
n_datasets=${#data_names[@]}
gold_label=("PTYPE_MODERATE_PLUS_POSITIVE" "PTYPE_MODERATE_PLUS_POSITIVE" \
            "PTYPE_SYMPTOMATIC_POSITIVE" "PTYPE_SYMPTOMATIC_POSITIVE")
valid_label="Train_Eval_Set"
study_id="Studyid"
util_var="Utiliz"
site="kpwa"
external_site="vumc"
# toggle dimension reduction on/off, defaults to TRUE
no_dimension_reduction=0
# should we use non-normalized, normalized NLP variables? both default to TRUE
no_nonnormalized_data=0
no_normalized_data=0
# should we train on gold-labeled data as well? defaults to FALSE
train_on_gold_data=0
# edit the following directories to correspond to the filesystem on *your* computer
# dir_prefix: the main directory (at KPWHRI, a network drive called "G:")
# dir: the main directory for the scalable NLP project (where data, etc. live)
# raw_data_dir: where the raw data live; may differ for the different analyses
# analysis_data_dir: where we should put analysis datasets (constant)
# output_dir: where we should save results (constant)
dir_prefix="/mnt/g"
dir="${dir_prefix}/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell"
raw_data_dir="${dir}"/PROGRAMMING/SAS\ Datasets/Replicate\ VUMC\ analysis/Sampling\ for\ Chart\ Review/Phenorm\ Symptomatic\ Covid-19\ update/
analysis_data_dir="${dir}/PheNorm/analysis_datasets/"
output_dir="${dir}/PheNorm/results/"

# mount the G: drive (in /mnt/g); modify this line if you are using a different system (or if you don't have to mount drives)
sudo mount -t drvfs G: /mnt/g
mkdir -p $analysis_data_dir
mkdir -p $output_dir
