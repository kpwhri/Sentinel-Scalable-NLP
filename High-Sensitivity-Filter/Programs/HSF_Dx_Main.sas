*********************************************************************************************************************************************************************************************
HSF Programming: Develop scalable and portable (and packaged) SAS program to identify high-sensitivity filters (HSF) using diagnoses codes, procedure codes, medications, 
					laboratory tests, and problem list entries along with their relative risks (sorted high to low) to make it re-usable and support future Sentinel studies. 
					Basic idea is to make the HSF approach as generic method relevant to potential case identification in epidemiologic studies including FDA medical and 
					product safety studies
*********************************************************************************************************************************************************************************************;

*Programming Instructions:
* 							1. DO NOT edit standard macro: Include_HSF_DX_MACRO.SAS. Edit sections in the MAIN program between EDIT START and EDIT END  in the main program HSF_DX_MAIN.sas only
* 							2. The macro is primarily designed to execute on the following data models only:
*								a. Sentinel Common Data Model (SCDM). 
*								b. HCSRN's Virtual Data Warehouse (VDW)
*							3. Macro output is based on ALL encounter types (ENCTYPEs) including "virtual" encounters. To exclude virtual encounters, limiti the INPUTDXFILE 
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
%make_spm_comment(Scalable NLP COVID-19:Relative risk per Dx feature);

Options compress=yes NOFMTERR;
****************************************************;
*	1. SPECIFY ROOT FOLDER						 	;									
****************************************************;
%Let ROOT= \\Groups.ghc.org\data\CTRHS\Sentinel\Innovation_Center\NLP_COVID19_Carrell\PROGRAMMING;
Libname In "&ROOT.\SAS Datasets\Replicate VUMC analysis\Sampling for Chart Review\Demograhics for N14123" access=readonly;
*Libname Dx "&ROOT.\SAS Datasets\Replicate VUMC analysis" access=readonly;

%let ETL_new = ETL_28;
%let cdmnew = &GHRIDW_ROOT\sasdata\Sentinel_CDM\Tables\&ETL_new.;
libname cdmnew "&cdmnew." access=readonly;

****************************************************;
*	2. SPECIFY LIBNAME FOR THE OUTPUT LIBRARY	 	;									
****************************************************;
Libname Out "&ROOT.\SAS Datasets\HSF Programming\Dx";

****************************************************;
*	3. SPECIFY OUTPUT FOLDER TO SAVE EXCEL OUTPUT 	;									
****************************************************;
%LET EXCELOUT= &ROOT.\SAS Datasets\HSF Programming\Dx;

****************************************************;
*	4. INCLUDE HSF_DX_MACRO.sas					 	;
****************************************************;
%Include "&ROOT.\SAS Program\Include_HSF_Dx_Macro.sas";

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

Proc sql outobs=50000;
Create table Out.MyCohort3  as
Select Distinct MRN
From &_VDW_Utilization.
where "01Apr2020"d<=Adate <= "31Mar2021"d
order by MRN;
quit;

*50000+14123;
Data Out.MyCohort4;
set Out.MyCohort3
	Out.MyCohort2
	Out.MyCohort;
	run;


*- THIS STEP IS NOT REQUIRED: Diagnosis table;
/*Proc sql;
Create table Out.Diagnosis as
Select MRN as PatID
	, Adate
	, EncType
	, Dx
	, Dx_CodeType
From Dx.all_dx_01apr2020_31mar2021
Order by MRN, Adate;
quit;*/

*Pull random patients from CDM.Demographic table;
Proc sql outobs=500000;
Create table Out.CDMCohort   as
Select Distinct PatID
From cdmnew.Demographic
order by PatID;
quit;


