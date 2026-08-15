# qMRLab GUI migration — handover

Written at the end of the session that got CI green and built the gate under Stage F2.
Read this, then `docs/adr/0001-gui-migration.md` (decisions D1–D9a), then the plan at
`~/.claude/plans/i-ve-got-a-very-expressive-boole.md`.

## Where things stand

Branch `mb/migrate-v2`, **pushed**, 37 commits ahead of master. `Test/GUI`: **62/62**
on R2026b (46 at the start of the session).

Done: Stages A, B, C, D1–D4, E1–E4, and the **F2 gate** — the five Sim windows now
have tests and captured evidence, which they did not before.
Not done: the **F2 rewrite itself**, F3, F1, then the merge and the tagged release.

The app is still a hybrid: a modern, gridded, themed main window and Options window,
and five GUIDE Sim add-on windows behind them.

## First thing to check

**CI on the branch head.** Every non-GUI job is green, including
`MATLAB_1_quickMox_BatchExamplePart1`, which had been red since `Custom_OptionsGUI.m`
was deleted. The GUI legs were still settling as this was written: the last three
failures were all *measurement* bugs in tests written this session — a duration
standing in for a blocking assertion, and a geometry count hardcoded from macOS —
each fixed by making the assertion say what it means. Read a GUI diagnostic before
assuming the app is broken; check whether the claim is platform- or timing-shaped
first.

## What this session changed

1. **The appearance follows MATLAB, not a stale OS key** (`1014655`). Reported as
   "the GUI is dark and my Mac is in light mode". `defaults read -g
   AppleInterfaceStyle` answered `Dark` on a desktop that was demonstrably Light.
   This *reverses* a trap D9 recorded; see **D9a**.
2. **`Custom_OptionsGUI` restored** (`c1902a6`) as an entry point, because
   `qMRgenBatch` writes it into batch scripts on users' disks that no template edit
   can reach. Unattended callers get the model back without a window at all — the job
   that runs batch scripts has no Xvfb, and a `uifigure` is not a legacy figure.
3. **`geomAudit` re-audits until clean** (`940a920`) instead of sleeping 0.3 s.
4. **`tSimWindows`** (`ae3daf4`) — 12 characterisation tests that reach all five Sim
   windows, plus a fix to a flake I introduced in `tAPI` the push before.
5. **Evidence and tooling for F2** (`f8cc92c`) — `captureFigure`, `captureSimGoldens`,
   and `Test/GUI/evidence/before_F2/` for all five windows.

## What is left, in the order to do it

### 1. F2 — the five Sim windows  ← the gate is now in place, start here

| file (under `src/Addons/`) | lines | `handles.` | `guidata` |
|---|---|---|---|
| `SimMonteCarlo_Diffusion/Sim_MonteCarlo_Diffusion_GUI.m` | 307 | 61 | 3 |
| `SimVary/Sim_Sensitivity_Analysis_GUI.m` | 285 | 63 | 3 |
| `SimRnd/Sim_Multi_Voxel_Distribution_GUI.m` | 240 | 92 | 4 |
| `SimProtocolOpt/Sim_Optimize_Protocol_GUI.m` | 171 | 37 | 2 |
| `SingleVoxel/Sim_Single_Voxel_Curve_GUI.m` | 168 | 46 | 1 |

**Rebuild as programmatic *legacy* `figure`s — NOT App Designer.** Decided, not open:
they embed plain `axes` and call `axes(handles.SimCurveAxe)` before
`Model.plotModel(...)`, and `plotModel` takes no axes handle across 61 `subplot` and
23 `gca` sites in 22 model classes. `axes(h)` and `subplot` do not work in a
`uifigure`.

**Read each `.fig` without instantiating it** — loading one runs its `CreateFcn`s:

```matlab
s = load('src/Addons/SingleVoxel/Sim_Single_Voxel_Curve_GUI.fig', '-mat');
s.hgS_070000.children(1).properties      % type / properties / children, recursively
```

**The contract the rewrite must preserve** (all verified this session):
- `Tag='Simu'` on the figure. `MainApp.m:1164` tears these down by that tag.
- The figure `Name` — it is the only thing telling the five apart, and three are
  named after their `.fig` (`SimOptProt`, `SimMCdiff`, `Multi Voxel Distribution`).
- `HandleVisibility='callback'`, unless you change it deliberately and update
  `tSimWindows/theWindowsAreInvisibleToFindobj`.
- Every `handles.*` field name, **including `handles.Simu`** — `SimVary` uses it for
  `printdlg` and its close dialog (`Sim_Sensitivity_Analysis_GUI.m:147,154-161`).
