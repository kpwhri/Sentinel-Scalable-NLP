
# Anaphylaxis

The folder documents a subproject which used the PheNorm process in order to identify individuals with anaphylaxis.

## Prerequisites

To replicate or use the process described here, you will need:

* Python 3.10+ (for AFEP and NLP)
  * mml_utils package: https://github.com/kpwhri/mml_utils
* R (for PheNorm prediciton modeling)
  * See required packages in [Prediction-Modeling](../Prediction-Modeling/phenorm_anaphylaxis/README.md)
* Metamap
  * For text processing (`mml_utils` will generate the relevant shell scripts)

## Usage

1. Downloaded and cleaned articles from Mayo, Medline, Medscape, Merck, and Wikipedia (see [articles](AFEP/articles)).
2. Run exploration of possible parameters, and select the best CUI output (see [build_afep_multi](AFEP/configs/build_afep_multi.toml)).
  * Place the output selected CUIs into a file with one CUI per line (see [example from our work](NLP/cuis.txt))
3. Now that the CUIs have been identified, extract these CUIs from the entire corpus
   * Use [run_mm_on_corpus.toml](NLP/configs/run_mm_on_corpus.toml) to generate Metamap shell scripts
   * Run Metamap using these scripts
   * Extract the desired CUIs from the Metamap output using [extract_mml](NLP/configs/extract_mml.conf)
4. Using these outputs, run PheNorm using the include R package ([documented here](../Prediction-Modeling/phenorm_anaphylaxis))

## AFEP 

The AFEP folder documents the 'Automated Feature Extraction for Phenotyping' process using Metamap. This process uses a set of knowledge base articles (e.g., Wikipedia, Medscape, etc.) to reduce the number of relevant CUIs.

## NLP

The NLP folder documents the actual extraction from clinical notes of the CUIs identified through the AFEP process.

## PheNorm

Complete documentation is available in the [Prediction-Modeling](../Prediction-Modeling/phenorm_anaphylaxis/README.md) subdirectory, along with relevant R code.


