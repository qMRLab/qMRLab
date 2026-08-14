# qMRLab GUI geometric triage (merged)

- Shards: 41 model/window rows
- Captures: 38 PNG
- Status: 17 defects, 3 error, 21 ok
- Defects: 44 (35 Collapsed, 8 Overflow, 1 OffFigure)
- Models not clean: 20 -- amico, b0_dem, b1_afi, b1_dam, charmed, denoising_mppca, dti, filter_map, inversion_recovery, mono_t2, mp2rage, mt_sat, mtv, mwf, noddi, noise_level, qmt_bssfp, qmt_sirfse, qmt_spgr, qsm_sb

## Summary

| Model | Window | Status | Defects |
|---|---|---|---|
| amico | main | ok | 0 |
| amico | options | defects | 1 |
| b0_dem | main | ok | 0 |
| b0_dem | options | defects | 3 |
| b1_afi | main | ok | 0 |
| b1_afi | options | defects | 3 |
| b1_dam | main | ok | 0 |
| b1_dam | options | defects | 3 |
| charmed | main | ok | 0 |
| charmed | options | defects | 2 |
| denoising_mppca | launch | error | 0 |
| dti | main | ok | 0 |
| dti | options | defects | 2 |
| filter_map | main | ok | 0 |
| filter_map | options | defects | 3 |
| inversion_recovery | main | ok | 0 |
| inversion_recovery | options | defects | 1 |
| mono_t2 | main | ok | 0 |
| mono_t2 | options | defects | 1 |
| mp2rage | main | ok | 0 |
| mp2rage | options | defects | 3 |
| mt_ratio | main | ok | 0 |
| mt_ratio | options | ok | 0 |
| mt_sat | main | ok | 0 |
| mt_sat | options | defects | 6 |
| mtv | launch | error | 0 |
| mwf | main | ok | 0 |
| mwf | options | defects | 1 |
| noddi | main | ok | 0 |
| noddi | options | defects | 1 |
| noise_level | main | ok | 0 |
| noise_level | options | defects | 3 |
| qmt_bssfp | main | ok | 0 |
| qmt_bssfp | options | defects | 4 |
| qmt_sirfse | main | ok | 0 |
| qmt_sirfse | options | defects | 3 |
| qmt_spgr | main | ok | 0 |
| qmt_spgr | options | defects | 4 |
| qsm_sb | launch | error | 0 |
| vfa_t1 | main | ok | 0 |
| vfa_t1 | options | ok | 0 |

## Detail

### amico / options

- **Collapsed** `` — size 1.0 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### b0_dem / options

- **Collapsed** `OptionsPanel` — size 0.5 x 1.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel]`
- **Collapsed** `` — size 1.0 x 36.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Overflow** `` — extends outside its parent (left 0.0, bottom -35.0, right +0.5, top +0.0)
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### b1_afi / options

- **Collapsed** `OptionsPanel` — size 0.5 x 1.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel]`
- **Collapsed** `` — size 0.9 x 215.7 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Overflow** `` — extends outside its parent (left 0.1, bottom -214.7, right +0.5, top +0.0)
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### b1_dam / options

- **Collapsed** `OptionsPanel` — size 0.5 x 1.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel]`
- **Collapsed** `` — size 0.9 x 215.7 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Overflow** `` — extends outside its parent (left 0.1, bottom -214.7, right +0.5, top +0.0)
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### charmed / options

- **Collapsed** `` — size 1.0 x 0.2 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 0.9 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### denoising_mppca / launch

```
ERROR: Error setting property 'ColumnWidth' of class 'Table':
'ColumnWidth' must be an array containing 'fit', 'auto', positive numbers, or positive integers paired with 'x'. You can specify 'ColumnWidth' as a cell array containing any combination of values, or as a string array when all elements are of the same type.
```


### dti / options

- **Collapsed** `` — size 0.9 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 1.0 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### filter_map / options

- **Collapsed** `OptionsPanel` — size 0.5 x 1.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel]`
- **Collapsed** `` — size 0.9 x 215.7 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Overflow** `` — extends outside its parent (left 0.1, bottom -214.7, right +0.5, top +0.0)
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### inversion_recovery / options

- **Collapsed** `` — size 1.0 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### mono_t2 / options

- **Collapsed** `` — size 1.0 x 0.2 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### mp2rage / options

- **Collapsed** `OptionsPanel` — size 0.5 x 1.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel]`
- **Collapsed** `` — size 1.0 x 36.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Overflow** `` — extends outside its parent (left 0.0, bottom -35.0, right +0.5, top +0.0)
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### mt_sat / options

- **Collapsed** `OptionsPanel` — size 0.5 x 1.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel]`
- **Collapsed** `` — size 0.9 x 36.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Overflow** `` — extends outside its parent (left 0.1, bottom -70.9, right +0.5, top +-36.0)
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **OffFigure** `` — lies entirely outside the window at [14.6 -58.9 0.9 36.0]
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 1.0 x 36.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Overflow** `` — extends outside its parent (left 0.0, bottom -35.0, right +0.5, top +0.0)
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### mtv / launch

```
ERROR: Error setting property 'ColumnWidth' of class 'Table':
'ColumnWidth' must be an array containing 'fit', 'auto', positive numbers, or positive integers paired with 'x'. You can specify 'ColumnWidth' as a cell array containing any combination of values, or as a string array when all elements are of the same type.
```


### mwf / options

- **Collapsed** `` — size 1.0 x 0.2 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### noddi / options

- **Collapsed** `` — size 1.0 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### noise_level / options

- **Collapsed** `OptionsPanel` — size 0.5 x 1.0 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel]`
- **Collapsed** `` — size 1.0 x 71.9 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Overflow** `` — extends outside its parent (left 0.0, bottom -70.9, right +0.5, top +0.0)
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### qmt_bssfp / options

- **Collapsed** `` — size 0.9 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 1.0 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 0.9 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 0.9 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### qmt_sirfse / options

- **Collapsed** `` — size 0.9 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 0.9 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 0.9 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### qmt_spgr / options

- **Collapsed** `` — size 1.0 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 0.9 x 0.2 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 1.0 x 0.1 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`
- **Collapsed** `` — size 0.9 x 0.3 px is below the 40 px floor
  - `matlab.ui.Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel`

### qsm_sb / launch

```
ERROR: Error setting property 'ColumnWidth' of class 'Table':
'ColumnWidth' must be an array containing 'fit', 'auto', positive numbers, or positive integers paired with 'x'. You can specify 'ColumnWidth' as a cell array containing any combination of values, or as a string array when all elements are of the same type.
```


