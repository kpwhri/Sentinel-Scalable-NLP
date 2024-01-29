*Pull Note text records for encounters between Episode_Start_Date and Episode_End_Date;
*Signoff;
%include "H:\sasCSpassword.sas";
%include "\\ghcmaster.ghc.org\ghri\warehouse\sas\includes\globals.sas";
%include "\\groups.ghc.org\data\CTRHS\CHS\ITCore\SASCONNECT\RemoteStartRDW.sas";
*Point to the VDW StdVars.sas file;
%include "&GHRIDW_ROOT.\Sasdata\CRN_VDW\lib\StdVars.sas" ;
%make_spm_comment(DI7 Assisted Review-Pull note text);
options compress=yes nocenter nofmterr;

%let mypath = \\Groups.ghc.org\Data\CTRHS\Sentinel\Innovation_Center\DI7_Assisted_Review;
Libname out "&MYPATH.\PROGRAMMING\SAS Datasets\02_Pull_Note_Text";


*******************************************
	1. Extract Note Text records
******************************************;
*N=41,884   2,383,784;
proc sql;
connect to &clarity_odbc_conn. ;
create table out.note_text_1 as
select * from CONNECTION to CLARITY
(Select distinct nlp.Mrn
		, nlp.Studyid
		, nlp.CONSUMNO_EVEN_ODD	
		, nlp.anaphylaxis_Num  	
		, nlp.episodeid
   		, nlp.visit_start_date   
		, nlp.Visit_End_Date 
   		, nlp.Visit_Days         
		, nlp.Visit_Year
  		, nlp.Episode_Start_date 
		, nlp.Episode_End_Date 
		, nlp.Episode_Days
    	, nlp.PATH1              
		, nlp.PATH2            
		, nlp.PATH3         
		, nlp.ASSIGN_PATH    
      	, nlp.Age                
		, nlp.Sex
      	, nlp.White              
		, nlp.black            
		, nlp.asian    
      	, nlp.hawaiian           
		, nlp.natamer          
		, nlp.other         
		, nlp.hispanic                                           
   		, nlp.ChartAvail	
      	, nlp.ANTIHISTRSD   		
		, nlp.EPIRSD        
  		, nlp.EXT_ENCOUNTER      
		, nlp.INT_ENCOUNTER    
		, nlp.ANA_DX_N_ENCS 
	    , pat_enc.PAT_ENC_CSN_ID 
		, Pat_Enc.contact_date 
	    , EncNotes.NoteTypeCode                                                         as note_type_code
	    , EncNotes.NoteType                                                             as note_type
	    , ZC_NOTE_STATUS.ABBR                                                           as note_status
	    , coalesce(Note_enc_info.UPD_AUT_LOCAL_DTTM, Note_enc_info.ENT_INST_LOCAL_DTTM) as note_entry_datetime
	    , EncNotes.NoteEntryDate                                                        as note_date
	    , EncNotes.CONTACT_DATE_REAL                                                   				
	    , EncNotes.NoteId                                                               as note_id
	    , EncNotes.NoteLine                                                             as note_line
	    , EncNotes.NoteText                                                             as note_text
	    , ZC_DISP_ENC_TYPE.abbr                                                         as enc_abbr
	    , Clarity_Dep.Dept_Abbreviation                                                 as dept
	    , clarity_loc.loc_name                                                          as location_name
From  [GHC_Lookup].[CS\G067730].[Anaphylaxis_presumptive_final] as nlp 
							INNER JOIN [GHC_LOOKUP].[dbo].[CHSID_CONSUMNO]	on nlp.mrn=CHSID_CONSUMNO.CHSID
							INNER JOIN [CLARITY].[dbo].[IDENTITY_ID]  		on IDENTITY_ID.identity_id =CHSID_CONSUMNO.CONSUMNO 
																			and IDENTITY_ID.identity_type_id=50190
							INNER JOIN [CLARITY].[dbo].[PATIENT]			on IDENTITY_ID.pat_id = PATIENT.pat_id 
																			and IDENTITY_ID.identity_type_id=50190
							INNER JOIN [CLARITY].[dbo].[pat_enc]			on patient.pat_id = Pat_enc.Pat_id
																		  /*and Cast(nlp.Episode_Start_date as DATE)<= Cast(Pat_Enc.contact_date as Date) 
																			and Cast(Pat_Enc.contact_date as Date) <= Cast(nlp.Episode_End_Date as Date)*/
							LEFT  JOIN [CLARITY].[dbo].[NOTE_ENC_INFO]		on pat_enc.pat_enc_csn_id = Note_enc_info.CONTACT_SERIAL_NUM
							INNER JOIN [CLARITY].[dbo].[ZC_DISP_ENC_TYPE]	on pat_enc.enc_type_c = ZC_DISP_ENC_TYPE.DISP_ENC_TYPE_C
							LEFT  JOIN [CLARITY].[dbo].[clarity_dep]		on pat_enc.department_id = clarity_dep.department_id
							LEFT  JOIN [CLARITY].[dbo].[clarity_loc]		on clarity_dep.rev_loc_id = clarity_loc.loc_id
																			AND clarity_dep.serv_area_id = clarity_loc.serv_area_id
							LEFT  JOIN [CLARITY].[dbo].[ZC_NOTE_STATUS]		on NOTE_ENC_INFO.NOTE_STATUS_C = ZC_NOTE_STATUS.NOTE_STATUS_C
							INNER JOIN (Select  HNO_INFO.Pat_id
											  , HNO_INFO.pat_enc_csn_id    as ENC_ID
											  , HNO_NOTE_TEXT.CONTACT_DATE_REAL
											  , HNO_INFO.IP_NOTE_TYPE_C    as NoteTypeCode
											  , ZC_NOTE_TYPE_IP.Name       as NoteType
											  , HNO_NOTE_TEXT.CONTACT_DATE as NoteEntryDate
											  , HNO_NOTE_TEXT.NOTE_ID      as NoteId
											  , HNO_NOTE_TEXT.LINE         as NoteLine
											  , HNO_NOTE_TEXT.NOTE_TEXT    as NoteText
											  , Row_number() Over (Partition by HNO_INFO.pat_enc_csn_id
																			, HNO_NOTE_TEXT.NOTE_ID
																			, HNO_NOTE_TEXT.LINE
																	order by HNO_NOTE_TEXT.CONTACT_DATE_REAL desc
																						) as NoteRow
									   from  [CLARITY].[dbo].[HNO_INFO] INNER JOIN [CLARITY].[dbo].[HNO_NOTE_TEXT]		ON hno_info.NOTE_ID = HNO_NOTE_TEXT.NOTE_ID
																		LEFT  JOIN [CLARITY].[dbo].[ZC_NOTE_TYPE_IP]	ON HNO_INFO.IP_NOTE_TYPE_C = ZC_NOTE_TYPE_IP.TYPE_IP_C
																		INNER JOIN [CLARITY].[dbo].[IDENTITY_ID]		ON HNO_INFO.pat_id=IDENTITY_ID.pat_id 
																														and IDENTITY_ID.identity_type_id=50190
																		INNER JOIN [GHC_LOOKUP].[dbo].[CHSID_CONSUMNO] 	ON IDENTITY_ID.identity_id =CHSID_CONSUMNO.CONSUMNO 
																														and IDENTITY_ID.identity_type_id=50190
																		Inner JOin (Select distinct MRN
																					From [GHC_Lookup].[CS\G067730].[Anaphylaxis_presumptive_final])
																						 as deno ON CHSID_CONSUMNO.CHSID=deno.MRN
										) as EncNotes																	ON Pat_Enc.pat_id = EncNotes.PAT_ID
																														and Pat_Enc.pat_enc_Csn_id = EncNotes.ENC_ID
																														and EncNotes.NoteRow = 1
Order by nlp.mrn
       , pat_enc.PAT_ENC_CSN_ID
       , EncNotes.NoteId
       , EncNotes.NoteLine
		);
		DISCONNECT from CLARITY;
