
# Running PheNorm

The SAS code in this directory not only provides an implementation of PheNorm with Anaphylaxis, but also a template for applying PheNorm to novel conditions. To do so will mostly involve changes to `01_define_cohort.sas`.

Here are the steps for running:

1.	Cohort identification (`01_define_cohort.sas`)
  a.	Identify cohort based on project specifications: --- e.g.
    i.	study period of interest (start date and end date)
    ii.	diagnosis and Procedure code list
    iii.	age inclusion
    iv.	enrollment requirements
    v.	care setting (IP, ED, AV, UC, etc.)
    vi.	other specs of interest
  b.	The output file should include:
    i.	StudyID
    ii.	EpisodeID
    iii.	Visit_Start_Date
    iv.	Visit_End_Date
    v.	Episode_Start_Date
    vi.	Episode_End_Date
    vii.	Episode_Days
    viii.	Demographic (age, gender, race, etc.)
    ix.	Other variables of interest
2.	Pull note text and secure messages (`02_Pull_Note_Text_and_SM_Records.sas`)
  a.	Use the output file from #1 to extract note text and secure messages
between episode start date and episode end date
3.	Operationalize clinical text measures (`03_Clinical_Text_Measures.sas`)
  a.	Use the extracted notes and secure messages from #2
  b.	Count characters per note_id 
  c.	Apply inclusion/exclusion criterion on note types and message types
4.	Clinical text for NLP (`04_Clinical_Text_For_NLP.sas`)
  a.	Use the computed clinical measures from #3
  b.	Apply criteria for each episode on the number of notes and number of characters 
to include for NLP processing
  c. Send the output files from this step to the Python program described in the [`mml_utils` documentation](https://github.com/kpwhri/mml_utils/tree/master/examples/phenorm)
