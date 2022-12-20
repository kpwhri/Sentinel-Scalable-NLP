#!/bin/bash

# process datasets -------------------------------------------------------------

# project-specific setup
source phenorm_covid/00_covid19_phenorm_setup.sh

# ensure that required packages are installed by first running install_packages.sh

# for each analysis, do the following steps (internal): ------------------------
for (( i=0; i<${n_analyses}; i++)); do
    analysis="${analyses[$i]}"
    if [ $n_datasets -ge 2 ]; then
        data_name="${data_names[$i]}"
    else 
        data_name="${data_names[0]}"
    fi
    args=(
        --data_dir "${raw_data_dir}" --analysis_data_dir "${analysis_data_dir}" \
        --data_name "${data_name}" --analysis "$analysis" \
        --gold_label "${gold_label[$i]}" --valid_label "${valid_label}" \
        --study_id ${study_id} --utilization "${util_var}" --site "${site}"
    )
    if [[ ${analysis} =~ "non_negated" ]]; then
        args+=(--no_nonneg)
    fi
    if [ ${no_dimension_reduction} -ge 1 ]; then
        args+=(--no_afep)
    fi
    if [ ${no_nonnormalized_data} -ge 1 ]; then
        args+=(--no_nonnormalized)
    fi
    if [ ${no_normalized_data} -ge 1 ]; then
        args+=(--no_normalized)
    fi
    if [ ${train_on_gold_data} -ge 1 ]; then
        args+=(--train_on_gold)
    fi
    # process the dataset: 
    echo "Processing data for analysis ${analysis}"
    Rscript phenorm_covid/01_process_data.R "${args[@]}" > "./${io_dir}/01_process_data_${analysis}.out" 2>&1
    echo "Data processing for analysis ${analysis} complete"
done