# COVID-19 PheNorm Analyses

This document specifies the code used to run the COVID-19 PheNorm analyses. For further information, please see the analysis plan on Google Drive (https://docs.google.com/document/d/1oX5tDAi6h8QYVma0UHcFp_chTggYNY50Dqth8aoby6Y/edit#heading=h.1xu099earfks).

The code is designed to be run from the command line (Unix-style; you can also use Windows Subsystem for Linux on a Windows computer) or interactively from an `R` console (or `RStudio`). The input data can either include both counts of all mentions *and* counts of non-negated mentions, or can include only one of these two -- based on an argument specified in the data processing step, only one of the sets of NLP variables is included for analysis.

The remainder of this document is organized as follows:
* Requirements: system-level requirements for running the code.
* Dataset requirements: a discussion of the dataset that the code expects.
* Contents: a brief description of the code in this directory.
* Running the analysis: a high-level overview of how to run various steps in the analysis.
* Example: a fully-specified example of how to run the code when KPWA data are used to evaluate model performance.

## Requirements

The code is run in `R` (version >= 4.0.2). The code expects your working directory to be one level higher than the folder `phenorm_covid`, which is the location of all code (specified in the next section). All file paths within the code are relative to this directory. Code filepaths should not need to be changed on a computer-by-computer basis, but paths to data *will* need to be changed between KPWA and VUMC. The input data paths are arguments passed to the `R` code.

The code requires the following `R` packages:
* `optparse`: for parsing command-line arguments, available on CRAN. (version >= 1.7.3)
* `PheNorm`: the PheNorm functions, available on CRAN. (version >= 0.1.0)
* `ROCR`: functions for assessing prediction performance, available on CRAN.  (version >= 1.0-11)
* `WeightedROC`: functions for assessing weighted prediction performance, available on CRAN. (version >= 2020.1.31)
* `tidyverse`: convenient packages for data wrangling and plotting. (version >= 1.3.2)
* `cowplot`: nice package for plotting. (version >= 1.1.1)

You can install the latest version of all packages by running `00_install_packages.R` (either from the command line or interactively). If the command-line code terminates with an error at this step, check to make sure that you have the software installed that is necessary to install R source packages (Rtools on Windows; Tcl/Tk libraries, Texinfo, and GNU Fortran for Mac. See the respective "R for X" page on CRAN for more information).

## Dataset requirements

The input dataset must contain one row per patient and columns corresponding to the analysis of interest. An analysis consists of the following core components:
1. A variable designating the study id for each patient
2. The outcome of interest (e.g., symptomatic COVID-19)
3. A variable designating the training and testing sets
4. A variable designating the inverse probability of sampling weights (into the evaluation/testing set) (if not entered, assumed to be the same for all participants [i.e., set to 1])
5. A variable designating "healthcare system utilization" (if not entered, assumed to be the same for all participants [i.e., set to 1])
6. A collection of silver labels
7. A collection of structured data features to adjust for
8. A collection of NLP variables to adjust for

The project-agnostic code below assumes that only these relevant variables are entered. If, for example, there is a single "raw" dataset containing all outcomes of interest, many silver labels, and features that are extraneous for a given analysis, these *must be removed* prior to running the analysis of interest. Project-specific code is available below to modify to meet these needs. 

Additionally, any binary/dichotomous variables should be coded as 0/1, rather than using character values.

## Contents of the `phenorm_covid` folder

The main code to run the analysis is in the following files:
* `phenorm_utils.R`: functions that are useful throughout the PheNorm analysis, including the AFEP screen and the prediction function.
* `00_install_packages.R`: installs required packages listed above.
* `00_project_specific_preprocessing.R`: Project-specific preprocessing to meet the dataset requirements for the specified analysis (combination of outcome, silver labels, structured data features, and NLP variables). _This file may have to be edited between phenotypes, if the input dataset does not conform to the required specifications_.
* `01_process_data.R`: input a dataset with structured and/or NLP variables, including silver labels; return training and testing analysis datasets. In this step, the following analysis options may be used: incorporating negation (default: no), using a normalized version of the NLP variables (default: no), and incorporating dimension reduction in the NLP variables using AFEP screening (default: no). 
* `02_run_phenorm.R`: input the training and testing datasets; return the fitted PheNorm model (from the training data) and the predictions (on the testing data).
* `03_get_results.R`: input the PheNorm model and predictions and the true (gold-standard) outcomes; return plots and tables describing prediction performance.
* `04_get_predicted_probabilities.R`: input the PheNorm model and the entire dataset; return datasets (.csv files) with study id and predicted probabilities.
* `run_all_covid19_phenorm.sh`: run all KPWA data-based analyses (i.e., KPWA is the data site; the external model site is VUMC). Calls the following in turn:
    * `00_covid19_phenorm_setup.sh`: system-specific environment variables _(this will have to be changed for each person running code, based on your computer's filesystem)_.
    * `00_install_packages.sh`: only needs to be run a single time. Installs R packages.
    * `00_preprocess_covid19_dataset.sh`: only needs to be run once per (outcome, set of features/silver labels) combination. Does project-specific preprocessing so that downstream datasets follow the specifications outlined in the previous section.
    * `01_process_covid19_datasets.sh`: creates analysis datasets for the analyses of interest.
    * `02_run_covid19_phenorm_internal.sh`: run all internal PheNorm model building and evaluation analyses.
    * `03_run_covid19_phenorm_external.sh`: run all external PheNorm model evaluation analyses. Requires PheNorm model trained at an external site (e.g., VUMC if the evaluation site is KPWA).

## Running the analysis

To run the analyses, you should run `R` one level higher than the folder `phenorm_covid`. The analysis consists of three steps:
1. Processing analytic datasets (splitting into testing and training, extracting outcomes and other relevant variables).
2. Internal model training and evaluation: train the PheNorm model on site-specific data (e.g., data from KPWA), and evaluate this PheNorm model on data from the same site.
3. External model evaluation: predict on data from the site (e.g., from KPWA) using the model trained in step 2 at another site (e.g., from VUMC).

The file `run_all_covid19_phenorm.sh` contains bash code that will run all of the COVID-19 PheNorm analyses from the command line. This file also serves as a reference for interactive `R` sessions -- it specifies the values that you will need to change defaults to, as I outline below. You can also run each of the consituent bash scripts referenced above in order.

If you prefer to run `R` in an interactive session, use the following steps (changing the defaults to match those used in `run_all_covid19_phenorm.sh`, but relative to your computer/filesystem):
1. "source" `00_install_packages.R`
2. Run `00_project_specific_preprocessing.R`. Change the defaults as necessary.
2. Run `01_process_data.R`. Change the defaults for `data_dir`, `data_name`, `site`, `analysis`, and `use_afep` to match your computer/filesystem and the given analysis.
3. Run `02_run_phenorm.R`. Change the defaults for `data_dir`, `output_dir`, `site`, and `analysis` to match your filesystem and the given analysis.
4. Run `03_get_results.R`. Change the defaults for `data_dir`, `output_dir`, `data_site`, `model_site`, and `analysis` to match your filesystem and the given analysis. In this run, `data_site` and `model_site` should be the same.
5. Run `04_get_results.R`. Change the defaults for `data_dir`, `output_dir`, `data_site`, `model_site`, and `analysis` to match your filesystem and the given analysis. In this run, `data_site` and `model_site` should be the same.
6. Once you obtain the external model file (e.g., from VUMC if KPWA is the data site), run `03_get_results.R` again, changing the defaults for `data_dir`, `output_dir`, `data_site`, `model_site`, and `analysis` to match your filesystem and the given analysis. In this run, `data_site` and `model_site` should be different.

## Example: running the phase 1 enhanced symptomatic COVID-19 analysis on a KPWA filesystem

In this section, we provide the arguments used to run the PheNorm analyses for the symptomatic COVID-19 outcome using the enhanced phase 1 predictor set on a KPWA filesystem. We assume that you have already "source"d `00_install_packages.R` and therefore have access to all of the required `R` packages. The default values listed below are also provided in `run_all_covid19_phenorm.sh`.

To train the PheNorm models and obtain internal model training and evaluation results, run `run_all_covid19_phenorm.sh`, which you can run using 

```
chmod u+x phenorm_covid/run_all_covid19_phenorm.sh
./phenorm_covid/run_all_covid19_phenorm.sh
```

Note that package install and project-specific data preprocessing (step 0), analysis dataset creation (step 1), and internal model building and evaluation (step 2) will complete without the need for an externally-trained model to be provided. External model evaluation (step 3) will fail unless an externally-trained model is available. Once both sites (KPWA and VUMC) have trained their PheNorm models and sent the models to the opposite site, obtain plots and tables with external model evaluation results by running `03_run_phenorm_external.sh`. Be sure to save the external model in the same folder as the corresponding internally-trained models for the analysis of interest.

Alternatively, you can use the following steps (each step is run twice, once for NLP variables based on all mentions and once for NLP variables based only on non-negated mentions):
1. Process the datasets: 
    1. `Rscript phenorm_covid/01_process_data.R --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PROGRAMMING/SAS Datasets/Replicate VUMC Analysis/Sampling for Chart Review/Phenorm Symptomatic Covid-19 update/" --analysis_data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --data_name "COVID_PheNorm_N8329_12DEC2022.csv" --analysis "phase_1_enhanced_symptomatic_covid_all_mentions" --gold_label "PTYPE_SYMPTOMATIC_POSITIVE" --valid_label "Train_Eval_Set" --study_id "Studyid" --utilization "Utiliz" --use_afep TRUE --use_nonneg FALSE --site "kpwa"`
    2. `Rscript phenorm_covid/01_process_data.R --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PROGRAMMING/SAS Datasets/Replicate VUMC Analysis/Sampling for Chart Review/Phenorm Symptomatic Covid-19 update/" --analysis_data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --data_name "COVID_PheNorm_N8329_12DEC2022.csv" --analysis "phase_1_enhanced_symptomatic_covid_non_negated" --gold_label "PTYPE_SYMPTOMATIC_POSITIVE" --valid_label "Train_Eval_Set" --study_id "Studyid" --utilization "Utiliz" --use_afep TRUE --use_nonneg TRUE --site "kpwa"`
2. Run PheNorm on the training data and get predictions on the test data: (note that each call to the `R` script results in a model and predictions for each individual silver label *and* the aggregate predictor [the average of all silver-label-specific models])
    1. `Rscript phenorm_covid/02_run_phenorm.R --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --output_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/results/" --analysis "phase_1_enhanced_symptomatic_covid_all_mentions" --site "kpwa"`
    2. `Rscript phenorm_covid/02_run_phenorm.R --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --output_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/results/" --analysis "phase_1_enhanced_symptomatic_covid_non_negated" --site "kpwa"`
3. Obtain plots and tables with internal model training and evaluation results:
    1. `Rscript phenorm_covid/03_get_results.R --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --output_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/results/" --analysis "phase_1_enhanced_symptomatic_covid_all_mentions" --data_site "kpwa" --model_site "kpwa"`
    2. `Rscript phenorm_covid/03_get_results.R --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --output_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/results/" --analysis "phase_1_enhanced_symptomatic_covid_non_negated" --data_site "kpwa" --model_site "kpwa"`
4. Once both sites (KPWA and VUMC) have trained their PheNorm models and sent the models to the opposite site, obtain plots and tables with external model evaluation results:
    1. `Rscript phenorm_covid/03_get_results.R --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --output_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/results/" --analysis "phase_1_enhanced_symptomatic_covid_all_mentions" --data_site "kpwa" --model_site "vumc"`
    2. `Rscript phenorm_covid/03_get_results.R --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --output_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/results/" --analysis "phase_1_enhanced_symptomatic_covid_non_negated" --data_site "kpwa" --model_site "vumc"`
5. Get predicted probabilities for the entire sample:
    1. `Rscript phenorm_covid/04_get_predicted_probabilities --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --output_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/results/" --analysis "phase_1_enhanced_symptomatic_covid_all_mentions" --data_site "kpwa" --model_site "kpwa"`
    2. `Rscript phenorm_covid/04_get_predicted_probabilities --data_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/PheNorm/analysis_datasets/" --output_dir "G:/CTRHS/Sentinel/Innovation_Center/NLP_COVID19_Carrell/results/" --analysis "phase_1_enhanced_symptomatic_covid_non_negated" --data_site "kpwa" --model_site "kpwa"`

## Using other specifications

In the default analysis, we used the following specifications:
1. Incorporate negation in NLP features: no
2. Use normalized NLP features: no (only use non-normalized NLP data)
3. Use dimension reduction: no
3. Train on observations with gold labels (but don't look at gold labels): no

These specifications can be changed by changing the value of the following variables in `00_covid19_phenorm_setup.sh`:
1. `use_negation`: set to 1 to incorporate negation
2. `use_dimension_reduction`: set to 1 to use dimension reduction
3. `use_normalized_data`: set to 1 (and set `use_nonnormalized_data` to 0) to use only normalized NLP features
4. `train_on_gold_data`: set to 1 to use observations with gold labels in training

_These flags will automatically create new output directories to save files in. When incorporating externally-developed models, be sure to save the models in the directory corresponding to the correct analysis._