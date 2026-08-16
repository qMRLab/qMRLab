# Changelog
All notable changes to this project will be documented in this file.

## Release [3.0.0] - 2026-08-15

The graphical interface has been rebuilt. Nothing about fitting, models, protocols or
saved `FitResults` changes in this release.

### ⚠️ Breaking Changes
- **The GUI no longer uses GUIDE, and there are no `.fig` files left.**
    - MATLAB removed GUIDE in R2025a, where the 2.x interface can no longer be opened.
      That is the reason for this release.
    - The main window and the options panel are now programmatic `uifigure` apps; the
      five simulation windows are built in code. Local edits to any `.fig`, and code
      that drove the interface through GUIDE's `handles` struct, no longer apply.
- **The GUI now targets MATLAB R2020b or newer.**
    - The layout uses `uigridlayout` with `Scrollable`, which arrives in R2020b. On
      older releases the interface will not lay out correctly.
    - Fitting from the command line is unaffected on every release qMRLab supports.
- Octave is unaffected: the GUI has never been available there, and `qMRLab` continues
  to direct Octave users to the command line.

### New ✨
- 🆕 Light and dark theme
    - The interface follows MATLAB's own appearance setting on R2025a and newer, where
      `uifigure` theming is available. Below that a single palette is used.
- 🆕 User-controlled text size
    - Choose the interface text size; panels, tables and the file browser are measured
      against it and grow with it instead of clipping.
- 🆕 A regression test suite for the interface — 68 tests covering the main window, the
  options panel, the five simulation windows, the options DSL, theming, and the platform
  behaviours the layout depends on.
    - `matlab.uitest` can drive `uifigure` components but refuses legacy `uicontrol`, so
      rebuilding the interface is what made it testable at all.

### Improvements 🚀
- **Windows resize.** The layout is grid-managed throughout, so the viewer, the datasets
  panel and the options column grow with the window instead of holding their designed
  size.
- **Panels are sized to the model you picked.**
    - Protocol tables size to the protocol, so `inversion_recovery`'s 9 inversion times
      and `qmt_spgr`'s 10 MT data rows are fully visible instead of scrolling inside a
      fixed-height table.
    - The Fitting table sizes to the parameter count, so every model's parameters are
      visible — from `mp2rage`'s 4 to `noddi`'s 8.
    - The Simulation tools panel is sized to the simulation tools a model actually
      offers, rather than reserving a fixed six slots.
- The viewer clears when you switch models, instead of leaving the previous model's
  image, mask and volume list on screen.
- Typing or pasting a folder into *Path data* now loads it. Previously the box had no
  callback and only the Browse dialog worked.

### Bug Fixes🐛
- The simulation windows now adopt the model you give them.
    - They were built once and kept the first model they saw, so opening a simulation
      window on one model and then another went on simulating the first.
- Options panels no longer render partly off-screen for `qmt_spgr` and `qsm_sb`.
- Switching models no longer leaks graphics handles.
- `imtool3D` no longer leaks 63 graphics objects every time an image is loaded.
    - `setupGrid` deleted the previous grid in a single call, which throws for a
      heterogeneous array of handles and was swallowed by a bare `try`. This affected
      every data load, not only the GUI. See `External/imtool3D_td/QMRLAB_PATCHES.md`.
- Fitting with a mask that excludes every voxel now fails cleanly, instead of erroring
  part-way through saving after it had already created an output directory.

### Removed 🧹
- Every GUIDE `.fig` file.

## Release [2.5.0] - 2026-08-15

### ⚠️ Breaking Changes
- Model: `mt_sat` — **B1-corrected results change.**
    - The supplied B1 map now corrects the excitation flip angles in both `R1` and `A`.
      Previously both used nominal flip angles and B1 entered only through the empirical
      Weiskopf correction.
    - Fits **with** a B1 map produce different `MTSAT` and `T1` values than 2.4.1. Fits
      without one are unchanged. Re-run any B1-corrected data you intend to compare
      against, or pool with, 2.4.1 output.
