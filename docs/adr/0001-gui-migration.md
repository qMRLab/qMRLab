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

### D7 — Layout is grid-managed; nothing computes a rectangle at runtime

*Decided during Stage E, from measurement.*

Every container that held children at absolute or normalized coordinates is now a
`uigridlayout`. This was not a tidy-up: the old scheme could not be made correct.

`AutoResizeChildren`, which the layout relied on, is a pure **top-anchor
translation** — measured on R2026b, a panel taken from 900x700 to 1800x891 moved
all four probe children `dy=+191` with `dx=dw=dh=0`. It never resizes anything, so
growing the window only ever added dead space.

The options generator was worse than wrong, it was unstable: its rows are a fixed
35 px expressed as `35/panelHeight` while its group gap is a flat `0.02` of the
panel, and the stack walks down from `y = 1` with no floor. The height it *needs*
therefore grows with the panel, so it can overflow a **taller** container than it
fitted. Making the options column 18 px taller pushed `qsm_sb`'s last group 3.4 px
out the bottom.

Consequence: overflow is now handled by `Scrollable`, not by hoping it fits. The
Datasets browser, the viewer's control strip, the sidebar and the options column
all scroll. The minimum-window clamp is gone; the window audits clean at 700x520.

### D8 — The options DSL payload is frozen bit-for-bit, and that constrains the widgets

*Decided during Stage E3.*

`Model.options` field names and values are written into saved `FitResults`, so the
renderer may change how options *look* but not what they *are*. Two widget choices
follow from that and look like mistakes otherwise:

- Numeric options render in a **text** field, not `uieditfield('numeric')`. A
  "numeric" option does not always hold a number — `dti` assigns
  `options.Riciannoisebias_value = 'auto'`, and `qmt_spgr`/`qmt_sirfse` put
  `'R1MAP'`, `'R1f'` and `'(R1f*T2f)/R1f'` in the fitting Start column. A numeric
  field rejects every one of them.
- Values format with `sprintf('%g')` — six significant digits, matching what
  `set(uicontrol,'String',d)` did. The widget round-trips through text, so **the
  formatting is the stored value**. `string()` (full precision) and `num2str`
  (five digits) each changed four options across `mtv`, `qmt_spgr` and `qsm_sb`.
  More precision would be an improvement and is still a payload change.

`button_handle2opts` dispatches on **class**, never on `Style`: against native
components that property throws on checkboxes and buttons, and on a dropdown or
table it silently returns the *uistyle style table*, so a `switch` on it takes no
branch and drops the option with no error.

`Test/GUI/tDSL.m` asserts the new renderer and the old generator produce identical
field sets, classes and values for all 22 models.

### D9 — Theming is MATLAB's job; the app states only colours that carry meaning

*Decided during Stage D2, revising the plan's expectation.*

A `uifigure` themes its own components — measured, an untouched panel goes
`[0.961]` light to `[0.129]` dark. The app's ~290 lines of theme engine existed
only to undo the 58 explicit colours it had set on itself. Those are deleted; ten
that carry meaning (accent, warning, success, muted) became tokens in
`qmrlab.gui.Theme`, exported through `qmrlabUIColor` so vendored and headless code
reads them without depending on `+qmrlab/+gui` — the arrangement `qmrlabUIScale`
already uses for text size.

Two corrections to the plan:

- **The OS detection could not simply be deleted.** ~~MATLAB does not reliably follow
  the OS appearance: with macOS in Dark, a bare `uifigure` still reported "Light
  Theme".~~ **Corrected 2026-08-14 — see below.** The query is kept, once, in
  `Theme.systemAppearance`, instead of duplicated in both windows. `Theme.adopt`
  always assigns `fig.Theme` explicitly, so the IDE, `-batch` and the compiled
  standalone agree.
- **The viewer keeps its black canvas.** `imtool3D`'s colour constants are
  untouched. The image area displays greyscale MRI and must stay neutral — tinting
  it is a scientific display problem, not a cosmetic one — and a dark canvas is the
  convention for medical image viewers in either mode. In dark mode it now blends
  with the shell for free, which was the original complaint. Theming its *chrome*
  remains open.

### D9a — Correction: it was the OS that lied, not MATLAB

*2026-08-14, after a user reported every window dark on a light desktop.*

D9 above recorded that "MATLAB does not reliably follow the OS appearance", from a
measurement that read a bare `uifigure` as Light while macOS was believed to be in
Dark. That inference was backwards. Re-measured on the same machine with the desktop
in **Light**:

| source | answer |
|---|---|
| `defaults read -g AppleInterfaceStyle` | `Dark` |
| `NSApp.effectiveAppearance` (live) | `NSAppearanceNameAqua` — light |
| `settings().matlab.appearance.MATLABTheme` | `System` |
| a bare `uifigure` | `light` |

macOS keeps `AppleInterfaceStyle` in `~/Library/Preferences/.GlobalPreferences.plist`
and it can outlive the appearance it describes. MATLAB was right both times; the
`defaults` query was wrong both times, and reading it *first* is what painted the app
dark on a light desktop.

The contract is unchanged — resolve once, assign `fig.Theme` explicitly — but the
source order is inverted. `Theme.systemAppearance` now asks, in order:

1. `settings().matlab.appearance.MATLABTheme`, when the user pinned MATLAB to
   Light or Dark. qMRLab looking unlike every other MATLAB window is the complaint.
2. A hidden probe `uifigure`, when MATLAB is itself on `System` — this reads the
   **live** appearance rather than a stored key.
3. `Theme.queryOS`, the old `defaults`/registry query, only below R2025a where a
   figure has no `Theme` to read.

The answer is cached, which also removes a `system()` fork per colour lookup.
`Theme.choose('system')` refreshes it. Pinned by
`tTheme/systemFollowsMatlabAndNotAStoredOsKey`, which drives MATLAB's own setting
(the one input a test can change on any platform) and fails against the old order on
both macOS and Linux.

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
