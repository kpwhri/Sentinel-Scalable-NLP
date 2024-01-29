*-------------------------------------------------------------------------------------------;
* STUDY: PHENORM ANAPHYLAXIS                                      					        ;
* STUDY NUMBER: (TASK ORDER F1 CONCEPT) 													;
* STUDY TYPE:	KPWA for the moment 	                                                    ;
* PROGRAM: \\groups.ghc.org\data\CTRHS\Immu\VSD Task Order F1 concept ideas                 ;
*           \KPWPhenormAnaphylaxis\Programming\Programs                                     ;
*           \01_define_cohort_SF.sas     											        ;
*-------------------------------------------------------------------------------------------;
* VERSION: 1                                                                                ;
* CHANGES: 								                                                    ;
*-------------------------------------------------------------------------------------------;
* AGES: all     											                                ;
*-------------------------------------------------------------------------------------------;
* PURPOSE:  To identify cases of presumed anaphylaxis for NLP analysis                      ;
*-------------------------------------------------------------------------------------------;
* PROGRAMMING SPEC:   \\groups.ghc.org\data\CTRHS\Immu\VSD Task Order F1 concept ideas      ;
* 					    \KPWPhenormAnaphylaxis                                     			;
* 						\Programming_Specs\ANA_PheNorm_Methods_2023_04_27_15.55PM_Pac.docx  ;
*-------------------------------------------------------------------------------------------;
* PROGRAMMER:          Sharon Fuller (sharon.fuller@kp.org) (KPWA)                    		;
* REQUESTED BY:        Onchee, Yu for David Carrell                       					;
* DATE CREATED:	       May 2023                        										;
* SITES PARTICIPATING: KPWA       							                                ;
*-------------------------------------------------------------------------------------------;
* BRIEF DESCRIPTION OF WHAT THE PROGRAM DOES:	     								        ;
* 1. ID population of interest (target.enroll, target.constant)                             ;
* 2. Pull anaphylaxis-related diagnoses and procedures from VDW Dx and Px                   ;
* 3. Use these codes to identify cases of presumed anapylaxis                               ;
* 4. Calculate additional variables, including nearby vaccines                              ;
* 5. Output 2 final datasets - target.anaphylaxis_presumptive, target.anaphylaxis_details   ;
* ------------------------------------------------------------------------------------------;
* INPUT DATASETS: from Event files: ENROLL, CONSTANT, VACCINE,                              ;
*                   (using DDF rather than cycle, because need data into current year)      ;
*                   no longer using OUTPT, INPT, PROCDRE                                    ;
*                     because VDW currently more reliable                                   ;
*                     and want to be able to easily repurpose code for Sentinel             ;
*                 from VDW: Px (for HCPC - not included in VSD PROCDRE file)                ;
*                   also now using for Dx (and Utilization)                                 ;
*                 StudyID/MRN Crosswalk: \\ghcmaster\ghri\GHRI-VSD\VSD_Data\VSD\csridxrfmstr; 
* DATA DICTIONARY:        G:\CTRHS\Immu\Programmers\Cycle Code\cycle2022\data dictionaries  ;
* STATISTICAL PROCEDURES: none																;
* OUTPUT DATASETS:        TBD                                                               ;
* BRIEF DESCRIPTION OF TRANSFER OF DATA SETS:	                     NA						;
* HOW MANY, CPT OR XPT?: 	                                         NA     	            ;
* IF DATA IS LEFT @ EACH SITE, WHERE IS IT AND HOW IS IT NAMED?:	 NA                     ;
* SITE SPECIFIC INSTRUCTIONS THAT ARE CRITICAL FOR IRB AND SPECIAL INSTRUCTIONS:	NA      ;
* PROGRAM HAS BEEN TESTED AT MY SITE:                              YES                      ;
* INDIVIDUAL LEVEL DATA:	                                         YES					;
* PHIs?:                  diagnosis and procedure dates       	                        	;
* LARGE SORT PROCEDURES:	PROC SORT, PROC SQL ORDER BY              					  	;
*-------------------------------------------------------------------------------------------;

/*********************************************
* REVISIONS:
*  2023-07-24 changed from Anaphylaxis_id to Anaphylaxis_Num per Onchee request
*       changed calc of INPT, OUTPT and PROCDRE visit start and end dates
*         to improve quality, and make sure episode length is later calculated correctly
*  2023-08-04 changed from using kpwa_diagdate in INPT and OUTPT to using adate per team request
*         revised INPT and OUTPT visit start and end date calcs again, accordingly
*       re-ran utilization pieces through end to implement changes
*         and take advantage of updated VDW data
*       note that size of INPT decreased a lot because now only one adate per admit
*         but minimal effect on final numbers
*  2023-08-07 excluded VDW IS enctype from OUTPT file per Onchee report of long encounter
*       fixed creation of CareType variable in HCPC section, so does not default to VDW enctype as often
*       fixed label for CareType variable
*       changed the single instance of X for primsec in vdw to N (CX->CN)
*  2023-08-08 excluded OE enctype from OUPT, PROCDRE and HCPC
*       reverted to original CareType label
*
* TO DO:
*
* RUN NOTES:  
*    do not run any code that hits VSD files on Monday before noon
*    2023-08-03 confirmed that do NOT want to use kpwa_diagdate for INPT or OUTPT - use adate instead
*    episode key is studyid, visit_start_date, episode_end_date
*
*********************************************/
*Signoff;
%include "H:\sasCSpassword.sas";
%include "\\ghcmaster.ghc.org\ghri\warehouse\sas\includes\globals.sas";
%include "\\groups.ghc.org\data\CTRHS\CHS\ITCore\SASCONNECT\RemoteStartRDW.sas";

%make_spm_comment(DI7 Assisted Review-Define cohort) ;
*include VDW standard vars and macros;
options nosymbolgen;
%include "&GHRIDW_ROOT.\Sasdata\CRN_VDW\lib\StdVars.sas" ;

options source2 linesize = 95 pageno=1 nocenter msglevel = i
        formchar='|-++++++++++=|-/|<>'  noovp;
options compress = yes;
options symbolgen;
*options mprint mlogic;

*needed to run my macros;
options sasautos = ("\\groups\DATA\CTRHS\CHS\FullerSharon\macros" "&GHRIDW_ROOT.\sas\sasautos" sasautos);

*footnote1 is currfile and is set in remoteactivate.sas;
footnote2 "Created by &sysuserid. on &sysday., &sysdate9.";

%put PROGRAM START TIME : %sysfunc(datetime(),datetime14.);

* ________________________________________________________________________________________________;
*folders for lookup and output;
%let outdata = \\Groups.ghc.org\Data\CTRHS\Sentinel\Innovation_Center\DI7_Assisted_Review;
%let lookup = &outdata.\PROGRAMMING\Specs;
	libname lookup "&lookup.";
%let target = &outdata.\PROGRAMMING\SAS Datasets\01_Define_Cohort\09AUG2023;
	libname target "&target.";
%let temp = &target.\PROGRAMMING\SAS Datasets\01_Define_Cohort\09AUG2023;
	libname temp "&temp.";
%let analyt = &outdata.\PROGRAMMING\SAS Datasets\01_Define_Cohort\09AUG2023;
	libname analyt "&analyt.";

Libname xwalk "&outdata.\PROGRAMMING\SAS Datasets\xwalk";

*Assign libname to GHC_LOOKUP db so programmers can upload sample patients to enable merge with Clarity DB. Both GHC_LOOKUP and CLARITY dbs are on the same server;
libname  GHCLKUP   OLEDB provider=SQLOLEDB datasource='EPCLARITY_RPT' properties=("Integrated Security"=SSPI "Initial Catalog"=GHC_LOOKUP) DBMAX_TEXT=32767 ;
Libname CHSID "\\ghcmaster\ghri\Warehouse\sasdata\Chsid" access=readonly;

*data file to pull from;
/*  libname event "\\ghcmaster\ghri\ghri-vsd\vsd_model\event"     access=readonly;*/
*  libname c2022 "\\ghcmaster\ghri\ghri-vsd\VSD_Model\Cycle2022" access=readonly;

*crosswalk;
/*  libname vsd 	  "\\ghcmaster\ghri\GHRI-VSD\VSD_Data\VSD"      access=readonly;*/

*%let daysTol=0; *do we still need to collapse enrollments? VSD data dictionary seems to say not;
%let lookbackdays = 60; *shortest possible 2 months is Jan-Feb (59), but affirmatively chose 60;

*---Dates of Interest---;
%let studyStartDate=01Jan2006;
%let studyEndDate  =31Mar2023;

**------------- Utility macro for fairly precisely calculating age.--------- ;
%macro CalcAge(BDtVar, RefDate);
  floor ((intck('month',&BDTVar,&RefDate) - (day(&RefDate) < min (day(&BDTVar),
  day (intnx ('month',&RefDate, 1) - 1) ) ) ) /12 )
%mend CalcAge;


********************************************;
*** read in lookup code list ***;
********************************************;
*only need to do if Excel list changes;
*see Notes tab on spreadsheet for rules for each path;

* IN: xlin.code_list;
*OUT: lookup.code_list;

%macro getcodelist;
title3 "GET CODE LIST";

  *n=399;
  libname xlin XLSX "&lookup.\anaphylaxis_code_lookup.xlsx";
  data work.code_list;
    set xlin.code_list;
  run;
  libname xlin clear; /*removes the lock*/

  proc sql;
  	create table lookup.code_list as
  	select *
  	from work.code_list
  	order by code_type, code
  	;
  	*index is to speed queries below;
	create unique index TypeAndCode
	on lookup.code_list(code_type, code)
	;
  quit;

  proc contents data=lookup.code_list; run;

  	proc freq data=lookup.code_list;
  		tables 	DX_PX * CODE_TYPE
  				WalshTable  * WalshGroup
  				/ list missing;
	run;

title3;
%mend getcodelist;
%getcodelist;


********************************************;
*** SUBSET ENROLL FILE ***;
********************************************;
*during timeframe of interest, with long enough enrollment;
*takes about 2 minutes;

*for SENTINEL - rebuild using VDW;