- Nothing to preserve on the GUIDE dispatch side: **no caller anywhere uses the
  `('CALLBACK', hObject, ...)` string form** (grepped across `src/` and `Test/`), so
  `gui_State`, `gui_mainfcn` and the `gui_Callback` branch can all go.

**Two defects `tSimWindows` pins in their broken form.** Both are asserted as they
behave today so the rewrite has to change them *deliberately*, in the same commit as
the test:
- `Sim_Single_Voxel_Curve_GUI.m:55-57` assigns `handles.Model` **inside** the
  `~isfield(handles,'opened')` guard, unlike the other four. Since `MethodMenu` does
  not tear these windows down on a model switch, the window keeps simulating the model
  it was **first** opened with.
- Monte Carlo audits **one Overflow**: an axes whose box sits ~60 px below its parent.
- **Optimize Protocol's `ParamTable` overflows the top of its panel by ~15 px on
  Linux** and not on macOS — so on the CI runner that table is clipped. Allowed by
  name in `tSimWindows/noSimWindowCollapsesOrOverflowsItsPanels`; delete that
  allowance when F2 rebuilds the window. Geometry counts differ by platform
  generally: [0 0 0 0 1] on macOS, [0 0 0 2 3] on Linux.

**One thing worth fixing while you are in there:** all five `.fig`s set the figure
`Color` to `[0.251 0.251 0.251]`, a hard-coded dark grey a legacy figure will never
theme. Look at `evidence/before_F2/charmed_SingleVoxelCurve.png` — it shows through as
dark gaps between light panels. Route it through `qmrlabUIColor`, the arrangement the
other vendored code already uses.

**Capture the diff:** `captureSimGoldens('Test/GUI/evidence/after_F2')`, then
`diff -ru Test/GUI/evidence/before_F2 Test/GUI/evidence/after_F2` on the `.txt` files.

### 2. F3 — delete the generator, get CI coverage
`GenerateButtonsWithPanels` survives **only** for three Sim GUIs (`SingleVoxel:66`,
`SimRnd:59`, `SimVary:92`). Once F2 lands it can go with the five `.fig` files. Then
remove `-cover_exclude '*GUI*'` from `.github/workflows/matlab.yml:62`.

Note `Sim_Optimize_Protocol_GUI.m:69` calls the *other* generator, `GenerateButtons`,
which names handles differently — it does not strip `##`/`**`. `tDSL` pins
`parseButtons` against `GenerateButtonsWithPanels` only.

### 3. F1 — retire the `handles` shim (do this LAST)
487 `handles.` references and 27 `guidata` calls in `src/`. MATLAB's migration runtime
*translates* `String`, numeric `Value`, `ForegroundColor` and `TooltipString`, so those
sites are **not broken** — F1 is readability and deletion, not a bug hunt. After F2/F3,
or a large share of the churn lands on code F2 deletes.

### 4. The landing
No master merge and no tagged release until the migration is complete. `version.txt`
is already at v2.4.2 against a published v2.4.1, so every startup prints a nag.
The origin remote reports the repository has **moved** to `qMRLab/qMRLab.git`; pushes
still work through the redirect, but the URL is stale.

## Traps — each of these cost real time; do not relearn them

**Green tests are evidence only for code paths they execute.** The suite was 26/26
while "Fit data" was wired to nothing. Corollary burned again this session: 50 tests
were green while nothing had ever opened a Sim window.

**Look at a screenshot.** Found by looking, never by a test: `"View View"` in the menu
bar; grey boxes behind the compass letters; and this session, the dark grey gaps in the
Sim windows.

**The OS lies about its own appearance; MATLAB does not.** `defaults read -g
AppleInterfaceStyle` answered `Dark` on a desktop that was Light
(`NSApp.effectiveAppearance` = Aqua, MATLAB = light) — the key outlives the appearance.
`system` now asks MATLAB's theme setting, then a probe `uifigure`, and the OS only
below R2025a. Reverses the trap recorded in D9; see **D9a**.

**Duration is not blocking.** `verifyGreaterThan(elapsed, 1)` measures how fast the
*closer* is, not whether the call blocked — a correct implementation failed CI at
0.616 s. Blocking is an **ordering** claim: record when the window was closed on the
caller's clock and assert the call returned after it. Also assert the closer fired at
all, or the test passes having closed nothing.

**`findobj` cannot see the Sim windows.** All five carry
`HandleVisibility='callback'`. From a test body `findobj` returns empty and the
assertion passes vacuously. Use `findall`. `MainApp.m:1164` works only because it runs
inside a callback.