quit;

*Dates manipulation;
Data out.note_text_2 (drop= dt1 dt2 dt3 dt4 dt5 dt6);
Set out.note_text_1 (rename =(Episode_Start_date=dt1 contact_date=dt2 Episode_End_Date=dt3 note_date=dt4 visit_start_date=dt5 visit_end_date=dt6));
format Episode_Start_date contact_date Episode_End_Date note_date visit_start_date visit_end_date date9.;
Episode_Start_date=datepart(dt1);
contact_date=datepart(dt2);
Episode_End_Date=datepart(dt3);
note_date=datepart(dt4);
visit_start_date=datepart(dt5);
visit_end_date=datepart(dt6);
run;

*Limiting to Episode start and end dates;
*Counting character lengths;
*N=41,884;
Data out.note_text_3;
Set out.note_text_2;
where Episode_Start_date<= contact_date<=Episode_End_Date;
count_characters = length(note_text);
run;

*QC - 2,447(62%) of 3,951 w/ 1+ note text records;
*N_pts   Mindt     Maxdt 
2447   01JAN2006 24APR2023; 
Proc sql;
Select Count(distinct MRN) as N_pts
, min(datepart(contact_date)) as Mindt format=date9.
, max(datepart(contact_date)) as Maxdt format=date9.
, min(datepart(note_date)-datepart(contact_date)) as Min
, max(datepart(note_date)-datepart(contact_date)) as Max
From out.note_text_3;
quit;

