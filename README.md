![alt text](https://dev.sentinelsystem.org/projects/AP/repos/sentinel-analytic-packages/raw/resources/logo.png?at=refs%2Fheads%2Fmaster)

<br>

<div>

  <h2 align="center">IC FE2 Carrell Smith</h2>

  <h3 align="center">Sentinel Scalable NLP</h3>

</div>


Sentinel Scalable NLP is a collection of projects supported by the Sentinel Initiative that develop scalable, reusable methods and approaches to enhance the development of computable phenotype models with the aim of improving the overall efficiency and accuracy of Sentinel's automated phenotyping efforts. 

One of these projects, referred to as **High-Sensitivity Filter** implements a method for improving the sensitivity of filters used to identify patients (or healthcare events) that are candidates for phenotype modeling--an important first step in developing phenotype models where a set of relatively simple rules is used to identify candidate patients (or candidate events experienced by patients) for which phenotype status will eventually be predicted by a phenotype model, subsequently developed. When used, this high-sensitivity filtering approach may be able to identify additional candidates overlooked by a simple implementation of such a filter, thereby yielding improved sensitivity for identifying true phenotype cases at a reasonable expense in terms of the increase in sample size of the candidate pool. Since the method is largely data-driven, it is possible to implement high-sensitivity filtering with moderate effort. 

Another project, referred to as **Prediction Modeling**, implements a highly automated approach to developing models to determine whether a patient has experienced a particular health outcome of interest based heavily on information extracted from unstructured clinical chart notes. This automated and scalable approach to model development, referred to as the PheNorm approach.  The name PheNorm comes from the term "phenotype normalization," the goal of which is to both speed up the process of developing phenotype models and minimize operator dependence, which often accompanies manual approaches to feature engineering and model development.  Code and tools available in the Prediction Modeling project were developed while implementing the PheNorm method to model the phenotype “symptomatic COVID-19 disease” using data from two different healthcare settings.


## Prediction Modeling Quick Start

### Prerequisites

* SAS
* Python
  * Install `mml_utils` package
* MetaMap with MDR and RXNORM vocabularies
* R

### Steps

* Create the Anaphylaxis Cohort using [SAS code](High-Sensitivity-Filter/Programs)
* Process the corpus output by `04_CLinical_Text_for_NLP.sas` with `mml_utils` using [configuration files](Prediction-Modeling/Anaphylaxis/NLP/configs)
  * A step-by-step guide is provided in the [`mml_utils` documentation](https://github.com/kpwhri/mml_utils/tree/master/examples/phenorm)
* Run PheNorm using the [R code](Prediction-Modeling/)
  * If you are only applying the model, consider using the [Prenorm Predict repository](https://github.com/kpwhri/phenorm_predict) which contains only the necessary scripts to run an existing model.
