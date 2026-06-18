These URLs point to a specific run workspace and expire when the run is reaped.
Re-running the bundle (`./run_jenner.sh t002_hsf_lab_macro`) regenerates them.

## Files

| name | type | size | url |
|------|------|------|-----|
| listing.txt | text/plain | 4288 | https://api.jenneranalytics.com/v1/run/r_019edb98b56570f28dc51bc6988c1662/files/listing.txt?token=c1e64c8d19fe458fab43622a02b97e79 |

## Datasets

| name | rows | columns | preview |
|------|------|---------|---------|
| _opt_WORK_0 | 3 | patid, dx, origdx, adate | https://api.jenneranalytics.com/v1/run/r_019edb98b56570f28dc51bc6988c1662/datasets/_opt_WORK_0?token=c1e64c8d19fe458fab43622a02b97e79 |
| dxdata | 5 | PATID, ENCTYPE, DX, ORIGDX, ADATE | https://api.jenneranalytics.com/v1/run/r_019edb98b56570f28dc51bc6988c1662/datasets/dxdata?token=c1e64c8d19fe458fab43622a02b97e79 |
| labdata | 7 | PATID, Test_Type, Loinc, Lab_Dt | https://api.jenneranalytics.com/v1/run/r_019edb98b56570f28dc51bc6988c1662/datasets/labdata?token=c1e64c8d19fe458fab43622a02b97e79 |
| mycohort | 6 | PATID | https://api.jenneranalytics.com/v1/run/r_019edb98b56570f28dc51bc6988c1662/datasets/mycohort?token=c1e64c8d19fe458fab43622a02b97e79 |
| numerator_lab | 7 | PATID, Test_Type, Loinc, Lab_Dt, SLDx_Dt, Flag_Lab_with_SLDx_Any, Flag_Lab_with_SLDx_Ever | https://api.jenneranalytics.com/v1/run/r_019edb98b56570f28dc51bc6988c1662/datasets/numerator_lab?token=c1e64c8d19fe458fab43622a02b97e79 |
| silverlabeldx | 3 | patid, enctype, dx, origdx, adate | https://api.jenneranalytics.com/v1/run/r_019edb98b56570f28dc51bc6988c1662/datasets/silverlabeldx?token=c1e64c8d19fe458fab43622a02b97e79 |
| summary_by_lab | 3 | Test_Type, LAB_COUNTS, SLDX_COUNTS, OTHER_COUNTS, N_WO_SLDX_EVER, WITH_SLDX_RATE, WITHOUT_SLDX_RATE, RELATIVE_RISK | https://api.jenneranalytics.com/v1/run/r_019edb98b56570f28dc51bc6988c1662/datasets/summary_by_lab?token=c1e64c8d19fe458fab43622a02b97e79 |
