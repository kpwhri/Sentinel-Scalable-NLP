These URLs point to a specific run workspace and expire when the run is reaped.
Re-running the bundle (`./run_jenner.sh t001_hsf_dx_macro`) regenerates them.

## Files

| name | type | size | url |
|------|------|------|-----|
| listing.txt | text/plain | 4697 | https://api.jenneranalytics.com/v1/run/r_019edb98a6af7212b14694b7a008fd12/files/listing.txt?token=4e7b2fced2a945cf87be31f9003bc9fc |

## Datasets

| name | rows | columns | preview |
|------|------|---------|---------|
| _opt_WORK_0 | 3 | patid, dx, origdx, adate | https://api.jenneranalytics.com/v1/run/r_019edb98a6af7212b14694b7a008fd12/datasets/_opt_WORK_0?token=4e7b2fced2a945cf87be31f9003bc9fc |
| diagcd | 4 | DIAGCD, DIAGDESC | https://api.jenneranalytics.com/v1/run/r_019edb98a6af7212b14694b7a008fd12/datasets/diagcd?token=4e7b2fced2a945cf87be31f9003bc9fc |
| dxdata | 9 | PATID, ENCTYPE, DX, ORIGDX, ADATE | https://api.jenneranalytics.com/v1/run/r_019edb98a6af7212b14694b7a008fd12/datasets/dxdata?token=4e7b2fced2a945cf87be31f9003bc9fc |
| mycohort | 6 | PATID | https://api.jenneranalytics.com/v1/run/r_019edb98a6af7212b14694b7a008fd12/datasets/mycohort?token=4e7b2fced2a945cf87be31f9003bc9fc |
| numerator_dx | 9 | PATID, ADATE, DX, DIAGDESC, ENCTYPE, SLDx_Dt, Flag_Dx_with_SLDx_Any, Flag_Dx_with_SLDx_Ever | https://api.jenneranalytics.com/v1/run/r_019edb98a6af7212b14694b7a008fd12/datasets/numerator_dx?token=4e7b2fced2a945cf87be31f9003bc9fc |
| silverlabeldx | 3 | patid, enctype, dx, origdx, adate | https://api.jenneranalytics.com/v1/run/r_019edb98a6af7212b14694b7a008fd12/datasets/silverlabeldx?token=4e7b2fced2a945cf87be31f9003bc9fc |
| summary_by_dx | 4 | DX, DIAGDESC, DX_COUNTS, SLDX_COUNTS, OTHER_COUNTS, N_WITHOUT_SLDX_EVER, WITH_SLDX_RATE, WITHOUT_SLDX_RATE, RELATIVE_RISK | https://api.jenneranalytics.com/v1/run/r_019edb98a6af7212b14694b7a008fd12/datasets/summary_by_dx?token=4e7b2fced2a945cf87be31f9003bc9fc |
