%Macro HSF_PX( InLib 			= 		/*Input libname reference*/
			 , InputCohortfile 	= 		/*Filename containing cohort of interest.Input files to include list of patient ids (variable: PatID)*/
			 , InputDxFile   	= 		/*Table name containing diagnoses data. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, DX, DX_CODETYPE*/
			 , InputPxFile   	= 		/*Table name containing Procedures data. Include the following columns: PATID, ENCOUNTERID, ADATE, ENCTYPE, PX*/
			 , PatIDvarName		=		/*Variable name corresponding to Patient identifier. Ex. MRN (in HCSRN.VDW), PATID (in SCDM)*/
			 , VisitType		= A		/*Valid values: I=Inpatient, B=both Inpatient and Outpatient, A=All encountertypes, or C=custom list (populate ENCTYPE_LIST parameter)*/
			 , Enctype_List     =		/*Create custom list of encounter types here if VISITYPE=C. ex. ENCTYPE_LIST  = ('IP','AV') */
			 , OutLib			=		/*Ouput library reference*/
			 , OutputFileName	=		/*Name of the output file (output exported to both Excel and SAS dataset)*/
			 , SilverLabelDx	= 		/*List the "Silver" label diagnoses within single quotes"'" and separated by comma "," (in case of multiple diagnosis codes). For example: 'U07.1'*/
			 , DaysLookup		=		/*Number of days following Silver Label dx within which we are including diagnoses. Ex DaysLookup=3*/
			 , StartDt			= 		/*Start date of the data period (without quotes). Ex: 01Apr2020*/
			 , EndDt			= 		/*End date of the data period (without quotes). Ex: 31Mar2021*/
			 , PxCodeList	    =		/*File containing list of diagnosis codes and descriptions. Include variables: PX, PX_DESC*/
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

*Pull Silver Label DX encounters for PATIDs in InputCohortFile during the study start and end dates;
Proc sql;
Create table &OUTLIB..SLDX_Visits as
Select b.*

From &INLIB..&INPUTCOHORTFILE. as A INNER JOIN &INPUTDXFILE. as B ON a.&PATIDVARNAME.=b.&PATIDVARNAME.
																 and "&STARTDT."d<=b.Adate<="&ENDDT."d
																 and  (b.DX in (&SILVERLABELDX.) or b.ORIGDX in (&SILVERLABELDX.))
																&VISITTYPE.
Order by b.&PATIDVARNAME., b.Adate;
quit;

*Pull Silver Label Dx encounters (for ALL members, DO NOT limit to cohort);
Proc sql;
Create table &OUTLIB..SilverLabelDx as
Select *
From &OUTLIB..SLDX_Visits
where  (DX in (&SILVERLABELDX.) or ORIGDX in (&SILVERLABELDX.))
and "&STARTDT."d<=Adate<="&ENDDT."d;
quit;

*Create macro variable capturing #Patients w/ Silver Label dx (Ex: U07.1);
Proc sql;
Select count(distinct &PATIDVARNAME.) into: N_PTS_SilverLabelDx
From &OUTLIB..SilverLabelDx
where  (DX in (&SILVERLABELDX.) or ORIGDX in (&SILVERLABELDX.));
quit;
%put &N_PTS_SilverLabelDx.;

*Numerator;
Proc sql;
Create table &OUTLIB..Numerator_Px as
Select 	  a.&PATIDVARNAME.
		, a.Adate
		, a.Px
		, c.Px_desc
		, a.EncType

		/*Numerators for Primary Analysis*/
		, Min(Case when a.&PATIDVARNAME.=b.&PATIDVARNAME.
					 and 0<=intck('Days',b.Adate,a.Adate)<=&DAYSLOOKUP.		
						&VISITTYPE.		then b.ADate end)  
				as SLDx_Dt
				Label="[SLDx_Dt]Qualifying Silver Label dx date(earliest of the dates w/ Silver Label Dx:&SILVERLABELDX. followed by Px encounter within &DAYSLOOKUP. days"
				Format=date9.
		, Max(Case when a.&PATIDVARNAME.=b.&PATIDVARNAME.
					 and 0<=intck('Days',b.Adate,a.Adate)<=&DAYSLOOKUP.	 		
						&VISITTYPE. then 1 else 0 end) 
			as Flag_Px_with_SLDx_Any
				Label="[Flag_Px_with_SLDx_Any]1=Yes, have Silver Label Dx:&SILVERLABELDX. followed by Px encounter within &DAYSLOOKUP. days, 0=else"

		/* Those with this specific Dx (at any time during the study period) did not have a Silver Label Dx at any time during the study period*/
		 , Max(Case when a.&PATIDVARNAME.=b.&PATIDVARNAME.
						&VISITTYPE. then 1 else 0 end) 
			as Flag_Px_with_SLDx_Ever
				Label="[Flag_Px_with_SLDx_Ever]1=Yes,have Silver Label Dx:&SILVERLABELDX. ever during the study period, 0=else"

From &INPUTPXFILE. as A Left Join &OUTLIB..SilverLabelDx (drop=ENCTYPE)	as B on a.&PATIDVARNAME.=b.&PATIDVARNAME.
						Left Join &PxCodeList.						    as C on compress(a.Px,".")=c.Px
						Inner Join &INLIB..&INPUTCOHORTFILE.			as D on a.&PATIDVARNAME.=d.&PATIDVARNAME.

Where "&STARTDT."d<=a.Adate<="&ENDDT."d
 &VISITTYPE.
Group by  a.&PATIDVARNAME.
		, a.Adate
		, a.Px
		, c.Px_desc
		, a.EncType;
quit;

********************************************;
*  	Denominators for Primary analysis       ;
********************************************;
* denominator=total number of distinct patients w/ Silver Label Dx (any) in the study period;
Proc sql;
 select count(distinct case when Flag_Px_with_SLDx_Any=1 then &PATIDVARNAME. end) into: PX_DENO_W_SLDx 
from &OUTLIB..Numerator_Px ;
quit;

%Put &PX_DENO_W_SLDx ;

* denominator=total number of distincts patients without Silver Label Dx (any) in the study period;
*All ENCTYPEs;
Proc sql;
select count(distinct case when Flag_Px_with_SLDx_Any=0 then &PATIDVARNAME. end) into: PX_DENO_WO_SLDx 
from &OUTLIB..Numerator_Px;
quit;

%Put &PX_DENO_WO_SLDx ;


Proc sql;
Create table &OUTLIB..&OutputFileName. as
Select PX
	, Px_desc

	/*Primary Analyses*/
	, count(distinct &PATIDVARNAME.) 
		as PX_COUNTS
			format=comma10.
			Label="[PX_COUNTS]COL-A=#Distinct patients with PX encounter (any)"
	, Count(distinct Case when Flag_Px_with_SLDx_Any=1 then &PATIDVARNAME. end) 
		as SLDX_COUNTS
			format=comma10.
			Label="[SLDX_COUNTS]COL-B=#Distinct patients w/ SILVER LABEL dx followed by PX encounter within &DAYSLOOKUP. days"
	, Count(distinct Case when Flag_Px_with_SLDx_Any=0 then &PATIDVARNAME. end) 
		as OTHER_COUNTS
			format=comma10.
			Label="[OTHER_COUNTS]COL-C=#Distinct patients with other Px encounter and without SILVER LABEL dx in &DAYSLOOKUP. days prior"
	, Count(distinct Case when Flag_Px_with_SLDx_Ever=0 then &PATIDVARNAME. end)
		as N_WO_SLDX_EVER
			Label="[N_WO_SLDX_EVER]COL-D=#Distinct Patients who did not have a U07.1 at any time during the study period"
	, calculated SLDX_COUNTS / &PX_DENO_W_SLDX.
		as WITH_SLDX_RATE
			format=comma10.8
			Label="[WITH_SLDX_RATE]COL-E=COL-B/#Pts w/ Silver Label dx. Numerator= SLDX_COUNTS; Denominator= #distinct patients with SILVER LABEL dx (Deno=&PX_DENO_W_SLDX.)"
	, calculated OTHER_COUNTS / &PX_DENO_WO_SLDX.
		as WITHOUT_SLDX_RATE
			format=comma10.8
			Label="[WITHOUT_SLDX_RATE]COL-F=COL-C/#Pts w/o Silver Label dx. Numerator=OTHER_COUNTS; Denominator= #distinct patients without SILVER LABEL dx (Deno=&PX_DENO_WO_SLDX.)"
	, Calculated WITH_SLDX_RATE / Calculated WITHOUT_SLDX_RATE
		as RELATIVE_RISK
			format=comma10.2
			Label="[RELATIVE_RISK]COL-G=COL-E/COL-F. Numerator=WITH_SLDX_RATE; Denominator=WITHOUT_SLDX_RATE"

From &OUTLIB..Numerator_Px
Group by Px
	, Px_desc
Having calculated RELATIVE_RISK >=&RRMAX.
    or calculated RELATIVE_RISK =.
Order by calculated RELATIVE_RISK desc, calculated PX_COUNTS desc;
quit;

********************************************;
*  	EXPORT TO EXCEL  	EXPORT TO EXCEL     ;
********************************************;
title "High Sensitivity Filter (PX) - SLDx &SILVERLABELDX., lookup &DAYSLOOKUP. days, RR>=&RRMAX.";
Proc print data=&OUTLIB..&OutputFileName. Noobs Label;
run;
title;

%Mend HSF_PX;
%HSF_Px(Inlib            = WORK
    ,   InputCohortfile  = MyCohort
    ,   InputDxFile      = WORK.DxData
    ,   InputPxFile      = WORK.PxData
    ,   PatIDvarName     = PATID
    ,   VisitType        = A
    ,   Enctype_List     =
    ,   OutLib           = WORK
    ,   OutputFileName   = Summary_by_Px
    ,   SilverLabelDx    = 'U07.1'
    ,   DaysLookup       = 10
    ,   StartDt          = 01Apr2020
    ,   EndDt            = 31Mar2021
    ,   PxCodeList       = WORK.PxCd
    ,   RRmax            = 0
       );
