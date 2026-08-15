# qMRLab GUI migration — handover

Written at the end of the session that got CI green and built the gate under Stage F2.
Read this, then `docs/adr/0001-gui-migration.md` (decisions D1–D9a), then the plan at
`~/.claude/plans/i-ve-got-a-very-expressive-boole.md`.

## Where things stand

Branch `mb/migrate-v2`, **pushed**, 37 commits ahead of master. `Test/GUI`: **62/62**
on R2026b (46 at the start of the session).

Done: Stages A, B, C, D1–D4, E1–E4, the F2 gate, and **four of F2's five windows**.
Not done: **Monte Carlo** (the fifth), F3, F1, then the merge and the tagged release.

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

### 1. F2 — four of five done; Monte Carlo is left

| file (under `src/Addons/`) | state |
|---|---|
| `SingleVoxel/Sim_Single_Voxel_Curve_GUI.m` | **rebuilt**, `.fig` deleted |
| `SimProtocolOpt/Sim_Optimize_Protocol_GUI.m` | **rebuilt**, `.fig` deleted |
| `SimRnd/Sim_Multi_Voxel_Distribution_GUI.m` | **rebuilt**, `.fig` deleted |
| `SimVary/Sim_Sensitivity_Analysis_GUI.m` | **rebuilt**, `.fig` deleted |
| `SimMonteCarlo_Diffusion/Sim_MonteCarlo_Diffusion_GUI.m` | **not started** (307 lines, 61 `handles.`) |

**The shape each rebuild takes**, established across the four and worth copying:

```
function varargout = X_GUI(Model)      % Model optional; falls back to appdata
    fig = findall(groot,'Type','figure','Tag','Simu','Name',NAME);
    if isempty(fig), fig = buildWindow(NAME); else, fig = fig(1); figure(fig); end
    showModel(fig, Model);             % runs on EVERY open, not once
```

`buildWindow` creates the components with the `.fig`'s own geometry; `showModel`
fills them from the model and rebuilds the options panel. Splitting it that way is
what fixed the stale-model defect: GUIDE did all of it once, behind
`~isfield(handles,'opened')`.

Read a `.fig` without instantiating it (loading one runs its `CreateFcn`s):

```matlab
s = load('src/Addons/.../X_GUI.fig', '-mat');
s.hgS_070000.children(1).properties    % type / properties / children, recursively
```

**Preserved in all four, and required:** `Tag='Simu'` (`MainApp.m:1164` tears these
down by it), the figure `Name` (the only thing telling the five apart), 
`HandleVisibility='callback'`, and every `handles.*` field name — including
`handles.Simu`. Nothing anywhere uses GUIDE's `('CALLBACK',...)` string form, so
`gui_State`/`gui_mainfcn` go outright.

**Deliberate, in all four:** the figure `Color` follows `qmrlabUIColor('viewerChrome')`
instead of a hard-coded `[0.251 0.251 0.251]` that a legacy figure will never theme;
the Update/Fit button uses the `accent` token; `ToolBar='figure'` replaces the two
custom tools, which were MATLAB's own annotation tools declared with
`ClickedCallback='%default'`. Where a help button existed it is APPENDED to the
standard toolbar — giving it its own `uitoolbar` costs a whole row.

**CHARACTER UNITS ARE THE BUG BEHIND MOST OF THIS.** A character is a font metric,
so a rectangle in characters is a different size on every machine. Measured here,
1 char = **7.035 x 15.0 px**. It is what made Optimize Protocol's table overflow on
Linux but not macOS, and it is what puts Monte Carlo's plot axes 60 px below its
panel (`-4.03333` chars). Convert by measuring the rendered geometry and dividing
by the parent's INNER size — not its outer rect, which differs by the title band.
Solve the inner size from a sibling whose normalized position the `.fig` stored.

### Monte Carlo, specifically

Everything needed is measured already:
`Test/GUI/evidence/before_F2/MONTECARLO_MEASURED_GEOMETRY.txt` has every component
with its parent, the parent's pixel size, and the **normalized** position to use.

It is the worst of the five, and it is broken TODAY on macOS — look at
`before_F2/charmed_SimMCdiff.png` before deciding what "faithful" means:

- Every label in the Axon Packing panel is vertically clipped: "# axons: 100",
  "mean diameter: 3um", "Diameter variance:", "Gap between axons:". They are
  `0.866667` characters tall, which is not enough for the text at this font.
- The Monte Carlo panel on the right is clipped the same way — "Permeability: 0",
  "Number of particles: 100", and "(stepflight^2 =" is cut mid-line.
- `tableVolumes` shows ~3.5 of its 4 rows with a scrollbar.
- `SimMCdiff` (the Plot Results axes) sits at normalized y = **-0.128**, hanging
  below its panel, which is the one Overflow `tSimWindows` reports and prints.

So this one needs a layout pass, not just a units conversion: converting faithfully
preserves the clipping. Give the labels the height their text needs, then convert.

Two runtime details found by measurement: `axes_axonDist` and `axes_axonPack` LOSE
their tags at runtime (the window ends up with three axes, two untagged), and the
`.fig`'s `preset_packing` String is the GUIDE placeholder `'Pop-up Menu'` — the real
list is built at open time from the packing `.mat` files.

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
