**********************************************************************************************************************************************************************************
Clinical Text for NLP Processing
Limiting to note text records/ SM data with allowable character count and note count (based on Clinical Measures computed)
Require each event to have at least 2 notes (any kind) AND at least 500 characters (any kind).
	• apply the rule 
		? at least one note
		AND
		? at least 500 total chars of text across all notes in the episode
**********************************************************************************************************************************************************************************;

*Signoff;
%include "H:\sasCSpassword.sas";
%include "\\ghcmaster.ghc.org\ghri\warehouse\sas\includes\globals.sas";
%include "\\groups.ghc.org\data\CTRHS\CHS\ITCore\SASCONNECT\RemoteStartRDW.sas";
*Point to the VDW StdVars.sas file;
%include "&GHRIDW_ROOT.\Sasdata\CRN_VDW\lib\StdVars.sas" ;
%make_spm_comment(DI7 Assisted Review-clinical text for NLP processing);
options compress=yes nocenter nofmterr;

%let mypath = \\Groups.ghc.org\Data\CTRHS\Sentinel\Innovation_Center\DI7_Assisted_Review;
Libname cohort "&MYPATH.\PROGRAMMING\SAS Datasets\01_Define_Cohort\09AUG2023" access=readonly;
Libname Notes "&MYPATH.\PROGRAMMING\SAS Datasets\02_Pull_Note_Text" access=readonly;
Libname CTM "&MYPATH.\PROGRAMMING\SAS Datasets\03_Clinical_text_measures" access=readonly;
Libname Out "&MYPATH.\PROGRAMMING\SAS Datasets\04_Clinical_Text_For_NLP";
Libname xwalk "&MYPATH.\PROGRAMMING\SAS Datasets\xwalk" access=readonly;


*Append Birth_date to Crosswalk;
*N=3,951;
/*Proc sql;
Create table Crosswalk as
Select a.*
	, b.Birth_Date Format=Date9.

From Xwalk.Crosswalk as A Inner Join &_VDW_Demographic. as B on a.MRN=b.MRN;
quit;

Proc download data=crosswalk; run;

*NOTE- Run this only once;
*N=3,951;
Data Xwalk.Crosswalk;
Set Crosswalk;
run;*/

Proc contents data=Xwalk.Crosswalk order=varnum;run;

*Max Char count;
%Let Max_CHARCOUNT = 500;

*Max #Notes;
%Let Max_N_NOTES=1;

*N=2,432    2,579;
Proc sql;
Create Table TmpA as
Select *
From CTM.Clinical_Text_measures
where N_NOTES_W_SM >= &Max_N_NOTES.
and TOT_NOTES_CHARCOUNT_W_SM >= &Max_CHARCOUNT.;
quit;


Proc means data=TmpA N NMISS Min Mean Std P25 Median P75 P90 P99 Max Maxdec=1;
var N_CALDAYS_W_NOTES_WO_SM
	N_CALDAYS_W_NOTES_W_SM
	N_NOTES_WO_SM
	N_NOTES_W_SM
	TOT_NOTES_CHARCOUNT_WO_SM
	TOT_NOTES_CHARCOUNT_W_SM;
run;

*Final note text records;
*N=36,810    37,035;
Proc sql;
Create table Out.Note_Text_final as
Select distinct  a.Studyid 	
	, a.CONSUMNO_EVEN_ODD				
	, a.anaphylaxis_Num  	
	, a.episodeid
   	, a.visit_start_date   
	, a.Visit_End_Date 
   	, a.Visit_Days         
	, a.Visit_Year
  	, a.Episode_Start_date 
	, a.Episode_End_Date 
	, a.Episode_Days
    , a.PATH1              
	, a.PATH2            
	, a.PATH3         
	, a.ASSIGN_PATH    
    , a.Age                
	, a.Sex
    , a.White              
	, a.black            
	, a.asian    
    , a.hawaiian           
	, a.natamer          
	, a.other         
	, a.hispanic                                           
   	, a.ChartAvail	
    , a.ANTIHISTRSD   		
	, a.EPIRSD        
  	, a.EXT_ENCOUNTER      
	, a.INT_ENCOUNTER    
	, a.ANA_DX_N_ENCS 
    , b.PAT_ENC_CSN_ID 
	, b.contact_date 
	, b.note_type_code
	, b.note_type
	, b.note_status
	, b.note_entry_datetime
	, b.note_date
	, b.CONTACT_DATE_REAL                                                   				
	, b.note_id
	, b.note_line
	, b.note_text
	, b.count_characters
	, b.enc_abbr
	, b.dept
	, b.location_name

