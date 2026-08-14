# qMRLab GUI migration — handover

Written at the end of the session that landed Stages E, D2 and D4. Read this, then
`docs/adr/0001-gui-migration.md` (decisions D1–D9), then the plan at
`~/.claude/plans/i-ve-got-a-very-expressive-boole.md`.

## Where things stand

Branch `mb/migrate-v2`, **pushed**. `Test/GUI`: **46/46** on R2026b, and verified
44/44 on R2026a (the release CI actually uses — `latest` resolves to R2026a).

Done: Stages A, B, C, D1, **D2**, D3, **D4**, **E1–E4**.
Not done: **Stage F** in full, plus the release.

The app today is a **hybrid**: a modern, gridded, themed main window and Options
window — and five GUIDE Sim add-on windows behind them, reachable from the sidebar.

## First thing to check

CI was just pushed for the first time since the licensing fix (`4665551`). The GUI
job used to die with `MathWorks Licensing Error 1`. **Confirm it now passes.**
Cause was calling the `matlab` binary directly, which bypasses the `matlab-batch`
wrapper that carries the licence; it goes through `matlab-actions/run-command` now,
like every other job. That fix is the only thing on the branch never verified.

## What is left, in the order to do it

### 1. Test the Sim windows before touching them
**Nothing in the suite reaches them.** 46 tests, zero coverage of the five windows
F2 is about to rewrite. Write that test first — Stage D1 shipped an empty panel with
every test green, and this is a much bigger blast radius.

They open from the sidebar via `MainApp.SimfunGUI` (`MainApp.m:428`), which the
buttons `MethodMenu` builds at runtime (`:290`) — not static components, so a test
has to go through that path or call the `_GUI` function directly.

### 2. F2 — the five Sim windows
| file | lines | `handles.` | `guidata` |
|---|---|---|---|
| `SimMonteCarlo_Diffusion/Sim_MonteCarlo_Diffusion_GUI.m` | 307 | 61 | 3 |
| `SimVary/Sim_Sensitivity_Analysis_GUI.m` | 285 | 63 | 3 |
| `SimRnd/Sim_Multi_Voxel_Distribution_GUI.m` | 240 | 92 | 4 |
| `SimProtocolOpt/Sim_Optimize_Protocol_GUI.m` | 171 | 37 | 2 |
| `SingleVoxel/Sim_Single_Voxel_Curve_GUI.m` | 168 | 46 | 1 |

Each has a `.fig` and two `gui_mainfcn` references.

**Rebuild as programmatic *legacy* `figure`s — NOT App Designer.** This is decided,
not open: they embed plain `axes` and call `axes(handles.SimCurveAxe)` before
`Model.plotModel(...)`, and `plotModel` takes no axes handle across 61 `subplot` and
23 `gca` sites in 22 model classes. `axes(h)` and `subplot` do not work in a
`uifigure`. App-Designering them forces an axes-handle refactor that breaks every
user's plotting script and the Octave/CLI path. Build the figure in code, drop the
`.fig` and the `gui_mainfcn` preamble, keep `Tag='Simu'`.

### 3. F3 — delete the generator, get CI coverage
`GenerateButtonsWithPanels` survives **only** for three Sim GUIs. Once F2 lands it
can go, along with the five `.fig` files. Then remove `-cover_exclude '*GUI*'` from
`.github/workflows/matlab.yml:62` — GUI coverage in CI for the first time.

### 4. F1 — retire the `handles` shim (do this LAST)
487 `handles.` references and 27 `guidata` calls in `src/`.

**Its character changed this session and that matters.** MATLAB's migration runtime
(`convertToGUIDECallbackArguments` → `appdesigner.appmigration.UIControlPropertiesConverter`)
wraps every tagged component and *translates* `String`, numeric `Value`,
`ForegroundColor`, `TooltipString`. So those sites are **not broken** — F1 is
readability and deletion, not a bug hunt. Do it after F2/F3, or a large share of the
churn lands on code F2 deletes.

### 5. Decided this session
- **`QMRLAB_GUI=new|legacy` switch: skip it.** `qMRLab.fig` is already deleted, so
  there is no legacy path on this branch to switch to. It only ever mattered for the
  master landing, which is not happening until the migration is finished.
