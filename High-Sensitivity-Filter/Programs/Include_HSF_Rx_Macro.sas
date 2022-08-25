*********************************************************************************************************************************************************************************************
Objective		: Develop scalable and portable (and packaged) SAS program to identify high-sensitivity filters(HSF) using diagnoses codesalong with their relative 
					risks (sorted high to low) to make it re-usable and support future Sentinel studies. Basic idea is to make the HSF approach as generic method 
					relevant to potential case identification in epidemiologic studies including FDA medical and product safety studies

Program			:	Include_HSF_RX_Macro.sas

Version			:	v01

Investigators	: David Carrell <David.S.Carrell@kp.org>, Associate Investigator, Kaiser Permanente Washington Health Research Institute
				  Joshua Carl Smith <joshua.smith@vumc.org>, Vanderbilt University Medical Center

Programmer		: Arvind Ramaprasan <Arvind.Ramaprasan@kp.org>,Data Reporting & Analytics Consultant, Kaiser Permanente Washington Health Research Institute

Date			: 6/7/2022

**********************************************************************************************************************************************************************************************
Updates			:

*********************************************************************************************************************************************************************************************;

****************************************************;
************** MACRO DEFINITION *******************
************** MACRO DEFINITION *******************
************** MACRO DEFINITION *******************
****************************************************;

%Macro HSF_RX( InLib 			= 		/*Input libname reference*/
			 , InputCohortfile 	= 		/*Filename containing cohort of interest.Input files to include list of patient ids (variable: PatID)*/
			 , InputDxFile   	= 		/*Table name containing diagnoses data. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, DX, DX_CODETYPE*/
			 , InputRxFile   	= 		/*Table name containing pharmacy disensing data. Include the following columns: PATID,RXDATE, NDC */
			 , InputUtilFile	=   	/*Table name containing utilization records. Include Libname. Include the following columns: PATID, ADATE, ENCOUNTERID */
			 , PatIDvarName		=		/*Variable name corresponding to Patient identifier. Ex. MRN (in HCSRN.VDW), PATID (in SCDM)*/
			 , VisitType		= A		/*Valid values: I=Inpatient, B=both Inpatient and Outpatient, A=All encountertypes, or C=custom list (populate ENCTYPE_LIST parameter)*/
			 , Enctype_List     =		/*Create custom list of encounter types here if VISITYPE=C. ex. ENCTYPE_LIST  = ('IP','AV') */
			 , OutLib			=		/*Ouput library reference*/
			 , OutputFileName	=		/*Name of the output file (output exported to both Excel and SAS dataset)*/
			 , SilverLabelDx	= 		/*List the "Silver" label diagnoses within single quotes"'" and separated by comma "," (in case of multiple diagnosis codes). For example: 'U07.1'*/
			 , DaysLookup		=		/*Number of days following Silver Label dx within which we are including diagnoses. Ex DaysLookup=3*/
			 , StartDt			= 		/*Start date of the data period (without quotes). Ex: 01Apr2020*/
			 , EndDt			= 		/*End date of the data period (without quotes). Ex: 31Mar2021*/
			 , NdcCodeList	     =		/*File containing list of NDC codes, Brand and Generic names. Include variables: NDC, BRAND, GENERIC*/
			 , RRmax			=		/*Specify the threshold for the relative risk. Ex: 10 to output only those DX codes w/ relative risk >= 10*/
			 );

***********************************************;
**implement the Inpatient and Outpatient Flags ;
***********************************************;
  %if       &VISITTYPE =I %then %let VISITTYPE= AND EncType in ('IP');
  %else %if &VISITTYPE =B %then %let VISITTYPE= AND EncType in ('IP','AV');
  %else %if &VISITTYPE =A %then %let VISITTYPE=;
  %else %if &VISITTYPE =C %then %let VISITTYPE= AND EncType in (&enctype_list);
  %else %do;
   %Put ERROR in VisitType flag.;
   %Put Valid values are I for Inpatient and B for both Inpatient and Outpatient (AV), A for All Encounters or C for a custom list (use the ENCTYPE_LIST parameter) ;
  %end;

  %If 		&PatIDvarName=MRN 	%then %do;
			%Let ENCIDVAR= ENC_ID;
			%Let NDCVAR = NDC;
		%End;
  %else %if &PatIDvarName=PATID %then %do;
			%Let ENCIDVAR= ENCOUNTERID;
			%Let NDCVAR = RX;
       %end; 
	%else %do;
   %Put ERROR in ENCIDVAR flag.;
   %Put Valid values are encounter id variable:ENC_ID (if using VDW data model) or ENCOUNTERID(if using Sentinel Common Data Model) ;
  %end;

