# Prediction-Modeling

This folder contains the code necessary to run phenotyping models using PheNorm. 

The `phenorm_covid` subdirectory contains a further README file with instructions on how to run the COVID-19 analyses.

The `phenorm_anaphylaxis` subdirectory contains a further README file with instructions on how to run the anaphylaxis analysis.

The code is designed to be run from the command line (Unix-style; you can also use Windows Subsystem for Linux on a Windows computer) or interactively from an `R` console (or `RStudio`). The input data can either include both counts of all mentions *and* counts of non-negated mentions, or can include only one of these two -- based on an argument specified in the data processing step, only one of the sets of NLP variables is included for analysis.

The remainder of this document is organized as follows:
* Requirements: system-level requirements for running the code.
* Dataset requirements: a discussion of the dataset that the code expects.
* Contents: a brief description of the code in this directory.
* Running the analysis: a high-level overview of how to run various steps in the analysis.

## Requirements

### Required software

The code is run in `R` (version >= 4.0.2). Other necessary software includes the necessary software for installing R source packages (Rtools on Windows; Tcl/Tk libraries, Texinfo, and GNU Fortran for Mac. See the respective "R for X" page on [CRAN](https://cran.r-project.org/) for more information).

### Required input data format

The input dataset must contain one row per independent unit (e.g., patient or encounter) and columns corresponding to the outcome variable of interest, NLP variables, and other variables. An analysis consists of the following core components:
1. A variable designating the study id for each independent unit
2. The outcome of interest (e.g., symptomatic COVID-19)
3. A variable designating the training and testing sets
4. A variable designating the inverse probability of sampling weights (into the evaluation/testing set) (if not entered, assumed to be the same for all participants [i.e., set to 1])
5. A variable designating "healthcare system utilization" (if not entered, assumed to be the same for all participants [i.e., set to 1])
6. A collection of silver labels
7. A collection of structured data features to adjust for
8. A collection of NLP variables to adjust for

The project-agnostic code below assumes that only these relevant variables are entered. If, for example, there is a single "raw" dataset containing all outcomes of interest, many silver labels, and features that are extraneous for a given analysis, these *must be removed* prior to running the analysis of interest. Project-specific code is available below to modify to meet these needs. 

All covariates must be coded as numeric values. For example, if a variable corresponding to "Sex assigned at birth" is included with possible categories "Male" and "Female", then one category should be assigned the value 1 and the other category should be assigned the value 0. In other words, any binary/dichotomous variables should be coded as 0/1, rather than using character values.

There are several key variables that must be present in the dataset and by default should be named in the following way:
* `PTYPE_POSITIVE`: a binary (0/1) indicator of phenotype positive status (`NA` for observations for which chart review to determine phenotype status was not done). This is the gold label. 
* `Train_Eval_Set`: the indicator of sampling into the gold-label set (1 if included in the gold label set, 0 otherwise)
* `Studyid`: the studyid
* `Utiliz`: a variable describing utilization (for PheNorm). If not included, set to 1 for all observations
* `Sampling_Weight`: the sampling weights for each participant's probability of inclusion into the gold-standard sample. Can be set to 1 for all participants, in which case the sample is assumed to be a simple random sample.
* Silver labels should contain the string `silver_` as a prefix.

(advanced users may change these variable names, but the proper command-line arguments must be modified accordingly)

### Required R packages

`00_install_packages.R` installs the necessary packages for these analyses. They are:
* `optparse`: allows parsing of command-line arguments
* `here`: relative directory parsing
* `PheNorm`: fit PheNorm
* `ROCR`: obtain prediction performance for binary outcomes
* `WeightedROC`: obtain weighted prediction performance for binary outcomes, with weights necessary in studies that did not use a simple random sample
* `tidyverse`: various packages for nice data wrangling and plotting
* `cowplot`: nice plotting

This file can be run using `00_install_packages.sh` or can be run interactively, and should only need to be run once so long as your version of R has not changed.

## Running the analysis

A full analysis consists of three steps:
1. Processing analytic datasets (splitting into testing and training, extracting outcomes and other relevant variables).
2. Internal model training and evaluation: train the PheNorm model on site-specific data (e.g., data from Kaiser Permanente Washington (KPWA)), and evaluate this PheNorm model on data from the same site.
3. External model evaluation: predict on data from the site (e.g., from KPWA) using the model trained in step 2 at another site (e.g., from Vanderbilt University Medical Center (VUMC)).

Each step is described further in the sections below. If you are running the code from the command line, each shell script (file ending in `.sh`) must first be made executable; this can be accomplished using, e.g.,
```
chmod u+x *.sh
```

### 0: Generally-useful functions

`00_utils.R` contains functions that are useful across several files in the analysis pipeline. Important functions include:
* `run_phenorm`: obtains a fitted PheNorm object and predictions
* `phenorm_afep`: implement AFEP variable selection (based on univariate correlation with the CUI of interest)
* `get_performance_metrics`: obtain all prediction performance metrics
* `phenorm_prob`: an implementation of PheNorm that returns objects required for making predictions
* `predict.PheNorm`: a prediction method implemented for a PheNorm object

### 1: Processing the dataset

Though the dataset will be in the correct format following step 0 above (i.e., one row per independent unit, columns correspond to variables of interest), several processing steps occur in `01_process_data.R`:
* setting up training and testing sets
* performing AFEP screening, if requested
* log transforming all datasets
* computing summary statistics

Running this code results in a `.rds` file with a name specified by the argument `analysis`. The `.rds` file is a list containing the necessary components for prediction. This code can be run from the command line on a Unix machine using `01_process_datasets.sh`.

### 2: Internal model training (Running PheNorm)

The file `02_run_phenorm.R` runs a PheNorm analysis on the training data created in the previous step and obtains predicted probabilities on the test set. The input to this file is the result from `01_process_data.R`. Running `02_run_phenorm.R` results in a `.rds` file with a name specified by the argument `analysis`.

### 3: Internal model evaluation (Obtaining prediction performance)

The file `03_get_results.R` reads in the results of both `01_process_data.R` and `02_run_phenorm.R` to obtain prediction performance of the PheNorm algorithm on the test data. Plots and tables are output as a result of running this file; these are placed in a directory specified by `output-dir`.

## 4: Internal model evaulation (Obtaining predicted probabilities)

Finally, the file `04_get_predicted_probabilities.R` obtains predicted probabilities on the entire dataset (both training and testing).

## 5: External model evaluation (optional)

If there is an external evaluation site (e.g., the PheNorm model was trained in step 2 on data from KPWA and it is an analysis goal to evaluate its performance on data from VUMC), then the file `03_get_results.R` can be run again, with the argument `--data-site` changed to be the external site (e.g., VUMC).

## Running the entire analysis

The entire analysis can be run from the command line using `run_analysis.sh`. This file contains bash code that will run an entire PheNorm from the command line. This file also serves as a reference for interactive `R` sessions -- it specifies the values that you will need to change defaults to, as outlined below. You can also run each of the consituent bash scripts referenced above in order.

If you prefer to run `R` in an interactive session, use the following steps (changing the defaults to match those used in `run_analysis.sh`, but relative to your computer/filesystem):
1. "source" `00_install_packages.R`
2. Run `01_process_data.R`. Change the defaults for `data_dir`, `data_name`, `site`, `analysis`, and `use_afep` to match your computer/filesystem and the given analysis.
3. Run `02_run_phenorm.R`. Change the defaults for `data_dir`, `output_dir`, `site`, and `analysis` to match your filesystem and the given analysis.
4. Run `03_get_results.R`. Change the defaults for `data_dir`, `output_dir`, `data_site`, `model_site`, and `analysis` to match your filesystem and the given analysis. In this run, `data_site` and `model_site` should be the same.
5. Run `04_get_results.R`. Change the defaults for `data_dir`, `output_dir`, `data_site`, `model_site`, and `analysis` to match your filesystem and the given analysis. In this run, `data_site` and `model_site` should be the same.
6. Once you obtain the external model file (e.g., from VUMC if KPWA is the data site), run `03_get_results.R` again, changing the defaults for `data_dir`, `output_dir`, `data_site`, `model_site`, and `analysis` to match your filesystem and the given analysis. In this run, `data_site` and `model_site` should be different.