*QC;
Proc sql;
Select note_type
	, count(distinct note_id) as N_noteIds
	, count(distinct MRN) 	 as N_Mrns
From out.note_text_3
group by note_type;
quit;
 
Proc freq data=out.note_text_3;
tables note_type/norow nocol missing list;
run;
	
*******************************************
	2. Extract Secure Messages
******************************************;

*N= 52,537   7,405,132;
proc sql;
connect to &clarity_odbc_conn. ;
create table out.SM_1 as select * from CONNECTION to CLARITY
(
 SELECT   distinct nlp.Mrn
		, nlp.Studyid
 		, nlp.CONSUMNO_EVEN_ODD	
		, nlp.anaphylaxis_Num  	
		, nlp.episodeid
   		, nlp.visit_start_date   
		, nlp.Visit_End_Date 
   		, nlp.Visit_Days         
		, nlp.Visit_Year
  		, nlp.Episode_Start_date 
		, nlp.Episode_End_Date 
		, nlp.Episode_Days
    	, nlp.PATH1              
		, nlp.PATH2            
		, nlp.PATH3         
		, nlp.ASSIGN_PATH    
      	, nlp.Age                
		, nlp.Sex
      	, nlp.White              
		, nlp.black            
		, nlp.asian    
      	, nlp.hawaiian           
		, nlp.natamer          
		, nlp.other         
		, nlp.hispanic                                           
   		, nlp.ChartAvail	
      	, nlp.ANTIHISTRSD   		
		, nlp.EPIRSD        
  		, nlp.EXT_ENCOUNTER      
		, nlp.INT_ENCOUNTER    
		, nlp.ANA_DX_N_ENCS 
		, MYC_MESG.Message_ID
		, MYC_MESG.PARENT_MESSAGE_ID
		, MYC_MESG.PAT_ENC_CSN_ID 
		, MYC_MESG.Created_Time     as msg_created_date
		, MYC_MESG.MYC_MSG_TYP_C
		, ZC_MYC_MSG_TYP.NAME		as MYC_MSG_TYP
		, MYC_MESG.TOFROM_PAT_C
		, ZC_TOFROM_PAT.NAME		as TOFROM_PAT
		, MSG_TXT.LINE 				as msg_line
		, MSG_TXT.MSG_TXT           as message_text

From [GHC_Lookup].[CS\G067730].[Anaphylaxis_presumptive_final] as nlp   INNER JOIN [GHC_LOOKUP].[dbo].[CHSID_CONSUMNO] 	ON nlp.mrn=CHSID_CONSUMNO.CHSID
				 														INNER JOIN [CLARITY].[dbo].[IDENTITY_ID]  	 	ON IDENTITY_ID.identity_id =CHSID_CONSUMNO.CONSUMNO 
																													   and IDENTITY_ID.identity_type_id=50190
																		INNER JOIN [CLARITY].[dbo].[PATIENT]			ON IDENTITY_ID.pat_id = PATIENT.pat_id 
																													   and IDENTITY_ID.identity_type_id=50190
														                INNER JOIN [CLARITY].[dbo].[MYC_MESG]		  	ON Patient.pat_id = MYC_MESG.pat_id
																		  											 /*and Cast(MYC_MESG.created_time as Date)>=Cast(nlp.Episode_Start_date as Date)
																													   and Cast(MYC_MESG.created_time as Date)<= Cast(nlp.Episode_End_Date as Date)*/
																		LEFT  Join [CLARITY].[dbo].[ZC_MYC_MSG_TYP]		ON MYC_MESG.MYC_MSG_TYP_C =ZC_MYC_MSG_TYP.MYC_MSG_TYP_C
																		LEFT  JOIN [CLARITY].[dbo].[ZC_TOFROM_PAT]		ON MYC_MESG.TOFROM_PAT_C =ZC_TOFROM_PAT.TOFROM_PAT_C
																		INNER JOIN [CLARITY].[dbo].[MSG_TXT]			ON MYC_MESG.MESSAGE_ID=MSG_TXT.MESSAGE_ID
Order by  nlp.Mrn
		, nlp.Studyid 			
		, nlp.anaphylaxis_Num  	
		, nlp.episodeid
   		, nlp.visit_start_date   
		, nlp.Visit_End_Date 
   		, nlp.Visit_Days         
		, nlp.Visit_Year
  		, nlp.Episode_Start_date 
		, nlp.Episode_End_Date 
		, MYC_MESG.PAT_ENC_CSN_ID
		, MYC_MESG.Message_ID
		, MSG_TXT.LINE
		, MYC_MESG.Created_Time
);
DISCONNECT from CLARITY;
quit;