* IN: event.enroll ;
*OUT: target.enroll;

%macro getenroll;
title3 "GET ENROLL";
  title4 "target.enroll - 1 record per enrollment (at least &lookbackdays. days long) in study period";
*n= 11,688,375  eligible enrollments;
	proc sql;
	  create table Target.enroll_tmpA as
		select  c.mrn
		  	  , c.Birth_date                as Birthdate                   format date10.
			  , e.Enr_Start                 as EnrollStartDate             format date10.
			  , e.Enr_End                   as EnrollEndDate               format date10.
			  , e.GPDConfidence
			  , Case when e.GPDConfidence >=0.8 Then 1 else 0 end
				as chrtflag      
					label "[chrtflag] 1=chart avail for review (i.e. GPDConfidence >= 0.8)"

	from &_VDW_Enroll. as E INNER JOIN &_VDW_Demographic. as C  on e.MRN = c.MRN
 															   and e.Enr_Start <= "&studyenddate."d   /*enroll starts before study end*/
  	                                                           and e.Enr_End >= "&studystartdate."d   /*enroll ends after study start*/
															   and c.Birth_date ne .;				  /*drop members with missing birth_date*/
  quit;

*Include flag:chrtflag; 
	proc sort data=target.Enroll_tmpA out=Enroll_tmpA(keep= MRN Birthdate EnrollStartDate EnrollEndDate chrtflag);
	by MRN EnrollStartDate;
	run;

*n=4,145,186;
*Collapse enrollment records 0 day gap between enrollment periods;
	%CollapsePeriods(Lib		= work				/*The name of the sas library where your input dataset is located (e.g., ‘work’, ‘perm’, etc.)*/
					,DSet		= Enroll_tmpA		/*The name of your input dataset*/
					,RecStart	= EnrollStartDate	/*The name of the date variable in Dset holding the start of a period.*/
					,RecEnd		= EnrollEndDate		/*The name of the date variable in Dset holding the end of a period.*/
					,PersonID	= MRN				/*The name of the variable in Dset that uniquely identifies a person.  Defaults to MRN.*/
					,DaysTol	= 0					/*The number of days gap to ignore between otherwise contiguous periods of no change.*/
					,OutSet		= target.Enroll_tmpA_Collapse);	/*(Optional) The name of a dataset to put the collapsed records in.  If not given, the dataset specified in &Lib..&DSet is replaced.*/

*Have a 60-day continuous enrollment at KPWA;
	*n=3,797,341;
	data target.Enroll_tmpB;
	set target.Enroll_tmpA_Collapse;	
	where EnrollEndDate - EnrollStartDate >= &lookbackdays.;
	format EnrollStartPlusLookbackDate date10.;
		EnrollStartPlusLookbackDate= EnrollStartDate + &lookbackdays.; /*needed for dx and px calcs*/
	run;

  *n=3,797,329 - 0 dups;
  proc sort data=target.Enroll_tmpB out=target.enroll nodupkey;
    by mrn enrollstartdate;
  run;
  
  proc freq data=target.enroll;
    tables  enrollstartdate /*1998-2023*/ 
            enrollenddate   /*2026-2023*/
            chrtflag        /*43% 1 else U*/
            ;
    format enrollstartdate enrollenddate year.;
  run;
  
title3;
%mend getenroll;
%getenroll;
 
*QC;
*NObs     	  NMrns                                                                                                                                                         
3,797,341    2,347,801;   
Proc sql;
Select count(*) as NObs
, count(distinct MRN) as NMrns
From target.enroll;
quit;

********************************************;
*** SUBSET CONSTANT FILE ***;
********************************************;
*one record per patient in enroll file;
*takes about 2 minutes;

*for SENTINEL - rebuild using VDW Demographic;

* IN: event.constant;
*OUT: target.constant;

%macro getconstant;
title3 "GET CONSTANT";
  
  title4 "target.constant - 1 record per person in target.enroll";
  *for n=2,347,789 distinct MRNs;
  proc sql;
  	create table Target.constant_A as
  	select distinct e.mrn
  	  	, e.Birthdate
  		, c.sex_admin 
			as sex 
				label="[sex] F/M/U"
      	, c.RACE1
		, c.RACE2
		, c.RACE3
		, c.RACE4
		, c.RACE5
		, c.HISPANIC as HISPETHNICITY
  	from target.enroll  as E INNER JOIN &_VDW_Demographic. c on e.mrn = c.mrn
 	;
  quit;

	*Race recoding;
  data Target.constant_A;
  set Target.constant_A;
	      if RACE1 in ('BA') or
		    RACE2 in ('BA') or
		  	RACE3 in ('BA') or
		  	RACE4 in ('BA') or
		  	RACE5 in ('BA') 		then BLACK=1;  /*Black*/
	else if RACE1 in ('IN') or 
		    RACE2 in ('IN') or 
			RACE3 in ('IN') or 
	  	 	RACE4 in ('IN') or 
	  	 	RACE5 in ('IN') 		then NATAMER=1;  /*American Indian/Alaska Native*/
	else if HISPETHNICITY='Y' 		then HISPANIC=1;  /*Hispanic/Latino*/
	else if RACE1 in ('AS') or 
	  		RACE2 in ('AS') or 
	  		RACE3 in ('AS') or
	  	 	RACE4 in ('AS') or 
	  	 	RACE5 in ('AS') 		then ASIAN=1;  /*Asian*/
	else if RACE1 in ('HP') or 
	  		RACE2 in ('HP') or 
	  		RACE3 in ('HP') or
	  	 	RACE4 in ('HP') or 
	  	 	RACE5 in ('HP') 		then HAWAIIAN=1;  /*Native HP/Other Pacific Islander*/
	else if RACE1 in ('WH') or 
			RACE2 in ('WH') or 
			RACE3 in ('WH') or
	  	 	RACE4 in ('WH') or 
	  	 	RACE5 in ('WH') 		then WHITE=1; /*White*/
									else OTHER=1; /*Other or Unknown*/
	run;

  *set races to numeric, and add 0 where appropriate;
  data Target.constant_B;
  set  Target.constant_A;
    whitenumorig    = white   ;
    blacknumorig    = black   ;
    asiannumorig    = asian   ;
    hawaiiannumorig = hawaiian;
    natamernumorig  = natamer ;
    othernumorig    = other   ;
    hispanicnum     = hispanic;
    
    /*RaceCount = 0;
    RaceCount   = sum(whitenumorig,blacknumorig,asiannumorig,hawaiiannumorig,natamernumorig,othernumorig,0);
    HasRace  = .;
    if RaceCount>=1 then HasRace = 0;*/*sic;
    
    whitenum    = coalesce(whitenumorig    , 0);
    blacknum    = coalesce(blacknumorig    , 0);
    asiannum    = coalesce(asiannumorig    , 0);
    hawaiiannum = coalesce(hawaiiannumorig , 0);
    natamernum  = coalesce(natamernumorig  , 0);
    othernum    = coalesce(othernumorig    , 0);
	hispanicnum = coalesce(hispanicnum    , 0);
  run;
  
  proc contents data=Target.constant_B;
  run;

  proc freq data=Target.constant_B;
    tables whitenumorig
           whitenum/ missing;
  run;
  
  proc sql;
    create table work.constant as
    select c.Mrn
	  , c.Birthdate
  	  , c.sex
  	  , c.RACE1
	  , c.RACE2
	  , c.RACE3
	  , c.RACE4
	  , c.RACE5
	  , c.HISPETHNICITY
      , c.WHITEnum        as  WHITE     label "[white   ] patient has white    race recorded (1=yes/0=no/. = no race recorded)"          
      , c.BLACKnum        as  BLACK     label "[black   ] patient has black    race recorded (1=yes/0=no/. = no race recorded)"          
      , c.ASIANnum        as  ASIAN     label "[asian   ] patient has asian    race recorded (1=yes/0=no/. = no race recorded)"          
      , c.HAWAIIANnum     as  HAWAIIAN  label "[hawaiian] patient has hawaiian race recorded (1=yes/0=no/. = no race recorded)"          
      , c.NATAMERnum      as  NATAMER   label "[natamer ] patient has natamer  race recorded (1=yes/0=no/. = no race recorded)"          
      , c.OTHERnum        as  OTHER     label "[other   ] patient has other    race recorded (1=yes/0=no/. = no race recorded)"          
      , c.HISPANICnum     as  HISPANIC  label "[hispanic] patient has hispanic ethnicity recorded (1=yes/0=no/. = no ethnicity recorded)"
    from Target.constant_B as C
    order by mrn
    ;
  quit;

  *n=2,347,789 - no idea why there would have been a duplicate;
  proc sort data=work.constant out = target.constant nodupkey;
    by mrn;
  run;
  
  *hope to speed VDW joins, also confirms have only unique records;
  proc sql;
  create unique index mrn
	on target.constant(mrn);
  quit;
   
  proc freq data=target.constant;
    tables birthdate       /*1897-2023*/
           sex             /*53% female, a few U*/
           WHITE BLACK ASIAN HAWAIIAN NATAMER OTHER HISPANIC
           / missing;
    format birthdate  year.;
  run;
 
%mend getconstant;
%getconstant; 


********************************************;
*** get INPT Dx from VDW ***;
********************************************;
*takes 5 minutes;

*for SENTINEL - throughout the code, some of the transforms are less than intuitive;
*  they are written as they are to try to reproduce VSD variables;

* IN: &_vdw_utilization., &_vdw_px., target.enroll, lookup.code_list;
* OUT:temp.inptvdw, target.inptvdw;

%macro getinptVDW;
title3 "GET INPT VDW - dx codes from VDW";

  *get all relevant dx from inpt enc types in study period;
  *n=101,932;
  proc sql;
    create table target.inptvdw_tempA as
    select distinct dx.mrn
	  , dx.enc_id
