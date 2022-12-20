#!/bin/bash

# run external COVID-19 PheNorm models at KPWA ---------------------------------
# this code can only be run after internal model building 
# (and hence data processing) has occurred locally

# project-specific setup
source phenorm_covid/00_covid19_phenorm_setup.sh

# ensure that required packages are installed by first running install_packages.sh

# for each analysis, do the following steps (external): ------------------------
for (( i=0; i<${n_analyses}; i++)); do
analysis="${analyses[$i]}"
    if [ $n_datasets -ge 2 ]; then
        data_name="${data_names[$i]}"
    else 
        data_name="${data_names[0]}"
    fi
    # get predictions on test data, plot results:
    echo "Obtaining results for analysis ${analysis}"
    Rscript phenorm_covid/03_get_results.R --data_dir "${analysis_data_dir}" --output_dir "${output_dir}" --analysis "$analysis" --data_site "${site}" --model_site "${external_site}" > "./${io_dir}/03_get_results_${analysis}_${site}_${external_site}.out" 2>&1
done