**Wait for the layout to be finished, not for a duration.** `geomAudit` re-runs the
audit until it finds nothing or a 10 s deadline expires. Placeholders clear at ~1.7 s
on `qsm_sb`, at which point three tables measure 17 px — 3 px under the floor — and
reach 27 px only at ~2.9 s. Waiting for placeholders alone, or for the geometry to
merely stop changing, both report defects that are gone a second later.

**`get(h,'Style')` on native components is worse than useless** — it throws on
checkboxes and buttons, and on a dropdown or table silently returns a *uistyle style
table*. Dispatch on `class(h)`. (Inside the legacy Sim figures `Style` is fine.)

**`set(h,'BackgroundColor','remove')` does not un-set a colour** — it freezes it.

**The options payload is frozen bit-for-bit.** `Model.options` lands in saved
`FitResults`; numeric options render in a **text** field and format with
`sprintf('%g')`, so **the formatting is the stored value**. `Test/GUI/tDSL.m` pins this
for all 22 models; `Test/GUI/KNOWN_BUGS.md` has the three preserved defects.

**Overflow inside a `Scrollable` container is not a defect.**

**`-batch` stdout is not trustworthy for probe output.** `GUI_animation` uses
`cprintf`, whose control characters swallow later lines — a probe that printed five
models' measurements showed one. Write probe results to a file with `fprintf(fid,...)`.

**A `.fig` is a v5 MAT-file.** `load(path,'-mat')` gives you `hgS_070000` —
`type`/`properties`/`children`, recursively — without running any `CreateFcn`.

## Open, small, and user-reported

- **"The Sim Tools buttons look off-centre."** Measured: they are, by 17 px, but only
  the *skeleton* ones. `MainApp.m` positions them in pixels for a 252 px panel
  (`:1735`) while the grid gives the panel 270 px; `Save Results` is 135 px off. The
  runtime buttons `MethodMenu` builds use normalized units and are exactly centred
  (11.7 px both sides). You only ever see the skeleton during the launch delay below,
  so the launch fix removes this symptom too. F3 deletes those buttons anyway.
- **"I see the blank template for a long time before the model loads."** The window is
  made visible at the end of `createComponents` (`MainApp.m:1875`), then
  `qMRLab_OpeningFcn` does ~8 s of work: `GUI_animation` alone is ~2 s of `pause()`
  calls, plus 90 web components (~3 s), `imtool3D` (1.5 s), `MethodBrowser` (1 s).
  **Decided with the maintainer: hold the window hidden until it is populated and show
  a loading bar.** `versionChecker` (two `api.github.com` calls) is on this path too.
- `imtool3D` chrome theming stays optional and low priority; the black canvas is
  deliberate (D9).

## Working practice that paid off

- **Prove a new test fails against the broken code.** Every test added this session was
  run against a mutant first — the shim deleted, `uiwait` removed, the popup seeding
  commented out. Three of them would otherwise have been vacuous.
- **Run one model, not the suite, while iterating.** `optionsWindowRendersEveryModel`
  and `datasetsPanelIsPopulatedForEveryModel` each loop all 22 models. Full suite once,
  before a commit: ~13 min for the whole of `Test/GUI`, and `tSimWindows` adds ~1 min.
- **Always `cd` to the repo in a `-batch` call.**
- **`Test/GUI/captureGoldens.m`** for the main and options windows,
  **`captureSimGoldens.m`** for the Sim windows; both write a PNG *and* a diffable
  inventory via `captureFigure.m`. Capture before an appearance change, not after.
- Guard Python slice-rewrites: an empty slice turned `str.replace` into "insert between
  every character" and destroyed `OptionsWindow.m` once. Assert the anchor matches
  exactly once before replacing.

## Map of the new code

```
qMRLab.m                                       35-line shim (mcc/list_models pin it)
src/Common/GUI/Custom_OptionsGUI.m             entry point for generated batch scripts
src/Common/GUI/+qmrlab/+gui/MainApp.m          1905  main window
                              OptionsWindow.m  1098  per-model options
                              OptionsRenderer.m 290  buttons DSL -> grid, native
                              Theme.m           363  light/dark + semantic tokens
                              TypeScale.m       340  user text size
src/Common/tools/parseButtons.m                 172  pure DSL parse, Octave-clean
src/Common/tools/qmrlabUIColor.m                 38  token transport for vendored code
src/Common/tools/qmrlabUIScale.m                     same, for text size
```

`Test/GUI/`: `tCapabilities` (15, platform assumptions), `tSimWindows` (12, the Sim
add-on windows), `tMainApp` (9), `tControls` (7), `tAPI` (7, entry-point contracts),
`tTheme` (7), `tDSL` (5). Helpers: `geomAudit`, `captureGoldens`, `captureSimGoldens`,
`captureFigure`, `resizeCheck`, `probeTheme`.
