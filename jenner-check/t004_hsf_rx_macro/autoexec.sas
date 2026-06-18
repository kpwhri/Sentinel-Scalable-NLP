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

/* Dx file needs ENCOUNTERID for the utilization join (Rx macro, PATID model) */
data work.DxData;
  length PATID $4 ENCOUNTERID $6 ENCTYPE $2 DX $8 ORIGDX $8;
  informat ADATE date9.; format ADATE date9.;
  input PATID $ ENCOUNTERID $ ADATE ENCTYPE $ DX $ ORIGDX $;
  datalines;
P001 E1001 05APR2020 AV U07.1 U071
P002 E1002 10APR2020 IP U07.1 U071
P004 E1004 20MAY2020 AV U07.1 U071
P003 E1003 15APR2020 AV J44.9 J449
P005 E1005 01JUN2020 AV J12.89 J1289
;
run;

/* Utilization records: PATID, ENCOUNTERID, Adate, ENCTYPE, DDATE */
data work.UtilData;
  length PATID $4 ENCOUNTERID $6 ENCTYPE $2;
  informat Adate date9. DDATE date9.; format Adate date9. DDATE date9.;
  input PATID $ ENCOUNTERID $ Adate ENCTYPE $ DDATE;
  datalines;
P001 E1001 05APR2020 AV 06APR2020
P002 E1002 10APR2020 IP 11APR2020
P004 E1004 20MAY2020 AV 21MAY2020
P003 E1003 15APR2020 AV 16APR2020
P005 E1005 01JUN2020 AV 02JUN2020
;
run;

/* Pharmacy dispensings: PATID, RxDate, RX (the NDC value under SCDM) */
data work.RxData;
  length PATID $4 RX $11;
  informat RxDate date9.; format RxDate date9.;
  input PATID $ RxDate RX $;
  datalines;
P001 06APR2020 00069015001
P002 11APR2020 00069015001
P004 21MAY2020 00071015523
P003 16APR2020 00071015523
P005 02JUN2020 00069015001
P006 03JUN2020 00071015523
;
run;

data work.NdcCd;
  length NDC $11 BRAND $20 GENERIC $20;
  input NDC $ BRAND $ GENERIC $;
  datalines;
00069015001 Veklury Remdesivir
00071015523 Lipitor Atorvastatin
;
run;

%let EXCELOUT = .;
