options obs=100;
data work.MyCohort;
  input PATID $4.;
  datalines;
P001
P002
P003
P004
P005
P006
;
run;

data work.DxData;
  length PATID $4 ENCTYPE $2 DX $8 ORIGDX $8;
  informat ADATE date9.; format ADATE date9.;
  input PATID $ ADATE ENCTYPE $ DX $ ORIGDX $;
  datalines;
P001 05APR2020 AV U07.1 U071
P002 10APR2020 IP U07.1 U071
P004 20MAY2020 AV U07.1 U071
P003 15APR2020 AV J44.9 J449
P005 01JUN2020 AV J12.89 J1289
;
run;

data work.PxData;
  length PATID $4 ENCTYPE $2 Px $8;
  informat ADATE date9.; format ADATE date9.;
  input PATID $ ADATE ENCTYPE $ Px $;
  datalines;
P001 06APR2020 AV 94640
P002 11APR2020 IP 94002
P003 16APR2020 AV 71046
P004 21MAY2020 AV 94640
P005 02JUN2020 AV 71046
P006 03JUN2020 AV 94640
;
run;

data work.PxCd;
  length Px $8 Px_desc $40;
  input Px $ Px_desc $40.;
  datalines;
94640 Inhalation treatment
94002 Ventilation mgmt initial
71046 Chest x-ray 2 views
;
run;

%let EXCELOUT = .;