/*      , dx.kpwa_diagdate*/
      , dx.adate
      , u.ddate
      , compress(dx.dx, '.')  as DxPxCode
      , u.discharge_status
      , dx.DX_codetype        as CodeType
      , dx.enctype
      , u.encounter_subtype
	  , dx.primary_dx 
	  , dx.kpwa_int_ext 
      , c.walshtable, c.walshgroup
    from &_vdw_dx. as DX inner join &_vdw_utilization. as U on u.enc_id = dx.enc_id
   	  					 inner join lookup.code_list   as C on  c.dx_px = 'DX'
   	                                  						and dx.dx_codetype = c.code_type
   										                	and compress(dx.dx, '.') = c.code
    where dx.enctype = 'IP'
      and dx.adate between "&studystartdate."d and "&studyenddate."d
    ;
  quit;
  
  *all are AI (acute inpatient);
  proc freq data=target.inptvdw_tempA;
    tables encounter_subtype;
  run;

  *limit to population;
  *n=96,414;
  proc sql;
    create table work.inptvdw (drop = /*kpwa_diagdate*/ adate ddate discharge_status primary_dx
                                      enctype kpwa_int_ext) as
    select e.mrn
     , a.*
      /*, coalesce(a.kpwa_diagdate, a.adate)          as Visit_Start_Date format mmddyy10.
      , coalesce(a.ddate, a.kpwa_diagdate, a.adate) as Visit_End_Date   format mmddyy10.
      */
      , /*case when a.ddate >= a.adate
			    then a.kpwa_diagdate else*/ a.adate /*end*/             as Visit_Start_Date format mmddyy10. label "Visit Start Date - date of diagnosis or procedure (or admit date if actual date unknown, or not between adate and ddate)"
			, case when a.ddate >= a.adate /*calculated Visit_Start_Date*/
			    then a.ddate else a.adate /*calculated Visit_Start_date*/ end as Visit_End_Date   format mmddyy10.
      , calculated visit_end_date - a.adate/*calculated visit_start_date*/ as Duration /*used only for sorting*/

      /*, case when a.kpwa_diagdate is not null 
          then a.kpwa_diagdate - a.adate end  as DxDaysAfterAdmit*/
      , case 
 		      when a.discharge_status = 'EX'         then 'EX'
 		      when a.discharge_status = 'SN'         then 'SF'
 		      when a.discharge_status in ('IP','SH') then 'HS'
 	          when a.discharge_status in ('HO','AF','AL','AM','AW','HH','HS','NH','RS','RH') then 'AN'
 		      else '' end                        	as DischargeDisposition
		  , 'H'||trim(left(a.primary_dx))         	as CareTYPE   
      , '1INPT'                               		as CareSetting
      , case when a.kpwa_int_ext = 'E' then 'O'
          else a.kpwa_int_ext end             		as LOCATION
    from target.inptvdw_tempA as A inner join target.enroll  as E on a.mrn = e.mrn    
   where a.adate/*calculated Visit_Start_Date*/ between e.EnrollStartPlusLookbackDate and e.EnrollEndDate  
    order by e.mrn, visit_start_date/*, kpwa_diagdate*/
      , walshtable, walshgroup, dxpxcode
    	, caretype, duration desc, dischargedisposition
    	, encounter_subtype
    	;
  quit;

  *one record per caredate, code;
  *N=85,488 ;
  proc sort data=work.inptvdw out = target.inptvdw nodupkey;
    by mrn visit_start_date walshtable walshgroup dxpxcode;
  run;
  
  proc freq data=target.inptvdw;
    tables  dxpxcode                    /*mostly the 2 usual*/
            visit_start_date * location
            /list missing;   
    format visit_start_date year.;       
  run;

title3;
%mend getinptVDW;
%getinptVDW;

 
********************************************;
*** get OUTPT Dx from VDW ***;
********************************************;
*takes 15-20 minutes;

*for SENTINEL - theoretically, could roll this into getinptVDW above;
  *but no compelling need, and leaving separate ensures comparability with VSD;

* IN: &_vdw_utilization., &_vdw_dx.,target.enroll, lookup.code_list;
* OUT:temp.outptvdw, target.outptvdw;

%macro getoutptVDW;
title3 "GET OUTPT - dx codes from VDW";

  *get dx of interest during entire study period;
  *n=364,669;
  proc sql;
    create table target.outptvdw_tempA as
    select a.mrn
      /*, a.kpwa_diagdate*/, a.adate, u.ddate
      , u.DEPT              /*would need to add the manual assignment of VDW to VSD dept in next step*/
      , u.discharge_status
      , a.DX_codetype         as CodeType
      , compress(a.Dx, '.')   as DxPxCode
		  , a.primary_dx
		  , a.enctype
		  , u.encounter_subtype 
		  , a.kpwa_int_ext 
      , c.walshtable, c.walshgroup
    from &_vdw_dx. as A inner join &_vdw_utilization. as U on u.enc_id = a.enc_id
  						inner join lookup.code_list   as C on c.dx_px = 'DX'
		  		                                          and a.dx_codetype = c.code_type 
		  		                               			  and compress(a.Dx, '.') = c.code
    where a.adate between "&studystartdate."d and "&studyenddate."d
  	  and a.enctype not in ('IP', 'VC', 'IS', 'OE', 'LO') /*2023-08-07 added exclusion on IS per Onchee report of long stay*/
  		                                            	  /*2023-08-08 added exclusion on OE because rare and odd*/
    ;
  quit;

  *limit to population and drop Walsh Table 3 dx that are not in ED;  
  *n=150,179;
  proc sql;
    create table work.outptvdw (drop = adate   /*kpwa_diagdate*/     ddate 
                                       discharge_status  primary_dx   primsec 
                                       enctype encounter_subtype kpwa_int_ext) as
    select e.mrn
      , a.*
      /*, coalesce(a.kpwa_diagdate, a.aDATE)          as Visit_Start_Date     format mmddyy10.
      , coalesce(a.ddate, a.kpwa_diagdate, a.adate) as Visit_End_Date       format mmddyy10.
      */
      , /*case when a.ddate >= a.adate
			    then a.kpwa_diagdate else*/ a.adate /*end*/      
													as Visit_Start_Date 
														format mmddyy10. 
														label "Visit Start Date - date of diagnosis or procedure (or admit date if actual date unknown, or not between adate and ddate)"
	  , case when a.ddate >= a.adate /*calculated Visit_Start_Date*/ then a.ddate else a.adate /*calculated Visit_Start_Date*/ end 
													as Visit_End_Date   format mmddyy10.
        , case 
 		      when a.discharge_status = 'EX'         then 'EX'
 		      when a.discharge_status = 'SN'         then 'SF'
 		      when a.discharge_status in ('IP','SH') then 'HS'
 	        when a.discharge_status in ('HO','AF','AL','AM','AW','HH','HS','NH','RS','RH') then 'AN'
 		      else '' end                      		as DischargeDisposition
		  , case when a.primary_dx = 'X' then 'N'
		      else trim(left(a.primary_dx)) end 	as primsec /*2023-08-07 added case to handle the oddball value of primary_dx*/
		  , case when a.encounter_subtype ='UC' 
			         then 'U'||calculated primsec
			       when a.enctype in ('AV','RO','LO')  
			         then 'C'||calculated primsec
			       when a.enctype ='ED' then 'E'||calculated primsec
			       else a.enctype end            	as CareTYPE   
      , case when a.encounter_subtype = 'UC' then '3URGENT'
          when a.enctype = 'ED' then '2ED'
          else '4OUTPT' end                			as CareSetting
      , case when a.kpwa_int_ext = 'E' then 'O'
          else a.kpwa_int_ext end          			as LOCATION

    from target.outptvdw_tempA as A inner join target.enroll as E on a.mrn = e.mrn
   where a.adate /*calculated Visit_Start_Date*/ between e.EnrollStartPlusLookbackDate and e.EnrollEndDate
      and (a.walshtable in (1,2) or a.enctype = 'ED')
    order by a.mrn, visit_start_date, walshtable, walshgroup, dxpxcode, caresetting, caretype
    	, dischargedisposition desc
    ;
  quit;

  *one record per caredate, dx code, setting;
  *130,134 after dedupe;
  proc sort data=work.outptvdw out = target.outptvdw nodupkey;
    by mrn visit_start_date walshtable walshgroup dxpxcode caresetting;
  run;

  *mostly I959 and 4589, also 51911, J9801 (confirmed this is ICD-10, rather than HCPC);
  proc freq data=target.outptvdw;
     tables dxpxcode  / list missing;           
  run;

title3;
%mend getoutptVDW;
%getoutptVDW;


********************************************;
*** get PROCDRE PX from VDW ***;
********************************************;
*takes 15-20 minutes;
*why so few ICD-9-PCS CPR codes, as compared to ICD-10-PCS?;

* IN: &_vdw_px., target.enroll, lookup.code_list;
* OUT:temp.procdrevdw, target.procdreVDW;

