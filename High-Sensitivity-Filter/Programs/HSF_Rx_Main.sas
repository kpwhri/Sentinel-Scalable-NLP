*********************************************************************************************************************************************************************************************
HSF Programming: Develop scalable and portable (and packaged) SAS program to identify high-sensitivity filters (HSF) using diagnoses codes, procedure codes, medications, 
					laboratory tests, and problem list entries along with their relative risks (sorted high to low) to make it re-usable and support future Sentinel studies. 
					Basic idea is to make the HSF approach as generic method relevant to potential case identification in epidemiologic studies including FDA medical and 
					product safety studies
*********************************************************************************************************************************************************************************************;

*Programming Instructions:
* 							1. DO NOT edit standard macro: Include_HSF_RX_MACRO.SAS. Edit sections in the MAIN program between EDIT START and EDIT END  in the main program HSF_RX_MAIN.sas only
* 							2. The macro is primarily designed to execute on the following data models only: 
*								a. HCSRN's Virtual Data Warehouse (VDW)
*							3. Macro output is based on ALL encounter types (ENCTYPEs) including "virtual" encounters. To exclude virtual encounters, limit the INPUTDXFILE 
*								to diagnosis encounters other than virtual encounter.
*								
*********************************************************************************************************************************************************************************************;


****************************************************;
***************** EDIT START ***********************
***************** EDIT START ***********************
***************** EDIT START ***********************
****************************************************;

****************************************************;
*	1.	SIGNON TO SAS SERVER						;									
****************************************************;
*Signoff;
%include "H:\sasCSpassword.sas";
%include "\\ghcmaster.ghc.org\ghri\warehouse\sas\includes\globals.sas";
%include "\\groups.ghc.org\data\CTRHS\CHS\ITCore\SASCONNECT\RemoteStartRDW.sas";
%include "&GHRIDW_ROOT.\Sasdata\CRN_VDW\lib\StdVars.sas" ; 
%make_spm_comment(Scalable NLP COVID-19:Relative risk per Rx feature);

Options compress=yes NOFMTERR symbolgen macrogen;
****************************************************;
*	1. SPECIFY ROOT FOLDER						 	;									
****************************************************;
%Let ROOT= \\Groups.ghc.org\data\CTRHS\Sentinel\Innovation_Center\NLP_COVID19_Carrell\PROGRAMMING;
Libname In "&ROOT.\SAS Datasets\Replicate VUMC analysis\Sampling for Chart Review\Demograhics for N14123" access=readonly;
*Libname Dx "&ROOT.\SAS Datasets\Replicate VUMC analysis" access=readonly;

%let ETL_new = ETL_28;
%let cdmnew = \\ghcmaster\ghri\Warehouse\sasdata\Sentinel_CDM\Tables\&ETL_new.;
libname cdmnew "&cdmnew." access=readonly;

****************************************************;
*	2. SPECIFY LIBNAME FOR THE OUTPUT LIBRARY	 	;									
****************************************************;
Libname Out "&ROOT.\SAS Datasets\HSF Programming\Rx";

****************************************************;
*	3. SPECIFY LIBNAME FOR NDC->Generic crosswalk	;									
****************************************************;
Libname EverNDC "\\ghcmaster\ghri\Warehouse\sasdata\CRN_VDW";
****************************************************;
*	4. SPECIFY OUTPUT FOLDER TO SAVE EXCEL OUTPUT 	;									
****************************************************;
%LET EXCELOUT= &ROOT.\SAS Datasets\HSF Programming\Rx;

****************************************************;
*	5. INCLUDE HSF_DX_MACRO.sas					 	;
****************************************************;
%Include "&ROOT.\SAS Program\Include_HSF_Rx_Macro.sas";

*HSF Cohort= 14,123;
Proc sql outobs=14123;
Create table Out.MyCohort  as
Select Distinct MRN
From In.Demographics_n14123
order by MRN;
quit;

Proc sql outobs=50000;
Create table Out.MyCohort2  as
Select Distinct MRN
From &_VDW_Demographic.
order by MRN;
quit;

*50000_14123=64123;
Data  Out.MyCohort3;
set Out.MyCohort
	Out.MyCohort2;
	run;



*Pull random patients from CDM.Demographic table;
Proc sql outobs=100000;
Create table Out.CDMCohort1   as
Select Distinct PatID
From cdmnew.Demographic
order by PatID;
quit;

Proc sql outobs=10000;
Create table Out.CDMCohort   as
Select Distinct PatID
From cdmnew.Diagnosis
Where OrigDx in ('U07.1')
and "01Apr2020"d <=Adate <= "31Mar2021"d
order by PatID;
quit;

Data Out.CDMCohort3;
set Out.CDMCohort Out.CDMCohort1;
run;


*Local copy of EVERndc (NDC->Generic crosswalk);
Proc sql ;
Create table Out.EverNDC  as
Select NDC
, Brand
, Generic
, Strength
, Dosage_Form
, Unit_of_measure
From EverNDC.Everndc
order by NDC;
quit;

