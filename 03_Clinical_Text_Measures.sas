*************************************************************************************************************************************************************************************************
Objective: Operationalize Clinical Text Measures (Silver labels)

	1.a. Number of distinct calendar days with any clinical notes (NOT including secure messages)
	1.b. Number of distinct calendar days with any clinical notes (INCLUDING secure messages)
	2.a. Number of distinct notes (NOT including secure messages)
	2.b. Number of distinct notes (INCLUDING secure messages)
	3.a. Total character count of all notes (NOT including secure messages)
	3.b. Total character count of all notes (INCLUDING secure messages)

************************************************************************************************************************************************************************************************;

*Signoff;
%include "H:\sasCSpassword.sas";
%include "\\ghcmaster.ghc.org\ghri\warehouse\sas\includes\globals.sas";
%include "\\groups.ghc.org\data\CTRHS\CHS\ITCore\SASCONNECT\RemoteStartRDW.sas";
*Point to the VDW StdVars.sas file;
%include "&GHRIDW_ROOT.\Sasdata\CRN_VDW\lib\StdVars.sas" ;
%make_spm_comment(DI7 Assisted Review-clinical text measures);
options compress=yes nocenter nofmterr;

%let mypath = \\Groups.ghc.org\Data\CTRHS\Sentinel\Innovation_Center\DI7_Assisted_Review;
Libname cohort "&MYPATH.\PROGRAMMING\SAS Datasets\01_Define_Cohort\09AUG2023" access=readonly;
Libname Notes "&MYPATH.\PROGRAMMING\SAS Datasets\02_Pull_Note_Text";
Libname Out "&MYPATH.\PROGRAMMING\SAS Datasets\03_Clinical_text_measures";
Libname xwalk "&MYPATH.\PROGRAMMING\SAS Datasets\xwalk";

*Count characters per Note_id;
*Exclude certain note types;
*N=24,933;
Proc sql;
Create table Out.Summary_per_NoteId_1 as
Select Studyid
	 , mrn
	 , Episode_Start_date 
	 , Episode_End_Date 
	 , note_id
	 , note_type
	 , contact_date
	 , sum(count_characters) as N_Chars

From Notes.note_text_3
Where note_type NOT in ('ED AVS Snapshot','IP AVS Snapshot','MR AVS Snapshot','Patient Instructions')
group by Studyid
	  , mrn
	  , Episode_Start_date 
	  , Episode_End_Date
	  , note_id
	  , note_type
	  , contact_date
Order by Studyid, contact_date, Note_Id , calculated N_Chars desc;
quit;


*QC - 0 dups;
Proc sort data=Out.Summary_per_NoteId_1  nodupkey out=nodups dupout=dups;
by studyid Episode_Start_date note_id;
run;

*QC;
Proc freq data=Out.Summary_per_NoteId_1;
tables note_type/norow nocol nopercent missing list;
run;

*Include only certain message types;
*N=1,822;
Proc sql;
Create table Out.Summary_per_SM_1 as
Select Studyid
	 , mrn
	 , Episode_Start_date 
	 , Episode_End_Date 
	 , Message_ID
	 , MYC_MSG_TYP
	 , msg_created_date
	 , sum(count_characters) as N_Chars

From Notes.SM_3
Where MYC_MSG_TYP in ('E-Visit','Patient Medical Advice Request','Shared Note','User Message')
group by Studyid
	  , mrn
	  , Episode_Start_date 
	  , Episode_End_Date
	  , Message_ID
	  , MYC_MSG_TYP
	  , msg_created_date
Order by Studyid, msg_created_date, Message_Id , calculated N_Chars desc;
quit;

*QC - 0 dups;
Proc sort data=Out.Summary_per_SM_1  nodupkey out=nodups dupout=dups;
by studyid Episode_Start_date Message_ID;
run;

*QC;
Proc freq data=Out.Summary_per_SM_1;
tables MYC_MSG_TYP/norow nocol nopercent missing list;
run;

*Setting Note text + SMs;
*N=26,755;
Proc sql;
Create table Out.Summary_Per_id as
Select Studyid
	 , mrn
	 , Episode_Start_date 
	 , Episode_End_Date 
	 , note_id				as Record_id
	 , contact_date			
	 , N_Chars
	 , note_type 			as Record_type format=$50.
	 ,'NoteText'			as Record_type2 format=$8.
From Out.Summary_per_NoteId_1
UNION
Select Studyid
	 , mrn
	 , Episode_Start_date 
	 , Episode_End_Date 
	 , Message_ID			as Record_id
	 , msg_created_date		as contact_date	
	 , N_Chars
	 , MYC_MSG_TYP 			as Record_type format=$50.
	 ,'SM'					as Record_type2 format=$8.
From Out.Summary_per_SM_1
Order by Studyid, contact_date;
quit;

*N=4,297 - OK;
Proc sql;
Create table Out.Clinical_Text_measures as
Select a.Studyid
	, c.mrn	
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

From Cohort.Anaphylaxis_presumptive_final as A Left Join Out.Summary_Per_id as B on a.Studyid=b.Studyid 
																				and a.Episode_Start_date=b.Episode_Start_date
											   Inner Join xwalk.Crosswalk as C on a.Studyid=c.Studyid
Group by a.Studyid
	, c.mrn	
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
	, a.ANA_DX_N_ENCS     ;
quit;

*QC;
Proc means data=Out.Clinical_Text_measures N NMISS Min Mean Std P25 Median P75 P90 P99 Maxdec=1;
var N_CALDAYS_W_NOTES_WO_SM
	N_CALDAYS_W_NOTES_W_SM
	N_NOTES_WO_SM
	N_NOTES_W_SM
	TOT_NOTES_CHARCOUNT_WO_SM
	TOT_NOTES_CHARCOUNT_W_SM;
run;

*#Number of notes/sms and #pts;
Proc freq data=Out.Clinical_Text_measures;
Tables N_CALDAYS_W_NOTES_WO_SM
	N_CALDAYS_W_NOTES_W_SM
	N_NOTES_WO_SM
	N_NOTES_W_SM
	TOT_NOTES_CHARCOUNT_WO_SM
	TOT_NOTES_CHARCOUNT_W_SM;
run;