%macro getprocdreVDW;
title3 "GET PROCDRE VDW - px codes from VDW";

  *get all px of interest during study period;
  *n=9,621;
  proc sql;
    create table target.procdrevdw_tempA as
    select px.mrn
      , px.procdate, px.adate, u.ddate
      , compress(px.px, '.') as DxPxCode
      , px.px_codetype                          
      , u.discharge_status
		  , px.enctype
		  , u.encounter_subtype 
		  , px.kpwa_int_ext 
      , c.walshtable, c.walshgroup
	  from &_vdw_px. as PX inner join &_vdw_utilization. as U on px.enc_id = u.enc_id
					  	   inner join lookup.code_list   as C on c.dx_px = 'PX' 
					  	                                       and compress(px.px, '.') = c.code
					  	                                       and (px.px_codetype = 'C4'
					  	                                         or px.px_codetype = c.code_type) 
   where px.adate between "&studystartdate."d and "&studyenddate."d
   	 and px_codetype <> 'H4' /*doing these in next step - though if did all code in vdw, could wrap hcpcs in here*/
   	 and px.enctype not in ('VC', 'OE', 'IS', 'LO') /*2023-08-08 added OE, IS, LO exclusions as for OUTPT*/
    ;
  quit;

  *limit to population;
  *n=8,100;
  proc sql;
    create table work.procdrevdw (drop = procdate adate    ddate    discharge_status 
                                         px_codetype
                                         enctype  encounter_subtype kpwa_int_ext) as
    select e.mrn
      , a.*
      /*, coalesce(a.procdate, a.aDATE)          as Visit_Start_Date  format mmddyy10.
      , coalesce(a.dDate, a.procdate, a.aDATE) as Visit_End_Date    format mmddyy10.*/
	 , case when a.procdate between a.adate and coalesce(a.ddate, a.adate)
			    and a.ddate >= a.adate
			    then a.procdate else a.adate end            		as Visit_Start_Date format mmddyy10. label "Visit Start Date - date of diagnosis or procedure (or admit date if actual date unknown, or not between adate and ddate)"
	 , case when a.ddate >= calculated Visit_Start_Date
			    then a.ddate else calculated Visit_Start_date end 	as Visit_End_Date   format mmddyy10.
      , case when a.px_CodeType= 'C4' then 'C'
		      else a.px_CodeType end           						as codetype length = 2
      , case when a.discharge_status = 'EX'         then 'EX'
 		     when a.discharge_status = 'SN'         then 'SF'
 		     when a.discharge_status in ('IP','SH') then 'HS'
 	         when a.discharge_status in ('HO','AF','AL','AM','AW','HH','HS','NH','RS','RH') then 'AN'
 		      else '' end                      						as DischargeDisposition
	  , case when a.encounter_subtype ='UC'  	then 'UN'
			 when a.enctype = 'IP' 				then 'HN'
			 when a.enctype in ('AV','RO','LO') then 'CN'
			 when a.enctype ='ED' 				then 'EN' else a.enctype end           	
																	as CareTYPE   
      , case when a.enctype = 'IP' 				then '1INPT'
             when a.encounter_subtype = 'UC' 	then '3URGENT'
             when a.enctype = 'ED' 				then '2ED'
             when a.enctype = 'AV' 				then '4OUTPT' else a.enctype end               		 	
																	as CareSetting
      , case when a.kpwa_int_ext = 'E' then 'O'
          else a.kpwa_int_ext end           						as LOCATION
	from target.procdrevdw_tempA as A inner join target.enroll as E on a.mrn = e.mrn
    where calculated Visit_Start_Date between e.EnrollStartPlusLookbackDate and e.EnrollEndDate  
    order by e.mrn, visit_start_date, walshtable, walshgroup, dxpxcode
      , caresetting, caretype
    ;
  quit;

  title4 "target.procdrevdw - one record per patient, caredate, px code, setting";
  *n=7,516;
  proc sort data=work.procdrevdw out = target.procdrevdw nodupkey;
    by mrn visit_start_date walshtable walshgroup dxpxcode caresetting;
  run;

  proc freq data=target.procdrevdw;
     tables codetype   * dxpxcode  /*mostly 92950 (CPT), some 9960 (ICD9 px)*/
            CareType
            /list missing;           
  run;

title3;
%mend getprocdrevdw;
%getprocdrevdw;


********************************************;
*** get HCPC from VDW ***;
********************************************;
*because HCPC codes are not in VSD PROCDRE Table;
*takes about 20 minutes;

*for SENTINEL - theoretically, could roll this into getprocdreVDW above;
  *but no compelling need, and leaving separate ensures comparability with VSD;

* IN: &_vdw_px , chsid.chsid, vsd.csridxrfmstr,target.enroll, lookup.code_list;
* OUT:target.hcpcvdw;

%macro gethcpcvdw;
title3 "GET HCPC codes from VDW";

	*n=175,088;
	proc sql;
		create table work.hcpcvdw as
		select distinct px.mrn
			, px.px
			, px.px_codetype
			, px.adate    format date10.
			, u.ddate     format date10.
			, px.procdate format date10.
			, px.kpwa_subtype
			, px.enctype
			, px.kpwa_int_ext
			, c.walshtable, c.walshgroup
		from &_vdw_px. px
		    inner join &_vdw_utilization. u on px.enc_id = u.enc_id
  			inner join (select * 
   			            from lookup.code_list
   			            where dx_px = 'PX') c  on px.px_codetype= c.code_type and px.px = c.code
 		where px.px_codetype = 'H4'
			and px.adate between "&studystartdate."d and "&studyenddate."d
			and px.enctype not in ('VC','LO','IS','OE') /*LO and IS exceedingly rare and do not know how to interpret; safer to just exclude*/
                                                    	  /*2023-08-08 added OE exclusion as for OUTPT*/
	;
	quit;

	proc freq data=work.hcpcvdw;
		tables kpwa_subtype * enctype
		      / missing;
	run;

	*n=163,135 after deduping to one record per day, enctype, px code;
	proc sql;
		create table target.hcpcvdw as
		select distinct px.MRN
  		  /*, px.procdate, px.adate, px.ddate*/
			, case when px.procdate between px.adate and coalesce(px.ddate, px.adate)
			    and px.ddate >= px.adate
			    then px.procdate else px.adate end            		as Visit_Start_Date format mmddyy10. label "Visit Start Date - date of diagnosis or procedure (or admit date if actual date unknown, or not between adate and ddate)"
			, case when px.ddate >= calculated Visit_Start_Date
			    then px.ddate else calculated Visit_Start_date end 	as Visit_End_Date   format mmddyy10.
			, calculated visit_end_date - calculated visit_start_date  + 1 as Visit_days_temp
			, px.px_codetype   										as CodeType 			label "CodeType - e.g. 10, 09, H4, C"
		  /*, px.enctype       as CareType*/
            , case when px.kpwa_subtype ='UC'  			then 'UN'
                   when px.enctype = 'IP' 				then 'HN'
                   when px.enctype in ('AV','RO','LO')  then 'CN'
                   when px.enctype = 'ED' 				then 'EN'
                   else px.enctype end          					as CareTYPE    /*2023-08-07 correction*/
			, case when kpwa_subtype = 'UC' 			then '3URGENT'
				   when EncType in ('AV', 'RO', 'OE') 	then '4OUTPT' /*2023-08-08 OE is now moot - excluded above*/
				   when EncType = 'IP' 					then '1INPT'
				   when EncTYPE = 'ED' 					then '2ED'
				 /*when EncTYPE = 'VC' 					then '5TEL_VIRT'*/
				   else EncType end 								as CareSetting 	label "CareSetting - 1INPT, 2ED, 3URGENT, 4OUTPT"
			, case when px.kpwa_int_ext = 'E' then 'O'
			    else px.kpwa_int_ext end                   			as Location
			, px.Px            										as DxPxCode 	label "DxPxCode - diagnosis or procedure code (without decimals)"
			, walshtable 					          label "WalshTable - lookup table containing this dx or px code"
			, walshgroup 					          label "WalshGroup - for Table 2, dx or px code categorized into group (1,2)"
		from work.hcpcvdw           px
		  inner join target.enroll 	e  on px.mrn = e.mrn
    where calculated Visit_Start_Date between e.EnrollStartPlusLookbackDate and e.EnrollEndDate
    order by MRN, visit_start_date, walshtable, walshgroup, dxpxcode, caresetting, caretype
		;
	quit;
	
  proc freq data=target.hcpcvdw;
     tables dxpxcode                   /*mostly j1200, also some J0171 and a little bit of J0170*/        
            /missing;          
  run;

title3;
%mend gethcpcvdw;
%gethcpcvdw;


********************************************;
*** combine all dx/px codes, settings, dates ***;
********************************************;
*and add a FauxEncID;
*no de-duplication or exclusions yet;

*for SENTINEL - could use the VDW enc id, but probably better to do it this way;
  *for comparability with the VSD dataset (which lacks an enc id!);
  
* IN: target.inpt, target.outptvdw, target.procdrevdw, target.hcpcs;
* OUT:target.combined;

%macro combinecodes;
title3 "COMBINE CODES - from all sources";

  *combine data from INPT, OUTPT, PROCDRE and HCPC files;
  *n= 474,921 (now 386,273);
  data work.combined_A;
    set target.outptVDW
        target.inptVDW 
        target.procdreVDW
        target.hcpcVDW;
  run;

  *n=386,273 unchanged;
  proc sql;
    create table work.combined_B as
    select distinct a.mrn
			, a.Visit_Start_Date                   	label "[Visit_Start_Date] date of diagnosis or procedure (though may be admit date)"
			, a.Visit_End_Date                     	label "[Visit_End_Date] should differ from Visit_Start_Date only where CareSetting = 1INPT"
			, a.dischargedisposition               	label "[DischargeDisposition] for 1INPT encs, EX=Expired, HS=Hospice, SF=SNF, AN=Alive"
			, a.CodeType 	                       	label "[CodeType] 10, 09, H4, C"
			, a.CareType                           label "[CareType] source data for CareSetting - second char indicates primary(P), secondary(S), or unspecified(N) dx"
      /*2023-08-07 corrected CareType label*//*label "[CareType] source data for CareSetting - after C/E/H/U the second char indicates primary(P), secondary(S), or unspecified(N) dx - remaining values are VDW enctypes"*/
			, case when a.caretype = 'IP' then 3
			  when a.caretype like '%P' then 1
			  when a.caretype like '%S' then 2
			  else 3 end as PrimSecondDx           	label "[PrimSecondDx] Code Primary dx as 1, Secondary as 2, not specified as 3 (for sorting purposes)"
			, a.CareSetting                        	label "[CareSetting] 1INPT, 2ED, 3URGENT, 4OUTPT"
			, a.location                           	label '[Location] I = internal, E=external, null = unknown'
			, a.DxPxCode 	                       	label "[DxPxCode] Diagnosis or procedure code (without decimals)"
			, case when a.DxPxCode = 'J1200'
			    then 1 else 0 end  as ANTIHISTRSD 	label "[ANTIHISTRSD] DxPxCode = J1200 (HCPC for IM diphenydramine) (1=Yes/0=No)"
			, case when a.DxPxCode in ('J0170', 'J0171')
			    then 1 else 0 end  as 	EPIRSD     	label "[EPIRSD] DxPxCode in (J0170, J0171) (HCPC for IM epinephrine) (1=Yes/0=No)"
			, a.walshtable                         	label "[WalshTable] lookup table containing this dx or px code (1,2,3)"
			, a.walshgroup                         	label "[WalshGroup] for Table 2, dx or px code categorized into group (1,2, or null if not in Table 2)"
    		, case when visit_end_date is null then 1
    			else (visit_end_Date - visit_start_date) + 1
    			end                 as Visit_Days   label "[Visit_Days] Number of calendar days of visit (visit_end_date - visit_start_Date + 1)"
		  	, year(visit_start_date) as Visit_Year  label "[Visit_Year] year of Visit_Start_Date"
	    	, %calcage(b.Birthdate,a.visit_start_Date) 
                               		as Age
	    	, b.Sex
	    	, b.white, b.black, b.asian, b.hawaiian, b.natamer, b.other, b.hispanic
    from work.combined_A as A inner join target.constant as B on a.mrn = b.mrn
     ;
  quit;

  *create Encounter ID variable - have to do this in two steps;
  *n=443,262 (now 355,681);
  proc sql;
    create table work.encounter_A as
    select distinct mrn
			, Visit_Start_Date
			, caresetting
			, visit_days
			, location
    from work.combined_b
    ;
    create table work.encounter as
    select monotonic() as FauxEncID
		, a.*
    from work.encounter_a as A;
  quit;

  *add Encounter ID variable;
  *n=474,921  (now 386,273);
  proc sql;
    create table work.combined as
    select distinct enc.FauxEncID
		, a.*
    from work.combined_b as A inner join work.encounter as Enc on a.mrn = enc.mrn
							                                  and a.visit_start_date = enc.visit_start_date
							                                  and a.caresetting = enc.caresetting
							                                  and a.visit_days = enc.visit_days
							                                  and a.location = enc.location
     order by mrn, visit_Start_date, dxpxcode
        , caresetting          /*prioritize inpatient*/
      	, PrimSecondDx         /*prioritize primary dx*/
      	, visit_days           /*prioritize shorter stay*/
      	, dischargedisposition /*prioritize alive*/
    ;
   quit;

  *one record per person/visit/dxpxcode/caresetting;
  *n=474,848  (now 386,209), so do lose a few 64 based on primary/secondary;
  proc sort data=work.combined out = target.combined nodupkey;
    by mrn visit_start_date dxpxcode caresetting;
  run;

