*********************************************************************************************************************************************************************************************
Objective		: Develop scalable and portable (and packaged) SAS program to identify high-sensitivity filters(HSF) using diagnoses codesalong with their relative 
					risks (sorted high to low) to make it re-usable and support future Sentinel studies. Basic idea is to make the HSF approach as generic method 
					relevant to potential case identification in epidemiologic studies including FDA medical and product safety studies

Program			:	Include_HSF_DX_Macro.sas

Version			:	v01

Investigators	: David Carrell <David.S.Carrell@kp.org>, Associate Investigator, Kaiser Permanente Washington Health Research Institute
				  Joshua Carl Smith <joshua.smith@vumc.org>, Vanderbilt University Medical Center

Programmer		: Arvind Ramaprasan <Arvind.Ramaprasan@kp.org>,Data Reporting & Analytics Consultant, Kaiser Permanente Washington Health Research Institute

Date			: 5/9/2022

**********************************************************************************************************************************************************************************************
Updates			:

*********************************************************************************************************************************************************************************************;

****************************************************;
************** MACRO DEFINITION *******************
************** MACRO DEFINITION *******************
************** MACRO DEFINITION *******************
****************************************************;

%Macro HSF_DX( InLib 			= 		/*Input libname reference*/
			 , InputCohortfile 	= 		/*Filename containing cohort of interest.Input files to include list of patient ids (variable: PatID)*/
			 , InputDxFile   	= 		/*Table name containing diagnoses data. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, DX, DX_CODETYPE*/
			 , PatIDvarName		=		/*Variable name corresponding to Patient identifier. Ex. MRN (in HCSRN.VDW), PATID (in SCDM)*/
			 , VisitType		= A		/*Valid values: I=Inpatient, B=both Inpatient and Outpatient, A=All encountertypes, or C=custom list (populate ENCTYPE_LIST parameter)*/
			 , Enctype_List     =		/*Create custom list of encounter types here if VISITYPE=C. ex. ENCTYPE_LIST  = ('IP','AV') */
			 , OutLib			=		/*Ouput library reference*/
			 , OutputFileName	=		/*Name of the output file (output exported to both Excel and SAS dataset)*/
			 , SilverLabelDx	= 		/*List the "Silver" label diagnoses within single quotes"'" and separated by comma "," (in case of multiple diagnosis codes). For example: 'U07.1'*/
			 , DaysLookup		=		/*Number of days following Silver Label dx within which we are including diagnoses. Ex DaysLookup=3*/
			 , StartDt			= 		/*Start date of the data period (without quotes). Ex: 01Apr2020*/
			 , EndDt			= 		/*End date of the data period (without quotes). Ex: 31Mar2021*/
			 , DxCodeList	    =		/*File containing list of diagnosis codes and descriptions. Include variables: DIAGCD, DIAGDESC*/
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

*Pull DX encounters for PATIDs in InputCohortFile during the study start and end dates;
Proc sql;
Create table &OUTLIB..SilverLabelDx as
Select b.*

From &INLIB..&INPUTCOHORTFILE. as A INNER JOIN &INPUTDXFILE. as B ON a.&PATIDVARNAME.=b.&PATIDVARNAME.
																 and "&STARTDT."d<=b.Adate<="&ENDDT."d
																 and (b.DX in (&SILVERLABELDX.) or b.ORIGDX in (&SILVERLABELDX.))
																&VISITTYPE.
Order by b.&PATIDVARNAME., b.Adate;
quit;

*Create macro variable capturing #Patients w/ Silver Label dx (Ex: U07.1;
Proc sql;
Select count(distinct &PATIDVARNAME.) into: N_PTS_SilverLabelDx
From &OUTLIB..SilverLabelDx
where  (DX in (&SILVERLABELDX.) or ORIGDX in (&SILVERLABELDX.));
quit;
%put &N_PTS_SilverLabelDx.;

*Numerator;
Proc sql;
Create table &OUTLIB..Numerator_Dx as
Select 	  a.&PATIDVARNAME.
		, a.Adate
		, a.Dx
		, c.Diagdesc
		, a.EncType

		/*Numerators for Primary Analysis*/
		, Min( Case when a.&PATIDVARNAME.=b.&PATIDVARNAME.
					 and 0<=intck('Days',b.Adate,a.Adate)<=&DAYSLOOKUP. then b.ADate end)  
				as SLDx_Dt
				Label="[SLDx_Dt]Qualyfying Silver Label dx date (earliest of the dates w/ Silver Label Dx:&SILVERLABELDX.)"
				Format=date9.
		, Max( Case when a.&PATIDVARNAME.=b.&PATIDVARNAME.
					 and 0<=intck('Days',b.Adate,a.Adate)<=&DAYSLOOKUP. then 1 else 0 end) 
			as Flag_Dx_with_SLDx_Any
				Label="[Flag_Dx_with_SLDx_Any]1=Yes, have Silver Label Dx:&SILVERLABELDX. followed by Dx encounter within &DAYSLOOKUP. days, 0=else"

		/* Those with this specific Dx (at any time during the study period) did not have a Silver Label Dx at any time during the study period*/
		 , Max( Case when a.&PATIDVARNAME.=b.&PATIDVARNAME.  then 1 else 0 end) 
			as Flag_Dx_with_SLDx_Ever
				Label="[Flag_Dx_with_SLDx_Ever]1=Yes,have Silver Label Dx:&SILVERLABELDX. ever during the study period, 0=else"

From &INPUTDXFILE. as A Left Join &OUTLIB..SilverLabelDx (drop=ENCTYPE)	as B on a.&PATIDVARNAME.=b.&PATIDVARNAME.
						Left Join &DxCodeList.						    as C on compress(a.Dx,".")=c.DIAGCD
						Inner Join &INLIB..&INPUTCOHORTFILE.			as D on a.&PATIDVARNAME.=d.&PATIDVARNAME.
Where "&STARTDT."d<=a.Adate<="&ENDDT."d
 &VISITTYPE.
Group by  a.&PATIDVARNAME.
		, a.Adate
		, a.Dx
		, c.Diagdesc
		, a.EncType;
quit;

********************************************;
*  	Denominators for Primary analysis       ;
********************************************;
* denominator=total number of distinct patients w/ Silver Label Dx (any) in the study period;
Proc sql;
 select count(distinct case when Flag_Dx_with_SLDx_Any=1 then &PATIDVARNAME. end) into: DX_DENO_W_SLDx 
from &OUTLIB..Numerator_Dx ;
quit;

%Put &DX_DENO_W_SLDx ;

* denominator=total number of distincts patients without Silver Label Dx (any) in the study period;
*All ENCTYPEs;
Proc sql;
select count(distinct case when Flag_Dx_with_SLDx_Any=0 then &PATIDVARNAME. end) into: DX_DENO_WO_SLDx 
from &OUTLIB..Numerator_Dx;
quit;

%Put &DX_DENO_WO_SLDx ;


Proc sql;
Create table &OUTLIB..&OutputFileName. as
Select /*compress(CATX('-',DX,Diagdesc)) as DX_DESC*/
  DX
, Diagdesc

/*Primary Analyses*/
, count(distinct &PATIDVARNAME.) 
	as DX_COUNTS
		format=comma10.
		Label="[DX_COUNTS]COL-A=#Distinct patients with DX encounter (any)"
, Count(distinct Case when Flag_Dx_with_SLDx_Any=1 then &PATIDVARNAME. end) 
	as SLDX_COUNTS
		format=comma10.
		Label="[SLDX_COUNTS]COL-B=#Distinct patients w/ SILVER LABEL dx followed by DX encounter within &DAYSLOOKUP. days"
, Count(distinct Case when Flag_Dx_with_SLDx_Any=0 then &PATIDVARNAME. end) 
	as OTHER_COUNTS
		format=comma10.
		Label="[OTHER_COUNTS]COL-C=#Distinct patients with other Dx encounter and without SILVER LABEL dx in &DAYSLOOKUP. days prior"
, Count(distinct Case when Flag_Dx_with_SLDx_Ever=0 then &PATIDVARNAME. end)
	as N_WITHOUT_SLDX_EVER
		Label="[N_WITHOUT_SLDX_EVER]COL-D=#Distinct Patients who did not have a U07.1 at any time during the study period"
, calculated SLDX_COUNTS / &DX_DENO_W_SLDX.
	as WITH_SLDX_RATE
		format=comma10.8
		Label="[WITH_SLDX_RATE]COL-E=COL-B/#Pts w/ Silver Label dx. Numerator= SLDX_COUNTS; Denominator= #distinct patients with SILVER LABEL dx (Deno=&DX_DENO_W_SLDX.)"
, calculated OTHER_COUNTS / &DX_DENO_WO_SLDX.
	as WITHOUT_SLDX_RATE
		format=comma10.8
		Label="[WITHOUT_SLDX_RATE]COL-F=COL-C/#Pts w/o Silver Label dx. Numerator=OTHER_COUNTS; Denominator= #distinct patients without SILVER LABEL dx (Deno=&DX_DENO_WO_SLDX.)"
, Calculated WITH_SLDX_RATE / Calculated WITHOUT_SLDX_RATE
	as RELATIVE_RISK
		format=comma10.2
		Label="[RELATIVE_RISK]COL-G=COL-E/COL-F. Numerator=WITH_SLDX_RATE; Denominator=WITHOUT_SLDX_RATE"

From &OUTLIB..Numerator_Dx
Group by DX
, Diagdesc
Having calculated RELATIVE_RISK >=&RRMAX.
    or calculated RELATIVE_RISK =.
Order by calculated RELATIVE_RISK desc, calculated DX_COUNTS desc;
quit;

********************************************;
*  	EXPORT TO EXCEL  	EXPORT TO EXCEL     ;
********************************************;
ods excel file="&EXCELOUT.\&OutputFileName..xlsx"
style=minimal options(embedded_titles='yes' embedded_footnotes='yes');

ods excel options (sheet_name = "HSF DX" sheet_interval="none");
proc odstext;
	p "Silver Label Dx (a.k.a. SLDX): &SILVERLABELDX." / style=[fontweight=bold fontsize=14pt];
	p "Lookup window: &DAYSLOOKUP. days (output based on 'other' diagnoses encounters within &DAYSLOOKUP. days of Silver Label Dx)" / style=[fontweight=bold fontsize=14pt];
	p "Study Period: &StartDt.- &EndDt." / style=[fontweight=bold fontsize=14pt];
	p "Encounters included: &Enctype_List." / style=[fontweight=bold fontsize=14pt];
	p "Relative Risk (Threshold): &RRMAX. (display output with relative risk of &RRMAX. or greater (high to low))" / style=[fontweight=bold fontsize=14pt];
run;

Proc print data=&OUTLIB..&OutputFileName. Noobs Label style=minimal;
run;
ods excel close;

%Mend HSF_DX;

****************************************************;
************** SAMPLE MACRO CALL *******************
************** SAMPLE MACRO CALL *******************
************** SAMPLE MACRO CALL *******************
****************************************************;

*%HSF_DX(Inlib 			 = OUT				  /*Input library reference*/
	,	InputCohortfile  = MyCohort		  	  /*Filename containing cohort of interest.Input files to include list of patient ids (variable: PatID or MRN)*/
	,	InputDxFile   	 = Out.Diagosis_Table /*table name containing diagnoses data. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, DX, DX_CODETYPE*/
	, 	PatIDvarName	 = PATID			  /*Variable name for Patient ID. Ex. MRN (if using HCSRN.VDW data modl), PATID (if using SCDM data model)*/
	,   VisitType		 = C				  /*Valid values: I=Inpatient, B=both Inpatient and Outpatient, A=All encountertypes, or C=custom list (populate ENCTYPE_LIST parameter)*/
	,   Enctype_List     = 'IP','AV'		  /*Create custom list of encounter types (with quotes, separated by comma) here if VISITYPE=C. ex. ENCTYPE_LIST  = 'IP','AV' */
	,	OutLib			 = OUT				  /*Output library reference*/
	, 	OutputFileName	 =	Summary_by_dx	  /*Output file name*/	
	,	SilverLabelDx	 = 'U07.1'			  /*List the "Silver" label diagnoses within single quotes"'" and separated by comma "," (in case of multiple diagnosis codes). For example: 'U07.1'*/
	,   DaysLookup		 =	3				  /*Output to include diagnoses following the Silver Label dx within the look up window . Ex DaysLookup=3 */
	,	StartDt		 	 = 01Apr2020 		  /*Start date of the data period (without quotes). Ex: 01Apr2020*/
	,	EndDt			 = 31Mar2021 		  /*End date of the data period (without quotes). Ex: 31Mar2021*/
	,	DxCodeList		 = OUT.Distinct_DiagCd/*List of ICD9/10 codes with descriptions. Include 2 columns:DIAGCD and DIAGDESC */
	,	RRmax			 = 10				  /*Specify the threshold for the relative risk. Ex: 10 (output to consist of only those DX codes w/ relative risk >= 10*/
	   );
