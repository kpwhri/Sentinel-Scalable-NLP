#!/bin/bash

# preprocess datasets ----------------------------------------------------------
# this runs R code that may have to be edited, unless your dataset for analysis
# already meets the specifications.

# project-specific setup
source phenorm_covid/00_covid19_phenorm_setup.sh

# ensure that required packages are installed by first running install_packages.sh

# for each analysis, do the following steps (internal): ------------------------
for (( i=0; i<${n_analyses}; i++)); do
    analysis="${analyses[$i]}"
    args=(
        --data-dir "${raw_data_dir}" --analysis-data-dir "${raw_data_dir}" \
        --data-name "${raw_data_name}" --analysis "$analysis" \
        --gold-label "${gold_label[$i]}" --valid-label "${valid_label}" \
        --study-id ${study_id} --utilization "${util_var}"  \
        --weight ${weight_var} --site "${site}"
    )
    # process the dataset: 
    echo "Preprocessing data for analysis ${analysis}"
    Rscript phenorm_covid/00_project_specific_preprocessing.R "${args[@]}" > "./${io_dir}/00_preprocess_data_${analysis}.out" 2>&1
    echo "Data preprocessing for analysis ${analysis} complete"
done