*Pull Silver Label DX encounters for PATIDs in InputCohortFile during the study start and end dates;
Proc sql;
Create table &OUTLIB..SilverLabelDx as
Select b.*
	, coalesce(c.DDATE,b.ADATE) as DDATE Format=Date9.

From &INLIB..&INPUTCOHORTFILE. as A INNER JOIN &INPUTDXFILE. as B ON a.&PATIDVARNAME.=b.&PATIDVARNAME.
																 and "&STARTDT."d<=b.Adate<="&ENDDT."d
																 and (b.DX in (&SILVERLABELDX.) or b.ORIGDX in (&SILVERLABELDX.))
																&VISITTYPE.
									INNER JOIN &INPUTUTILFILE.(drop=ENCTYPE) as C on b.&PATIDVARNAME.=c.&PATIDVARNAME.
																					and b.&ENCIDVAR.=c.&ENCIDVAR.
																					and "&STARTDT."d<=c.Adate<="&ENDDT."d
Order by b.&PATIDVARNAME., b.Adate;
quit;

*Create macro variable capturing #Patients w/ Silver Label dx (Ex: U07.1);
Proc sql;
Select count(distinct &PATIDVARNAME.) into: N_PTS_SilverLabelDx
From &OUTLIB..SilverLabelDx
where (DX in (&SILVERLABELDX.) or ORIGDX in (&SILVERLABELDX.))
&VISITTYPE.;
quit;
%put &N_PTS_SilverLabelDx.;

*Numerator;
Proc sql;
Create table &OUTLIB..Numerator_Rx as
Select 	  a.&PATIDVARNAME.
		, a.RxDate
		, a.&NDCVAR.
		, c.Generic

		/*Numerators for Primary Analysis*/
		, Min(Case when a.&PATIDVARNAME.=b.&PATIDVARNAME.
					 and 0<=intck('Days',b.DDATE,a.RXDATE)<=&DAYSLOOKUP.		
						&VISITTYPE.		then b.ADate end)  
				as SLDx_Dt
				Label="[SLDx_Dt]Qualifying Silver Label dx date(earliest of the dates w/ Silver Label Dx:&SILVERLABELDX. followed by RX dispensing within &DAYSLOOKUP. days"
				Format=date9.
		, Max(Case when a.&PATIDVARNAME.=b.&PATIDVARNAME.
					 and 0<=intck('Days',b.DDATE,a.RXDATE)<=&DAYSLOOKUP.	 		
						&VISITTYPE. then 1 else 0 end) 
			as Flag_Rx_with_SLDx_Any
				Label="[Flag_Lab_with_SLDx_Any]1=Yes, have Silver Label Dx:&SILVERLABELDX. followed by RX dispensing within &DAYSLOOKUP. days, 0=else"

		/* Those with this specific Dx (at any time during the study period) did not have a Silver Label Dx at any time during the study period*/
		 , Max(Case when a.&PATIDVARNAME.=b.&PATIDVARNAME.
						&VISITTYPE. then 1 else 0 end) 
			as Flag_Rx_with_SLDx_Ever
				Label="[Flag_Lab_with_SLDx_Ever]1=Yes,have Silver Label Dx:&SILVERLABELDX. ever during the study period, 0=else"

From &INPUTRXFILE. as A Left Join &OUTLIB..SilverLabelDx (drop=ENCTYPE)	as B on a.&PATIDVARNAME.=b.&PATIDVARNAME.
						Left Join &NDCCodeList.						    as C on a.&NDCVAR.=c.NDC
						Inner Join &INLIB..&INPUTCOHORTFILE.			as D on a.&PATIDVARNAME.=d.&PATIDVARNAME.
