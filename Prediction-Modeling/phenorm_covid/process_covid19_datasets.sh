#!/bin/bash

# process datasets -------------------------------------------------------------

# project-specific setup
source phenorm_covid/covid19_phenorm_setup.sh

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
    if [ ${use_dimension_reduction} -ge 1 ]; then
        args+=(--use_afep)
    fi
    if [ ${use_nonnormalized_data} -ge 1 ]; then
        args+=(--use_nonnormalized)
    fi
    if [ ${use_normalized_data} -ge 1 ]; then
        args+=(--use_normalized)
    fi
    if [ ${train_on_gold_data} -ge 1 ]; then
        args+=(--train_on_gold)
    fi
    # process the dataset: 
    echo "Processing data for analysis ${analysis}"
    Rscript phenorm_covid/01_process_data.R "${args[@]}" > "./${io_dir}/01_process_data_${analysis}.out" 2>&1
    # Rscript phenorm_covid/01_process_data.R --data_dir "${raw_data_dir}" --analysis_data_dir "${analysis_data_dir}" --data_name "${data_name}" --analysis "$analysis" --gold_label "${gold_label[$i]}" --valid_label "${valid_label}" --study_id ${study_id} --utilization "${util_var}" --site "${site}" > "./${io_dir}/01_process_data_${analysis}.out" 2>&1
done