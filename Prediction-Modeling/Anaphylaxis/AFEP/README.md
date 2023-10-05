
# AFEP

## Prerequisites

* Install Metamap
  * Download UMLS NLM subset
* Install Python 3.10+
  * Install `mml_utils` package

## Usage

To perform the Automated Feature Extraction for Phenotyping (AFEP):

1. Downloaded and cleaned articles from Mayo, Medline, Medscape, Merck, and Wikipedia (see [articles](articles)).
2. Run exploration of possible parameters, and select the best CUI output (see [build_afep_multi](configs/build_afep_multi.toml)).