Where "&STARTDT."d<=a.RXDATE<="&ENDDT."d
 &VISITTYPE.
Group by  a.&PATIDVARNAME.
		, a.&NDCVAR.
		, a.RxDate
		, c.Generic;
quit;

********************************************;
*  	Denominators for Primary analysis       ;
********************************************;
* denominator=total number of distinct patients w/ Silver Label Dx (any) in the study period;
Proc sql;
 select count(distinct case when Flag_Rx_with_SLDx_Any=1 then &PATIDVARNAME. end) into: RX_DENO_W_SLDx 
from &OUTLIB..Numerator_Rx ;
quit;

%Put &RX_DENO_W_SLDx ;

* denominator=total number of distincts patients without Silver Label Dx (any) in the study period;
*All ENCTYPEs;
Proc sql;
select count(distinct case when Flag_Rx_with_SLDx_Any=0 then &PATIDVARNAME. end) into: RX_DENO_WO_SLDx 
from &OUTLIB..Numerator_Rx;
quit;

%Put &RX_DENO_WO_SLDx ;

*Group by NDC code and Generic names;
Proc sql;
Create table &OUTLIB..&OutputFileName. as
Select &NDCVAR.
	, Propcase(Generic) as Generic

	/*Primary Analyses*/
	, count(distinct &PATIDVARNAME.) 
		as RX_COUNTS
			format=comma10.
			Label="[RX_COUNTS]COL-A=#Distinct patients with RX dispensings (any)"
	, Count(distinct Case when Flag_Rx_with_SLDx_Any=1 then &PATIDVARNAME. end) 
		as SLDX_COUNTS
			format=comma10.
			Label="[SLDX_COUNTS]COL-B=#Distinct patients w/ SILVER LABEL dx followed by RX dispensing within &DAYSLOOKUP. days"
	, Count(distinct Case when Flag_Rx_with_SLDx_Any=0 then &PATIDVARNAME. end) 
		as OTHER_COUNTS
			format=comma10.
			Label="[OTHER_COUNTS]COL-C=#Distinct patients with other RX dispensing and without SILVER LABEL dx in &DAYSLOOKUP. days prior"
	, Count(distinct Case when Flag_Rx_with_SLDx_Ever=0 then &PATIDVARNAME. end)
		as N_WO_SLDX_EVER
			Label="[N_WO_SLDX_EVER]COL-D=#Distinct Patients who did not have a U07.1 at any time during the study period"
	, calculated SLDX_COUNTS / &RX_DENO_W_SLDX.
		as WITH_SLDX_RATE
			format=comma10.8
			Label="[WITH_SLDX_RATE]COL-E=COL-B/#Pts w/ Silver Label dx. Numerator= SLDX_COUNTS; Denominator= #distinct patients any RX dispensing and SILVER LABEL dx &DAYSLOOKUP. days prior (Deno=&RX_DENO_W_SLDX.)"
	, calculated OTHER_COUNTS / &RX_DENO_WO_SLDX.
		as WITHOUT_SLDX_RATE
			format=comma10.8
			Label="[WITHOUT_SLDX_RATE]COL-F=COL-C/#Pts w/o Silver Label dx. Numerator=OTHER_COUNTS; Denominator= #distinct patients without RX dispensing and and without SILVER LABEL dx &DAYSLOOKUP. days prior (Deno=&RX_DENO_WO_SLDX.)"
	, Calculated WITH_SLDX_RATE / Calculated WITHOUT_SLDX_RATE
		as RELATIVE_RISK
			format=comma10.2
			Label="[RELATIVE_RISK]COL-G=COL-E/COL-F. Numerator=WITH_SLDX_RATE; Denominator=WITHOUT_SLDX_RATE"

From &OUTLIB..Numerator_Rx
Group by &NDCVAR., calculated Generic
Having calculated RELATIVE_RISK >=&RRMAX.
    or calculated RELATIVE_RISK =.
Order by calculated RELATIVE_RISK desc, calculated RX_COUNTS desc;
quit;