title3;
%mend combinecodes;
%combinecodes;


********************************************;
*** report data sources ***;
********************************************;

* IN: target.inptvdw, target.outptvdw , target.procdrevdw, target.hcpcvdw;
*     target.combined;
* OUT:list;

%macro reportsources;
title3 "REPORT SOURCES";

  title4 "VDW INPT File";
  proc freq data=target.inptvdw;
    tables  visit_start_date                  
            CodeType                 /*54% ICD-10*/
            caresetting * caretype   /*93% HS, 7% HP*/
            /*encounter_subtype        all are AI*/
            location                 /*35% I, rest O*/
            WalshTable * WalshGroup  /*all 2:2*/
            DischargeDisposition     /*mostly AN, fair portion SF*/
            / list missing;
    format visit_start_date year.;
  run;
  proc freq data=target.inptvdw order = freq;
     tables dxpxcode  /list missing;   /*mostly 4589, I959, followed by T and E codes from ICD-10*/        
  run;

  proc means data=target.inptvdw maxdec=0 nolabels N Min p1 p5 p10 p25 median p75 p90 p95 p99 Max printalltypes;
    var DURATION
        DXDaysAfterAdmit /*range -43 to 740, p5 to median is -1 to 1*/
        ;
    class walshtable;
  run;

  proc means data=target.inptvdw maxdec=0 nolabels N Min p25 median p75 p95 p99 Max;
    var DURATION
        DXDaysAfterAdmit;
    class caretype;
  run;

  title4 "VDW OUTPT File";
  proc freq data=target.outptvdw;
    tables  visit_start_date                    
            CodeType                 /*50-50 ICD 9 and 10*/
            caresetting * caretype   
            Location                 /*34% internal*/
            Dept                     /*none null - bulk are ALLrgy, EMENOS, FAMILY, INTMED, OTHNOS, URGENT*/
            WalshTable  * WalshGroup 
            DischargeDisposition     /*99% null*/
            /list missing;
     format visit_start_date year.;
   run;
  
  proc freq data=target.outptvdw order = freq;
     tables dxpxcode  /list missing;   /*more I959, 4589, less for others*/        
  run;

  title4 "VDW PROCDRE File - CPR codes";
  proc freq data=target.procdrevdw;
    tables  visit_start_date            /*big uptick in 2016 - presumably due to ICD-10 CPR codes*/            
            CodeType                    /*why so few ICD9 CPR codes?*/
            visit_start_date * codetype
            /missing;                
    tables  caresetting * caretype      /*81% INPT*/
            Location                    /*99% external*/
            WalshTable * WalshGroup     /*all 2,2 by definition*/
            /list missing;
    format  visit_start_date year.;
  run;
  proc freq data=target.procdrevdw order = freq;
     tables dxpxcode  /list missing;           
  run;

  title4 "VDW HCPC Medication Codes";
	proc freq data=target.hcpcvdw;
		tables Visit_Start_Date               
		       codetype                    /*all H4*/
		       caresetting * caretype      /*only 1% IP - legit? - yes - because Path 2*/
           Location                    /*75% O*/
           WalshTable  * WalshGroup    /*all table 2, 87% group 1*/
           / list missing;
		format Visit_Start_Date year.;
	run;
  proc freq data=target.hcpcvdw order = freq;
     tables dxpxcode                   /*mostly j1200, also some J0171 and a little bit of J0170*/
            DxPxCode * CareType        
            /missing;          
  run;
	
	title4 "All sources combined - one record per person / startdate / dxpxcode / caresetting";
	proc freq data=target.combined;
    tables  visit_Start_date 
            CodeType                   /*44% H4*/
            caresetting * caretype   
            Location                   /*72% out*/
            walshtable  * walshgroup   /*mostly table 2*/
            DischargeDisposition       /*75% null*/
            primseconddx               /*11% primary*/
            /list missing;
     tables caresetting * primseconddx
            caresetting * walshtable  /*table1 nearly always outpatient, table 3 mostly inpatient*/
            /missing;           
    format visit_Start_date year.;
  run;
  proc freq data=target.combined order = freq;
     tables dxpxcode                   /*mostly J1200, also I959, 4589*/
            /missing;           
  run;
  title5 "Compare this to the Walsh tables to see if any glaring omissions";
  proc freq data=target.combined;
     tables walshtable * walshgroup * dxpxcode
            /list missing;           
  run;
  title5;

  proc means data=target.combined maxdec=0 nolabels N Min median p75 p99 Max printalltypes;
    var FauxEncID
        Visit_Days
    	  ;
    class caresetting;
  run;

  title5 "Limited to inpt";
  *Visit days maxes at about 800 (p99 is 44);
  proc means data=target.combined maxdec=0 nolabels N Min median p75 p99 Max;
    var Visit_Days;
    class caretype;
    where caresetting = '1INPT';
  run;
 
title3;
%mend reportsources;
%reportsources;


********************************************;
*** exclude all dx/px with Table 1 in 60 days prior ***;
********************************************;
*deduping logic around mincaresetting is not right;
*  however, since not retaining that variable, does not matter enough to mess with;

* IN: target.combined;
* OUT:target.combined_remaining;

%macro DropTooClose;
title3 "DROP TOO CLOSE";

  *get all care start dates for Table 1 diagnoses, prioritizing most intensive caresetting;
  *n=15,608;
  proc sql;
  	create table work.distincttable1caredate_A as
  	select distinct mrn
		, visit_start_date
		, visit_end_date
  		, min(caresetting) as MinCareSetting
  	from target.combined
  	where walshtable=1
  	group by mrn, visit_start_date, visit_end_date
    order by mrn, visit_start_date, MinCareSetting, visit_end_date desc
  	;
  quit;

  *n unchanged - a little surprising;
    *would have expected some visits starting on same date to end on different dates;
    *e.g. an office visit followed by inpatient stay;
  proc sort data=work.distincttable1caredate_A out = work.distincttable1caredate nodupkey;
    by mrn visit_start_date /*Mincaresetting*/;
  run;

  *for every distinct caredate, flag the the most recent table 1 diagnosis, if any;
  *theoretically, would no calc prior caresetting var until have dates set;
  *n=352,529;
  proc sql;
    create table work.getgap as
    select distinct a.mrn
		, a.visit_start_date
		, a.CareSetting
      	, max(b.visit_start_date) as MostRecentPriorTable1Date format date10.
      /*, min(b.mincaresetting  ) as MostRecentTable1CareSetting*/
    from target.combined  as A left join work.distinctTable1caredate as B on a.mrn = b.mrn
      									                                 and b.visit_start_date < a.visit_start_date
   group by a.mrn, a.visit_start_date, a.CareSetting
   order by a.mrn, a.visit_start_date, a.CareSetting
   ;
  quit;

  *add var for how close together the dx are;
  proc sql;
    create table work.distinct_with_gaps as
    select distinct mrn
		, visit_start_date
		, caresetting
      /*, MostRecentTable1CareSetting*/
      	, MostRecentPriorTable1Date
      	, case when MostRecentPriorTable1Date <> .
      	  then visit_start_date - MostRecentPriorTable1Date end as DaysSincePriorTable1Dx
    from work.getgap
   ;
  quit;

  proc freq data=work.distinct_with_gaps;
    tables caresetting
          /* MostRecentTable1CareSetting      about 12k have a prior table 1*/
          /* caresetting * MostRecentTable1CareSetting outpt most likely to have a prior table 1*/
           /missing;
  run;

  *range 1 to >6000 days since prior table 1 dx, median 254;
  *approx 4-6k will have <90 days;
  proc means data=work.distinct_with_gaps maxdec=0 nolabels N Min p1 p5 p10 p25 median p75 p99 Max;
    var DaysSincePriorTable1Dx;
  run;

  *remove care dates that are too close together;
  *n=381,125 (compare 366k - makes sense with the means above);
   proc sql;
    create table target.combined_remaining as
    select distinct a.*
      /*, b.MostRecentTable1CareSetting*/
      , b.MostRecentPriorTable1Date
      , b.DaysSincePriorTable1Dx
      , case when a.walshtable = 1 and a.caresetting in ('1INPT', '2ED')
 		      then 1 else 0 end 
			as PathOne             
				label "[PathOne] visit has an IP dx/px in Walsh Table 1 (1=Yes/0=No)"
 	  , case when a.walshtable = 1 and a.caresetting in ('3URGENT', '4OUTPT')
 		      then 1 else 0 end 
			as PathTwoTableOne     
				label "[PathTwoTableOne] visit has an OUTPT or ED dx/px in Walsh Table 1 (1=Yes/0=NNo)"
 	  , case when a.walshtable = 2                      then 1 else 0 end 
			as PathTwoTableTwo
 	  , case when a.walshtable = 3 and a.caresetting in ('1INPT', '2ED') then 1 else 0 end 
			as PathThreeTableThree
 	  , case when a.walshtable = 2 and a.walshgroup = 1 then 1 else 0 end 
			as PathThreeTableTwoGroupOne
 	  , case when a.walshtable = 2 and a.walshgroup = 2 then 1 else 0 end 
			as PathThreeTableTwoGroupTwo
    from target.combined as A left join work.distinct_with_gaps as B on a.mrn = b.mrn
    										                 		and a.visit_start_date = b.visit_start_date
    where b.DaysSincePriorTable1Dx = .
      or b.DaysSincePriorTable1Dx > &lookbackdays.
    ;
  quit;

  title4 "target.combined_remaining - and limited to caresetting = 1INPT";
  *Visit days maxes at about 800;
  proc means data=target.combined_remaining maxdec=0 nolabels N Min median p75 p99 Max;
    var Visit_Days;
    where caresetting = '1INPT';
  run;