- **`imtool3D` chrome: leave the black canvas.** The image area displays greyscale
  MRI; tinting it is a scientific-display problem, and a dark canvas is conventional
  for medical viewers in either mode. In dark mode it now blends for free. Theming
  only its chrome (info strip, tool rails) stays optional and low priority.
- **No master merge, no tagged release until the migration is complete.** 32 commits
  ahead of master.

## Traps — each of these cost real time; do not relearn them

**Green tests are evidence only for code paths they execute.** The suite was 26/26
while the "Fit data" button was wired to nothing. Nothing pressed a button. Corollary
already burned twice: a test that samples the part MATLAB handles will pass while the
part *you* control is broken (`tTheme` sampled themed panels and missed ten frozen
tokens).

**Look at a screenshot.** Found by looking, never by a test: `"View View"` in the
menu bar; the figure's `Color` surviving a strip because it is `.Color` not
`.BackgroundColor`; grey boxes behind the compass letters; three clipped labels at
the `large` text size.

**`isempty(callback)` does not mean dead.** The migration adapter rewrites the
component's own callback property. The authority is `guidata(fig).<Tag>.Callback`.

**`get(h,'Style')` on native components is worse than useless** — it throws on
checkboxes and buttons, and on a dropdown or table it silently returns a *uistyle
style table*, so a `switch` takes no branch and drops the value with no error.
Dispatch on `class(h)`.

**`set(h,'BackgroundColor','remove')` does not un-set a colour** — it freezes it at
the currently-resolved value. Stripping must happen in source.

**MATLAB does not reliably follow the OS appearance.** Measured with macOS in Dark, a
fresh `uifigure` still reported `"Light Theme"`. `Theme.adopt` always assigns
`fig.Theme` explicitly.

**The options payload is frozen bit-for-bit.** `Model.options` lands in saved
`FitResults`. Numeric options render in a **text** field (they hold `'auto'`,
`'R1MAP'`, `'(R1f*T2f)/R1f'`), and values format with `sprintf('%g')` — six
significant digits, because the widget round-trips through text, so **the formatting
is the stored value**. `Test/GUI/tDSL.m` pins this against the old generator for all
22 models. See `Test/GUI/KNOWN_BUGS.md` for the three deliberately-preserved defects.

**Overflow inside a `Scrollable` container is not a defect.** `geomAudit` and
`tMainApp.isReachable` know this now; both were corrected by measurement (scrolling
genuinely brings the content into view) rather than by loosening.

## Working practice that paid off

- **Run one model, not the suite, while iterating.** `optionsWindowRendersEveryModel`
  and `datasetsPanelIsPopulatedForEveryModel` each loop all 22 models — filtering to
  one *test* does not help. Full suite once, before a commit. It takes ~13 min.
- **Always `cd` to the repo in a `-batch` call.** A run from elsewhere silently finds
  no tests and reports a confusing parse error.
- **`Test/GUI/captureGoldens.m`** writes a PNG *and* a diffable inventory (text,
  visibility, size, colour) per window. Capture before an appearance change, not
  after. Evidence lives in `Test/GUI/evidence/{before_E,after_E1,after_E2,after_E3,after_D2}`.
- Guard Python slice-rewrites: an empty slice turned `str.replace` into "insert
  between every character" and destroyed `OptionsWindow.m` once.

## Map of the new code

```
qMRLab.m                                       35-line shim (mcc/list_models pin it)
src/Common/GUI/+qmrlab/+gui/MainApp.m          1905  main window
                              OptionsWindow.m  1098  per-model options
                              OptionsRenderer.m 290  buttons DSL -> grid, native
                              Theme.m           258  light/dark + semantic tokens
                              TypeScale.m       340  user text size
src/Common/tools/parseButtons.m                 172  pure DSL parse, Octave-clean
src/Common/tools/qmrlabUIColor.m                 38  token transport for vendored code
src/Common/tools/qmrlabUIScale.m                     same, for text size
```

`Test/GUI/`: `tCapabilities` (15, platform assumptions), `tMainApp` (9),
`tControls` (7, drives controls), `tDSL` (5, DSL contract), `tTheme` (6),
`tAPI` (4). Helpers: `geomAudit`, `captureGoldens`, `resizeCheck`, `probeTheme`.