*Grouped by Generic names;
Proc sql;
Create table &OUTLIB..&OutputFileName._ByGeneric as
Select Propcase(Generic) as Generic

	/*Primary Analyses*/
	, count(distinct &PATIDVARNAME.) 
		as RX_COUNTS
			format=comma10.
			Label="[RX_COUNTS]COL-A=#Distinct patients with RX dispensings (any)"
	, Count(distinct Case when Flag_Rx_with_SLDx_Any=1 then &PATIDVARNAME. end) 
		as SLDX_COUNTS
			format=comma10.
			Label="[SLDX_COUNTS]COL-B=#Distinct patients w/ SILVER LABEL dx followed by RX dispensing within &DAYSLOOKUP. days"
	, Count(distinct Case when Flag_Rx_with_SLDx_Any=0 then &PATIDVARNAME. end) 
		as OTHER_COUNTS
			format=comma10.
			Label="[OTHER_COUNTS]COL-C=#Distinct patients with other RX dispensing and without SILVER LABEL dx in &DAYSLOOKUP. days prior"
	, Count(distinct Case when Flag_Rx_with_SLDx_Ever=0 then &PATIDVARNAME. end)
		as N_WO_SLDX_EVER
			Label="[N_WO_SLDX_EVER]COL-D=#Distinct Patients who did not have a U07.1 at any time during the study period"
	, calculated SLDX_COUNTS / &RX_DENO_W_SLDX.
		as WITH_SLDX_RATE
			format=comma10.8
			Label="[WITH_SLDX_RATE]COL-E=COL-B/#Pts w/ Silver Label dx. with lab test Numerator= SLDX_COUNTS; Denominator= #distinct patients any RX dispensing and SILVER LABEL dx &DAYSLOOKUP. days prior (Deno=&RX_DENO_W_SLDX.)"
	, calculated OTHER_COUNTS / &RX_DENO_WO_SLDX.
		as WITHOUT_SLDX_RATE
			format=comma10.8
			Label="[WITHOUT_SLDX_RATE]COL-F=COL-C/#Pts w/o Silver Label dx. and w/o lab test Numerator=OTHER_COUNTS; Denominator= #distinct patients without RX dispensing and and without SILVER LABEL dx &DAYSLOOKUP. days prior (Deno=&RX_DENO_WO_SLDX.)"
	, Calculated WITH_SLDX_RATE / Calculated WITHOUT_SLDX_RATE
		as RELATIVE_RISK
			format=comma10.2
			Label="[RELATIVE_RISK]COL-G=COL-E/COL-F. Numerator=WITH_SLDX_RATE; Denominator=WITHOUT_SLDX_RATE"

From &OUTLIB..Numerator_Rx
Group by  calculated Generic
Having calculated RELATIVE_RISK >=&RRMAX.
    or calculated RELATIVE_RISK =.
Order by calculated RELATIVE_RISK desc, calculated RX_COUNTS desc;
quit;

********************************************;
*  	EXPORT TO EXCEL  	EXPORT TO EXCEL     ;
********************************************;
ods excel file="&EXCELOUT.\&OutputFileName..xlsx" style=minimal;

ods excel options (sheet_name = "HSF RX1") ;
ods text= "High Sensitivity Filter (HSF) - Pharmacy dispensing" / style=[fontweight=bold fontsize=14pt];
ods text="NOTE: Pharmacy output grouped by NDC code and Generic names" / style=[fontweight=bold fontsize=14pt];
ods text="Silver Label Dx (a.k.a. SLDX): &SILVERLABELDX." / style=[fontweight=bold fontsize=14pt];
ods text="#Patients w/ 1+ Silver Label Dx (&SILVERLABELDX.): &N_PTS_SilverLabelDx." / style=[fontweight=bold fontsize=14pt];
ods text="Lookup window: &DAYSLOOKUP. days (output based on 'other' RX dispensings within &DAYSLOOKUP. days of Silver Label Dx)" / style=[fontweight=bold fontsize=14pt];
ods text="Study Period: &StartDt.- &EndDt." / style=[fontweight=bold fontsize=14pt];
ods text="Encounters included: &Enctype_List." / style=[fontweight=bold fontsize=14pt];
ods text="Relative Risk (Threshold): &RRMAX. (display output with relative risk of &RRMAX. or greater (high to low))" / style=[fontweight=bold fontsize=14pt];
Proc print data=&OUTLIB..&OutputFileName. Noobs Label style=minimal;
run;