title3;
%mend DropTooClose;
%droptooclose;
  

*************************************************;
*** get vaccines - NOT APPLICABLE TO SENTINEL ***;
*************************************************;
*flag for any vaccine in 0-2 days before visit date;
*takes about 1 minute;

*for SENTINEL - recreate using EDW or CLARITY;

* IN: target.combined_remaining, event.vaccine;
* OUT:target.vaccine;

%macro GetVax;
title3 "GET VAX";

  **goes back many years - functionally to the mid 1980s anyway;
  *proc sql;
  *	select year(vacdate) as VacYear, count(*) as NumUses
  *	from event.vaccine
  *	group by calculated VacYear
  *	order by VacYear
  *	;
  *quit;

  *n=341,364;
  proc sql;
  	create table target.vaccine as
  	select distinct b.studyid, b.visit_start_date
  		, case when a.studyid is not null
  		    then 1 else 0 end as Vaccine label "[Vaccine] There was a vaccine given from 0-2 days before Visit_Start_date (1=Yes/0=No)"
  	from target.combined_remaining b
  		left join event.vaccine      a on a.studyid=b.studyid
  										              and a.vacdate between b.visit_start_date-2 and b.visit_start_date
  	;
  quit;

title3;
%mend GetVax;
*%getvax;


********************************************;
*** count int/ext encs during visit ***;
********************************************;
*wonder if fauxencid working exactly as desired;
*95 encs in a day seems like a lot?;

* IN: target.combined_remaining;
* OUT:target.intext;

%macro CountIntExt;
title3 "COUNT INT EXT";

  *for each person/visit start, calc num int encs and num ext encs;
  *n=346,662;
  proc sql;
    create table work.intext as
    select distinct mrn
		 , visit_start_date
		 , location
      	 , count(distinct FauxEncID) as NumEncs
    from target.combined_remaining
    group by mrn, visit_start_date, location
    ;
  quit;

  *n=341,640;
  proc sql;
    create table target.intext as
    select distinct a.mrn
	  , a.visit_start_date
      , max(case when b.location = 'O'
          then 1 else 0 end)         
		as Ext_Encounter 
			label "[Ext_Encounter] Any external encounters with a Walsh dx/px and starting during visit (1=Yes/0=No)"
      , max(case when b.location = 'I'
          then 1 else 0 end)         
		as Int_Encounter 
			label "[Int_Encounter] Any internal encounters with a Walsh dx/px and starting during visit (1=Yes/0=No)"
      /*the rest are just QA variables*/
      , sum(case when b.location = 'O'
          then b.NumEncs else 0 end) 
		as Num_Ext_Encounter
      , sum(case when b.location = 'I'
          then b.numencs else 0 end) 
		as Num_Int_Encounter
      , sum(b.numencs)               
		as Num_All_Encounter
    from target.combined_remaining  as A inner join work.intext as B on a.mrn = b.mrn
                                     								and b.visit_start_date between a.visit_start_date and a.visit_end_date
    group by a.mrn, a.visit_start_date
    ;
  quit;

  proc freq data=target.intext;
    tables  Ext_Encounter     /*74%*/
            Int_Encounter     /*28%*/
			Ext_Encounter * Int_Encounter /*n=58 are neither*/
            Num_Ext_Encounter /*range 0-245, 93% are 0-1, 99% in 0-4, 99.9% in 0-9 */
            Num_Int_Encounter /*range 0- 95, 97% are 0-1, 99% in 0-3, 99.9% in 0-9 */
            Num_All_Encounter /*range 1-245, 91% are 1  , 99% in 1-5, 99.9% in 1-14*/
            / missing;
  run;

title3;
%mend CountIntExt;
%CountIntExt;


********************************************;
*** add flags and summarize ***;
********************************************;
*de-dupe to one record per episode;
*add episode vars, including Episode ID;

* IN: target.combined_remaining;
* OUT:target.episode;

%macro MakeEpisode;
title3 "MAKE EPISODE - target.episode";

 *n= 341,640 distinct patient / visit start dates that are far enough from a prior Table1 dx;
 	*create flags for each part of a Walsh path;
 proc sql;
 	create table work.episode_a as
 	select distinct mrn
		, visit_start_date, visit_year
 	  	, max(visit_end_date           ) as MaxVisitEndDate 	format date10.
 		, max(PathOne                  ) as PathOne             label "[PathOne] visit has an IP dx/px in Walsh Table 1 (1=Yes/0=No)"
 		, max(PathTwoTableOne          ) as PathTwoTableOne     label "[PathTwoTableOne] visit has an OUTPT or ED dx/px in Walsh Table 1 (1=Yes/0=NNo)"
 		, max(PathTwoTableTwo          ) as PathTwoTableTwo
 		, max(PathThreeTableThree      ) as PathThreeTableThree
 		, max(PathThreeTableTwoGroupOne) as PathThreeTableTwoGroupOne
 		, max(PathThreeTableTwoGroupTwo) as PathThreeTableTwoGroupTwo
 	from target.combined_remaining
 	group by mrn, visit_start_date, visit_year
 	order by mrn, visit_start_date, visit_year
 		  , PathOne desc, PathThreeTableThree Desc, PathTwoTableTwo desc
 		  , PathThreeTableTwoGroupOne desc, PathThreeTableTwoGroupTwo desc
 		;
 	quit;

  *add Episode vars;
  proc sql;
    create table work.episode_b as
    select *
      , Visit_start_date - 2                       as Episode_Start_Date format mmddyy10.
		  , Case when MaxVisitEndDate is null then Visit_Start_Date + 7
			  else MaxVisitEndDate + 7 end               as Episode_End_Date format mmddyy10.
	    , calculated Episode_End_Date - calculated Episode_Start_Date + 1
	                                                 as Episode_Days
    from work.episode_a;
  quit;
  
  *create more episode vars;
  proc sql;
    create table work.episode_vars as
    select distinct mrn
	  , Visit_Start_Date
      , Episode_Start_Date                        label "[Episode_Start_Date] first day of episode (visit_start_date - 2)"
      , max(episode_end_date) as Episode_End_Date format mmddyy10. label "[Episode_End_Date] last day of episode (visit_end_date + 7)"
      , max(Episode_days)     as Episode_Days     label "[Episode_Days] length of episode in days"
    from work.episode_b
    group by mrn, visit_start_date, episode_start_date
    ;
    create table work.episodeid as
    select monotonic()        as EpisodeID        label "[EpisodeID] faux key - unique identifier for person, visit_start_date, episode_start_date"
      , a.*
    from work.episode_vars as A;
  quit;

  *add episode vars;
  proc sql;
    create table target.episode as
    select a.mrn
	  , b.episodeid                 
      , b.episode_start_date  
	  , b.episode_end_date          
	  , b.episode_days
      , a.visit_start_date    
	  , a.visit_year                
	  , a.MaxVisitEndDate 
   	  , a.PathOne             
	  , a.PathTwoTableOne           
	  , a.PathTwoTableTwo
   	  , a.PathThreeTableThree 
	  , a.PathThreeTableTwoGroupOne 
	  , a.PathThreeTableTwoGroupTwo
    from work.episode_b as A inner join work.episodeid  as B on a.mrn = b.mrn                          
						                                    and a.visit_start_date   = b.visit_start_date
						                                    and a.Episode_Start_Date = b.Episode_Start_Date
   ;
  quit;
  
title3;
%mend MakeEpisode;
%MakeEpisode;


********************************************;
*** create summary table                 ***;
********************************************;

* IN: target.combined, target.episode, target.vaccine, target.intext;
* OUT: target.Anaphylaxis_presumptive, analyt.Anaphylaxis_presumptive;

