#!/bin/bash

# run internal COVID-19 PheNorm models at KPWA ---------------------------------

# project-specific setup
source phenorm_covid/00_covid19_phenorm_setup.sh

# ensure that required packages are installed by first running install_packages.sh

# for each analysis, do the following steps (internal): ------------------------
for (( i=0; i<${n_analyses}; i++)); do
    analysis="${analyses[$i]}"
    seed="${rng_seeds[$i]}"
    if [ $n_datasets -ge 2 ]; then
        data_name="${data_names[$i]}"
    else 
        data_name="${data_names[0]}"
    fi
    # run PheNorm on the training data:
    echo "Running PheNorm for analysis ${analysis}"
    Rscript phenorm_covid/02_run_phenorm.R --data-dir "${analysis_data_dir}" --output-dir "${output_dir}" --analysis "$analysis" --seed $seed --utilization ${util_var} --weight ${weight_var} --corrupt-rate ${corrupt_rate} --train-size-multiplier ${train_size_mult} --site "${site}" > "./${io_dir}/02_run_phenorm_${analysis}.out" 2>&1
    # get predictions on test data, plot results:
    echo "Obtaining internal validation results for analysis ${analysis}"
    Rscript phenorm_covid/03_get_results.R --data-dir "${analysis_data_dir}" --output-dir "${output_dir}" --analysis "$analysis" --data-site "${site}" --model-site "${site}" > "./${io_dir}/03_get_results_${analysis}.out" 2>&1
    # get predictions on entire dataset
    echo "Obtaining predicted probabilities on entire dataset for analysis ${analysis}"
    Rscript phenorm_covid/04_get_predicted_probabilities.R --data-dir "${analysis_data_dir}" --output-dir "${output_dir}" --analysis "$analysis" --data-site "${site}" --model-site "${site}" > "./${io_dir}/04_get_predprobs_${analysis}.out" 2>&1
    echo "Model training and internal results for analysis ${analysis} complete"
done