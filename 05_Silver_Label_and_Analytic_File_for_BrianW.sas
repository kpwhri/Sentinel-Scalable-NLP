*****************************************************************************************************************************************************************************************
Structured data features
	- Obs_ID. A unique observation identifier created by concatenating StudyID and Anaphylaxis_Num 
	- Assigned path. Each potential event included in the study cohort was assigned to one and only one of the three eligibility paths 
				(Path 1, Path 2, or Path 3, as defined above under “Cohort identification of potential anaphylaxis events”), even if data associated with a potential event 
				met criteria for two different paths. We used a rule (described above) to assign a unique path to each potential event, and stored this assignment in an 
				“assigned path” variable, having values of 1, 2, or 3. To use assigned path in PheNorm models we will convert the assigned path information into the following 
				two binary flag variables:
	- Assigned_Path_2: A binary (0/1) flag set to 1 if the event’s assigned path was Path 2 and set to 0 otherwise
	- Assigned_Path_3: A binary (0/1) flag set to 1 if the event’s assigned path was Path 3 and set to 0 otherwise.
Note: These flag variables use Path 1 as the reference group.  Accordingly, for potential events assigned to Path 1, both of the above flags will be equal to 0. 
	- Filter_Group (a string variable indicating the name of the group by which the observation qualified for inclusion in the cohort, also referred to as 
	a “filter group”: “Assigned_Path_1,” “Assigned_Path_2,” or “Assigned_Path_3”)
	- Sampling_Weight (a numeric variable indicating the sampling weight associated with the observation’s Sample_Group with at least 4 significant digits to the right of the decimal)
	- ANA_DX_N_ENCS (silver label #1 above)
	- ANA_MENTIONS_N (silver label #2 above) 
	- ANA_CUI_NOTES_N (silver label #3 above)
	- ANA_EPI_MENTIONS_N (silver label #4 above)
	- ANTIHISTRSD (structured data feature defined above)
	- EPIRSD (structured data feature defined above)
	- Age_Index in years at index
	- Sex_F (=1 if patient’s sex in healthcare data is recorded as female and 0 otherwise)
Race as represented by the following 6 binary flags, which allow for each observation to be represented by more than one race category:
	- Race_AFAM (set to 1 if race is Black/African American and 0 otherwise)
	- Race_Asian  (set to 1 if race is Asian and 0 otherwise)
	- Race_HP (set to 1 if race is Native Hawaiian or Pacific Islancer and 0 otherwise)
	- Race_NatAm (set to 1 if race is Native American or Alaska Native and 0 otherwise)
	- Race_Other (set to 1 if any other race is reported and 0 otherwise)
	- Race_UNKN (set to 1 if all race information is missing and 0 otherwise)
	- Ethnicity (set to 1 if ethnicity is Hispanic and 0 otherwise)
	- HOI_2_0_Gold_Set (set to 1 if this event is also represented in the HOI 2.0 anaphylaxis modeling study conducted in 2021 by Jennifer Nelson and David Carrell and 0 otherwise)
	- HOI_2_0_Gold_Case (this variable is populated only for observations where HOI_2_0_Gold_Set = 1, a “Yes” value indicates this observation was determined to be 
		an actual anaphylaxis case based on the HOI 2.0 study’s manual chart review, and a “No” value indicates the observation was determined not to be a case.)
	- NLP covariates (a set of 160 NLP covariates whose names are listed in tab “Unique Operationalized CUIs” of Google sheet ANA_AFEP_All_PTs_and_LLTs_2023_08_28 stored in 
		folder “August 2023 Deliverables”)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Update 1/11/2024
Include the following Silver labels (Epic Chart Review)
	- DI7_GOLD_SET (1=1 HAS GOLD LABEL FROM DI7, 0=OTHERWISE)
	- DI7_ANA_CASE_STATUS (1=CASE, 0=NON A CASE)

****************************************************************************************************************************************************************************************;
*Signoff;
%include "H:\sasCSpassword.sas";
%include "\\ghcmaster.ghc.org\ghri\warehouse\sas\includes\globals.sas";
%include "\\groups.ghc.org\data\CTRHS\CHS\ITCore\SASCONNECT\RemoteStartRDW.sas";
%include "&GHRIDW_ROOT.\Sasdata\CRN_VDW\lib\StdVars.sas" ;
%make_spm_comment(DI7 Assisted Review-Silver Labels & Analytic File);
options compress=yes nocenter nofmterr;
%let mypath = \\Groups.ghc.org\Data\CTRHS\Sentinel\Innovation_Center;
Libname cohort "&MYPATH.\DI7_Assisted_Review\PROGRAMMING\SAS Datasets\01_Define_Cohort\09AUG2023" access=readonly;
Libname CTM "&MYPATH.\DI7_Assisted_Review\PROGRAMMING\SAS Datasets\03_Clinical_text_measures" access=readonly;
Libname Out "&MYPATH.\DI7_Assisted_Review\PROGRAMMING\SAS Datasets\05_Silver_Labels_and_Analytic_File_for _BrianW";
Libname xwalk "&MYPATH.\DI7_Assisted_Review\PROGRAMMING\SAS Datasets\xwalk" access=readonly;
Libname HOI2 "&MYPATH.\NLP_COVID19_Carrell\PROGRAMMING\Anaphylaxis\SAS Datasets\HOI2.0 analphylaxis datasets\Append Discharge Dates" access=readonly;
Libname NLP "&MYPATH.\DI7_Assisted_Review\PROGRAMMING\NLP\share\arvind\for_phenorm" ;
Libname IRR "&MYPATH.\DI7_Assisted_Review\PROGRAMMING\SAS Datasets\10_Chart_Review_IRR" access=readonly;
%Include "&MYPATH.\DI7_Assisted_Review\PROGRAMMING\SAS Programs\MakeDataDictionaryForLib.sas";

*Chart review as of date;
%Let REDCapAsOfDate = 2024_01_11;

*N=4,297;
Proc sql;
Create table Out.TmpA as
Select b.MRN
	 , a.StudyID
	 , a.CONSUMNO_EVEN_ODD
	 , a.Anaphylaxis_Num
	 , Compress(a.StudyID||'_'||put(a.Anaphylaxis_Num,8.))
	 	as Obs_ID
			Label="[Obs_ID]A unique observation identifier created by concatenating StudyID and Anaphylaxis_Num"
/*	 , a.EpisodeID*/
	 , a.Visit_Start_Date
	 , a.Visit_End_Date
	 , a.Visit_Days
	 , a.Visit_Year
	 , a.Episode_Start_Date
	 , a.Episode_End_Date
	 , a.Episode_Days
	 , a.PATH1
	 , a.PATH2
	 , a.PATH3
	 , a.ASSIGN_PATH
	 	as ASSIGNED_PATH
			Label="[ASSIGNED_PATH]Each potential event included in the study cohort was assigned to one and only one of the three eligibility paths (Path 1, Path 2, or Path 3)"
	 , Case when a.ASSIGN_PATH in (2) Then 1 else 0 end
	 	as ASSIGNED_PATH_2
			Label="[ASSIGNED_PATH_2]A binary (0/1) flag set to 1 if the event’s assigned path was Path 2 and set to 0 otherwise"
	 , Case when a.ASSIGN_PATH in (3) Then 1 else 0 end
	 	as ASSIGNED_PATH_3
			Label="[ASSIGNED_PATH_3]A binary (0/1) flag set to 1 if the event’s assigned path was Path 3 and set to 0 otherwise"
	 , Case when a.ASSIGN_PATH in (1) Then "Assigned_Path_1"
	 	    when a.ASSIGN_PATH in (2) Then "Assigned_Path_2"
			when a.ASSIGN_PATH in (3) Then "Assigned_Path_3" end
		as FILTER_GROUP 
			Label="[FILTER_GROUP]a string variable indicating the name of the group by which the observation qualified for inclusion in the cohort, also referred to as  a filter group: 'Assigned_Path_1','Assigned_Path_2', or 'Assigned_Path_3'"
	 , 1 
	 	as Sampling_Weight
			Label="[Sampling_Weight]A numeric variable indicating the sampling weight associated with the observation’s Sample_Group with at least 4 significant digits to the right of the decimal) - populate with all 1s"

	 , a.Age
	 	as AGE_INDEX 
			Label="[AGE_INDEX ] Age(in years) at index (@Visit_Start_Date)"
	 , a.sex
	 , Case when a.sex in ('F','f') then 1 else 0 end
	 	as SEX_F
			Label="[SEX_F]1=if patient’s sex in healthcare data is recorded as female, 0=Otherwise"
	 , a.White
	 , a.black
	 	as Race_AFAM
			Label="[Race_AFAM]1=if race is Black/African American, 0=Otherwise"
	 , a.asian
	 	 as Race_Asian
			Label="[Race_Asian]1=if race is Asian, 0=otherwise"
	 , a.hawaiian
	 	 as Race_HP
			Label="[Race_HP]1=if race is Native Hawaiian or Pacific Islander, 0=Otherwise"
	 , a.natamer
	 	 as Race_NatAm
			Label="[Race_NatAm]1=if race is Native American or Alaska Native, 0=Otherwise"
	 , a.other
	 	 as Race_Other
			Label="[Race_Other]1=if any other race is reported, 0=Otherwise"
	 , Case when a.White =.
	 		 and a.black=.
			 and a.hawaiian=.
			 and a.natamer=.
			 and a.other=. Then 1 else 0 end
		as Race_UNKN 
			Label="[Race_UNKN]1=if all race information is missing, 0=Otherwise"
	 , a.HISPANIC
	 	as Ethnicity 
			Label="[Ethnicity ]1=ethnicity is Hispanic, 0=otherwise"
	 , a.ChartAvail
	 , a.ANTIHISTRSD
	 , a.EPIRSD
	 , a.EXT_ENCOUNTER
	 , a.INT_ENCOUNTER
	 , a.ANA_DX_N_ENCS
/*Clinical Text Measures*/
	 , c.N_CALDAYS_W_NOTES_WO_SM
	 , c.N_CALDAYS_W_NOTES_W_SM
	 , c.N_NOTES_WO_SM
	 , c.N_NOTES_W_SM
	 , c.TOT_NOTES_CHARCOUNT_WO_SM
	 , c.TOT_NOTES_CHARCOUNT_W_SM

From Cohort.Anaphylaxis_presumptive_Final as A Inner Join XWALK.Crosswalk 				as B on a.Studyid=b.Studyid
											   Left JOin  CTM.Clinical_Text_measures 	as C on a.Studyid=c.Studyid
																				       		and a.Episode_Start_Date=c.Episode_Start_Date;
quit;

*N=4,297;
*Per Brian W: Here are the sampling weights (HOI_2_0_sampling_weight) for HOI 2.0:
•	Path 1: weight = 1.684
•	Path 2: weight = 2.387
•	Path 3: weight = 14.025974026 (= 1080 / 77) ;
Proc sql;
Create table Out.TmpB as
Select a.*
	, Case when a.MRN=b.MRN
			and a.visit_Start_Date=b.eventdte Then 1 else 0 end
		as HOI_2_0_Gold_Set 
			Label="[HOI_2_0_Gold_Set]set to 1 if this event is also represented in the HOI 2.0 anaphylaxis modeling study conducted in 2021 by Jennifer Nelson and David Carrell and 0 otherwise"
	, Case when calculated HOI_2_0_Gold_Set =1
			and Sampson in (1) Then 'Yes' else 'No' end
		as HOI_2_0_Gold_Case 
			Label="[HOI_2_0_Gold_Case] populated only for observations where HOI_2_0_Gold_Set = 1, 'Yes' =observation was determined to be an actual anaphylaxis case based on the HOI 2.0 study’s manual chart review, 'No' =observation was determined not to be a case."
	, b.Sampson
	, b.Path
		as HOI_2_0_PATH
			Label="[HOI_2_0_PATH] HOI2.0 events identified by Path who have Gold Standard Lanels"
	, Case when b.Path=1 Then 1.684
		   when b.Path=2 Then 2.387
 		   when b.Path=3 Then 14.025974026 end
		as HOI_2_0_sampling_weight 
			Format=8.10
			Label="[HOI_2_0_Sampling_Weight]Corresponds to the HOI2.0 outcome in Paths 1,2 & 3"

From Out.TmpA as A left Join HOI2.anaph_analytic_20230621 as B on a.MRN=b.MRN
																and a.visit_Start_Date=b.eventdte;
quit;

*QC;
Proc freq data=Out.TmpB;
tables HOI_2_0_Gold_Set HOI_2_0_Gold_Set*sampson*HOI_2_0_Gold_Case
HOI_2_0_PATH*HOI_2_0_Sampling_Weight/norow nocol nopercent missing list;
run;

*QC;
Proc sql;
Select Sampson
, count(*) as Nobs
, count(distinct MRN) as NMrns
From out.TmpB
where HOI_2_0_Gold_Set=1
  and Sampson in (0,1)
  and Path in (1,2)
Group by Sampson
;
quit;

*QC;
Proc sql;
Select Sampson
, count(*) as Nobs
, count(distinct MRN) as NMrns
From out.TmpB
where HOI_2_0_Gold_Set=1
  and Sampson in (0,1)
  and Path in (3)
Group by Sampson
;
quit;

*QC;
Proc freq data=Out.&_SITEABBR._ANA_Phenorm_Analytic;
tables ASSIGNED_PATH*ASSIGNED_PATH_2*ASSIGNED_PATH_3/norow nocol nopercent missing list;
run;

*QC;
Proc sql ;
Select HOI_2_0_Gold_Set label=""
	 , HOI_2_0_Gold_Case label=""
	 , count(*) as N_ANA_events
	 , count(distinct MRN) as N_CHSID
From Out.Tmpb
Group by HOI_2_0_Gold_Set
	 , HOI_2_0_Gold_Case;
quit;


***********************************************************************************************	
- DI7_GOLD_SET (1 = 1 HAS GOLD LABEL FROM DI7, 0=OTHERWISE)
- DI7_ANA_CASE_STATUS (1=CASE, 0=NON A CASE)
**********************************************************************************************;
*QC - 0 dups O.K.;
Proc sort data=IRR.IRR_Group_&REDCapAsOfDate. nodupkey out=nodups dupout=dups;
by studyid anaphylaxis_num;
run;

Data Out.IRR_A;
set IRR.IRR_Group_&REDCapAsOfDate. (drop= IRR_Group);
Label N_Abstractor="[N_Abstractor] #Reviewers";
Label Sum_Judgement="[Sum_Judgement] #Inedependent decisions";
Label DI7_ANA_CASE_STATUS="[DI7_ANA_CASE_STATUS]1=CASE, 0=NOT A CASE";
Label DI7_GOLD_SET="[DI7_GOLD_SET] 1=HAS GOLD LABEL FROM DI7, 0=OTHERWISE)";

DI7_GOLD_SET=1;

N_Abstractor= N(JC_judge, TD_Judge, MW_Judge);
Sum_Judgement= Sum(JC_judge, TD_Judge, MW_Judge);

     If N_Abstractor=1 and Sum_Judgement =0 then DI7_ANA_CASE_STATUS = 0;
Else If N_Abstractor=1 and Sum_Judgement =1 then DI7_ANA_CASE_STATUS = 1;
Else If N_Abstractor=2 and Sum_Judgement =0 then DI7_ANA_CASE_STATUS = 0;
Else If N_Abstractor=2 and Sum_Judgement =1 then DI7_ANA_CASE_STATUS = 1; /*Check prioritization logic with Josh/David*/
Else If N_Abstractor=2 and Sum_Judgement =2 then DI7_ANA_CASE_STATUS = 1;
Else If N_Abstractor=3 and Sum_Judgement =0 then DI7_ANA_CASE_STATUS = 0;
Else If N_Abstractor=3 and Sum_Judgement =1 then DI7_ANA_CASE_STATUS = 0;
Else If N_Abstractor=3 and Sum_Judgement =2 then DI7_ANA_CASE_STATUS = 1;
Else If N_Abstractor=3 and Sum_Judgement =3 then DI7_ANA_CASE_STATUS = 1;
run;

*QC- Case/Non-Case assignment;                                                                         
*DI7_ANA_CASE_STATUS  N_Abstractor    Sum_Judgement  Freq     Cum Freq                                                   
         0               1                0          33            33                           
         0               2                0          11            44                           
         0               3                0          14            58                           
         0               3                1           1            59                           
         1               1                1          23            82                           
         1               2                1           8            90 /*Check prioritization logic with Josh/David*/                          
         1               2                2          12           102                           
         1               3                2           3           105                           
         1               3                3           6           111;  
Proc freq data=Out.IRR_A;
tables DI7_ANA_CASE_STATUS*N_Abstractor*Sum_Judgement
DI7_GOLD_SET*DI7_ANA_CASE_STATUS
/norow nocol nopercent missing list;
run;

***********************************************************************************
	Count of all mentions of REGEX terms per note
**********************************************************************************;
*N=26,589;
data Out.regex_counts_1 (rename=(meta0=id));
set NLP.regex_counts_20231121_173937;
anaph_epine=sum(anaphylaxis,epinephrine);
run;

*QC;
Proc means data=Out.regex_counts_1 N NMISS Min Mean Max maxdec=1;
var anaph_epine 
anaphylaxis
epinephrine;
run;

*N_obs	 N_id 
26,589   26,589 ; 
Proc sql;
Select Count(*) as N_obs
, count(distinct id) as N_id
From Out.regex_counts_1;
quit;

*QC - o dups;
Proc sort data=Out.regex_counts_1 nodupkey out=nodups dupout=dups;
by id;
run;

*Import NLP output - Used StatTransfer to read into SAS;
/*proc import datafile="&MYPATH.\DI7_Assisted_Review\PROGRAMMING\NLP\share\arvind\for_phenorm\corpus_20231220_meta.csv"
   dbms=CSV
   out=NLP.corpus_20231220_meta
replace;
run; */ 

*N=26,666  26,663;
Proc contents data=NLP.Corpus_20231220_meta;run;
                                                                                        
*N_obs      N_id  	N_message_id    N_note_id    N_pat_enc_csn_id  N_studyid                                                                   
26,666 		26,589 		1,817 		24,849 			26,666 			2,407
26,663      26,589      1,818       24,845          26,663          2,407;                                  
Proc sql;
Select Count(*) as N_obs
, count(distinct id) as N_id
, count(Case when message_id not in (.) then message_id end) as N_message_id
, count(Case when note_id not in (.) then note_id end) as N_note_id
, count(Case when pat_enc_csn_id not in (.) then pat_enc_csn_id end) as N_pat_enc_csn_id
, count(distinct studyid) as N_studyid
From NLP.corpus_20231220_meta;
quit;


*QC;
*74 dups by id;
*74 dups by id + message_id
*74 dups by id + message_id + note_id
*74 dups by id + message_id + note_id + pat_enc_csn_id
*74 dups by id + message_id + note_id + pat_enc_csn_id + studyid;
Proc sort data=NLP.Corpus_20231220_meta nodupkey out=nodups dupout=dups;
by id message_id /*note_id pat_enc_csn_id studyid*/;
quit;

*Remove dups ID;
*N=26,589 - after removing 74 dups;
Proc sort data=NLP.corpus_20231220_meta nodupkey out=Corpus_20231220_meta_nodups dupout=dups;
by id ;
quit;

Data Out.Corpus_20231220_meta_nodups;
set Corpus_20231220_meta_nodups;
Note_or_mesg_id=coalesce(message_id, note_id);
run;

*N_obs      N_id    N_message_id  N_note_id  N_Note_or_mesg_id   N_pat_enc_csn_id  N_studyid                                      
26,589      26,589    1,810        24,779       26,589         	  26,589       		2,407
26,589      26,589    1,811        24,778       26,589            26,589            2,407;                                  
Proc sql;
Select Count(*) as N_obs
, count(distinct id) as N_id
, count(Case when message_id not in (.) then message_id end) as N_message_id
, count(Case when note_id not in (.) then note_id end) as N_note_id
, count(Case when Note_or_mesg_id not in (.) then Note_or_mesg_id end) as N_Note_or_mesg_id
, count(Case when pat_enc_csn_id not in (.) then pat_enc_csn_id end) as N_pat_enc_csn_id
, count(distinct studyid) as N_studyid
From Out.Corpus_20231220_meta_nodups;
quit;

*Counts of all mentions(possible for multiple mentions per note_id but we will count all mentions - summarized per event;
*N=26,589 - OK since INNER JOIN to merge at note level;
Proc sql;
Create table Out.regex_counts_2 as
Select a.studyid
	, a.id
	, a.message_id
	, a.note_id
	, a.Note_or_mesg_id
	, a.pat_enc_csn_id
	, b.anaphylaxis
		as ANA_MENTIONS_N
			Label="[ANA_MENTIONS_N]Counts of all mentions in a patient’s study notes of anaphylaxis identified by the case-insensitive regular expression: \banaph\w*"
	, b.anaph_epine
		as ANA_EPI_MENTIONS_N
			Label="[ANA_EPI_MENTIONS_N]Counts of all mentions in a patient’s study notes of anaphylaxis and/or epinephrine identified by either of the following two case-insensitive regular expressions: \banaph\w* or \bepine\w*"

From Out.Corpus_20231220_meta_nodups as A Inner Join Out.regex_counts_1 as B on a.id=b.id;
quit;

*QC;
Proc means data=Out.regex_counts_2 N NMISS Min Mean Max maxdec=1;
var ANA_EPI_MENTIONS_N
ANA_MENTIONS_N;
run;

*CUIs;
*QC-0 dups;
Proc sort data=NLP.Silver_Labels nodupkey out=nodups dupout=dups;
by docid;
run;

Proc contents data=NLP.Silver_Labels ;run;

*N_obs  N_Docid 
3,916    3,916; 
Proc sql;
Select Count(*) as N_obs
	 , count(distinct docid) as N_Docid
From NLP.Silver_Labels;
quit;

*153 CUI terms- 7 terms not found in documentation;
Proc contents data=nlp.nlp_data order=varnum;
run;

*154 CUI terms - 1 record per docid;
*N_obs   N_Docid 
17,001   17,001 ; 
Proc sql;
Select Count(*) as N_obs
	 , count(distinct docid) as N_Docid
From NLP.nlp_data;
quit;

*Append CUIs;
*N=26,589 - contains 1 record per encounter per note;
Proc sql;
Create table Out.regex_counts_3 as
Select a.studyid
	, a.id
	, a.message_id
	, a.note_id
	, a.Note_or_mesg_id
	, a.pat_enc_csn_id
	, a.ANA_MENTIONS_N
	, a.ANA_EPI_MENTIONS_N
	, b.c0002792
	, b.c0340865
	, b.c0685898
	, b.c0854649
	, b.c4316895
	, c.*
From Out.regex_counts_2 as A Left Join NLP.Silver_Labels 				as B on a.id=b.docid
							 Left Join NLP.nlp_data( drop = c0002792
															c0340865
															c0685898
															c0854649
															c4316895)	as C on a.ID=c.docid;
quit;

*Append 160 CUI NLP variables - JOIN by ID and DocId;
*N=26,589 - contains 1 record per encounter per note;
Proc sql;
Create table Out.CUI_NLP_Vars as
Select a.studyid
	, a.id
	, a.message_id
	, a.note_id
	, a.Note_or_mesg_id
	, a.pat_enc_csn_id
	, a.ANA_MENTIONS_N
	, a.ANA_EPI_MENTIONS_N
	, max(b.C0000729) as C0000729
	, max(b.C0000737) as C0000737
	, max(b.C0001883) as C0001883
	, max(b.C0002792) as C0002792
	, max(b.C0002994) as C0002994
	, max(b.C0003467) as C0003467
	, max(b.C0004096) as C0004096
	, max(b.C0005658) as C0005658
	, max(b.C0006266) as C0006266
	, max(b.C0007203) as C0007203
	, max(b.C0008031) as C0008031
	, max(b.C0009443) as C0009443
	, max(b.C0009676) as C0009676
	, max(b.C0010200) as C0010200
	, max(b.C0011991) as C0011991
	, max(b.C0012833) as C0012833
	, max(b.C0013182) as C0013182
	, max(b.C0013404) as C0013404
	, max(b.C0013604) as C0013604
	, max(b.C0014236) as C0014236
	, max(b.C0014563) as C0014563
	, max(b.C0015376) as C0015376
	, max(b.C0015663) as C0015663
	, max(b.C0016382) as C0016382
	, max(b.C0016462) as C0016462
	, max(b.C0016470) as C0016470
	, max(b.C0018790) as C0018790
	, max(b.C0019825) as C0019825
	, max(b.C0020517) as C0020517
	, max(b.C0020523) as C0020523
	, max(b.C0020649) as C0020649
	, max(b.C0020683) as C0020683
	, max(b.C0021368) as C0021368
	, max(b.C0021564) as C0021564
	, max(b.C0021925) as C0021925
	, max(b.C0021932) as C0021932
	, max(b.C0022885) as C0022885
	, max(b.C0023052) as C0023052
	, max(b.C0024899) as C0024899
	, max(b.C0026821) as C0026821
	, max(b.C0027497) as C0027497
	, max(b.C0027498) as C0027498
	, max(b.C0027627) as C0027627
	, max(b.C0028778) as C0028778
	, max(b.C0030193) as C0030193
	, max(b.C0030252) as C0030252
	, max(b.C0033774) as C0033774
	, max(b.C0035273) as C0035273
	, max(b.C0036974) as C0036974
	, max(b.C0036980) as C0036980
	, max(b.C0037090) as C0037090
	, max(b.C0037296) as C0037296
	, max(b.C0038340) as C0038340
	, max(b.C0038450) as C0038450
	, max(b.C0038999) as C0038999
	, max(b.C0039070) as C0039070
	, max(b.C0039231) as C0039231
	, max(b.C0040533) as C0040533
	, max(b.C0041657) as C0041657
	, max(b.C0041755) as C0041755
	, max(b.C0042109) as C0042109
	, max(b.C0042196) as C0042196
	, max(b.C0042420) as C0042420
	, max(b.C0042963) as C0042963
	, max(b.C0043144) as C0043144
	, max(b.C0079603) as C0079603
	, max(b.C0079840) as C0079840
	, max(b.C0087111) as C0087111
	, max(b.C0149783) as C0149783
	, max(b.C0151602) as C0151602
	, max(b.C0151610) as C0151610
	, max(b.C0155877) as C0155877
	, max(b.C0162297) as C0162297
	, max(b.C0199176) as C0199176
	, max(b.C0199470) as C0199470
	, max(b.C0199747) as C0199747
	, max(b.C0202202) as C0202202
	, max(b.C0220787) as C0220787
	, max(b.C0220870) as C0220870
	, max(b.C0221232) as C0221232
	, max(b.C0231835) as C0231835
	, max(b.C0231848) as C0231848
	, max(b.C0232070) as C0232070
	, max(b.C0232292) as C0232292
	, max(b.C0235710) as C0235710
	, max(b.C0236068) as C0236068
	, max(b.C0236071) as C0236071
	, max(b.C0238614) as C0238614
	, max(b.C0240211) as C0240211
	, max(b.C0242073) as C0242073
	, max(b.C0242184) as C0242184
	, max(b.C0340865) as C0340865
	, max(b.C0344183) as C0344183
	, max(b.C0347950) as C0347950
	, max(b.C0349790) as C0349790
	, max(b.C0392707) as C0392707
	, max(b.C0413119) as C0413119
	, max(b.C0413120) as C0413120
	, max(b.C0413234) as C0413234
	, max(b.C0426576) as C0426576
	, max(b.C0442856) as C0442856
	, max(b.C0476207) as C0476207
	, max(b.C0476273) as C0476273
	, max(b.C0521481) as C0521481
	, max(b.C0542571) as C0542571
	, max(b.C0543467) as C0543467
	, max(b.C0546884) as C0546884
	, max(b.C0549249) as C0549249
	, max(b.C0554804) as C0554804
	, max(b.C0559469) as C0559469
	, max(b.C0559470) as C0559470
	, max(b.C0559546) as C0559546
	, max(b.C0577620) as C0577620
	, max(b.C0577628) as C0577628
	, max(b.C0586407) as C0586407
	, max(b.C0595862) as C0595862
	, max(b.C0600228) as C0600228
	, max(b.C0677500) as C0677500
	, max(b.C0685898) as C0685898
	, max(b.C0700184) as C0700184
	, max(b.C0700198) as C0700198
	, max(b.C0740651) as C0740651
	, max(b.C0740852) as C0740852
	, max(b.C0743747) as C0743747
	, max(b.C0744425) as C0744425
	, max(b.C0850569) as C0850569
	, max(b.C0854051) as C0854051
	, max(b.C0854649) as C0854649
	, max(b.C0856904) as C0856904
	, max(b.C0857035) as C0857035
	, max(b.C0857353) as C0857353
	, max(b.C0859897) as C0859897
	, max(b.C0877248) as C0877248
	, max(b.C0947961) as C0947961
	, max(b.C1145670) as C1145670
	, max(b.C1260880) as C1260880
	, max(b.C1260922) as C1260922
	, max(b.C1261392) as C1261392
	, max(b.C1304200) as C1304200
	, max(b.C1306577) as C1306577
	, max(b.C1328414) as C1328414
	, max(b.C1504374) as C1504374
	, max(b.C1527304) as C1527304
	, max(b.C1527344) as C1527344
	, max(b.C1533685) as C1533685
	, max(b.C1861783) as C1861783
	, max(b.C2939065) as C2939065
	, max(b.C4047193) as C4047193
	, max(b.C4055482) as C4055482
	, max(b.C4316895) as C4316895
	, max(b.C4324659) as C4324659
	, max(b.C4510560) as C4510560
	, max(b.C5208132) as C5208132

From Out.regex_counts_2 as A Left Join NLP.nlp_data	 as B on a.id=b.docid
Group by a.studyid
	, a.id
	, a.message_id
	, a.note_id
	, a.Note_or_mesg_id
	, a.pat_enc_csn_id
	, a.ANA_MENTIONS_N
	, a.ANA_EPI_MENTIONS_N;
quit;

*We've previously created records per RECORD_ID- use this to merge with Note_or_mesg_id;
*Note NoteText.Summary_Per_id has 79 dups - probably because same notes may be associated with multiple events- reason why we should have GROUP BY (does not matter- MAX or SUM;
*N=26,755 - OK - same as in the input dataset: NoteText.Summary_Per_id;
*1 record per record_id per event;
Proc sql;
Create table Out.Summary_Per_id as
Select a.Studyid
	 , a.MRN
	 , a.Episode_Start_date 
	 , a.Episode_End_Date 
	 , a.Record_id
	 , a.contact_date			
	 , a.N_Chars
	 , a.Record_type 
	 , a.Record_type2 
	 , sum(b.ANA_MENTIONS_N) 
		as ANA_MENTIONS_N
			Label="[ANA_MENTIONS_N]Counts of all mentions in a patient’s study notes of anaphylaxis identified by the case-insensitive regular expression “\banaph\w*”"
	 , sum(b.ANA_EPI_MENTIONS_N) 
		as ANA_EPI_MENTIONS_N
			Label="[ANA_EPI_MENTIONS_N]Counts of all mentions in a patient’s study notes of anaphylaxis and/or epinephrine identified by either of the following two case-insensitive regular expressions “\banaph\w*” or “\bepine\w*"
	 , Max(Distinct Case when input(a.Record_id,z12.)=b.Note_or_mesg_id
						  and (b.c0002792>=1
							or b.c0340865>=1
							or b.c0685898>=1
							or b.c0854649>=1
							or b.c4316895>=1) Then 1 else 0 end)
		as W_ANA_CUI_YESNO
/*160 CUI NLP vars*/	
	, max(c.C0000729) as C0000729
	, max(c.C0000737) as C0000737
	, max(c.C0001883) as C0001883
	, max(c.C0002792) as C0002792
	, max(c.C0002994) as C0002994
	, max(c.C0003467) as C0003467
	, max(c.C0004096) as C0004096
	, max(c.C0005658) as C0005658
	, max(c.C0006266) as C0006266
	, max(c.C0007203) as C0007203
	, max(c.C0008031) as C0008031
	, max(c.C0009443) as C0009443
	, max(c.C0009676) as C0009676
	, max(c.C0010200) as C0010200
	, max(c.C0011991) as C0011991
	, max(c.C0012833) as C0012833
	, max(c.C0013182) as C0013182
	, max(c.C0013404) as C0013404
	, max(c.C0013604) as C0013604
	, max(c.C0014236) as C0014236
	, max(c.C0014563) as C0014563
	, max(c.C0015376) as C0015376
	, max(c.C0015663) as C0015663
	, max(c.C0016382) as C0016382
	, max(c.C0016462) as C0016462
	, max(c.C0016470) as C0016470
	, max(c.C0018790) as C0018790
	, max(c.C0019825) as C0019825
	, max(c.C0020517) as C0020517
	, max(c.C0020523) as C0020523
	, max(c.C0020649) as C0020649
	, max(c.C0020683) as C0020683
	, max(c.C0021368) as C0021368
	, max(c.C0021564) as C0021564
	, max(c.C0021925) as C0021925
	, max(c.C0021932) as C0021932
	, max(c.C0022885) as C0022885
	, max(c.C0023052) as C0023052
	, max(c.C0024899) as C0024899
	, max(c.C0026821) as C0026821
	, max(c.C0027497) as C0027497
	, max(c.C0027498) as C0027498
	, max(c.C0027627) as C0027627
	, max(c.C0028778) as C0028778
	, max(c.C0030193) as C0030193
	, max(c.C0030252) as C0030252
	, max(c.C0033774) as C0033774
	, max(c.C0035273) as C0035273
	, max(c.C0036974) as C0036974
	, max(c.C0036980) as C0036980
	, max(c.C0037090) as C0037090
	, max(c.C0037296) as C0037296
	, max(c.C0038340) as C0038340
	, max(c.C0038450) as C0038450
	, max(c.C0038999) as C0038999
	, max(c.C0039070) as C0039070
	, max(c.C0039231) as C0039231
	, max(c.C0040533) as C0040533
	, max(c.C0041657) as C0041657
	, max(c.C0041755) as C0041755
	, max(c.C0042109) as C0042109
	, max(c.C0042196) as C0042196
	, max(c.C0042420) as C0042420
	, max(c.C0042963) as C0042963
	, max(c.C0043144) as C0043144
	, max(c.C0079603) as C0079603
	, max(c.C0079840) as C0079840
	, max(c.C0087111) as C0087111
	, max(c.C0149783) as C0149783
	, max(c.C0151602) as C0151602
	, max(c.C0151610) as C0151610
	, max(c.C0155877) as C0155877
	, max(c.C0162297) as C0162297
	, max(c.C0199176) as C0199176
	, max(c.C0199470) as C0199470
	, max(c.C0199747) as C0199747
	, max(c.C0202202) as C0202202
	, max(c.C0220787) as C0220787
	, max(c.C0220870) as C0220870
	, max(c.C0221232) as C0221232
	, max(c.C0231835) as C0231835
	, max(c.C0231848) as C0231848
	, max(c.C0232070) as C0232070
	, max(c.C0232292) as C0232292
	, max(c.C0235710) as C0235710
	, max(c.C0236068) as C0236068
	, max(c.C0236071) as C0236071
	, max(c.C0238614) as C0238614
	, max(c.C0240211) as C0240211
	, max(c.C0242073) as C0242073
	, max(c.C0242184) as C0242184
	, max(c.C0340865) as C0340865
	, max(c.C0344183) as C0344183
	, max(c.C0347950) as C0347950
	, max(c.C0349790) as C0349790
	, max(c.C0392707) as C0392707
	, max(c.C0413119) as C0413119
	, max(c.C0413120) as C0413120
	, max(c.C0413234) as C0413234
	, max(c.C0426576) as C0426576
	, max(c.C0442856) as C0442856
	, max(c.C0476207) as C0476207
	, max(c.C0476273) as C0476273
	, max(c.C0521481) as C0521481
	, max(c.C0542571) as C0542571
	, max(c.C0543467) as C0543467
	, max(c.C0546884) as C0546884
	, max(c.C0549249) as C0549249
	, max(c.C0554804) as C0554804
	, max(c.C0559469) as C0559469
	, max(c.C0559470) as C0559470
	, max(c.C0559546) as C0559546
	, max(c.C0577620) as C0577620
	, max(c.C0577628) as C0577628
	, max(c.C0586407) as C0586407
	, max(c.C0595862) as C0595862
	, max(c.C0600228) as C0600228
	, max(c.C0677500) as C0677500
	, max(c.C0685898) as C0685898
	, max(c.C0700184) as C0700184
	, max(c.C0700198) as C0700198
	, max(c.C0740651) as C0740651
	, max(c.C0740852) as C0740852
	, max(c.C0743747) as C0743747
	, max(c.C0744425) as C0744425
	, max(c.C0850569) as C0850569
	, max(c.C0854051) as C0854051
	, max(c.C0854649) as C0854649
	, max(c.C0856904) as C0856904
	, max(c.C0857035) as C0857035
	, max(c.C0857353) as C0857353
	, max(c.C0859897) as C0859897
	, max(c.C0877248) as C0877248
	, max(c.C0947961) as C0947961
	, max(c.C1145670) as C1145670
	, max(c.C1260880) as C1260880
	, max(c.C1260922) as C1260922
	, max(c.C1261392) as C1261392
	, max(c.C1304200) as C1304200
	, max(c.C1306577) as C1306577
	, max(c.C1328414) as C1328414
	, max(c.C1504374) as C1504374
	, max(c.C1527304) as C1527304
	, max(c.C1527344) as C1527344
	, max(c.C1533685) as C1533685
	, max(c.C1861783) as C1861783
	, max(c.C2939065) as C2939065
	, max(c.C4047193) as C4047193
	, max(c.C4055482) as C4055482
	, max(c.C4316895) as C4316895
	, max(c.C4324659) as C4324659
	, max(c.C4510560) as C4510560
	, max(c.C5208132) as C5208132

From CTM.Summary_Per_id as A Left Join Out.regex_counts_3 as B on input(a.Record_id,z12.)=b.Note_or_mesg_id
								  Left Join Out.CUI_NLP_Vars   as C on input(a.Record_id,z12.)=c.Note_or_mesg_id	
Group by a.Studyid
	 , a.MRN
	 , a.Episode_Start_date 
	 , a.Episode_End_Date 
	 , a.Record_id
	 , a.contact_date			
	 , a.N_Chars
	 , a.Record_type 
	 , a.Record_type2 ;
quit;

*QC;
Proc means data=Out.Summary_Per_id nmiss min mean median max maxdec=1;
var ANA_MENTIONS_N 
ANA_EPI_MENTIONS_N
ANA_CUI_NOTES_N;
run;

*Summarize Silver labels by ANA event/episode (sum up all notes associated with an event);
*N=2,653;
Proc sql;
Create table Out.Summary_by_ANA_Event as
Select Studyid
	 , MRN
	 , Episode_Start_date 
	 , Episode_End_Date
 	 , sum(ANA_MENTIONS_N) 
		as ANA_MENTIONS_N
			Label="[ANA_MENTIONS_N]Counts of all mentions in a patient’s study notes of anaphylaxis identified by the case-insensitive regular expression “\banaph\w*”"
	 , sum(ANA_EPI_MENTIONS_N) 
		as ANA_EPI_MENTIONS_N
			Label="[ANA_EPI_MENTIONS_N]Counts of all mentions in a patient’s study notes of anaphylaxis and/or epinephrine identified by either of the following two case-insensitive regular expressions “\banaph\w*” or “\bepine\w*"
	 , Count(distinct Case when W_ANA_CUI_YESNO>=1 then Record_id end)
	 	as ANA_CUI_NOTES_N
			Label="[ANA_CUI_NOTES_N]Counts of notes containing one or more strings tagged with the UMLS/MedDRA CUI for any of the following concepts"
	, Sum(C0000729) as C0000729
	, Sum(C0000737) as C0000737
	, Sum(C0001883) as C0001883
	, Sum(C0002792) as C0002792
	, Sum(C0002994) as C0002994
	, Sum(C0003467) as C0003467
	, Sum(C0004096) as C0004096
	, Sum(C0005658) as C0005658
	, Sum(C0006266) as C0006266
	, Sum(C0007203) as C0007203
	, Sum(C0008031) as C0008031
	, Sum(C0009443) as C0009443
	, Sum(C0009676) as C0009676
	, Sum(C0010200) as C0010200
	, Sum(C0011991) as C0011991
	, Sum(C0012833) as C0012833
	, Sum(C0013182) as C0013182
	, Sum(C0013404) as C0013404
	, Sum(C0013604) as C0013604
	, Sum(C0014236) as C0014236
	, Sum(C0014563) as C0014563
	, Sum(C0015376) as C0015376
	, Sum(C0015663) as C0015663
	, Sum(C0016382) as C0016382
	, Sum(C0016462) as C0016462
	, Sum(C0016470) as C0016470
	, Sum(C0018790) as C0018790
	, Sum(C0019825) as C0019825
	, Sum(C0020517) as C0020517
	, Sum(C0020523) as C0020523
	, Sum(C0020649) as C0020649
	, Sum(C0020683) as C0020683
	, Sum(C0021368) as C0021368
	, Sum(C0021564) as C0021564
	, Sum(C0021925) as C0021925
	, Sum(C0021932) as C0021932
	, Sum(C0022885) as C0022885
	, Sum(C0023052) as C0023052
	, Sum(C0024899) as C0024899
	, Sum(C0026821) as C0026821
	, Sum(C0027497) as C0027497
	, Sum(C0027498) as C0027498
	, Sum(C0027627) as C0027627
	, Sum(C0028778) as C0028778
	, Sum(C0030193) as C0030193
	, Sum(C0030252) as C0030252
	, Sum(C0033774) as C0033774
	, Sum(C0035273) as C0035273
	, Sum(C0036974) as C0036974
	, Sum(C0036980) as C0036980
	, Sum(C0037090) as C0037090
	, Sum(C0037296) as C0037296
	, Sum(C0038340) as C0038340
	, Sum(C0038450) as C0038450
	, Sum(C0038999) as C0038999
	, Sum(C0039070) as C0039070
	, Sum(C0039231) as C0039231
	, Sum(C0040533) as C0040533
	, Sum(C0041657) as C0041657
	, Sum(C0041755) as C0041755
	, Sum(C0042109) as C0042109
	, Sum(C0042196) as C0042196
	, Sum(C0042420) as C0042420
	, Sum(C0042963) as C0042963
	, Sum(C0043144) as C0043144
	, Sum(C0079603) as C0079603
	, Sum(C0079840) as C0079840
	, Sum(C0087111) as C0087111
	, Sum(C0149783) as C0149783
	, Sum(C0151602) as C0151602
	, Sum(C0151610) as C0151610
	, Sum(C0155877) as C0155877
	, Sum(C0162297) as C0162297
	, Sum(C0199176) as C0199176
	, Sum(C0199470) as C0199470
	, Sum(C0199747) as C0199747
	, Sum(C0202202) as C0202202
	, Sum(C0220787) as C0220787
	, Sum(C0220870) as C0220870
	, Sum(C0221232) as C0221232
	, Sum(C0231835) as C0231835
	, Sum(C0231848) as C0231848
	, Sum(C0232070) as C0232070
	, Sum(C0232292) as C0232292
	, Sum(C0235710) as C0235710
	, Sum(C0236068) as C0236068
	, Sum(C0236071) as C0236071
	, Sum(C0238614) as C0238614
	, Sum(C0240211) as C0240211
	, Sum(C0242073) as C0242073
	, Sum(C0242184) as C0242184
	, Sum(C0340865) as C0340865
	, Sum(C0344183) as C0344183
	, Sum(C0347950) as C0347950
	, Sum(C0349790) as C0349790
	, Sum(C0392707) as C0392707
	, Sum(C0413119) as C0413119
	, Sum(C0413120) as C0413120
	, Sum(C0413234) as C0413234
	, Sum(C0426576) as C0426576
	, Sum(C0442856) as C0442856
	, Sum(C0476207) as C0476207
	, Sum(C0476273) as C0476273
	, Sum(C0521481) as C0521481
	, Sum(C0542571) as C0542571
	, Sum(C0543467) as C0543467
	, Sum(C0546884) as C0546884
	, Sum(C0549249) as C0549249
	, Sum(C0554804) as C0554804
	, Sum(C0559469) as C0559469
	, Sum(C0559470) as C0559470
	, Sum(C0559546) as C0559546
	, Sum(C0577620) as C0577620
	, Sum(C0577628) as C0577628
	, Sum(C0586407) as C0586407
	, Sum(C0595862) as C0595862
	, Sum(C0600228) as C0600228
	, Sum(C0677500) as C0677500
	, Sum(C0685898) as C0685898
	, Sum(C0700184) as C0700184
	, Sum(C0700198) as C0700198
	, Sum(C0740651) as C0740651
	, Sum(C0740852) as C0740852
	, Sum(C0743747) as C0743747
	, Sum(C0744425) as C0744425
	, Sum(C0850569) as C0850569
	, Sum(C0854051) as C0854051
	, Sum(C0854649) as C0854649
	, Sum(C0856904) as C0856904
	, Sum(C0857035) as C0857035
	, Sum(C0857353) as C0857353
	, Sum(C0859897) as C0859897
	, Sum(C0877248) as C0877248
	, Sum(C0947961) as C0947961
	, Sum(C1145670) as C1145670
	, Sum(C1260880) as C1260880
	, Sum(C1260922) as C1260922
	, Sum(C1261392) as C1261392
	, Sum(C1304200) as C1304200
	, Sum(C1306577) as C1306577
	, Sum(C1328414) as C1328414
	, Sum(C1504374) as C1504374
	, Sum(C1527304) as C1527304
	, Sum(C1527344) as C1527344
	, Sum(C1533685) as C1533685
	, Sum(C1861783) as C1861783
	, Sum(C2939065) as C2939065
	, Sum(C4047193) as C4047193
	, Sum(C4055482) as C4055482
	, Sum(C4316895) as C4316895
	, Sum(C4324659) as C4324659
	, Sum(C4510560) as C4510560
	, Sum(C5208132) as C5208132

From  Out.Summary_Per_id 
Group by  Studyid
	 , MRN
	 , Episode_Start_date 
	 , Episode_End_Date;
quit;

*QC - 0 dups;
Proc sort data=Out.Summary_by_ANA_Event nodupkey out=nodups dupout=dups;
by Studyid Episode_Start_date;
run;

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
*			ANALYTIC FILE					;
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
*N=4,297;
Proc sql;
Create table Out.TmpC as
Select a.Obs_ID
			Label="[Obs_ID] A unique observation identifier created by concatenating StudyID and Anaphylaxis_Num"
	 , a.ASSIGNED_PATH
			Label="[ASSIGNED_PATH] Each potential event included in the study cohort was assigned to one and only one of the three eligibility paths (Path-1, Path-2, or Path-3)"
	 , a.ASSIGNED_PATH_2
			Label="[ASSIGNED_PATH_2] A binary (0/1) flag set to 1 if the event’s assigned path was Path 2 and set to 0 otherwise"
	 , a.ASSIGNED_PATH_3
			Label="[ASSIGNED_PATH_3] A binary (0/1) flag set to 1 if the event’s assigned path was Path 3 and set to 0 otherwise"
	 , a.Filter_Group 
			Label="[Filter_Group]String variable indicating the name of the group by which the observation qualified for inclusion in the cohort:'Assigned_Path_1','Assigned_Path_2', or 'Assigned_Path_3'"
	 , a.Sampling_Weight
			Label="[Sampling_Weight] A numeric variable indicating the sampling weight associated with the observation’s Sample_Group with at least 4 significant digits to the right of the decimal) - populate with all 1s"
	 , a.Age_Index 
			Label="[Age_Index] Age(in years) at index"
	 , a.SEX_F
			Label="[SEX_F] 1=if patient’s sex in healthcare data is recorded as female, 0=otherwise"
	 , a.Race_AFAM
			Label="[Race_AFAM] 1=if race is Black/African American, 0=otherwise"
	 , a.Race_Asian
			Label="[Race_Asian] 1=if race is Asian, 0=otherwise"
	 , a.Race_HP
			Label="[Race_HP] 1=if race is Native Hawaiian or Pacific Islander, 0=otherwise"
	 , a.Race_NatAm
			Label="[Race_NatAm] 1=if race is Native American or Alaska Native, 0=otherwise"
	 , a.Race_Other
			Label="[Race_Other] 1=if any other race is reported, 0=otherwise"
	 , a.Race_UNKN 
			Label="[Race_UNKN] 1=if all race information is missing, 0=otherwise"
	 , a.Ethnicity 
			Label="[Ethnicity ] 1=ethnicity is Hispanic, 0=otherwise"
	 , a.ANTIHISTRSD
	 		Label="[ANTIHISTRSD] DxPxCode = J1200 (HCPC for IM diphenydramine) (1=Yes/0=No)"
	 , a.EPIRSD
	 		Label="[EPIRSD] DxPxCode in (J0170, J0171) (HCPC for IM epinephrine) (1=Yes/0=No)" 		
	 , a.N_CALDAYS_W_NOTES_WO_SM
			Label="[N_CALDAYS_W_NOTES_WO_SM] Number of distinct calendar days with any clinical notes (NOT including secure messages)"
			format=comma8.
	 , a.N_CALDAYS_W_NOTES_W_SM
			Label="[N_CALDAYS_W_NOTES_W_SM] Number of distinct calendar days with any clinical notes (INCLUDING secure messages)"
	 , a.N_NOTES_WO_SM
			Label="[N_NOTES_WO_SM] Number of distinct notes (NOT including secure messages)"
	 , a.N_NOTES_W_SM
			Label="[N_NOTES_W_SM] Number of distinct notes (INCLUDING secure messages)"
	 , a.TOT_NOTES_CHARCOUNT_WO_SM
			Label="[TOT_NOTES_CHARCOUNT_WO_SM] Total character count of all notes (NOT including secure messages)"
	 , a.TOT_NOTES_CHARCOUNT_W_SM
			Label="[TOT_NOTES_CHARCOUNT_W_SM] Total character count of all notes (INCLUDING secure messages)"
	 , a.ANA_DX_N_ENCS
	 	as SILVER_ANA_DX_N_ENCS
	 		Label="[SILVER_ANA_DX_N_ENCS] Number of distinct encounters starting during episode with any Walsh Table 1 dx"
	 , coalesce(b.ANA_MENTIONS_N,0)
	 	as SILVER_ANA_MENTIONS_N
	 		Label="[SILVER_ANA_MENTIONS_N] Counts of all mentions in a patient’s study notes of anaphylaxis identified by the case-insensitive regular expression '\banaph\w*'"
	 , coalesce(b.ANA_CUI_NOTES_N,0) 
	 	as SILVER_ANA_CUI_NOTES_N
	 		Label="[SILVER_ANA_CUI_NOTES_N] Counts of notes containing one or more strings tagged with the UMLS/MedDRA CUI representing anaphylaxis and/or anaphylaxis treatment:"
	 , coalesce(b.ANA_EPI_MENTIONS_N,0) 
	 	as SILVER_ANA_EPI_MENTIONS_N
	 		Label="[SILVER_ANA_EPI_MENTIONS_N]Counts of all mentions in a patient’s study notes of anaphylaxis and/or epinephrine identified by either of the following two case-insensitive regular expressions '\banaph\w*' or '\bepine\w*'"
	 , a.HOI_2_0_Gold_Set 
			Label="[HOI_2_0_Gold_Set]Set to 1 if this event is also represented in the HOI 2.0 anaphylaxis modeling study conducted in 2021 by Jennifer Nelson and David Carrell, 0=otherwise"
	 , a.HOI_2_0_Gold_Case 
			Label="[HOI_2_0_Gold_Case] Populated only for observations where HOI_2_0_Gold_Set=1, 1=observation was determined to be an actual anaphylaxis case based on the HOI 2.0 study’s manual chart review, 0=observation was determined not to be a case"
	 , Coalesce(a.HOI_2_0_Sampling_Weight,1) 
	 	as HOI_2_0_Sampling_Weight
			Label="[HOI_2_0_Sampling_Weight]Corresponds to the HOI2.0 outcome in Paths 1,2 & 3"
	, Coalesce(c.DI7_GOLD_SET,0)
	 	as DI7_GOLD_SET
			Label="[DI7_GOLD_SET]1=HAS GOLD LABEL FROM DI7, 0=OTHERWISE"
	 , Coalesce(c.DI7_ANA_CASE_STATUS,0)
	 	as DI7_ANA_CASE_STATUS
			Label="[DI7_ANA_CASE_STATUS]1=CASE, 0=NOT A CASE"

	, coalesce(b.C0000729,0) as C0000729 Label='[C0000729] Count of all mentions of the CUI term:  Abdominal cramps'
	, coalesce(b.C0000737,0) as C0000737 Label='[C0000737] Count of all mentions of the CUI term:  Abdominal pain'
	, coalesce(b.C0001883,0) as C0001883 Label='[C0001883] Count of all mentions of the CUI term:  Airway obstruction NOS'
	, coalesce(b.C0002792,0) as C0002792 Label='[C0002792] Count of all mentions of the CUI term:  Anaphylactic reaction'
	, coalesce(b.C0002994,0) as C0002994 Label='[C0002994] Count of all mentions of the CUI term:  Angioedema'
	, coalesce(b.C0003467,0) as C0003467 Label='[C0003467] Count of all mentions of the CUI term:  Anxiety'
	, coalesce(b.C0004096,0) as C0004096 Label='[C0004096] Count of all mentions of the CUI term:  Asthma'
	, coalesce(b.C0005658,0) as C0005658 Label='[C0005658] Count of all mentions of the CUI term:  Bite NOS'
	, coalesce(b.C0006266,0) as C0006266 Label='[C0006266] Count of all mentions of the CUI term:  Bronchospasm'
	, coalesce(b.C0007203,0) as C0007203 Label='[C0007203] Count of all mentions of the CUI term:  Cardiopulmonary resuscitation'
	, coalesce(b.C0008031,0) as C0008031 Label='[C0008031] Count of all mentions of the CUI term:  Chest pain'
	, coalesce(b.C0009443,0) as C0009443 Label='[C0009443] Count of all mentions of the CUI term:  Common cold'
	, coalesce(b.C0009676,0) as C0009676 Label='[C0009676] Count of all mentions of the CUI term:  Confusional state'
	, coalesce(b.C0010200,0) as C0010200 Label='[C0010200] Count of all mentions of the CUI term:  Cough'
	, coalesce(b.C0011991,0) as C0011991 Label='[C0011991] Count of all mentions of the CUI term:  Diarrhoea'
	, coalesce(b.C0012833,0) as C0012833 Label='[C0012833] Count of all mentions of the CUI term:  Dizziness'
	, coalesce(b.C0013182,0) as C0013182 Label='[C0013182] Count of all mentions of the CUI term:  Drug hypersensitivity'
	, coalesce(b.C0013404,0) as C0013404 Label='[C0013404] Count of all mentions of the CUI term:  Dyspnoea'
	, coalesce(b.C0013604,0) as C0013604 Label='[C0013604] Count of all mentions of the CUI term:  Oedema'
	, coalesce(b.C0014236,0) as C0014236 Label='[C0014236] Count of all mentions of the CUI term:  Endophthalmitis'
	, coalesce(b.C0014563,0) as C0014563 Label='[C0014563] Count of all mentions of the CUI term:  epinephrine'
	, coalesce(b.C0015376,0) as C0015376 Label='[C0015376] Count of all mentions of the CUI term:  Extravasation'
	, coalesce(b.C0015663,0) as C0015663 Label='[C0015663] Count of all mentions of the CUI term:  Fasting'
	, coalesce(b.C0016382,0) as C0016382 Label='[C0016382] Count of all mentions of the CUI term:  Flushing'
	, coalesce(b.C0016462,0) as C0016462 Label='[C0016462] Count of all mentions of the CUI term:  Food contamination'
	, coalesce(b.C0016470,0) as C0016470 Label='[C0016470] Count of all mentions of the CUI term:  Food allergy'
	, coalesce(b.C0018790,0) as C0018790 Label='[C0018790] Count of all mentions of the CUI term:  Cardiac arrest'
	, coalesce(b.C0019825,0) as C0019825 Label='[C0019825] Count of all mentions of the CUI term:  Hoarseness'
	, coalesce(b.C0020517,0) as C0020517 Label='[C0020517] Count of all mentions of the CUI term:  Hypersensitivity'
	, coalesce(b.C0020523,0) as C0020523 Label='[C0020523] Count of all mentions of the CUI term:  Immediate hypersensitivity'
	, coalesce(b.C0020649,0) as C0020649 Label='[C0020649] Count of all mentions of the CUI term:  Blood pressure decreased'
	, coalesce(b.C0020683,0) as C0020683 Label='[C0020683] Count of all mentions of the CUI term:  Hypovolemic shock'
	, coalesce(b.C0021368,0) as C0021368 Label='[C0021368] Count of all mentions of the CUI term:  Inflammation'
	, coalesce(b.C0021564,0) as C0021564 Label='[C0021564] Count of all mentions of the CUI term:  Insect bite NOS'
	, coalesce(b.C0021925,0) as C0021925 Label='[C0021925] Count of all mentions of the CUI term:  Intubation NOS'
	, coalesce(b.C0021932,0) as C0021932 Label='[C0021932] Count of all mentions of the CUI term:  Endotracheal intubation'
	, coalesce(b.C0022885,0) as C0022885 Label='[C0022885] Count of all mentions of the CUI term:  Laboratory test'
	, coalesce(b.C0023052,0) as C0023052 Label='[C0023052] Count of all mentions of the CUI term:  Laryngeal oedema'
	, coalesce(b.C0024899,0) as C0024899 Label='[C0024899] Count of all mentions of the CUI term:  Mastocytosis'
	, coalesce(b.C0026821,0) as C0026821 Label='[C0026821] Count of all mentions of the CUI term:  Muscle cramp'
	, coalesce(b.C0027497,0) as C0027497 Label='[C0027497] Count of all mentions of the CUI term:  Nausea'
	, coalesce(b.C0027498,0) as C0027498 Label='[C0027498] Count of all mentions of the CUI term:  Nausea and vomiting'
	, coalesce(b.C0027627,0) as C0027627 Label='[C0027627] Count of all mentions of the CUI term:  Metastasis'
	, coalesce(b.C0028778,0) as C0028778 Label='[C0028778] Count of all mentions of the CUI term:  Obstruction'
	, coalesce(b.C0030193,0) as C0030193 Label='[C0030193] Count of all mentions of the CUI term:  Pain'
	, coalesce(b.C0030252,0) as C0030252 Label='[C0030252] Count of all mentions of the CUI term:  Palpitations'
	, coalesce(b.C0033774,0) as C0033774 Label='[C0033774] Count of all mentions of the CUI term:  Pruritus'
	, coalesce(b.C0035273,0) as C0035273 Label='[C0035273] Count of all mentions of the CUI term:  Resuscitation'
	, coalesce(b.C0036974,0) as C0036974 Label='[C0036974] Count of all mentions of the CUI term:  Shock'
	, coalesce(b.C0036980,0) as C0036980 Label='[C0036980] Count of all mentions of the CUI term:  Cardiogenic shock'
	, coalesce(b.C0037090,0) as C0037090 Label='[C0037090] Count of all mentions of the CUI term:  Respiratory symptom'
	, coalesce(b.C0037296,0) as C0037296 Label='[C0037296] Count of all mentions of the CUI term:  Skin test'
	, coalesce(b.C0038340,0) as C0038340 Label='[C0038340] Count of all mentions of the CUI term:  Sting'
	, coalesce(b.C0038450,0) as C0038450 Label='[C0038450] Count of all mentions of the CUI term:  Stridor'
	, coalesce(b.C0038999,0) as C0038999 Label='[C0038999] Count of all mentions of the CUI term:  Swelling'
	, coalesce(b.C0039070,0) as C0039070 Label='[C0039070] Count of all mentions of the CUI term:  Syncope'
	, coalesce(b.C0039231,0) as C0039231 Label='[C0039231] Count of all mentions of the CUI term:  Heart rate increased'
	, coalesce(b.C0040533,0) as C0040533 Label='[C0040533] Count of all mentions of the CUI term:  Toxic effect of venom'
	, coalesce(b.C0041657,0) as C0041657 Label='[C0041657] Count of all mentions of the CUI term:  Loss of consciousness'
	, coalesce(b.C0041755,0) as C0041755 Label='[C0041755] Count of all mentions of the CUI term:  Adverse drug reaction'
	, coalesce(b.C0042109,0) as C0042109 Label='[C0042109] Count of all mentions of the CUI term:  Urticaria'
	, coalesce(b.C0042196,0) as C0042196 Label='[C0042196] Count of all mentions of the CUI term:  Vaccination'
	, coalesce(b.C0042420,0) as C0042420 Label='[C0042420] Count of all mentions of the CUI term:  Vagal reaction'
	, coalesce(b.C0042963,0) as C0042963 Label='[C0042963] Count of all mentions of the CUI term:  Vomiting'
	, coalesce(b.C0043144,0) as C0043144 Label='[C0043144] Count of all mentions of the CUI term:  Wheezing'
	, coalesce(b.C0079603,0) as C0079603 Label='[C0079603] Count of all mentions of the CUI term:  Immunofluorescence'
	, coalesce(b.C0079840,0) as C0079840 Label='[C0079840] Count of all mentions of the CUI term:  Milk allergy'
	, coalesce(b.C0087111,0) as C0087111 Label='[C0087111] Count of all mentions of the CUI term:  Therapeutic procedure'
	, coalesce(b.C0149783,0) as C0149783 Label='[C0149783] Count of all mentions of the CUI term:  Steroid therapy'
	, coalesce(b.C0151602,0) as C0151602 Label='[C0151602] Count of all mentions of the CUI term:  Swelling face'
	, coalesce(b.C0151610,0) as C0151610 Label='[C0151610] Count of all mentions of the CUI term:  Tongue oedema'
	, coalesce(b.C0155877,0) as C0155877 Label='[C0155877] Count of all mentions of the CUI term:  Allergic asthma'
	, coalesce(b.C0162297,0) as C0162297 Label='[C0162297] Count of all mentions of the CUI term:  Respiratory arrest'
	, coalesce(b.C0199176,0) as C0199176 Label='[C0199176] Count of all mentions of the CUI term:  Prophylaxis'
	, coalesce(b.C0199470,0) as C0199470 Label='[C0199470] Count of all mentions of the CUI term:  Mechanical ventilation'
	, coalesce(b.C0199747,0) as C0199747 Label='[C0199747] Count of all mentions of the CUI term:  Allergy test'
	, coalesce(b.C0202202,0) as C0202202 Label='[C0202202] Count of all mentions of the CUI term:  Protein NOS'
	, coalesce(b.C0220787,0) as C0220787 Label='[C0220787] Count of all mentions of the CUI term:  Endotracheal aspiration'
	, coalesce(b.C0220870,0) as C0220870 Label='[C0220870] Count of all mentions of the CUI term:  Lightheadedness'
	, coalesce(b.C0221232,0) as C0221232 Label='[C0221232] Count of all mentions of the CUI term:  Welts'
	, coalesce(b.C0231835,0) as C0231835 Label='[C0231835] Count of all mentions of the CUI term:  Tachypnoea'
	, coalesce(b.C0231848,0) as C0231848 Label='[C0231848] Count of all mentions of the CUI term:  Air hunger'
	, coalesce(b.C0232070,0) as C0232070 Label='[C0232070] Count of all mentions of the CUI term:  Foreign body aspiration'
	, coalesce(b.C0232292,0) as C0232292 Label='[C0232292] Count of all mentions of the CUI term:  Chest tightness'
	, coalesce(b.C0235710,0) as C0235710 Label='[C0235710] Count of all mentions of the CUI term:  Chest discomfort'
	, coalesce(b.C0236068,0) as C0236068 Label='[C0236068] Count of all mentions of the CUI term:  Swelling of tongue'
	, coalesce(b.C0236071,0) as C0236071 Label='[C0236071] Count of all mentions of the CUI term:  Throat tightness'
	, coalesce(b.C0238614,0) as C0238614 Label='[C0238614] Count of all mentions of the CUI term:  Exposure to allergen'
	, coalesce(b.C0240211,0) as C0240211 Label='[C0240211] Count of all mentions of the CUI term:  Lip swelling'
	, coalesce(b.C0242073,0) as C0242073 Label='[C0242073] Count of all mentions of the CUI term:  Pulmonary congestion'
	, coalesce(b.C0242184,0) as C0242184 Label='[C0242184] Count of all mentions of the CUI term:  Hypoxia'
	, coalesce(b.C0340865,0) as C0340865 Label='[C0340865] Count of all mentions of the CUI term:  Anaphylactoid reaction'
	, coalesce(b.C0344183,0) as C0344183 Label='[C0344183] Count of all mentions of the CUI term:  Exercise-induced anaphylaxis'
	, coalesce(b.C0347950,0) as C0347950 Label='[C0347950] Count of all mentions of the CUI term:  Asthmatic attack'
	, coalesce(b.C0349790,0) as C0349790 Label='[C0349790] Count of all mentions of the CUI term:  Exacerbation of asthma'
	, coalesce(b.C0392707,0) as C0392707 Label='[C0392707] Count of all mentions of the CUI term:  Atopy'
	, coalesce(b.C0413119,0) as C0413119 Label='[C0413119] Count of all mentions of the CUI term:  Wasp sting'
	, coalesce(b.C0413120,0) as C0413120 Label='[C0413120] Count of all mentions of the CUI term:  Bee sting'
	, coalesce(b.C0413234,0) as C0413234 Label='[C0413234] Count of all mentions of the CUI term:  Acute allergic reaction'
	, coalesce(b.C0426576,0) as C0426576 Label='[C0426576] Count of all mentions of the CUI term:  Gastrointestinal symptom NOS'
	, coalesce(b.C0442856,0) as C0442856 Label='[C0442856] Count of all mentions of the CUI term:  Hypoperfusion'
	, coalesce(b.C0476207,0) as C0476207 Label='[C0476207] Count of all mentions of the CUI term:  Giddiness'
	, coalesce(b.C0476273,0) as C0476273 Label='[C0476273] Count of all mentions of the CUI term:  Respiratory distress'
	, coalesce(b.C0521481,0) as C0521481 Label='[C0521481] Count of all mentions of the CUI term:  Oedema mucosal'
	, coalesce(b.C0542571,0) as C0542571 Label='[C0542571] Count of all mentions of the CUI term:  Face oedema'
	, coalesce(b.C0543467,0) as C0543467 Label='[C0543467] Count of all mentions of the CUI term:  Surgery'
	, coalesce(b.C0546884,0) as C0546884 Label='[C0546884] Count of all mentions of the CUI term:  Hypovolaemia'
	, coalesce(b.C0549249,0) as C0549249 Label='[C0549249] Count of all mentions of the CUI term:  Depressed level of consciousness'
	, coalesce(b.C0554804,0) as C0554804 Label='[C0554804] Count of all mentions of the CUI term:  Assisted ventilation'
	, coalesce(b.C0559469,0) as C0559469 Label='[C0559469] Count of all mentions of the CUI term:  Egg allergy'
	, coalesce(b.C0559470,0) as C0559470 Label='[C0559470] Count of all mentions of the CUI term:  Peanut allergy'
	, coalesce(b.C0559546,0) as C0559546 Label='[C0559546] Count of all mentions of the CUI term:  Adverse reaction'
	, coalesce(b.C0577620,0) as C0577620 Label='[C0577620] Count of all mentions of the CUI term:  Allergy to nuts'
	, coalesce(b.C0577628,0) as C0577628 Label='[C0577628] Count of all mentions of the CUI term:  Latex allergy'
	, coalesce(b.C0586407,0) as C0586407 Label='[C0586407] Count of all mentions of the CUI term:  Skin symptom'
	, coalesce(b.C0595862,0) as C0595862 Label='[C0595862] Count of all mentions of the CUI term:  Vasodilatation'
	, coalesce(b.C0600228,0) as C0600228 Label='[C0600228] Count of all mentions of the CUI term:  Cardiopulmonary arrest'
	, coalesce(b.C0677500,0) as C0677500 Label='[C0677500] Count of all mentions of the CUI term:  Stinging'
	, coalesce(b.C0685898,0) as C0685898 Label='[C0685898] Count of all mentions of the CUI term:  Anaphylactic shock due to adverse food reaction'
	, coalesce(b.C0700184,0) as C0700184 Label='[C0700184] Count of all mentions of the CUI term:  Throat irritation'
	, coalesce(b.C0700198,0) as C0700198 Label='[C0700198] Count of all mentions of the CUI term:  Aspiration'
	, coalesce(b.C0740651,0) as C0740651 Label='[C0740651] Count of all mentions of the CUI term:  Abdominal symptom'
	, coalesce(b.C0740852,0) as C0740852 Label='[C0740852] Count of all mentions of the CUI term:  Upper airway obstruction'
	, coalesce(b.C0743747,0) as C0743747 Label='[C0743747] Count of all mentions of the CUI term:  Face angioedema'
	, coalesce(b.C0744425,0) as C0744425 Label='[C0744425] Count of all mentions of the CUI term:  Glucocorticoid therapy'
	, coalesce(b.C0850569,0) as C0850569 Label='[C0850569] Count of all mentions of the CUI term:  Allergic rash'
	, coalesce(b.C0854051,0) as C0854051 Label='[C0854051] Count of all mentions of the CUI term:  Allergy to sting'
	, coalesce(b.C0854649,0) as C0854649 Label='[C0854649] Count of all mentions of the CUI term:  Anaphylaxis treatment'
	, coalesce(b.C0856904,0) as C0856904 Label='[C0856904] Count of all mentions of the CUI term:  Fish allergy'
	, coalesce(b.C0857035,0) as C0857035 Label='[C0857035] Count of all mentions of the CUI term:  Acute anaphylaxis'
	, coalesce(b.C0857353,0) as C0857353 Label='[C0857353] Count of all mentions of the CUI term:  Hypotensive'
	, coalesce(b.C0859897,0) as C0859897 Label='[C0859897] Count of all mentions of the CUI term:  Vocal cord dysfunction'
	, coalesce(b.C0877248,0) as C0877248 Label='[C0877248] Count of all mentions of the CUI term:  Adverse event'
	, coalesce(b.C0947961,0) as C0947961 Label='[C0947961] Count of all mentions of the CUI term:  Atopic disorders'
	, coalesce(b.C1145670,0) as C1145670 Label='[C1145670] Count of all mentions of the CUI term:  Respiratory failure'
	, coalesce(b.C1260880,0) as C1260880 Label='[C1260880] Count of all mentions of the CUI term:  Rhinorrhoea'
	, coalesce(b.C1260922,0) as C1260922 Label='[C1260922] Count of all mentions of the CUI term:  Respiration abnormal'
	, coalesce(b.C1261392,0) as C1261392 Label='[C1261392] Count of all mentions of the CUI term:  Insect bite allergy'
	, coalesce(b.C1304200,0) as C1304200 Label='[C1304200] Count of all mentions of the CUI term:  Lip angioedema'
	, coalesce(b.C1306577,0) as C1306577 Label='[C1306577] Count of all mentions of the CUI term:  Death'
	, coalesce(b.C1328414,0) as C1328414 Label='[C1328414] Count of all mentions of the CUI term:  Blood tryptase'
	, coalesce(b.C1504374,0) as C1504374 Label='[C1504374] Count of all mentions of the CUI term:  Antihistamine therapy'
	, coalesce(b.C1527304,0) as C1527304 Label='[C1527304] Count of all mentions of the CUI term:  Allergic reaction NOS'
	, coalesce(b.C1527344,0) as C1527344 Label='[C1527344] Count of all mentions of the CUI term:  Dysphonia'
	, coalesce(b.C1533685,0) as C1533685 Label='[C1533685] Count of all mentions of the CUI term:  Injection'
	, coalesce(b.C1861783,0) as C1861783 Label='[C1861783] Count of all mentions of the CUI term:  Median arcuate ligament syndrome'
	, coalesce(b.C2939065,0) as C2939065 Label='[C2939065] Count of all mentions of the CUI term:  Airway edema'
	, coalesce(b.C4047193,0) as C4047193 Label='[C4047193] Count of all mentions of the CUI term:  epinephrine Auto-Injector'
	, coalesce(b.C4055482,0) as C4055482 Label='[C4055482] Count of all mentions of the CUI term:  Airway compromise'
	, coalesce(b.C4316895,0) as C4316895 Label='[C4316895] Count of all mentions of the CUI term:  Anaphylactic shock'
	, coalesce(b.C4324659,0) as C4324659 Label='[C4324659] Count of all mentions of the CUI term:  Respiratory angioedema'
	, coalesce(b.C4510560,0) as C4510560 Label='[C4510560] Count of all mentions of the CUI term:  Insect sting allergy'
	, coalesce(b.C5208132,0) as C5208132 Label='[C5208132] Count of all mentions of the CUI term:  Respiratory compromise'

/*Include 7 CUI terms with no data*/
	, 0 					 as	C0011992 Label='[C0011992] Count of all mentions of the CUI term:  Diarrhoea'
	, 0 					 as	C0751535 Label='[C0751535] Count of all mentions of the CUI term:  Cardiac syncope'
	, 0 					 as	C1096052 Label='[C1096052] Count of all mentions of the CUI term:  Venomous sting'
	, 0 					 as	C1275515 Label='[C1275515] Count of all mentions of the CUI term:  Venomous bite'
	, 0 					 as	C1504322 Label='[C1504322] Count of all mentions of the CUI term:  Tryptase increased'
	, 0 					 as	C3853540 Label='[C3853540] Count of all mentions of the CUI term:  Aspirin-exacerbated respiratory disease'
	, 0 					 as	C4728126 Label='[C4728126] Count of all mentions of the CUI term:  Gastrointestinal spasm'

From out.TmpB as A Left Join Out.Summary_by_ANA_Event as B on a.MRN=b.MRN
														  and a.Episode_Start_date=b.Episode_Start_date
				   Left Join Out.IRR_A				  as C on a.Studyid=c.Studyid
														  and a.Visit_Start_date=c.Index_Date;
quit;

*************************************************************************************************************
Limiting  note text records/ SM data to clinical measure values:
- = 1 [[N_NOTES_W_SM]Number of distinct notes (INCLUDING secure messages) 
		AND
- = 500 [TOT_NOTES_CHARCOUNT_W_SM]Total character count of all notes (INCLUDING secure messages)
************************************************************************************************************;
*N=2,579;
Proc sql;
Create table Out.DI7_PheNorm_Modeling_file (Label="[DI7_PheNorm_Modeling_file]KPWA's DI7 Anaphylaxis PheNorm Analytic file for Modeling") as
Select *
From Out.TmpC
where N_NOTES_W_SM >=1
  And TOT_NOTES_CHARCOUNT_W_SM >=500
Order by Obs_ID;
quit;

*N_obs N_Docid 
2,579 	2,407 ; 
Proc sql;
Select Count(*) as N_obs
	 , count(distinct substr(Obs_ID,1,11)) as N_Studyids
From Out.DI7_PheNorm_Modeling_file;
quit;

*For Brian's Modeling, drop 7 CUIs where all records have ZEROs;
%Let DropVars = C0011992
				C0751535
				C1096052
				C1275515
				C1504322
				C3853540
				C4728126
;

Proc sql;
Create table Out.DI7_PheNorm_Modeling_file_Brian (Label="[DI7_PheNorm_Modeling_file_Brian]KPWA's DI7 Anaphylaxis PheNorm Analytic file for Modeling") as
Select *
From Out.DI7_PheNorm_Modeling_file (drop = &DropVars.)
Order by Obs_ID;
quit;

*QC;
Proc freq data=Out.DI7_PheNorm_Modeling_file;
tables 
ASSIGNED_PATH
ASSIGNED_PATH_2
ASSIGNED_PATH_3
SEX_F
Race_AFAM
Race_Asian
Race_HP
Race_NatAm
Race_Other
Race_UNKN 
Ethnicity 
ANTIHISTRSD
EPIRSD
HOI_2_0_Gold_Set 
HOI_2_0_Gold_Case
HOI_2_0_sampling_weight 

/norow nocol missing list;
run;

*QC;
Proc freq data=Out.DI7_PheNorm_Modeling_file;
tables ASSIGNED_PATH*HOI_2_0_sampling_weight 
/norow nocol nopercent missing ;
run;

*QC;
Proc means data=Out.DI7_PheNorm_Modeling_file nmiss min mean median max maxdec=1;
var N_NOTES_W_SM
TOT_NOTES_CHARCOUNT_W_SM
SILVER_ANA_DX_N_ENCS
SILVER_ANA_MENTIONS_N 
SILVER_ANA_EPI_MENTIONS_N
SILVER_ANA_CUI_NOTES_N;
run;

Proc means data=Out.DI7_PheNorm_Modeling_file N nmiss min P25 Median P75 P90 P99 max maxdec=0;
var 
C0000729
C0000737
C0001883
C0002792
C0002994
C0003467
C0004096
C0005658
C0006266
C0007203
C0008031
C0009443
C0009676
C0010200
C0011991
C0012833
C0013182
C0013404
C0013604
C0014236
C0014563
C0015376
C0015663
C0016382
C0016462
C0016470
C0018790
C0019825
C0020517
C0020523
C0020649
C0020683
C0021368
C0021564
C0021925
C0021932
C0022885
C0023052
C0024899
C0026821
C0027497
C0027498
C0027627
C0028778
C0030193
C0030252
C0033774
C0035273
C0036974
C0036980
C0037090
C0037296
C0038340
C0038450
C0038999
C0039070
C0039231
C0040533
C0041657
C0041755
C0042109
C0042196
C0042420
C0042963
C0043144
C0079603
C0079840
C0087111
C0149783
C0151602
C0151610
C0155877
C0162297
C0199176
C0199470
C0199747
C0202202
C0220787
C0220870
C0221232
C0231835
C0231848
C0232070
C0232292
C0235710
C0236068
C0236071
C0238614
C0240211
C0242073
C0242184
C0340865
C0344183
C0347950
C0349790
C0392707
C0413119
C0413120
C0413234
C0426576
C0442856
C0476207
C0476273
C0521481
C0542571
C0543467
C0546884
C0549249
C0554804
C0559469
C0559470
C0559546
C0577620
C0577628
C0586407
C0595862
C0600228
C0677500
C0685898
C0700184
C0700198
C0740651
C0740852
C0743747
C0744425
C0850569
C0854051
C0854649
C0856904
C0857035
C0857353
C0859897
C0877248
C0947961
C1145670
C1260880
C1260922
C1261392
C1304200
C1306577
C1328414
C1504374
C1527304
C1527344
C1533685
C1861783
C2939065
C4047193
C4055482
C4316895
C4324659
C4510560
C5208132

C0011992
C0751535
C1096052
C1275515
C1504322
C3853540
C4728126
;
run;

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
*	EXPORT TO CSV FOR BRIAN W's MODELING	;
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
Proc Export datafile=Out.DI7_PheNorm_Modeling_file
     outfile="&MYPATH.\DI7_Assisted_Review\PROGRAMMING\SAS Datasets\05_Silver_Labels_and_Analytic_File_for _BrianW\di7_phenorm_modeling_file_brian.csv"
      dbms=CSV
replace;
run;  

*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
*			MAKE DATA DICTIONARY			;
*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~;
%MakeDataDictionaryForLib(libname    = Out
                         ,optFileNames = ("%upcase(DI7_PheNorm_Modeling_file)")
						 ,optpdfName = Data_Dictionary_Di7_PheNorm_Modeling_file
                         ,optTitle1  = %STR(DI7 - Structured/NLP data features for ANA PheNorm Modeling)
                         ,optTitle2  = %STR(Analytic file for Modeling)
                         ,optTitle3  =
                         ,optOrderBydslabel = N
                         ,optPrintListP1    = Y
                         ,optPrintPathFN    = Y );