%macro MakePresumptive;
title3 "MAKE PRESUMPTIVE";

  *calc ANA_DX_N_ENCS var - number of Table 1 encs during the episode;
  *n=12,884;
  proc sql;
    create table work.ana_dx_n_encs as
    select distinct b.mrn
	  , b.episodeid
      , count(distinct a.FauxEncID) 
		as ANA_DX_N_ENCs 
			label "[ANA_DX_N_ENCS] number of distinct encounters starting during episode with any Walsh Table 1 dx"
    from target.combined as A inner join target.episode as B on a.mrn = b.mrn
    where a.visit_start_date between b.episode_start_date and b.episode_end_date
      and a.walshtable=1
    group by b.mrn, b.episodeid
    ;
  quit;

  *calc ANTIHISTRSD and EPIRSD vars - number of J codes for antihistamines and for epinephrine during episode;
  *n=341,640;
  proc sql;
    create table work.RSD_Flags as
    select distinct b.mrn
		, b.episodeid
      	, max(a.ANTIHISTRSD) as ANTIHISTRSD
		, max(a.EPIRSD)      as EPIRSD
		from target.combined as A inner join target.episode as B on a.mrn = b.mrn                                
		where a.visit_start_date between b.episode_start_date and b.episode_end_date
		group by b.mrn, b.episodeid;
  quit;


  *create consolidated flags and wrap in all the vars;
  *n=448,135 - still some records or dupes to get rid of - from location/caresetting/caretype?;
	proc sql;
 	create table work.Anaphylaxis_presumptive_A as
 	select distinct a.mrn
    	, b.Age  
		, b.Sex
    	, case when 0+b.white+b.black+b.asian+b.hawaiian+b.natamer+b.other>=1 then 0 end 
													 as HasNoRace
    	, coalesce(b.white   , calculated HasNoRace) as White    label "[WHITE] Has White race recorded (1=Yes/0=No/. = no race recorded)"
    	, coalesce(b.black   , calculated HasNoRace) as black    label "[BLACK] Has Black race recorded (1=Yes/0=No/. = no race recorded)"
    	, coalesce(b.asian   , calculated HasNoRace) as asian    label "[ASIAN] Has Asian race recorded (1=Yes/0=No/. = no race recorded)"
    	, coalesce(b.hawaiian, calculated HasNoRace) as hawaiian label "[HAWAIIAN] Has Hawaiian/Pacific Islander race recorded (1=Yes/0=No/. = no race recorded)"
    	, coalesce(b.natamer , calculated HasNoRace) as natamer  label "[NATAMER] Has Native American race recorded (1=Yes/0=No/. = no race recorded)"
    	, coalesce(b.other   , calculated HasNoRace) as other    label "[OTHER] Has Other race recorded (1=Yes/0=No/. = no race recorded)"
    	, b.hispanic                                             label "[HISPANIC] Has Hispanic ethnicity recorded (1=Yes/0=No/. = no ethnicity recorded)"
 		, e.chrtflag
 		, a.visit_start_date                                
 		, a.MaxVisitEndDate                      	as Visit_End_Date format mmddyy10. label "[VISIT_END_DATE] last end date of relevant visitss with this start date"
 		, b.location           
 		, b.CareSetting      
 		, b.CareType
 		, b.Visit_Days         
		, a.Visit_Year
		, b.fauxencid          
		, a.episodeid
		, a.Episode_Start_date 
		, a.Episode_End_Date 
		, a.Episode_Days
 		, a.PathOne                              	as PATH1       label "[PATH1] Has inpatient or ED Table 1 dx (1=Yes/0=No)"
 		, case when a.PathTwoTableOne = 1
 				and a.PathTwoTableTwo = 1
 				then 1 else 0 end                   as PATH2       label "[PATH2] Has any Table 1 dx PLUS any Table 2 dx or px on same day (1=Yes/0=No)"
 		, case when a.PathThreeTableThree = 1
 				and a.PathThreeTableTwoGroupOne = 1
 				and a.PathThreeTableTwoGroupTwo = 1
 				then 1 else 0 end                   as PATH3       label "[PATH3] Has any inpatient or ED Table 3 dx PLUS dx or px from Table 2 Groups 1 and 2 on same day (1=Yes/0=No)"
 		, case when a.PathOne=1 
 		    or calculated Path2=1 
 		    or calculated Path3=1
 			  then 1 else 0 end                    	as HasPath     label "[HasPath] Has any Walsh path assigned (1=Yes/0=No)"
 		, case when a.PathOne=1 then 1
 				when calculated Path2 = 1 then 2
 				when calculated Path3 = 1 then 3
 				end 			                    as ASSIGN_PATH  label "[ASSIGN_PATH] lowest number of Walsh paths assigned"
    /*, b.MostRecentTable1CareSetting*/
    , b.MostRecentPriorTable1Date
    , b.DaysSincePriorTable1Dx
    , coalesce(d.ANA_DX_N_ENCs ,0)          		as ANA_DX_N_ENCS label "[ANA_DX_N_ENCS] number of distinct encounters starting during episode with any Walsh Table 1 dx"
/*    , v.Vaccine                             */
    , coalesce(f.ANTIHISTRSD   ,0)          		as ANTIHISTRSD   label "[ANTIHISTRSD] DxPxCode = J1200 (HCPC for IM diphenydramine) (1=Yes/0=No)"			                                      
		, coalesce(f.EPIRSD        ,0)          	as EPIRSD        label "[EPIRSD] DxPxCode in (J0170, J0171) (HCPC for IM epinephrine) (1=Yes/0=No)"
		, coalesce(ie.ext_encounter,0)          	as EXT_ENCOUNTER label "[EXT_ENCOUNTER] Any external encounters with a Walsh dx/px and starting during visit (1=Yes/0=No)"
    , coalesce(ie.int_encounter,0)          		as INT_ENCOUNTER label "[INT_ENCOUNTER] Any internal encounters with a Walsh dx/px and starting during visit (1=Yes/0=No)"
  from target.episode  as A
		inner join target.enroll              e on e.mrn = a.mrn
		inner join target.combined_remaining  b on a.mrn = b.mrn and a.visit_start_date = b.visit_start_date
/*    	inner join target.vaccine             v on a.mrn = v.mrn and a.visit_start_date = v.visit_start_date*/
		left join work.ana_dx_n_encs          d on a.episodeid = d.episodeid
 		left join work.RSD_Flags              f on a.episodeid = f.episodeid
 		left join target.intext              ie on a.mrn = ie.mrn and a.visit_start_date = ie.visit_start_date
 		;
 	quit;

 	proc freq data=work.Anaphylaxis_presumptive_A;
 		tables 	visit_start_date      
     				HasPath * Assign_Path /*2% of possible event dates have any path*/
     				/list missing;
    tables  ANA_DX_N_ENCS         /*95% 0, 99.9% <=3, range up to 21*/
     				ANTIHISTRSD           /*35%*/
     				EPIRSD                /*6%*/
     			  /*VACCINE*/             /*2%*/
     				EXT_ENCOUNTER * INT_ENCOUNTER /*71% ext, 32% int*/
     				/list;
 	    format  visit_start_date year.;
 	run;

 	*limit to presumed anaphylaxis cases and sort for deduping;
 	*n=11,542;
 	proc sql;
 		create table work.Anaphylaxis_presumptive_B as
 		select *
 		from work.Anaphylaxis_presumptive_A
 		where assign_Path is not null
 		order by episodeid
 		  , assign_path            /*prioritize Walsh Path 1 over Path 2, etc.*/
 		  , caresetting            /*prioritize more intensive care settings*/
 		  , location               /*prioritize internal*/
 		  , DaysSincePriorTable1Dx /*include vars for most recent prior, if any*/
 		;
 	quit;
 	
 	*no dedupe to one anaphylaxis case per episode;
 	*n=4,297;
 	proc sort data=work.Anaphylaxis_presumptive_B out = work.Anaphylaxis_presumptive_C nodupkey;
 	  by episodeid;
 	run;
 
  *create anaphylaxis_id;
  *2023-07-24 changed from anaphylaxis_id to to anaphylaxis_num per Onchee request;
  proc sql;
    create table work.Anaphylaxis_presumptive_D as
    select *
    from work.Anaphylaxis_presumptive_C
    order by mrn,visit_start_date 
    ;
/*    create table target.anaphylaxis_presumptive as*/
/*    select monotonic()        as Anaphylaxis_Num  */
/*      , a.**/
/*	  , chrtflag*/
/*			as ChartAvail	*/
/*				Label="[ChartAvail]Availability of data for chart review as of Visit_Start_Date (0=no, 1=yes. For KPWA, this is based on the variable GPDconfidence 80%+"*/
/**/
/*    from work.Anaphylaxis_presumptive_d a*/
/*    ;*/
  quit;

  data target.anaphylaxis_presumptive;
	  set work.Anaphylaxis_presumptive_D;
	  by MRN;
	  If first.MRN then Anaphylaxis_Num = 1;
	  else Anaphylaxis_Num + 1;
	  ChartAvail=chrtflag;
	  Label Age=[AGE]Age (as integer) at Visit_Start_Date, in years;
  run;

	*Create crosswalk, StudyID;
	*N=3,951;
  	Proc sql;
	Create table crosswalk as
	Select distinct a.MRN
	, b.Consumno
	From target.Anaphylaxis_presumptive as A Inner Join CHSID.Chsid as B on a.MRn=b.CHSID;
	quit;

	Data xwalk.Crosswalk;
	set crosswalk;
	StudyID=compress("KPWA"||Put(monotonic(), z7.));
	Format CONSUMNO_EVEN_ODD $4.;
	If mod(input(Consumno,8.),2)=0 Then CONSUMNO_EVEN_ODD="Even"; else CONSUMNO_EVEN_ODD="Odd";
	run;

	*N=3,951;
	Proc sql;
	Select count(distinct studyid) as N_studyid 	
	From xwalk.crosswalk;
	quit;
	
	*create analytic table without chsid/consumno;
	*and limited to vars specified in protocol;
	*N=4297;
  proc sql;
    create table analyt.Anaphylaxis_presumptive_final as
    select Studyid 			label="[StudyID] Study specific ID"
	    , CONSUMNO_EVEN_ODD label="[CONSUMNO_EVEN_ODD] 'Even'=if the last byte of the consumer number is EVEN number, 'Odd'=otherwise"
		, anaphylaxis_Num  	label="[Anaphylaxis_Num]Counting of presumptive anaphylaxis events in order of Visit_Start_Date per StudyID"   
		, episodeid
   		, visit_start_date   
		, Visit_End_Date 
   		, Visit_Days         
		, Visit_Year
  		, Episode_Start_date 
		, Episode_End_Date 
		, Episode_Days
    	, PATH1              
		, PATH2            
		, PATH3         
		, ASSIGN_PATH    
      	, Age        		       
		, Sex
      	, White              
		, black            
		, asian    
      	, hawaiian           
		, natamer          
		, other         
		, hispanic                                           
   		, ChartAvail	Label="[ChartAvail]Availability of data for chart review as of Visit_Start_Date (0=no, 1=yes. For KPWA, this is based on the variable GPDconfidence 80%+"
	/*  , Vaccine*/
      	, ANTIHISTRSD   		
		, EPIRSD        
  		, EXT_ENCOUNTER      
		, INT_ENCOUNTER    
		, ANA_DX_N_ENCS 
    from target.Anaphylaxis_presumptive as A Inner Join Xwalk.Crosswalk as B on a.MRN=b.MRN;
  quit;

