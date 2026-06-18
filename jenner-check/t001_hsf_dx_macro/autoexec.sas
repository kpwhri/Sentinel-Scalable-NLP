options obs=100;

/* Mock clinical encounter data — shapes match what HSF_DX reads:
   cohort(PATID), Dx(PATID,ADATE,ENCTYPE,DX,ORIGDX), code list(DIAGCD,DIAGDESC) */
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
  informat ADATE date9.;
  format ADATE date9.;
  input PATID $ ADATE ENCTYPE $ DX $ ORIGDX $;
  datalines;
P001 05APR2020 AV U07.1 U071
P001 07APR2020 AV J12.89 J1289
P002 10APR2020 IP U07.1 U071
P002 11APR2020 IP R05 R05
P003 15APR2020 AV J44.9 J449
P004 20MAY2020 AV U07.1 U071
P004 22MAY2020 AV R05 R05
P005 01JUN2020 AV J12.89 J1289
P006 02JUN2020 AV R05 R05
;
run;

data work.DiagCd;
  length DIAGCD $8 DIAGDESC $40;
  input DIAGCD $ DIAGDESC $40.;
  datalines;
U071 COVID-19
J1289 Viral pneumonia other
R05 Cough
J449 COPD unspecified
;
run;

%let EXCELOUT = .;

