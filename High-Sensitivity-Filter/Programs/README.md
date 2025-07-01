
# Running PheNorm

The SAS code in this directory not only provides an implementation of PheNorm with Anaphylaxis, but also a template for applying PheNorm to novel conditions. To do so will mostly involve changes to `01_define_cohort.sas`.

Here are the steps for running:

1.	Cohort identification (`01_define_cohort.sas`)
    1.	Identify cohort based on project specifications: --- e.g.
        1.	study period of interest (start date and end date)
        2.	diagnosis and Procedure code list
        3.	age inclusion
        4.	enrollment requirements
        5.	care setting (IP, ED, AV, UC, etc.)
        6.	other specs of interest
    2.	The output file should include:
        1.	StudyID
        2.	EpisodeID
        3.	Visit_Start_Date
        4.	Visit_End_Date
        5.	Episode_Start_Date
        6.	Episode_End_Date
        7.	Episode_Days
        8.	Demographic (age, gender, race, etc.)
        9.	Other variables of interest
2.	Pull note text and secure messages (`02_Pull_Note_Text_and_SM_Records.sas`)
    1.	Use the output file from #1 to extract note text and secure messages
between episode start date and episode end date
3.	Operationalize clinical text measures (`03_Clinical_Text_Measures.sas`)
    1.	Use the extracted notes and secure messages from #2
    2.	Count characters per note_id 
    3.	Apply inclusion/exclusion criterion on note types and message types
4.	Clinical text for NLP (`04_Clinical_Text_For_NLP.sas`)
    1.	Use the computed clinical measures from #3
    2.	Apply criteria for each episode on the number of notes and number of characters 
to include for NLP processing
    3. Send the output files from this step to the Python program described in the [`mml_utils` documentation](https://github.com/kpwhri/mml_utils/tree/master/examples/phenorm)