From TmpA as A Inner Join NOTES.note_text_3 as B on a.MRN=b.MRN
											    and a.Episode_Start_date=b.Episode_Start_date
												and b.note_type NOT in ('ED AVS Snapshot','IP AVS Snapshot','MR AVS Snapshot','Patient Instructions');
quit;

*QC;
Proc sql;
Select count(*) as N_Records
, count(distinct Note_id) as N_Note_Ids
, count(distinct studyid) as N_MRN
From Out.Note_Text_Final;
quit;

*Final Secure messages;
*N=41,424     41,527;
Proc sql;
Create table Out.SM_final as
Select distinct a.Studyid	
	, a.CONSUMNO_EVEN_ODD	 			
	, a.anaphylaxis_Num  	
	, a.episodeid
   	, a.visit_start_date   
	, a.Visit_End_Date 
   	, a.Visit_Days         
	, a.Visit_Year
  	, a.Episode_Start_date 
	, a.Episode_End_Date 
	, a.Episode_Days
    , a.PATH1              
	, a.PATH2            
	, a.PATH3         
	, a.ASSIGN_PATH    
    , a.Age                
	, a.Sex
    , a.White              
	, a.black            
	, a.asian    
    , a.hawaiian           
	, a.natamer          
	, a.other         
	, a.hispanic                                           
   	, a.ChartAvail	
    , a.ANTIHISTRSD   		
	, a.EPIRSD        
  	, a.EXT_ENCOUNTER      
	, a.INT_ENCOUNTER    
	, a.ANA_DX_N_ENCS 
	, b.Message_ID
	, b.PARENT_MESSAGE_ID
	, b.PAT_ENC_CSN_ID 
	, b.msg_created_date
	, b.MYC_MSG_TYP_C
	, b.MYC_MSG_TYP
	, b.TOFROM_PAT_C
	, b.TOFROM_PAT
	, b.msg_line
	, b.message_text
	, b.count_characters

From TmpA as A Inner Join NOTES.SM_3 as B on a.MRN=b.MRN
											    and a.Episode_Start_date=b.Episode_Start_date
												and b.MYC_MSG_TYP in ('E-Visit','Patient Medical Advice Request','Shared Note','User Message');
quit;


*QC;
Proc sql;
Select count(*) as N_Records
, count(distinct Message_ID) as N_Message_Ids
, count(distinct studyid) as N_MRN
From Out.SM_Final;
quit;

************************************************************************************************************************************************************
	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC	QC
************************************************************************************************************************************************************;
Proc sql;
Create table Summary_per_NoteId_1 as
Select Studyid
	 , Episode_Start_date 
	 , Episode_End_Date 
	 , note_id
	 , note_type
	 , contact_date
	 , sum(count_characters) as N_Chars

From Out.note_text_final
Where note_type NOT in ('ED AVS Snapshot','IP AVS Snapshot','MR AVS Snapshot','Patient Instructions')
group by Studyid
	  , Episode_Start_date 
	  , Episode_End_Date
	  , note_id
	  , note_type
	  , contact_date
Order by Studyid, contact_date, Note_Id , calculated N_Chars desc;
quit;

Proc sql;
Create table Summary_per_SM_1 as
Select Studyid
	 , Episode_Start_date 
	 , Episode_End_Date 
	 , Message_ID
	 , MYC_MSG_TYP
	 , msg_created_date
	 , sum(count_characters) as N_Chars

From Out.SM_Final
Where MYC_MSG_TYP in ('E-Visit','Patient Medical Advice Request','Shared Note','User Message')
group by Studyid
	  , Episode_Start_date 
	  , Episode_End_Date
	  , Message_ID
	  , MYC_MSG_TYP
	  , msg_created_date
Order by Studyid, msg_created_date, Message_Id , calculated N_Chars desc;
quit;

