# ADR 0001 — Migrating the qMRLab GUI off GUIDE

- **Status:** accepted
- **Date:** 2026-08-13
- **Supersedes:** the abandoned `mb/appmigration` approach (see *History*)

## Context

MathWorks removed GUIDE in R2025a. qMRLab's interface is a GUIDE app
(`qMRLab.m` + `qMRLab.fig`), so it has been frozen since. Existing GUIDE apps still
*run* on R2026b — `toolbox/matlab/guide/gui_mainfcn.m` is still shipped — but the
layout can no longer be edited with a supported tool, and there is no guarantee the
runtime survives another release.

Three properties of this codebase determine the approach:

1. **The `.fig` files are nearly empty.** `src/Common/GUI/Custom_OptionsGUI.fig` and
   the three per-model option figures contain a single component each — the figure.
   `qMRLab.fig` has 40. Roughly 90% of the interface is generated at runtime from
   model class definitions, so MathWorks' migration tool has very little to convert.
2. **Every window is an independent figure sharing state through root appdata**
   (`setappdata(0,'Model',…)`, ~123 sites) and locating its peers by name
   (`findobj('Name','qMRLab')`). This is poor design and it is precisely what makes a
   window-at-a-time migration possible: a `uifigure` window coexists with GUIDE windows.
3. **A prior migration exists** on `origin/mb/appmigration` and is roughly 70%
   complete.

## Decisions

### D1 — Salvage the existing branch rather than rewrite

Its two most expensive questions are already answered in code: `imtool3D` embeds in an
App Designer container, and the options mini-language needed no changes. Stage A
verified both. The branch's defects are small and enumerated (see
`Test/GUI/STAGE_A_FINDINGS.md`).

### D2 — Programmatic `classdef … < handle`, not `.mlapp` and not the plain-text app format

The interface is built with `uifigure` + `uigridlayout` in ordinary MATLAB code.

- `.mlapp` is a zip containing both `matlab/document.xml` (the code) and
  `appdesigner/appModel.mat` (a binary that must stay in sync). It is unreviewable in a
  pull request, and the round-trip is one-way.
- R2026b's plain-text app format is two files — a `.m` holding callbacks and a `.xml`
  holding the layout. The XML is App Designer's data file: text, but machine-managed
  and not meaningfully reviewable. Stage A also measured
  `feature('AppDesignerPlainTextFileFormat')` as **1 on R2026b but 0 on R2026a**, so
  adopting it would pin the GUI to a single prerelease.
- With ~90% of the interface generated at runtime, the designer could only ever help
  with a six-panel shell — a dozen lines of `uigridlayout`.

If hand-writing the shell proves painful, App Designer remains usable as a one-way
scratchpad: lay it out, export, paste the generated `createComponents` body. It emits
ordinary `uifigure` calls.

### D3 — `qMRLab.m` remains a real function file

It stays as a ~35-line shim: Octave guard, the `nargout` modal contract, `varargout`
model return, mcc entry point. Three things pin the filename:

- `Deploy/Compile/qMRLab_make_standalone.m` → `mcc -W main:qMRLab`
- `src/Common/list_models.m:3` → `which('qMRLab.m')`
- `Deploy/Documentation/GenerateDocumentation.m:3,81`

This is not theoretical. On `mb/appmigration`, where `qMRLab.m` was deleted in favour
of `qMRLab.mlapp`, `list_models()` returns **0 models** while 22 exist on disk. The app
itself survives because its own path lookup goes through `mfilename()`; the tests, the
documentation generator and the standalone build do not.

### D4 — Freeze `imtool3D`; freeze the `buttons` DSL; leave root appdata alone

- **Viewer:** 2760 lines of vendored BSD code providing the mask/ROI drawing that is
  qMRLab's workflow. Kept, patched minimally (see
  `External/imtool3D_td/QMRLAB_PATCHES.md`), and hidden behind one adapter so a future
  swap touches one file. Replacement with `viewer2d`/`images.roi` is a separate project.
- **Options DSL:** `buttons`, `button2opts.m`, `genvarname_v2.m` and the `AbstractModel`
  helpers are untouched public API, called from 23 model constructors on the Octave/CLI
  path. Two known quirks are deliberately preserved: the asymmetric `###`/`***` handling
  in `src/Models/Diffusion/dti.m:135-137`, and the `'R1MAP'` / `'R1f'` /
  `'(R1f*T2f)/R1f'` sentinels written into the numeric Start column for
  `qmt_spgr`/`qmt_sirfse`. Normalizing either renames option fields and silently
  corrupts saved `FitResults`.
- **State bus:** kept. Replacing it means running two state mechanisms concurrently
  during the transition, which is a larger risk than the smell it removes.

### D5 — MATLAB version floor

The GUI targets **R2020b+**, which is where `uigridlayout` `Scrollable` lands.
Capabilities newer than the floor are feature-detected, not assumed:

| Capability | Available from | Handling below the floor |
|---|---|---|
| `uifigure`, `uigridlayout` | R2018b | hard requirement |
| `uigridlayout` `Scrollable` | R2020b | hard requirement (the floor) |
| `uifigure.Theme` | R2025a | `isprop` guard; single palette below |

CI gains a `release:` matrix leg — it currently pins nothing and silently tracks
whatever `matlab-actions/setup-matlab@v2` installs. `Test/GUI/tCapabilities.m` runs on
every pinned release so a platform behaviour change fails loudly.

### D6 — Nothing blocks on an external party

The first attempt stalled in December 2025 waiting on MathWorks engineers who had
offered to help finalize the transition and never followed up. Every stage exit
criterion in this migration is something the maintainers can run themselves.

## Consequences

**Good.** The GUI becomes reviewable in a pull request for the first time. GUI tests
become possible at all — `matlab.uitest` drives `uifigure` components and refuses
legacy `uicontrol`, so migrating *is* what makes the interface testable. Layout bugs
that are currently invisible (panels rendering off-screen for `qmt_spgr` and `qsm_sb`,
sub-pixel collapse, a monotonic handle leak on model switching) get fixed structurally
rather than patched.

**Costs.** A vendored dependency now carries local patches that must be re-applied
after an upstream pull — mitigated by `QMRLAB_PATCHES.md`. The drag-and-drop designer
is given up. The five simulation add-on windows stay on GUIDE until the final stage,
so two idioms coexist for a while, behind a `QMRLAB_GUI=new|legacy` switch.

**Explicitly not addressed.** Multiple concurrent qMRLab instances (follows from
keeping root appdata — worth its own ADR). Octave is unaffected: the GUI is already
MATLAB-only by design (`qMRLab.m:22`).

## History

`origin/mb/appmigration` (R2025b) produced `qMRLab.mlapp` (1796 lines),
`Custom_OptionsGUI.mlapp` (1055 lines), a native rewrite of
`src/Common/tools/FileBrowser/{BrowserSet,MethodBrowser}.m`, hand-rolled OS dark-mode
detection, and logo assets. It stalled on the external dependency described in D6,
with ten of twenty-two model option screens broken by silent geometry failures that
were never triaged. That work is the starting point for this migration, not a
discarded attempt.