*Dates manipulation;
Data out.SM_2 (drop= dt1 dt2 dt3  dt4 dt5);
Set out.SM_1 (rename =(Episode_Start_date=dt1 msg_created_date=dt2 Episode_End_Date=dt3 visit_start_date=dt4 visit_end_date=dt5));
format Episode_Start_date msg_created_date Episode_End_Date  visit_start_date visit_end_date date9.;
Episode_Start_date=datepart(dt1);
msg_created_date=datepart(dt2);
Episode_End_Date=datepart(dt3);
visit_start_date=datepart(dt4);
visit_end_date=datepart(dt5);
run;

*Limiting to Episode start and end dates;
*Counting character lengths;
*N=52,537;
Data out.SM_3;
Set out.SM_2;
where Episode_Start_date<= msg_created_date<=Episode_End_Date;
count_characters = length(message_text);
run;

*N_pts  	Mindt 		Maxdt 
 744 	  01JAN2006   02APR2020; 
Proc sql;
Select Count(distinct MRN) as N_pts
, min(datepart(msg_created_date)) as Mindt format=date9.
, max(datepart(msg_created_date)) as Maxdt format=date9.
From out.SM_3;
quit;


Proc freq data=out.SM_3;
tables MYC_MSG_TYP/norow nocol missing list;
run;
	
