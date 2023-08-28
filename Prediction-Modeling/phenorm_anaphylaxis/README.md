# Anaphylaxis PheNorm Analyses

The anaphylaxis PheNorm analysis can be run by making minor modifications to the file `../00_setup.sh`, or equivalently, by running the individual `R` scripts with the appropriate arguments changed.

Your working directory should be one level higher than this directory (i.e., should be `<replace with path to Sentinel-Scalable-NLP>/Prediction-Modeling/`).

Once you have a dataset that meets the requirements detailed in `../README.md`, you can proceed by editing the following lines of `../00_setup.sh`:
* Line 7: define the CUI of interest for anaphylaxis (`"C0002792"`)
* Line 9: define the development site (e.g., `"vumc"` or `"kpwa"`)
* Line 10: define the external validation site, if any
* Line 14: define the analysis name (e.g., "phenorm_anaphylaxis")
* Line 16: define your working directory (`"<replace with path to Sentinel-Scalable-NLP>/Prediction-Modeling/"`)
* Line 18: define the directory where the data are located
* Line 20: define a random number seed (or leave at the default value)

Then, either run the analysis from the command line (using, e.g., `run_analysis.sh`) or interactively, using the steps outlined in the main directory `README` file.