- Model: `inversion_recovery` — the `General` fit model has been removed; only `Barral`
  remains. Saved models, protocols and scripts that select `General` need updating.
- Masked fits now zero the output of whole-volume models.
    - `FitData` zeroes every numeric output field whose size matches the mask. Previously
      only `mt_ratio` and `mp2rage` masked their own output and other whole-volume models
      returned values in masked-out voxels.
- `AbstractModel.qMRpatch` now takes `(obj, loadedStruct)`. In-tree models are updated;
  any out-of-tree model that overrides it must adopt the new signature.
- `SimDemo_SPGR`, `SimDemo_SIRFSE` and `SimDemo_bSSFP` are now functions returning
  `[Sim, SimCurveResults]` instead of scripts.
- `External/qMRWrappers` is now a git submodule. A plain `git clone` leaves it empty —
  clone or update with `--recurse-submodules`.
- The Sphinx documentation no longer ships in the repository. See **Removed**.
- `src/Common/pulse/sinc.m` is renamed `sinc_fn.m` so qMRLab no longer shadows MATLAB's
  built-in `sinc`.
- Loading a model saved by a different qMRLab version now emits a `qMRLab:VersionMismatch`
  warning. It is informational, and expected to be near-universal on first upgrade.

### New ✨
- 🆕 model: `b1_afi`
    - Map the transmit field (B1+) from Actual Flip-Angle Imaging data
      (Yarnykh, MRM 2007).
    - Returns raw, filtered and spurious-voxel maps. `B1map_filtered` is MATLAB-only:
      filtering depends on `imgaussfilt`/`medfilt3`, which Octave does not provide.
    - By @mathieuboudreau.
- 🆕 model: `mtv`
    - Compute Macromolecular Tissue Volume from a T1 map, an M0 map and a brain mask.
    - Graduated from `UnderDevelopment` **and rewritten**: inputs are now T1, M0 and a
      required brain mask, where the development version took raw SPGR, a B1 map and a
      CSF mask. Setups built on the old version cannot be reused.
    - Also returns the coil receive profile, a cleaned CSF mask and a four-class k-means
      segmentation. New options: voxel size, spline smoothness and CSF T1 threshold.
    - By @tanguyduval.
- 🆕 `ParFitData`
    - Fit voxelwise models in parallel across all physical cores.
    - Autosaves every 5 minutes and resumes from a `RecoverDirectory` after a crash. The
      GUI's *Fit Data* button offers to start a pool for you.
    - By @agahkarakuzu.
- 🆕 MINC support
    - The file browser accepts `.mnc` and `.mnc.gz`, fitted maps are written back as
      `.mnc.gz`, and the viewer takes its voxel aspect ratio from the MINC step attributes.
    - By @amie-demmans.
- 🆕 Interactive voxel selection in the output viewer
    - Click any voxel on a fitted map to plot that voxel's fit curve.
    - An optional fourth argument to `qMRshowOutput` overlays a second fit result on the
      same axes and opens a difference map of the two.
    - By @harrisoncbrammell.
- 🆕 `mp2rage`: magnitude-only fitting
    - Supply INV1 and INV2 magnitude images with no phase and no vendor UNI image; the
      UNI image is synthesised in-model.
    - By @mathieuboudreau.
- 🆕 `versionChecker`
    - Startup reports whether you are running the latest published release, and links to
      it if not.

### Improvements 🚀
- **qMRLab runs on current MATLAB again.**
    - The GUI, `imtool3D` and `nii_viewer` no longer break on releases that removed the
      Java figure back end (R2020b/R2021a+): scroll panels, drag-and-drop and mask
      overlays degrade gracefully instead of erroring, and mask overlays no longer
      require the Mapping Toolbox.
    - The histogram window's bin-width, min/max and normalization controls work again on
      R2023b and newer, where a single-character version parse made every 23.x release
      look older than R2014b.
    - By @agahkarakuzu and @martinherrerias.
