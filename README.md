
<div>
  <p>
    <a href="https://github.com/kpwhri/Sentinel-Scalable-NLP">
      <!-- img src="images/logo.png" alt="Logo" -->
    </a>
  </p>

  <h3 align="center">Sentinel Scalable NLP</h3>

  <p>
    Sentinel Scalable NLP is a collection of projects supported by the Sentinel Initiative that develop scalable, reusable methods and approaches to enhance the development of computable phenotype models with the aim of improving the overall efficiecy and accuracy of automated phenotyping efforts. One of these projects implements a methods for improving the sensitivity of filters used to identify patients (or healthcare events) that are candidates for phenotype modeling--an important first step in developing phenotype models where a set of relatively simple rules is used to identify candidate patients (or candidate events experienced by patients) for which phenotype status will eventually be predicted by a phenotype model, subsequently developed. When used, this high-sensitivity filtering approach may be able to identify additional candidates overlooked by a simple implementation of such a filter, thereby yielding improved sensitivity for identifying true phenotype cases at reasonable expense in terms of the increase in sample size of the candidate pool. We refer to this method as "high-sensitivity filtering."  Since the method is largely data-driven, it is possible to implement high-sensitivity filtering with  moderate effort. 
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

This project currently documents the high-sensivitiy filtering method to improve the sensitivity of filtering rules used as the first step in developing an automated phenotype model.  Eventually, this project will also document an automated approach to developing a phenotype model itself (i.e., a model that predicts which of the candidates is a true phenotype case and which are not). 

<!-- GETTING STARTED -->
## Getting Started

There is one folder for each project documented here.  Currently there is one project:

1. High Sensitivity Filter
   * [Instructions](High-Sensitivity-Filter/README.md)

### Prerequisites

In general, components of this project have been used/tested with:
* SAS version 9.4+ (?)
* Structured healthcare data organized according to the Sentinel Common Data Model (or any other comparable "flat file" formatted collection of structured healthcare data)
* Excel (or comparable spreadsheet softwared used to display data in a tabular format)


<!-- USAGE EXAMPLES -->
## Usage

Though it can be applied to any health-related phenotype documented by diagnosis, procedure, or medication codes, we developed and applied the high-sensitivity filtering (HSF) method to improve filtering of patients who may have symptomatic COVID-19 infection. Traditionally, a filtering rule to identify candidates for this phenotype would be patients (or patient encounters) coded with an International Classification of Disease, 10th Revision (ICD-10) diagnosis code for COVID-19 (i.e., the ICD-10 code U07.1 "COVID-19"). Briefly, the HSF method uses SAS code and structured healthcare data for a large collection of patients and encounters to to investigate other healthcare codes -- including diagnoses other than U07.1, medical procedure codes, and medication codes -- that co-occur with the traditional filter (ICD-10 U07.1) and may thereby be used to identify what could be described as surrogate codes for the traditional filter, U07.1. The method summarizes these co-occurrences in a tabular format, separatly for each type of coded data (e.g., diagnoses, procedures, medications) allowing it to be easily and rapidly manually reviewed by a clinical expert.  This review yields a set of codes that 1) have clinical face validity, 2) are much more likely to appear in the charts of patients with the phenotype in question (e.g., COVID-19) than patients without, and 3) if used as an additional filter criteria, would increase the sample size of candidate patients/events only momodestly dentify surrogate codes (or, seeks to identif. As described in a poster presented at the 2022 ICPE conference in Copenhagen, when applying the HSV method in an effort to identify patients with  COVID-19in two very differenty healthcare settings, the HSF approach increased the number of true COVID-19 cases by 13% at the expense of a 22% increase in the sample of candidate patients.2titled "" DATA-DRIVEN APPROACHES TO IMPROVE
PHENOTYPE SENSITIVITY USING EHR DATA
 s [SEMVER](https://semver.org/). -->

Updates/changes are not expected. Versioning likely based on release timing in `YYYYmm`. See https://github.com/kpwhri/Sentinel-Scalable-NLP/releases.


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
