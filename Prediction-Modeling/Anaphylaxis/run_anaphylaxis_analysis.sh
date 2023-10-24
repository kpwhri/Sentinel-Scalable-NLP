# run anaphylaxis analysis

# install packages, if necessary
source PheNorm/00_install_packages.sh

# run setup file
source Anaphylaxis/anaphylaxis_phenorm_setup.sh

# get PheNorm predictions
source PheNorm/01_process_datasets.sh
source PheNorm/02_run_phenorm_internal.sh