- **Substantially faster fitting.**
    - `inversion_recovery` ~5x faster: the NLS search grid depends only on the protocol,
      so it is now built once and cached. Results are bit-for-bit identical.
    - `qmt_spgr` ~4.5x faster: closed-form 2x2 matrix exponential, a single array-valued
      SuperLorentzian integration, and memoized lineshape terms. `qmt_bssfp` and
      `qmt_sirfse` share the improved code. Fitted values may differ in the last few digits.
    - By @mathieuboudreau.
- Model: `mt_sat` — the MTR map is now exported alongside MTsat. By @jvelazquez-reyes.
- Model: `vfa_t1` — set `Model.voxelwise = 1` to restore the weighted least-squares fit
  used before the linear-fit rewrite, for comparison against older results. The default
  is unchanged.
- Voxel-wise fitting no longer floods the console: per-voxel failures are capped at 10
  messages, followed by a hint to supply a binary mask.
- `qMRgenBatch` scripts now carry per-model BIDS filename and directory layouts, metadata
  keys, and a reference citation.
- The GUI shows the version number, links to the selected model's documentation, and
  offers an upgrade link when a newer release is published.
- Docker images rebased: `qmrlab/mcr` on `ubuntu:20.04`, `minimal` and `octjn` on
  `neurodebian:focal` with Octave 5.2.0, all cloning with `--recurse-submodules`.
- `ParFitData` defaults are read from an editable `usr/preferences.json` rather than a
  modal dialog.

