
<div>

  <h2 align="center">IC FE2 Carrell Smith</h2>

  <h3 align="center">Sentinel Scalable NLP</h3>

  <p>
    Sentinel Scalable NLP is a collection of projects supported by the Sentinel Initiative that develop scalable, reusable methods and approaches to enhance the development of computable phenotype models with the aim of improving the overall efficiency and accuracy of automated phenotyping efforts. One of these projects implements a method for improving the sensitivity of filters used to identify patients (or healthcare events) that are candidates for phenotype modeling--an important first step in developing phenotype models where a set of relatively simple rules is used to identify candidate patients (or candidate events experienced by patients) for which phenotype status will eventually be predicted by a phenotype model, subsequently developed. When used, this high-sensitivity filtering approach may be able to identify additional candidates overlooked by a simple implementation of such a filter, thereby yielding improved sensitivity for identifying true phenotype cases at a reasonable expense in terms of the increase in sample size of the candidate pool. We refer to this method as "high-sensitivity filtering."  Since the method is largely data-driven, it is possible to implement high-sensitivity filtering with moderate effort. 
  </p>
</div>


## Table of Contents

* [About the Project](#about-the-project)
* [Getting Started](#getting-started)
  * [Prerequisites](#prerequisites)
* [Usage](#usage)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [License](#license)
* [Contact](#contact)
* [Acknowledgements](#acknowledgements)

<!-- ABOUT THE PROJECT -->
## About The Project

This project currently documents the high-sensitivity filtering method to improve the sensitivity of filtering rules used as the first step in developing an automated phenotype model.  Eventually, this project will also document an automated approach to developing a phenotype model itself (i.e., a model that predicts which of the candidates is a true phenotype case and which are not). 

<!-- GETTING STARTED -->
## Getting Started

There is one folder for each project documented here.  Currently there is one project:

1. High Sensitivity Filter
   * [Instructions](High-Sensitivity-Filter/README.md)
2. Prediction-Modeling: R code for running PheNorm
3. Anaphylaxis: Applying to Anaphylaxis

### Prerequisites

In general, components of this project have been used/tested with:
* SAS version 9.4+
* Structured healthcare data organized according to the Sentinel Common Data Model (or any other comparable "flat file" formatted collection of structured healthcare data)
* Excel (or comparable spreadsheet software used to display data in a tabular format)


<!-- USAGE EXAMPLES -->
## Usage

See the contents of folder "High-Sensitivity-Filter" for code used to implement the high-sensitivity filtering approach.

Though it can be applied to any health-related phenotype documented by diagnosis, procedure, or medication codes, we developed and applied the high-sensitivity filtering (HSF) method to improve filtering of patients who may have symptomatic COVID-19 infection. Traditionally, a filtering rule to identify candidates for this phenotype would be patients (or patient encounters) coded with an International Classification of Disease, 10th Revision (ICD-10) diagnosis code for COVID-19 (i.e., the ICD-10 code U07.1 "COVID-19"). Briefly, the HSF method uses SAS code and structured healthcare data for a large collection of patients and encounters to investigate other healthcare codes -- including diagnoses other than U07.1, medical procedure codes, and medication codes -- that co-occur with the traditional filter (ICD-10 U07.1) and may thereby be used to identify surrogate codes for the traditional filter, U07.1. The method summarizes these co-occurrences in a tabular format, separately for each type of coded data (e.g., separately for diagnoses, procedures, medications) allowing them to be easily and rapidly manually reviewed by a clinical expert.  This manual review yields a set of codes that 1) have clinical face validity, 2) are much more likely to appear in the charts of patients with the phenotype in question (e.g., COVID-19) than patients without, and 3) if used as an additional filtering criterion (considered individually), would modestly increase the size of the sample of candidate patients/events. As described in a poster titled "DATA-DRIVEN APPROACHES TO IMPROVE PHENOTYPE SENSITIVITY USING EHR DATA," presented at the 2022 ICPE conference in Copenhagen in August 2022, when applying the HSF method in an effort to identify patients with COVID-19 in two very different healthcare settings, the HSF approach increased the number of true COVID-19 cases by an estimated 13% at the expense of a 22% increase in the size of the sample of candidate patients.

In-line instructions in the SAS code that implements the HSF approach and is shared via this GitHub site describe how you may edit the SAS code to reuse it for other phenotypes and other structured healthcare data collections.


<!-- ROADMAP -->
## Roadmap

See the [open issues](https://github.com/kpwhri/Sentinel-Scalable-NLP/issues) for a list of proposed features (and known issues).



<!-- CONTRIBUTING -->
## Contributing

Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE` or https://kpwhri.mit-license.org for more information.



<!-- CONTACT -->
## Contact

Please use the [issue tracker](https://github.com/kpwhri/Sentinel-Scalable-NLP/issues). 

## Disclaimer

* This is not a Sentinel Initiative-supported project.

<!-- ACKNOWLEDGEMENTS -->
## Acknowledgements

* This work was funded as part of the [Sentinel Initiative](https://www.fda.gov/safety/fdas-sentinel-initiative).
  * However, this is not a Sentinel Initiative-supported project.
* This project was supported by Task Order 75F40119F19002 under Master Agreement 75F40119D10037 from the U.S. Food and Drug Administration (FDA). Many thanks are due to members of the Sentinel Innovation Center Workgroup that provided critical feedback during development of this work.
