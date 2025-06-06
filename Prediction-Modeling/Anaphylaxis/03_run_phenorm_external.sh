#!/usr/bin/env bash

# run external PheNorm models --------------------------------------------------
# this code can only be run after internal model building 
# (and hence data processing) has occurred locally

# ensure that required packages are installed by first running install_packages.sh

# for each analysis, do the following steps (external): ------------------------
for (( i=0; i<${n_analyses}; i++)); do
    analysis="${analyses[$i]}"
    seed="${rng_seeds[$i]}"
    if [ $n_datasets -ge 2 ]; then
        data_name="${data_names[$i]}"
    else 
        data_name="${data_names[0]}"
    fi
    # get predictions on test data, plot results:
    echo "Obtaining external validation results for analysis ${analysis}"
    Rscript 03_get_results.R --data-dir "${analysis_data_dir}" --output-dir "${output_dir}" --analysis "$analysis" --weight ${weight_var} --data-site "${site}" --model-site "${external_site}" --seed "${seed}"  > "./${io_dir}/03_get_results_${analysis}_${site}_${external_site}.out" 2>&1
    echo "External results for analysis ${analysis} complete"
done