title3;
%mend MakePresumptive;
%MakePresumptive;

*QC;
*N_events     N_MRN 
4,297 		  3,951 ;
Proc sql;
Select count(*) as N_events
	 , count(distinct studyid) as N_studyid
From analyt.Anaphylaxis_presumptive_final;
quit;

*Delete dataset if the dataset containing sample already exists (we need to refresh this temp table each time we run RCT program);
proc datasets library=GHCLKUP;
delete Anaphylaxis_presumptive_final;
run;

*Upload current sample to GHC_LOOKUP;
*N=4,297;
Proc sql;
Create table GHCLKUP.Anaphylaxis_presumptive_final as
Select b.MRN
	, a.*
From analyt.Anaphylaxis_presumptive_final A Inner Join Xwalk.Crosswalk as B on a.studyid=b.studyid;
quit;


********************************************;
*** create details table ***;
********************************************;

* IN: target.combined_remaining, target.episode, target.anaphylaxis_presumptive;
* OUT:target.anaphylaxis_details, analyt.anaphylaxis_details;

%macro MakeDetails;
title3 "MAKE DETAILS - target.anaphylaxis_details";

  proc sql;
    create table work.path1 as
    select a1.*
      , b1.visit_end_date, b1.dxpxcode, b1.CodeType, b1.caresetting
      , 1 as Path 
    from target.episode                    a1
      inner join target.combined_remaining b1 on a1.mrn = b1.mrn
                                                and a1.visit_start_date = b1.visit_start_date
                                                and a1.maxvisitenddate >= b1.visit_end_date 
                                                and a1.PathOne = b1.PathOne
    where a1.PathOne = 1
    ;
    create table work.path21 as
    select a21.*
      , b21.visit_end_date, b21.dxpxcode, b21.codetype, b21.caresetting
      , 2 as Path 
    from target.episode                    a21
      inner join target.combined_remaining b21 on a21.mrn = b21.mrn
                                                and a21.visit_start_date = b21.visit_start_date
                                                and a21.maxvisitenddate >= b21.visit_end_date 
                                                and a21.PathTwoTableOne = b21.PathTwoTableOne      
    where a21.PathTwoTableOne = 1
  		 and a21.PathTwoTableTwo = 1
  	;
    create table work.path22 as
    select a22.*
      , b22.visit_end_date, b22.dxpxcode, b22.codetype, b22.caresetting
      , 2 as Path 
    from target.episode                    a22
      inner join target.combined_remaining b22 on a22.mrn = b22.mrn
                                                and a22.visit_start_date = b22.visit_start_date
                                                and a22.maxvisitenddate >= b22.visit_end_date 
                                                and a22.PathTwoTableTwo  = b22.PathTwoTableTwo      
    where a22.PathTwoTableOne = 1
  		 and a22.PathTwoTableTwo = 1
  	;
  	create table work.path321 as
  	select a321.*
      , b321.visit_end_date, b321.dxpxcode, b321.codetype, b321.caresetting
  	  , 3 as Path 
  	from target.episode                    a321
      inner join target.combined_remaining b321 on a321.mrn = b321.mrn
                                                and a321.visit_start_date = b321.visit_start_date
                                                and a321.maxvisitenddate >= b321.visit_end_date 
                                                and a321.PathTwoTableOne  = b321.PathTwoTableOne        	
  	where a321.PathThreeTableThree = 1
			 and a321.PathThreeTableTwoGroupOne = 1
			 and a321.PathThreeTableTwoGroupTwo = 1
   	;
  	create table work.path322 as
  	select a322.*
      , b322.visit_end_date, b322.dxpxcode, b322.codetype, b322.caresetting
  	  , 3 as Path 
  	from target.episode                    a322
      inner join target.combined_remaining b322 on a322.mrn = b322.mrn
                                                and a322.visit_start_date = b322.visit_start_date
                                                and a322.maxvisitenddate >= b322.visit_end_date 
                                                and a322.PathTwoTableTwo  = b322.PathTwoTableTwo        	
  	where a322.PathThreeTableThree = 1
			 and a322.PathThreeTableTwoGroupOne = 1
			 and a322.PathThreeTableTwoGroupTwo = 1
   	;
  	create table work.path33 as
  	select a33.*
      , b33.visit_end_date, b33.dxpxcode, b33.codetype, b33.caresetting
  	  , 3 as Path 
  	from target.episode                    a33
      inner join target.combined_remaining b33 on a33.mrn = b33.mrn
                                                and a33.visit_start_date = b33.visit_start_date
                                                and a33.maxvisitenddate >= b33.visit_end_date 
                                                and a33.PathTwoTableTwo  = b33.PathTwoTableTwo        	
  	where a33.PathThreeTableThree = 1
			 and a33.PathThreeTableTwoGroupOne = 1
			 and a33.PathThreeTableTwoGroupTwo = 1
   	;
  quit;

  *n=14,025;
  data work.allpaths;
    set work.path1
        work.path21  
		work.path22
        work.path321 
		work.path322 
		work.path33;
  run;

  *n=10,093;
  proc sql;
    create table work.anaphylaxis_details as
    select distinct b.mrn
	  , b.anaphylaxis_num 
	  , b.episodeid
      , a.visit_start_date   
	  , a.visit_end_date 
	  , a.Visit_Year        
      , a.Path
	  , b.Assign_Path
      , a.dxpxcode as Code
      , a.CodeType
      , case when a.caresetting = '1INPT'   then 1
             when a.caresetting = '2ED'     then 2
             when a.caresetting = '3URGENT' then 3
             when a.caresetting = '4OUTPT'  then 4 end as VisitType label "[VisitType]Setting of visit with dx or px code: 1=INPT, 2=ED, 3=URGENT, 4=OUTPT"
    from target.anaphylaxis_presumptive as B inner join work.allpaths as A on a.mrn = b.mrn
										                                  and a.visit_start_date = b.visit_start_date
										                                  and a.maxvisitenddate >= b.visit_end_date
    order by episodeid, path, code, visittype
    ;
  quit;

  *n unchanged;
  proc sort data=work.anaphylaxis_details out = target.anaphylaxis_details nodupkey;
    by episodeid path code visittype;
  run;  

  *Replace MRN -> StudyID
  *N=10,093;
  Proc sql;
	Create table analyt.anaphylaxis_details_final (drop=MRN) as
	Select b.Studyid
			label="[StudyID] study specific ID"
		   , b.CONSUMNO_EVEN_ODD
		 , a.*

	From target.anaphylaxis_details as A Inner Join Xwalk.Crosswalk as B on a.MRN=b.MRN;
	quit;
  
title3;
%mend MakeDetails;
%MakeDetails;


*QC;
*N_events     N_MRN 
10,093 		  3,951 ;
Proc sql;
Select count(*) as N_events
	 , count(distinct studyid) as N_studyid
From analyt.anaphylaxis_details_final;
quit;


********************************************;
*** report final tables ***;
********************************************;

* IN: target.anaphylaxis_presumptive, target.anaphylaxis_details;
* OUT:list;

%macro ReportFinalTables;
title3 "REPORT FINAL TABLES";

   title4 "target.anaphylaxis_pressumptive - one record per anaphylaxis episode";
   proc contents data=target.Anaphylaxis_presumptive_final order=varnum;
   run;

 	proc freq data=target.Anaphylaxis_presumptive;
 		tables 	visit_start_date * Visit_Year
     				Assign_Path
     				Path1                 /*Path1 most common w/ 54%*/
     				Path2                 
     				Path3                 /*Path3 least common w/ 23%*/
     				Assign_Path * Path1 * Path2 * Path3 /*only 12% of those with paths have more than ones*/
 		        	ANA_DX_N_ENCS         /*16% 0, 99% <=5, range up to 21*/
     				ANTIHISTRSD           /*55%*/
     				EPIRSD                /*58%*/
     				/*VACCINE*/           /*2%*/
     				/list;
     tables EXT_ENCOUNTER * INT_ENCOUNTER /*77% ext, 31% int*/
     				Sex
            ;
     tables white black  asian hawaiian natamer other     hispanic
            location           CareSetting      CareType
            /missing;
 	    format visit_start_date year.;
 	run;

  proc means data=target.Anaphylaxis_presumptive nolabels N NMiss Mean std Min P25 median p75 p99 Max maxdec=1;
    var  age; 
  run;

    proc means data=target.Anaphylaxis_presumptive nolabels N NMiss Mean std Min P25 median p75 p99 Max maxdec=1;
    var  age;
	where Age>=18; 
  	run;

  *episode_days ought always to be 10 for other than 1INPT, but can be more;
    *even when visit_days = 1 - why?;
  proc means data=target.Anaphylaxis_presumptive maxdec=0 nolabels N Min median p75 p99 Max printalltypes;
    var Visit_days
        Episode_Days; /*range 10-75, p99 is 23*/
    class CareSetting;
  run;

  title4 "target.anaphylaxis_details - one record per supporting dx/px code";
  title5 "with multiple records if a dx/px contributes to more than one met path";
   proc contents data=target.Anaphylaxis_details_final;
   run;
  proc freq data=target.anaphylaxis_details_final;
    tables  visit_start_date * visit_year
            path
			Assign_Path * path
			Assign_Path
			Assign_Path*
            visittype
            codetype
            codetype * code
            /list missing;
    format visit_start_date year.;
  run;

title3;
%mend ReportFinalTables;
%ReportFinalTables;


*********************************************************************************************;
*********************************************************************************************;
***   end of code                                                                         ***;
*********************************************************************************************;
*********************************************************************************************;