### Bug Fixes🐛
- Voxel-wise fitting no longer aborts the entire run when the first voxels fail to fit,
  which is typical of unmasked background ([#417](https://github.com/qMRLab/qMRLab/issues/417)).
- Spatial filtering is skipped rather than erroring on Octave, which lacks `imgaussfilt`
  and `medfilt3`.
- Model: `mono_t2` — corrected fitting bounds. By @BusraBulut222.
- NIfTI scaling is no longer applied twice when saving qMRI maps.
- Example-data downloads follow redirects and retry on failure, and a model's dataset is
  no longer replaced by the trimmed documentation copy.
- The mouse pointer no longer sticks on "loading" when a fit errors; `onCleanup` restores
  it. By @martinherrerias.
- Fitting from the GUI works on installations without the Parallel Computing Toolbox.
- `Model.sinc` no longer shadows MATLAB's built-in `sinc`. By @jvelazquez-reyes.

### Removed 🧹
- The bundled Sphinx documentation (`docs/`, 193 files).
    - Model pages are now generated from the code and published to the separate
      [qMRLab/documentation](https://github.com/qMRLab/documentation) repository.
    - Users who read the documentation locally or offline should use the online site.
- The `General` fit model for `inversion_recovery`.

### Other
- Continuous integration now runs on GitHub Actions.
- Test infrastructure: MOxUnit updated for recent MATLAB and Octave releases, and the
  batch tests assert that refits match their stored references within 5%.

## Release [2.4.1] - 2020-09-02

## New ✨
- 🆕 model: `inversion_recovery` 
    - Add general equation fitting in addition to Barral's model.

### Improvements 🚀
- GUI (JOSS review by @mfroeling)
    - Please see changes [here](https://github.com/qMRLab/qMRLab/pull/400).
- Documentation (JOSS review by @grlee77)
    - Please see changes [here](https://github.com/qMRLab/qMRLab/pull/399)

### Bug Fixes🐛
- `FilterClas` bug [fix](https://github.com/qMRLab/qMRLab/pull/385).

### Other
- Change citation reference to JOSS paper
    - Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
    Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
    Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

## Release [2.4.0] - 2020-02-14

### New ✨
- 🆕 model: `mp2rage` 
    - Fit MP2RAGE data to create a T1map.
    - The original codebase is [here](https://github.com/JosePMarques/MP2RAGE-related-scripts).
    - Check out [qMRLab's MP2RAGE blog post](https://qmrlab.org/2019/04/08/T1-mapping-mp2rage.html) by @mathieuboudreau!
- 🆕 model: `mono_t2`
    - Fit MESE data to create a T2map.
- 🆕 simulator: `Monte-Carlo Diffusion`
    - Monte Carlo simulator for 2D diffusion is able to generate synthetic 
    diffusion signal from any 2D axon packing.
    - An MRathon project by @Yasuhik, @TomMingasson and @tanguyduval. 
- 🆕 Changelog ❤️

### Improvements 🚀
- Model: `qsm_sb` 
    - With the new echo combination implementation, `qsm_sb` can now take 
      multi-echo GRE data. 
    - An MRathon project by @jeremie-fouquet.
- Get rid of redundant buttons in GUI `Protocol` panel. 

### Bug Fixes🐛
- `qMRgenBatch` account for models w/o fixed required inputs (e.g. `mp2rage`).
- Remove old built packages from `qmrlab/mcrgui`.
- Fix `qmrlab/octjn` dependencies.

### Removed 🧹

## Release [2.3.1] - 2020-01-07

### New ✨
- 🆕 static member function: getProvenance 
    - Scrape details and add more (optional) to save sidecar `*.json` files for maps.
    - See an example use [here](https://github.com/qMRLab/qMRWrappers/blob/master/mt_sat/mt_sat_wrapper.m).
- 🆕 Docker image: `qmrlab/minimal`
    - qMRLab + Octave - Jupyter for [qMRFlow](https://github.com/qMRLab/qMRflow) pipelines.    

### Improvements 🚀
- New MATLAB/Octave env: `ISNEXTFLOW` 
    - Deals with the `load_nii` case for symlinked inputs.
    - Enforces `gzip -d --force` if `ISNEXTFLOW` 
    - Commonly used by `qMRWrappers` 

### Bug Fixes🐛
- N/A

### Removed 🧹
- N/A 

## Release [2.3.0] - 2019-05-08

### New ✨

- 🆕 model: `Processing/filtermap` 
    - Apply 2D/3D spatial filtering, primarily intended for fieldmaps. 
        - `Polynomial`
        - `Gaussian` 
        - `Median` 
        - `Spline` 
- 🆕 model: `qsm_sb` 
    - Fast quantitative susceptibility mapping:
        - `Split-Bregman` 
        - `L1 Regularization`
        - `L2 Regulatization` 
        - `No Regularization` 
        - `SHARP background filtering` 
- 🆕 model: `mt_ratio` 
    - Semi-quantitative MTR. 
- 🆕 GUI 3D toolbox:
    - An array of UI tools for the visualization and brief statistical
      inspection of the data using ROI tools. 
- 🆕 functionality `qMRgenJNB`:
    - Create a Jupyter Notebook for any model. 
    - Insert Binder Badge to the documentation. 
- 🆕 Azure release pipelines and deployment protocols:
    - Set self-hosted Azure agent to compile qMRLab and ship in a Docker image
    - `qmrlab/mcrgui`: Use qMRLab GUI in a Docker image. 
    - `qmrlab/octjn`: Use qMRLab in Octave in Jupyter Env. 
    - See `/Deploy` folder for furhter details. 
    - [qMRLab DockerHub page.](https://hub.docker.com/orgs/qmrlab)

### Improvements 🚀
- Model: `vfa_t1`:
    - Bloch simulations are added 
    - Performance improvement 
- Model: `ir_t1` 
    - Parameter descriptions are improved. 
- Model: `b1_dam`
    - Protocol descriptions has been updated. 
- `FitTempResults`:
    - Is now saved every 5 minutes instead of every 20 voxels. 
    
### Bug Fixes🐛
- GUI fixes. 

### Removed 🧹
- N/A 