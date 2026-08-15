# qMRLab GUI migration — handover

Written at the end of the session that finished Stages F2 and F3. Read this, then
`docs/adr/0001-gui-migration.md` (decisions D1–D10), then the plan at
`~/.claude/plans/i-ve-got-a-very-expressive-boole.md`.

## Where things stand

Branch `mb/migrate-v2`, **pushed**, 51 commits ahead of master, open as **draft PR
#544**. `Test/GUI`: **62/62**, and CI green on all 11 jobs.

Read that carefully: CI runs `release: [R2026a, latest]` and `latest` currently
resolves to R2026a, so **CI runs R2026a twice and never runs R2026b**
(`.github/workflows/matlab.yml:134-147` — prereleases cannot be licensed through
`matlab-batch`). R2026b is the release this work is developed against and it is
verified **locally only**. Run it locally before believing a green build.

Done: Stages A, B, C, D1–D4, E1–E4, **F2** and **F3**.
Not done: **F1**, then the merge and the tagged release.

**There are zero `.fig` files left, anywhere.** GUIDE is gone from the
interface: the main window and Options window are `uifigure`s, and the five Sim
add-on windows are programmatic *legacy* figures, which is deliberate (D4/D10).

## First thing to check

The branch head has its own completed run and it is green on all 11 jobs, so there
is no inference to make: pick up F1 below.

When a GUI leg does go red, read the diagnostic before assuming the app is broken.
Four failures this session were **measurement bugs in the tests**, not defects:

- a duration (`elapsed > 1`) standing in for a blocking assertion,
- a geometry defect count hardcoded from macOS,
- twice: something that renders differently on the Linux runner than here.

Ask first whether the claim is platform- or timing-shaped. The real defects CI found
were worth having, so do not reach for the tolerance knob either.

## How to run it

MATLAB is at `/Applications/MATLAB_R2026a.app` and `/Applications/MATLAB_R2026b.app`.
**Always `cd` to the repo first** — a `-batch` call from elsewhere finds no tests and
fails with a confusing parse error.

```bash
cd /Users/mathieuboudreau/neuropoly/projects/qmrlab_gui_migration/qmrlab

# the whole GUI suite, the way CI runs it (~15 min)
/Applications/MATLAB_R2026b.app/bin/matlab -batch \
  "startup; r = runtests('Test/GUI','IncludeSubfolders',true); \
   fprintf('passed=%d failed=%d of %d\n',sum([r.Passed]),sum([r.Failed]),numel(r)); disp(table(r));"

# one file, or one test
... runtests('Test/GUI/tSimWindows.m')
... runtests('Test/GUI/tMainApp.m','ProcedureName','optionsWindowRendersEveryModel')

# evidence before an appearance change
... "startup; addpath('Test/GUI'); captureGoldens('Test/GUI/evidence/before_X')"
... "startup; addpath('Test/GUI'); captureSimGoldens('Test/GUI/evidence/before_X')"
diff -ru Test/GUI/evidence/before_X Test/GUI/evidence/after_X   # the .txt files
```

Runs take minutes; start them in the background rather than blocking on them. CI:
`gh run list --branch mb/migrate-v2`, then `gh run view <id> --log-failed`.

## What is left

### 1. F1 — retire the `handles` shim  ← the only engineering stage left

The plan scoped this as "~105 sites, all in the main app". Measured, it splits in
two, and the split is what makes it tractable:

| in `MainApp.m` | names | uses | what it takes |
|---|---|---|---|
| components with an app property | 11 | 45 | mechanical: `handles.X` → `app.X` |
| runtime state living in `guidata` | 9 | 57 | promote to properties first |

The state names are `tool` (27 uses), `CurrentData` (9), `dcm_obj` (7), `ModelDir`
(5), `Default` (5), `SimFileName`, `ProtFileName`, `FitOptFileName`, `opened`.

Four things the table does not show, each of which will bite:

- **Those 45 + 57 = 102 are not all of them.** `MainApp.m` holds 104. The other two
  are built by string at `MainApp.m:379` and `:383` —
  `eval(sprintf('set(handles.%sPanel, ''Visible'', ''off'')', panel))` — and no
  name-driven rewrite will find them.
- **`OptionsWindow.m` pins the shim too.** `convertToGUIDECallbackArguments` is
  called **16×** in `MainApp.m` and **4×** in `OptionsWindow.m` (`:822, :833, :843,
  :863`). `OptionsWindow` has zero `handles.` uses — they are pure destructuring —
  but clearing MainApp alone and deleting the shim breaks the options window. The
  function is not defined in this repo; it is inherited from `matlab.apps.AppBase`,
  which both classes still extend.
- **Five helpers take a `handles` struct and are live**, not four:
  `src/Common/tools/GUIfun/{DrawPlot,UpdateSlice,UpdatePopUp,GetMethod}.m` plus
  `FileBrowser/BrowserSet.m`. `GetMethod` is the one that is easy to miss — called
  from `MainApp.m:849`, `:861`, `:959`, and it reads `handles.MethodSelection`.
  (Careful: `MethodBrowser.m:216` defines an unrelated class method of the same
  name.)
- **Three of them write back into the main window's guidata from outside the app**:
  `DrawPlot.m:79`, `UpdatePopUp.m:23` and `GetPlotRange.m:41` all end with
  `guidata(findobj('Name','qMRLab'), handles)`, and `BrowserSet.m:395` reads it the
  same way. That round trip is the actual coupling to break, not the field names.

**Start with the dead code — four files, not one.** `GetPlotRange.m`, `ClearAxes.m`
and `RefreshColorMap.m` have no callers at all, and `GetCurrent.m`'s only caller is
`GetPlotRange.m:4`, so it dies with them. That is the cheapest win in the stage and
it shrinks everything above.

**The five Sim windows are NOT part of this.** They hold 375 of the repository's
`handles.` references and they keep them: they are legacy figures by decision, and
`guidata` is the native idiom there, not a shim to retire.

Convert each component in the same commit as its call sites. `handles.X` and `app.X`
coexist happily during the change, so a half-finished conversion fails silently
rather than loudly — keep the commits small and run the suite.

### 2. The landing

Merge to master and tag. `version.txt` is at v2.4.2 against a published v2.4.1, so
every startup prints a nag about it. The origin remote is
`https://www.github.com/qmrlab/qmrlab`, and the `www.` prefix makes every push
print a redirect warning — the repository has **not** moved and the path is
unchanged. `git remote set-url origin https://github.com/qMRLab/qMRLab.git` silences
it.

### Deferred, scoped, optional

**The launch shows an empty shell for ~8 s, and the fix was reverted.** Measured:
`createComponents` makes the figure visible at `MainApp.m:1875` and *then*
`qMRLab_OpeningFcn` does the work — the model, 90 web components, `imtool3D`
(1.5 s), `MethodBrowser` (1 s), and `GUI_animation` (~2 s of `pause()` calls).

Holding the figure at `Visible='off'` until it is populated **does not work**: its
components have no laid-out size while they are built, and `imtool3D` fails setting
`PlotBoxAspectRatio` to a non-finite value. That took down **9 tests on the R2026a
leg and 10 on `latest`** (run `31883579983`) — not the one or two you would expect,
and not the same set on each leg. It passed 62/62 on macOS first.

So the mechanism has to change, not the details: **build the window on screen but
positioned off the visible desktop, and move it back at reveal**,
which keeps the geometry real. Verify on a runner — here is where it looked fine.

The maintainer's preference, still standing: hold the window, show a loading bar.
This is also what makes the **Sim Tools buttons look off-centre**. The skeleton
buttons are pixel-positioned for a 252 px panel (`MainApp.m:1735`) that the grid
gives 270 px (`:1246`), so a button at `[13 … 227 …]` ends up with a 13 px gap on
the left and 30 on the right — 8.5 px off centre, and a 17 px difference between the
two gaps. `Save Results` is the left half of a two-button row with `Load Results`
(`:1766`, `:1774`), so it is not centred on anything; its gaps are 13 and 148. The
runtime buttons `MethodMenu` builds are normalized and exactly centred. One fix, two
symptoms.

