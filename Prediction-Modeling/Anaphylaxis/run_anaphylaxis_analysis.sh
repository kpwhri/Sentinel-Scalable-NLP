# run anaphylaxis analysis

# install packages, if necessary
source ../PheNorm/00_install_packages.sh

# run setup file
source 00_anaphylaxis_phenorm_setup.sh

# drop unnecessary columns, columns with zero variance
echo "Preprocessing data for anaphylaxis analysis"
args=(
    --data-dir "${data_dir}" --analysis-data-dir "${data_dir}" \
    --data-name "${data_name}" --analysis "${analysis_name}" \
    --gold-label "${gold_label}" --valid-label "${valid_label}" \
    --study-id ${study_id} --utilization "${util_var}"  \
    --weight ${weight_var}
)
Rscript 00_project-specific_preprocessing.R "${args[@]}" > "./${io_dir}/00_preprocess_data_${analysis_name}.out" 2>&1

# get PheNorm predictions
source 01_process_datasets.sh
source 02_run_phenorm_internal.sh