Proc sql;
Create table Summary_Per_id as
Select Studyid
	 , Episode_Start_date 
	 , Episode_End_Date 
	 , note_id				as Record_id
	 , contact_date			
	 , N_Chars
	 , note_type 			as Record_type format=$50.
	 ,'NoteText'			as Record_type2 format=$8.
From Summary_per_NoteId_1
UNION
Select Studyid
	 , Episode_Start_date 
	 , Episode_End_Date 
	 , Message_ID			as Record_id
	 , msg_created_date		as contact_date	
	 , N_Chars
	 , MYC_MSG_TYP 			as Record_type format=$50.
	 ,'SM'					as Record_type2 format=$8.
From Summary_per_SM_1
Order by Studyid, contact_date;
quit;

Proc sql;
Create table Clinical_Text_measures as
Select a.Studyid
	, c.mrn		
	, a.anaphylaxis_Num  	
	, a.episodeid
   	, a.visit_start_date   
	, a.Visit_End_Date 
   	, a.Visit_Days         
	, a.Visit_Year
  	, a.Episode_Start_date 
	, a.Episode_End_Date 
	, a.Episode_Days
    , a.PATH1              
	, a.PATH2            
	, a.PATH3         
	, a.ASSIGN_PATH    
    , a.Age                
	, a.Sex
    , a.White              
	, a.black            
	, a.asian    
    , a.hawaiian           
	, a.natamer          
	, a.other         
	, a.hispanic                                           
   	, a.ChartAvail	
    , a.ANTIHISTRSD   		
	, a.EPIRSD        
  	, a.EXT_ENCOUNTER      
	, a.INT_ENCOUNTER  
	, a.ANA_DX_N_ENCS 
	 , Count(Distinct Case when a.Studyid=b.Studyid 
							and a.Episode_Start_date=b.Episode_Start_date 
							and b.Record_type2 in ('NoteText') then b.contact_date end)
	 	as N_CALDAYS_W_NOTES_WO_SM
			Label="[N_CALDAYS_W_NOTES_WO_SM]Number of distinct calendar days with any clinical notes (NOT including secure messages)"
			format=comma8.
	 , Count(Distinct Case when a.Studyid=b.Studyid 
							and a.Episode_Start_date=b.Episode_Start_date 
							and b.Record_type2 in ('NoteText','SM') then b.contact_date end)
	 	as N_CALDAYS_W_NOTES_W_SM
			Label="[N_CALDAYS_W_NOTES_W_SM]Number of distinct calendar days with any clinical notes (INCLUDING secure messages)"
			format=comma8.
	 , Count(Distinct Case when a.Studyid=b.Studyid
							and a.Episode_Start_date=b.Episode_Start_date 
							and b.Record_type2 in ('NoteText') then b.Record_Id end)
	 	as N_NOTES_WO_SM
			Label="[N_NOTES_WO_SM]Number of distinct notes (NOT including secure messages)"
			format=comma8.
	 , Count(Distinct Case when a.Studyid=b.Studyid
							and a.Episode_Start_date=b.Episode_Start_date 
							and b.Record_type2 in ('NoteText','SM') then b.Record_Id  end)
	 	as N_NOTES_W_SM
			Label="[N_NOTES_W_SM]Number of distinct notes (INCLUDING secure messages)"
			format=comma8.
	 , Sum(Case when a.Studyid=b.Studyid
				 and a.Episode_Start_date=b.Episode_Start_date 
				 and b.Record_type2 in ('NoteText') then b.N_Chars else 0 end)
	 	as TOT_NOTES_CHARCOUNT_WO_SM
			Label="[TOT_NOTES_CHARCOUNT_WO_SM]Total character count of all notes (NOT including secure messages)"
			format=comma8.
	 , Sum(Case when a.Studyid=b.Studyid 
				 and a.Episode_Start_date=b.Episode_Start_date 
				 and b.Record_type2 in ('NoteText','SM') then b.N_Chars else 0  end)
	 	as TOT_NOTES_CHARCOUNT_W_SM
			Label="[TOT_NOTES_CHARCOUNT_W_SM]Total character count of all notes (INCLUDING secure messages)"
			format=comma8.

From Cohort.Anaphylaxis_presumptive_final as A Inner Join Summary_Per_id as B on a.Studyid=b.Studyid 
																				and a.Episode_Start_date=b.Episode_Start_date
											   Inner Join xwalk.Crosswalk as C on a.Studyid=c.Studyid