**Monte Carlo label sizing.** Its rebuild converted units and fixed its axes; the
labels still get only the box the `.fig` gave them. Deliberately scoped out.

## Traps — each of these cost real time; do not relearn them

**Green tests are evidence only for the code paths they execute.** Burned three
times now. The suite was 26/26 while "Fit data" was wired to nothing; 50 tests were
green while nothing had ever opened a Sim window; and `monteCarloBuildsItsPackingControls`
asserted three axes existed and passed against three *empty* ones.

**Look at a screenshot.** Everything in the previous paragraph was found by looking.
Monte Carlo's packing plots came up empty with no error anywhere, and the diffable
inventory could not show it either — only the PNG did.

**`HandleVisibility='callback'` breaks `axes(h)` from outside a callback.** MATLAB
will not make such a figure current, so `bar`/`plot` silently open a *new* figure
and draw there. GUIDE never hit this because `gui_mainfcn` is itself a callback
context. `Sim_MonteCarlo_Diffusion_GUI` lifts the restriction while it populates and
restores it after.

**Character units are a font metric.** A `Position` in `Units='characters'` is a
different rectangle on every machine — measured here, 1 char = 7.035 × 15.0 px. It
made a table fit its panel on macOS and overflow by 15 px on Linux, and put an axes
60 px below its panel. Convert by dividing measured pixels by the parent's **inner**
size (solve for it from a sibling whose normalized position the `.fig` stored), not
its outer rect, which differs by the title band.

**The OS lies about its own appearance; MATLAB does not.** `defaults read -g
AppleInterfaceStyle` answered `Dark` on a desktop that was demonstrably Light
(`NSApp.effectiveAppearance` = Aqua). `system` asks MATLAB's theme setting, then a
probe `uifigure`, and the OS only below R2025a. This *reverses* what D9 recorded;
see **D9a**.

**Blocking is an ordering claim, not a duration.** `verifyGreaterThan(elapsed, 1)`
measures how fast the *closer* is; a correct implementation failed CI at 0.616 s.
Record when the window was closed on the caller's clock and assert the call returned
after it — and assert the closer fired at all, or the test passes having closed
nothing.

**`findobj` cannot see the Sim windows.** All five are `HandleVisibility='callback'`,
so from a test body `findobj` returns empty and the assertion passes vacuously. Use
`findall`. `MainApp.m:1164` works only because it runs inside a callback.

**Wait for the layout to finish, not for a duration.** `geomAudit` re-runs the audit
until it finds nothing or a 10 s deadline expires. On `qsm_sb`, placeholders clear at
~1.7 s, at which point three tables measure 17 px — under the 20 px floor — and reach
27 px only at ~2.9 s. (`geomAudit.m:38` still justifies the deadline as "~6x the
worst convergence measured here (qsm_sb, 1.6 s)", which predates that second
measurement; the deadline is fine, the ratio in the comment is not.)

**`get(h,'Style')` on native components is worse than useless** — it throws on
checkboxes and buttons, and on a dropdown or table silently returns a *uistyle style
table*. Dispatch on `class(h)`. Inside the legacy Sim figures, `Style` is fine.

**`set(h,'BackgroundColor','remove')` does not un-set a colour** — it freezes it.

**The options payload is frozen bit-for-bit.** `Model.options` lands in saved
`FitResults`; numeric options render in a **text** field and format with
`sprintf('%g')`, so **the formatting is the stored value**. `Test/GUI/tDSL.m` pins
this for all 22 models; `Test/GUI/KNOWN_BUGS.md` has the three preserved defects.

**Overflow inside a `Scrollable` container is not a defect.**

**`-batch` stdout is not trustworthy for probe output.** `GUI_animation` uses
`cprintf`, whose control characters swallow later lines — a probe that printed five
models' measurements showed one. Write probe results to a file with `fprintf(fid,…)`.