*Example-1: Sample Macro call - HCSRN.vdw;
%HSF_RX(Inlib 			 = OUT				  /*Input library reference*/
	,	InputCohortfile  = MyCohort3		  /*Filename containing cohort of interest.Input files to include list of patient ids (variable: PatID)*/
	,	InputDxFile   	 = &_VDW_Dx  		  /*table name containing diagnoses data. Include the libname. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, DX, DX_CODETYPE*/
	,	InputRxFile   	 = &_VDW_Rx  		  /*table name containing Pharmacy dispensing data. Include the libname. Include the following columns: PATID,RXDATE, RX */
	,   InputUtilFile	 = &_VDW_Utilization  /*Table name containing utilization records. Include Libname. Include the following columns: PATID, ADATE, DDATE, ENCOUNTERID */
	, 	PatIDvarName	 = MRN			  	  /*Variable name corresponding to Patient identifier. Ex. MRN (if using HCSRN.VDW data modl), PATID (if using SCDM data model)*/
	,   VisitType		 = A				  /*Allowable values: B=both inpatient and outpatient, I=Inpatient only, A=all encounter types (default), C=custom list (populate enctype_list parameter)*/
	,   enctype_list     = 					  /*Create custom list of encounter types (with quotes, separated by comma) here if VISITYPE=C. ex. ENCTYPE_LIST  = 'IP','AV' */
	,	OutLib			 = OUT				  /*Output library reference*/
	,	OutputFileName	 = Summary_by_Rx_VDW  /*Name of the output file*/
	,	SilverLabelDx	 = 'U07.1'			  /*List the "Silver" label diagnoses within single quotes"'" and separated by comma "," (in case of multiple diagnosis codes). For example: 'U07.1'*/
	, 	DaysLookup		 = 7				  /*Number of days following Silver Label dx within which we are including pharmacy dispensings. Ex: DaysLookup=3 i.e. within 3 days following SilverLabelDx*/
	,	StartDt		 	 = 01Apr2020 		  /*Start date of the data period (without quotes). Ex: 01Apr2020*/
	,	EndDt			 = 31Mar2021 		  /*End date of the data period (without quotes). Ex: 31Mar2021*/
	,   NdcCodeList	     = Out.EverNdc		  /*File containing list of NDC codes, Brand and Generic names. Include variables: NDC, BRAND,GENERIC*/
	,	RRmax			 = 5				  /*Specify the threshold for the relative risk. Ex: 10 (display output consisting of only those DX codes w/ relative risk >= 10*/
	   );

*Example-2: Sample Macro call - Sentinel's CDM;
%HSF_RX(Inlib 			 = OUT				  /*Input library reference*/
	,	InputCohortfile  = CDMCohort3	  	  /*Filename containing cohort of interest.Input files to include list of patient ids (variable: PatID)*/
	,	InputDxFile   	 = cdmnew.Diagnosis   /*table name containing diagnoses data. Include the libname. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, DX, DX_CODETYPE*/
	,	InputRxFile   	 = cdmnew.Dispensing  /*table name containing Pharmacy dispensing data. Include the libname. Include the following columns: PATID,RXDATE, RX */
	,   InputUtilFile	 = cdmnew.Encounter   /*Table name containing utilization records. Include Libname. Include the following columns: PATID, ADATE, ENCOUNTERID */
	, 	PatIDvarName	 = PATID			  /*Variable name corresponding to Patient identifier. Ex. MRN (if using HCSRN.VDW data modl), PATID (if using SCDM data model)*/
	,   VisitType		 = A				  /*Allowable values: B=both inpatient and outpatient, I=Inpatient only, A=all encounter types (default), C=custom list (populate enctype_list parameter)*/
	,   enctype_list     = 					  /*Create custom list of encounter types (with quotes, separated by comma) here if VISITYPE=C. ex. ENCTYPE_LIST  = 'IP','AV' */
	,	OutLib			 = OUT				  /*Output library reference*/
	,	OutputFileName	 = Summary_by_Rx_CDM  /*Name of the output file*/
	,	SilverLabelDx	 = 'U07.1'			  /*List the "Silver" label diagnoses within single quotes"'" and separated by comma "," (in case of multiple diagnosis codes). For example: 'U07.1'*/
	, 	DaysLookup		 = 7				  /*Number of days following Silver Label dx within which we are including Rx dispensings. Ex: DaysLookup=3 i.e. within 3 days following SilverLabelDx*/
	,	StartDt		 	 = 01Apr2020 		  /*Start date of the data period (without quotes). Ex: 01Apr2020*/
	,	EndDt			 = 31Mar2021 		  /*End date of the data period (without quotes). Ex: 31Mar2021*/
	,   NdcCodeList	     = Out.EverNdc		  /*File containing list of NDC codes, Brand and Generic names. Include variables: NDC, BRAND,GENERIC*/
	,	RRmax			 = 10				  /*Specify the threshold for the relative risk. Ex: 10 (display output consisting of only those DX codes w/ relative risk >= 10*/
	   );

****************************************************;
******************* EDIT END ***********************
******************* EDIT END ***********************
******************* EDIT END ***********************
****************************************************;