*Example-1: Sample Macro call - HCSRN.vdw;
%HSF_DX(Inlib 			 = OUT				  /*Input library reference*/
	,	InputCohortfile  = MyCohort		  	  /*Filename containing cohort of interest.Input files to include list of patient ids (variable: PatID)*/
	,	InputDxFile   	 = &_VDW_DX	  		  /*table name containing diagnoses data. Include the libname. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, DX, DX_CODETYPE*/
	, 	PatIDvarName	 = MRN			  	  /*Variable name corresponding to Patient identifier. Ex. MRN (if using HCSRN.VDW data modl), PATID (if using SCDM data model)*/
	,   VisitType		 = A				  /*Allowable values: B=both inpatient and outpatient, I=Inpatient only, A=all encounter types (default), C=custom list (populate enctype_list parameter)*/
	,   enctype_list     = 					  /*Create custom list of encounter types (with quotes, separated by comma) here if VISITYPE=C. ex. ENCTYPE_LIST  = 'IP','AV' */
	,	OutLib			 = OUT				  /*Output library reference*/
	,	OutputFileName	 = Summary_by_Dx_VDW  /*Name of the output file*/
	,	SilverLabelDx	 = 'U07.1'			  /*List the "Silver" label diagnoses within single quotes"'" and separated by comma "," (in case of multiple diagnosis codes). For example: 'U07.1'*/
	, 	DaysLookup		 = 10				  /*Number of days following Silver Label dx within which we are including other diagnoses. Ex: DaysLookup=3 i.e. within 3 days following SilverLabelDx*/
	,	StartDt		 	 = 01Apr2020 		  /*Start date of the data period (without quotes). Ex: 01Apr2020*/
	,	EndDt			 = 31Mar2021 		  /*End date of the data period (without quotes). Ex: 31Mar2021*/
	,	DxCodeList		 = OUT.Distinct_DiagCd/*List of ICD9/10 codes with descriptions. Include 2 columns:DIAGCD and DIAGDESC */
	,	RRmax			 = 10				  /*Specify the threshold for the relative risk. Ex: 10 (display output consisting of only those DX codes w/ relative risk >= 10*/
	   );

*Example-2: Sample Macro call - Sentinel.CDM table;
%HSF_DX(Inlib 			 = OUT				  /*Input library reference*/
	,	InputCohortfile  = CDMCohort		  /*Filename containing cohort of interest.Input files to include list of patient ids (variable: PatID)*/
	,	InputDxFile   	 = CDMNEW.Diagnosis	  /*table name containing diagnoses data. Include the libname. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, DX, DX_CODETYPE*/
	, 	PatIDvarName	 = PATID		  	  /*Variable name corresponding to Patient identifier. Ex. MRN (if using HCSRN.VDW data modl), PATID (if using SCDM data model)*/
	,   VisitType		 = A				  /*Allowable values: B=both inpatient and outpatient, I=Inpatient only, A=all encounter types (default), C=custom list (populate enctype_list parameter)*/
	,   enctype_list     =					  /*Create custom list of encounter types here if VISITYPE=C. ex. ENCTYPE_LIST  = ('IP','AV') */
	,	OutLib			 = OUT				  /*Output library reference*/
	,	OutputFileName	 = Summary_by_Dx_CDM  /*Name of the output file*/
	,	SilverLabelDx	 = 'U07.1'			  /*List the "Silver" label diagnoses within single quotes"'" and separated by comma "," (in case of multiple diagnosis codes). For example: 'U07.1'*/
	, 	DaysLookup		 = 3				  /*Number of days following Silver Label dx within which we are including other diagnoses. Ex: DaysLookup=3 i.e. within 3 days following SilverLabelDx */
	,	StartDt		 	 = 01Apr2020 		  /*Start date of the data period (without quotes). Ex: 01Apr2020*/
	,	EndDt			 = 31Mar2021 		  /*End date of the data period (without quotes). Ex: 31Mar2021*/
	,	DxCodeList		 = OUT.Distinct_DiagCd/*List of ICD9/10 codes with descriptions. Include 2 columns:DIAGCD and DIAGDESC */
	,	RRmax			 = 10				  /*Specify the threshold for the relative risk. Ex: 10 (display output consisting of only those DX codes w/ relative risk >= 10*/
	   );


****************************************************;
******************* EDIT END ***********************
******************* EDIT END ***********************
******************* EDIT END ***********************
****************************************************;