ods excel options (sheet_name = "HSF RX2" sheet_interval="now" );
ods excel options (sheet_name = "HSF RX2" sheet_interval="none" );
proc odstext;
	p "High Sensitivity Filter (HSF) - Pharmacy dispensing" / style=[fontweight=bold fontsize=14pt];
	p "NOTE: Pharmacy output group by Generic names" / style=[fontweight=bold fontsize=14pt];
	p "Silver Label Dx (a.k.a. SLDX): &SILVERLABELDX." / style=[fontweight=bold fontsize=14pt];
	p "#Patients w/ 1+ Silver Label Dx (&SILVERLABELDX.): &N_PTS_SilverLabelDx." / style=[fontweight=bold fontsize=14pt];
	p "Lookup window: &DAYSLOOKUP. days (output based on 'other' RX dispensings within &DAYSLOOKUP. days of Silver Label Dx)" / style=[fontweight=bold fontsize=14pt];
	p "Study Period: &StartDt.- &EndDt." / style=[fontweight=bold fontsize=14pt];
	p "Encounters included: &Enctype_List." / style=[fontweight=bold fontsize=14pt];
	p "Relative Risk (Threshold): &RRMAX. (display output with relative risk of &RRMAX. or greater (high to low))" / style=[fontweight=bold fontsize=14pt];
run;

Proc print data=&OUTLIB..&OutputFileName._ByGeneric Noobs Label style=minimal;
run;

ods excel close;

%Mend HSF_RX;

****************************************************;
************** SAMPLE MACRO CALL *******************
************** SAMPLE MACRO CALL *******************
************** SAMPLE MACRO CALL *******************
****************************************************;

*%HSF_RX(Inlib 			 = OUT				  /*Input library reference*/
	,	InputCohortfile  = MyCohort		  	  /*Filename containing cohort of interest.Input files to include list of patient ids (variable: PatID or MRN)*/
	,	InputDxFile   	 = &_VDW_DX			  /*table name containing diagnoses data. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, DX, DX_CODETYPE*/
	, 	InputRXFile	 	 = &_VDW_RX 		  /*table name containing Pharmacy dispensing data data. Include the following columns: PATID,NDC RXDATE */
	,   InputUtilFile	 = &_VDW_UTILIZATION  /*Table name containing utilization records. Include Libname. Include the following columns: PATID, ADATE, ENCOUNTERID */
	, 	PatIDvarName	 = PATID			  /*Variable name for Patient ID. Ex. MRN (if using HCSRN.VDW data modl), PATID (if using SCDM data model)*/
	,   VisitType		 = C				  /*Valid values: I=Inpatient, B=both Inpatient and Outpatient, A=All encountertypes, or C=custom list (populate ENCTYPE_LIST parameter)*/
	,   Enctype_List     = 'IP','AV'		  /*Create custom list of encounter types (with quotes, separated by comma) here if VISITYPE=C. ex. ENCTYPE_LIST  = 'IP','AV' */
	,	OutLib			 = OUT				  /*Output library reference*/
	, 	OutputFileName	 =	Summary_by_Rx	  /*Output file name*/	
	,	SilverLabelDx	 = 'U07.1'			  /*List the "Silver" label diagnoses within single quotes"'" and separated by comma "," (in case of multiple diagnosis codes). For example: 'U07.1'*/
	,   DaysLookup		 =	3				  /*Output to include diagnoses following the Silver Label dx within the look up window . Ex DaysLookup=3 */
	,	StartDt		 	 = 01Apr2020 		  /*Start date of the data period (without quotes). Ex: 01Apr2020*/
	,	EndDt			 = 31Mar2021 		  /*End date of the data period (without quotes). Ex: 31Mar2021*/
	,   NdcCodeList	     = Out.EverNDC		  /*File containing list of NDC codes, Brand and Generic names. Include variables: NDC,BRAND,GENERIC*/
	,	RRmax			 = 10				  /*Specify the threshold for the relative risk. Ex: 10 (output to consist of only those DX codes w/ relative risk >= 10*/
	   );