Group by a.Studyid
	, c.mrn		
	, a.anaphylaxis_Num  	
	, a.episodeid
   	, a.visit_start_date   
	, a.Visit_End_Date 
   	, a.Visit_Days         
	, a.Visit_Year
  	, a.Episode_Start_date 
	, a.Episode_End_Date 
	, a.Episode_Days
    , a.PATH1              
	, a.PATH2            
	, a.PATH3         
	, a.ASSIGN_PATH    
    , a.Age                
	, a.Sex
    , a.White              
	, a.black            
	, a.asian    
    , a.hawaiian           
	, a.natamer          
	, a.other         
	, a.hispanic                                           
   	, a.ChartAvail	
    , a.ANTIHISTRSD   		
	, a.EPIRSD        
  	, a.EXT_ENCOUNTER      
	, a.INT_ENCOUNTER  
	, a.ANA_DX_N_ENCS     ;
quit;


Proc download data=Clinical_Text_measures;
run;

Proc means data=Clinical_Text_measures N NMISS Min P25 Median P75 P90 P99 Max Maxdec=0;
var N_CALDAYS_W_NOTES_WO_SM
	N_CALDAYS_W_NOTES_W_SM
	N_NOTES_WO_SM
	N_NOTES_W_SM
	TOT_NOTES_CHARCOUNT_WO_SM
	TOT_NOTES_CHARCOUNT_W_SM;
run;

*N_Obs    N_Studyids 
 2,432 	    2,274 2+ notes & 500+ Chars
 2,579      2,407 1+ notes & 500+ Chars                                                                                  ; 
Proc sql;
Select Count(*) as N_Obs
, count(distinct Studyid) as N_Studyids
From Clinical_Text_measures;
quit;


*Update 9/11/2023 - How many individuals had exactly 1 note with 500+ characters text;
*N_Obs 		N_Studyids 	N_w_0_Note 	N_w_1_Note_GE500Chars events_w_1_Note_GE500Chars N_w_GE1_Note_GE500Chars Events_w_GE1_Note_GE500Chars N_w_GE2Notes_GE500Chars Events_w_GE2Notes_GE500Chars 
 4,297 		  3,951 		1,552 		133 						135 						2,407 				2,579 						2,274 					2,432 ; 
Proc sql;
Select Count(*) as N_Obs
, count(distinct Studyid) as N_Studyids
, Count(distinct Case when N_NOTES_W_SM =0  then Studyid end)
	as N_w_0_Note
, Count(distinct Case when N_NOTES_W_SM =1 
						and TOT_NOTES_CHARCOUNT_W_SM >=500 
						and studyid not in (Select distinct Studyid from CTM.Clinical_Text_measures where N_NOTES_W_SM >=2 and TOT_NOTES_CHARCOUNT_W_SM >=500) then Studyid end)
	as N_w_1_Note_GE500Chars
, sum(Case when N_NOTES_W_SM =1 
		and TOT_NOTES_CHARCOUNT_W_SM >=500
		and studyid not in (Select distinct Studyid from CTM.Clinical_Text_measures where N_NOTES_W_SM >=2 and TOT_NOTES_CHARCOUNT_W_SM >=500)then 1 else 0 end)
	as Events_w_1_Note_GE500Chars
, Count(distinct Case when N_NOTES_W_SM >=1 and TOT_NOTES_CHARCOUNT_W_SM >=500 then Studyid end)
	as N_w_GE1_Note_GE500Chars
, sum(Case when N_NOTES_W_SM >=1 and TOT_NOTES_CHARCOUNT_W_SM >=500 then 1 else 0 end)
	as Events_w_GE1_Note_GE500Chars
, Count(distinct Case when N_NOTES_W_SM >=2 and TOT_NOTES_CHARCOUNT_W_SM >=500 then Studyid end)
	as N_w_GE2Notes_GE500Chars
, Sum(Case when N_NOTES_W_SM >=2 and TOT_NOTES_CHARCOUNT_W_SM >=500 then 1 else 0 end)
	as Events_w_GE2Notes_GE500Chars
From CTM.Clinical_Text_measures;
quit;


Proc freq data=CTM.Clinical_Text_measures;
tables N_NOTES_W_SM/norow nocol missing list;
run;
