#!/bin/bash

# process datasets -------------------------------------------------------------

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
        --data-dir "${data_dir}" --analysis-data-dir "${analysis_data_dir}" \
        --data-name "${data_name}" --analysis "$analysis" \
        --gold-label "${gold_label_arry[$i]}" --valid-label "${valid_label}" \
        --study-id ${study_id} --utilization "${util_var}"  \
        --weight ${weight_var} --site "${site}" --cui "${cui_of_interest}" \
        --train-value ${train_value} --nonneg-label ${nonneg_label}
    )
    if [[ ${use_negation} -ge 1 ]]; then
        args+=(--use-nonneg)
    else 
        args+=(--no-nonneg)
    fi
    if [ ${use_dimension_reduction} -ge 1 ]; then
        args+=(--use-afep)
    else
        args+=(--no-afep)
    fi
    if [ ${use_nonnormalized_data} -ge 1 ]; then
        args+=(--use-nonnormalized)
    else 
        args+=(--no-nonnormalized)
    fi
    if [ ${use_normalized_data} -ge 1 ]; then
        args+=(--use-normalized)
    else
        args+=(--no-normalized)
    fi
    if [ ${train_on_gold_data} -ge 1 ]; then
        args+=(--train-on-gold)
    fi
    # process the dataset: 
    echo "Processing data for analysis ${analysis}"
    Rscript 01_process_data.R "${args[@]}" > "./${io_dir}/01_process_data_${analysis}.out" 2>&1
    echo "Data processing for analysis ${analysis} complete"
done