
# Anaphylaxis

The folder documents a subproject which used the PheNorm process in order to identify individuals with anaphylaxis.

## Prerequisites

To replicate or use the process described here, you will need:

* Python 3.10+ (for AFEP and NLP)
  * mml_utils package: https://github.com/kpwhri/mml_utils
* R (for PheNorm prediciton modeling)
  * See required packages in [Prediction-Modeling](../Prediction-Modeling/Anaphylaxis/README.md)
* Metamap
  * For text processing (`mml_utils` will generate the relevant shell scripts)
* SAS

## Usage

1. Downloaded and cleaned articles from Mayo, Medline, Medscape, Merck, and Wikipedia (see [articles](AFEP/articles)).
2. Run exploration of possible parameters, and select the best CUI output (see [build_afep_multi](AFEP/configs/build_afep_multi.toml)).
   * Place the output selected CUIs into a file with one CUI per line (see [example from our work](NLP/cuis.txt))
3. Identify corpus using method described in SAS files [here](https://github.com/kpwhri/Sentinel-Scalable-NLP/tree/master/High-Sensitivity-Filter/Programs)
   * Run the SAS code in the enumerated order (from 01 - 05)
4. Now that the CUIs have been identified, extract these CUIs from the entire corpus
   * Use [run_mm_on_corpus.toml](NLP/configs/run_mm_on_corpus.toml) to generate Metamap shell scripts
   * Run Metamap using these scripts
   * Extract the desired CUIs from the Metamap output using [extract_mml](NLP/configs/extract_mml.conf)
5. Using these outputs, run PheNorm using the include R package ([documented here](../phenorm_anaphylaxis))

## AFEP 

The AFEP folder documents the 'Automated Feature Extraction for Phenotyping' process using Metamap. This process uses a set of knowledge base articles (e.g., Wikipedia, Medscape, etc.) to reduce the number of relevant CUIs.

## NLP

The NLP folder documents the actual extraction from clinical notes of the CUIs identified through the AFEP process.

## PheNorm

### Anaphylaxis PheNorm Analyses

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