**A `.fig` is a MAT v5 file.** `load(path,'-mat')` gives `hgS_070000` —
`type`/`properties`/`children`, recursively — without running any `CreateFcn`.
Properties stored *empty* matter: `RowName={}` is what suppresses a table's row
numbers, and omitting it silently numbers them.

## Working practice that paid off

- **Prove a new test fails against the broken code.** Every test added this session
  was run against a mutant first — the shim deleted, `uiwait` removed, the popup
  seeding commented out. Three would otherwise have been vacuous.
- **Measure, then write the number down.** The unit conversions, the launch profile
  and the F1 scope above are counts, not estimates. Where a count was guessed, it
  was wrong.
- **Run one model, not the suite, while iterating.** Full suite once before a commit:
  ~15 min for `Test/GUI`.
- **Always `cd` to the repo in a `-batch` call.** A backgrounded chain that loses the
  working directory fails with a confusing "Unrecognized function" instead.
- **Capture goldens before an appearance change, not after.**
  `Test/GUI/captureGoldens.m` for the main and options windows,
  `captureSimGoldens.m` for the Sim windows; both write a PNG *and* a diffable
  inventory via `captureFigure.m`. Evidence is in `Test/GUI/evidence/`, including
  `before_F2/` and `after_F2/`.
- Guard Python slice-rewrites: assert the anchor matches exactly once before
  replacing. An empty slice once turned `str.replace` into "insert between every
  character" and destroyed `OptionsWindow.m`.

## Map of the code

```
qMRLab.m                                        65  shim (mcc/list_models pin it)
src/Common/GUI/Custom_OptionsGUI.m             139  entry point for batch scripts
src/Common/GUI/+qmrlab/+gui/MainApp.m         1913  main window
                              OptionsWindow.m 1108  per-model options
                              OptionsRenderer.m 290  buttons DSL -> grid, native
                              Theme.m          362  light/dark + semantic tokens
                              TypeScale.m      340  user text size
src/Common/tools/parseButtons.m                172  pure DSL parse, Octave-clean
src/Common/tools/qmrlabUIColor.m                38  token transport for vendored code
src/Common/tools/GenerateButtonsWithPanels.m        legacy options builder -- STAYS,
                                                    see D10: the Sim windows need it

src/Addons/SingleVoxel/Sim_Single_Voxel_Curve_GUI.m                269
src/Addons/SimProtocolOpt/Sim_Optimize_Protocol_GUI.m              295
src/Addons/SimVary/Sim_Sensitivity_Analysis_GUI.m                  324
src/Addons/SimRnd/Sim_Multi_Voxel_Distribution_GUI.m               381
src/Addons/SimMonteCarlo_Diffusion/Sim_MonteCarlo_Diffusion_GUI.m  471
```

All five Sim windows follow the same shape, and reading one is the fastest way in:

```matlab
function varargout = X_GUI(Model)       % Model optional; falls back to appdata
    fig = findall(groot,'Type','figure','Tag','Simu','Name',NAME);
    if isempty(fig), fig = buildWindow(NAME); else, fig = fig(1); figure(fig); end
    showModel(fig, Model);              % runs on EVERY open, not once
```

`buildWindow` creates the components; `showModel` fills them from the model and
rebuilds the options panel. Splitting it that way is what fixed the stale-model
defect — GUIDE did all of it once, behind `~isfield(handles,'opened')`, so opening a
window on one model and then another left it simulating the first.

`Test/GUI/` — 62 tests: `tCapabilities` (15, platform assumptions), `tSimWindows`
(12, the Sim add-on windows), `tMainApp` (9), `tAPI` (7, entry-point contracts),
`tControls` (7), `tTheme` (7), `tDSL` (5, the DSL contract). Helpers: `geomAudit`,
`captureGoldens`, `captureSimGoldens`, `captureFigure`, `resizeCheck`, `probeTheme`.
