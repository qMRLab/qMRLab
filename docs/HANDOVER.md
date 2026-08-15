# qMRLab GUI migration — handover

Written at the end of the session that fixed the sizing defects the maintainer
reported after F3. Read this, then `docs/adr/0001-gui-migration.md` (decisions
D1–D12), then the plan at `~/.claude/plans/i-ve-got-a-very-expressive-boole.md`.

## Where things stand

Branch `mb/migrate-v2`, **pushed**, 72 commits ahead of master, open as **draft PR
#544** (`MERGEABLE`). `Test/GUI`: **67**, green on R2026b locally and on all 11 CI
jobs.

Done: Stages A, B, C, D1–D4, E1–E4, **F1**, **F2**, **F3**, plus the post-F3 defect
batch below. Not done: **the merge and the tagged release**. That is the only
stage-level work left.

**CI cannot run R2026b, and this is deliberate.** `.github/workflows/matlab.yml:134-147`
pins `release: [R2026a, latest]`; R2026b is a prerelease and prereleases cannot be
licensed through `matlab-batch`, so the leg would fail on licensing rather than on
code. `latest` currently resolves to R2026a as well, so **CI runs R2026a twice and
never runs R2026b**. R2026b is the release this work is developed against. A green
CI is therefore necessary and not sufficient — **run the suite locally on R2026b
before believing a build**, and add the R2026b leg on the day it ships.

**The GUIDE shim is gone.** `convertToGUIDECallbackArguments` is called zero times,
no `handles` struct is passed anywhere in the two `uifigure` windows or the helpers
they call, and `Test/GUI/tAPI.m/theGuideShimIsGone` fails if any of it comes back.
The five Sim add-on windows keep their `handles` structs by decision (D4/D10) —
there `guidata` is the native idiom, not a shim.

**There are zero `.fig` files left, anywhere.** The main and Options windows are
`uifigure`s; the five Sim add-on windows are programmatic *legacy* figures, which
is deliberate (D4/D10).

## First thing to check

`gh run list --branch mb/migrate-v2`. The branch head has its own run; if it is
green, pick up "The landing" below.

When a GUI leg goes red, read the diagnostic before assuming the app is broken.
Five failures across these sessions were **measurement bugs in the tests**, not
defects:

- a duration (`elapsed > 1`) standing in for a blocking assertion,
- a geometry defect count hardcoded from macOS,
- twice: something that renders differently on the Linux runner than here,
- a regexp that ate the file it was scanning, so the scan passed vacuously.

Ask first whether the claim is platform- or timing-shaped. The real defects CI
found were worth having, so do not reach for the tolerance knob either.

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

Runs take minutes; start them in the background rather than blocking on them. Write
probe output to a file, not stdout — see the `cprintf` trap below. CI:
`gh run list --branch mb/migrate-v2`, then `gh run view <id> --log-failed`.

## What is left

### The landing

Merge to master and tag. Three chores go with it:

- `version.txt` is at **v2.4.2** against a published **v2.4.1**, so every startup
  prints a nag (`ಠ_ಠ The version specified in version.txt is ahead of the latest
  published release`). Tagging on merge clears it.
- The origin remote is `https://www.github.com/qmrlab/qmrlab`, and the `www.`
  prefix makes every push print a redirect warning. The repository has **not**
  moved and the path is unchanged.
  `git remote set-url origin https://github.com/qMRLab/qMRLab.git` silences it.
- PR #544 is still a **draft**. It needs marking ready.

### Deferred, scoped, optional

#### The ~8 s empty launch — attempted twice, reverted twice

This is the one open defect with real history. **Do not attempt a third time
without reading all of it.**

Measured: `createComponents` makes the figure visible at `MainApp.m:1875`, and
*then* `qMRLab_OpeningFcn` does the work — the model, 90 web components,
`imtool3D` (1.5 s), `MethodBrowser` (1 s), and `GUI_animation` (~2 s of `pause()`).

**Attempt 1 — `26777cc`, reverted by `f9cfdaa`.** Held the figure at `Visible='off'`
until populated. Hidden components have no laid-out size, so `imtool3D` computed a
non-finite `PlotBoxAspectRatio` and MATLAB rejected it. Took down **9 tests on the
R2026a leg and 10 on `latest`** — not the same set on each leg — after passing
62/62 on macOS.

**Attempt 2 — `b44757c`, reverted by `dba9863`.** Used the mechanism the first
revert recommended: park the window off the bottom of the desktop, laid out and
visible, and move it back at reveal. **The mechanism is sound and is not what
failed** — `imtool3D` measured `PlotBoxAspectRatio = [1 1 2]`, finite, with the
park in place. Three separate faults killed it, and the maintainer found two within
minutes:

1. **The template still showed.** The park sat in the "SET WINDOW AND PANELS" block
   inside `qMRLab_OpeningFcn`, far later than `createComponents` where the figure is
   first made visible. Sampling position every 0.4 s through a launch caught it
   on screen twice before the park took: `[283 -771 …]` parked → `[283 31 …]` **on
   screen** → `[133 47 …]` **on screen** → `[133 -836 …]` parked → revealed.
2. **The Options window went with it.** `OptionsWindow` positions itself relative to
   its caller, and the caller was parked. Measured `[1259 -834 573 835]` — one pixel
   on screen. Reported as "the entire options window is shorter"; it is not shorter,
   it is off the desktop.
3. **The splash collided by name.** The splash `uifigure` was given `Name 'qMRLab'`,
   the same name the main window carries, so
   `findall(groot,'Type','figure','Name','qMRLab')` can match the splash instead of
   the app. Several call sites and test helpers resolve the main window exactly
   that way.

**So a third attempt needs all three constraints, as one commit written against
them** — not a patch on the second: park at the point of **first visibility** inside
`createComponents`; position the Options window against the **revealed** geometry;
give the splash **its own name**.

**And note what the suite did.** It was green — 62/62, then 64/64, three times
across this feature — every time. `tMainApp/everyWindowLandsOnScreen` was added
afterwards (`a033ced`) and fails against the shipped build, naming it exactly:

```
OptionsGUI "OptionsGUI" at [1259 -834 573 835] (211x0 px on a 1470x956 screen)
```

It is deliberately generous — 80 px of a window must be on the desktop — because it
is not a layout assertion. It should fail only when a window is effectively gone.
Verify a third attempt against a runner, not only here.

The maintainer's preference, still standing: hold the window, show a loading bar.
The interim state is `b24da53` — the panel shows one muted "Loading…" label instead
of six dead buttons — which fixed the *appearance* of the empty shell but not the
wait itself.

#### Monte Carlo label sizing

Its rebuild converted units and fixed its axes; the labels still get only the box
the `.fig` gave them. Deliberately scoped out.

#### The 47 magic `FontSize` numbers are whole point sizes in disguise

Every `FontSize = 13.3333333333332`-style literal in `MainApp.m` and
`OptionsWindow.m` is a GUIDE point size converted to pixels at 96 dpi — a flat
`× 4/3` — frozen into the generated `createComponents`. Measured on R2026b:

| | FontUnits | default |
|---|---|---|
| GUIDE `uicontrol` | **points** | 8 |
| App Designer `uilabel`/`uibutton` | **no such property** (pixels) | 12 |

```
 8 pt -> 10.6666666666667      12 pt -> 16          <- the only integer,
10 pt -> 13.3333333333333      14 pt -> 18.6666666666666    which is why 16
11 pt -> 14.6666666666667                                   looks "normal"
```

- **The trailing digits disagree.** One size, 10 pt, appears as four distinct
  doubles: `...3333`, `...3332`, `...3331`, `...3329`. Computed as `10*4/3` they
  would be bit-identical, so each went through a different arithmetic path — almost
  certainly a normalized-`FontUnits` round trip in the `.fig`. Same family as the
  character-units problem in D10.
- **One value is not a point size at all.** `MethodSelection` carries
  `12.570970970971` = 9.428 pt. Every other literal in both files is a whole point
  size.

Nothing is load-bearing: `TypeScale.apply` scales multiplicatively and leaves
`FontUnits` untouched (`TypeScale.m:90`), so the arithmetic is unit-invariant and
this has never produced a visible defect. Rounding them to `{11, 13, 15, 16, 19}` px,
or naming them as steps on `qmrlab.gui.TypeScale`, would make both files readable at
zero behavioural cost. Kept out of F1 to avoid putting cosmetic churn in the same
diff as the shim retirement.

## Resolved since the last handover

The maintainer reported four defects after F3; all four are fixed, and each fix
carries a measurement worth keeping.

**Tables were sized by one constant for every model** (`7e66a7b`, `e366935`).
Protocol tables were a flat 130 px — about four rows — while `inversion_recovery`'s
`IRData` has 9 and `qmt_spgr`'s `MTdata` has 10, so the majority of both sat behind
an internal scrollbar. The Fitting table clipped the same way by a different
mechanism: it was not grid-managed at all, carrying an absolute
`Position = [4 9 248 159]` inside a panel pinned by `RightGrid.RowHeight = {196,'1x'}`,
so it neither filled its panel nor scaled with the text-size preference.

- `OptionsWindow.tableHeightFor(nRows)` now sizes both. Measured on R2026b: a
  `uitable` in a `'fit'` row is 2 rows → 77 px, 3 → 100, 5 → 147, 10 → 263 — about
  **23.2 px per row over ~31 px of header and border**.
- It **clamps in rows, not pixels**, at 3 and 12. The ceiling matters more than it
  looks: `dti`'s `DiffusionData` has 109 rows and `charmed`'s has **1791** — sized
  to content those tables would be the entire window.
- The height stays **fixed rather than `'1x'`**. `ProtEditGrid`'s rows are `'fit'`,
  so `'1x'` has nothing to divide and the table collapses to zero — which is what
  `mp2rage`'s five panels did the last time this was touched. `mp2rage` is worth
  checking explicitly on any change here.
- It scales with `TypeScale.geomFactor`, for the same reason `MethodBrowser.heightFor`
  does: rows grow with the text-size preference and a pixel constant clips again at
  the larger steps.
- `panelChrome` is `Position(4) - InnerPosition(4)`. Measuring against a *child*
  instead makes the answer depend on the thing being sized, so it grows on every
  call — `MainApp.browserChrome` documents the same trap.

**What looks like a regression there and is not:** `mp2rage` and `b1_afi` now report
a Fitting table of height **0**. That is correct and the old number was the lie —
neither model defines an `equation` method, so `renderOptions` hides the panel with
`RightGrid.RowHeight{1} = 0`, while the absolutely positioned table went on
reporting 159 px because its `Position` was independent of the panel that was no
longer showing it.

**The Sim tools panel reserved space for buttons that do not exist** (`a033ced`).
"Open Options Panel" sat below the fold: the sidebar's rows came to 849 px inside an
821 px column, so the last row landed at `y = -19`, outside a `SideGrid` spanning
9..830 — and the grid is `Scrollable`, so it was reachable but invisible. Two causes,
both needed fixing: the track was a flat 351 px for every model, and `MethodMenu`
laid buttons out over `max(N,6)` slots. No model has more than five (`charmed`); the
median is three. Now sized from the count at **48 px per slot** — at the old 58,
`charmed` still failed at `y = -30`. Models with *no* Sim tools (`mp2rage`, `b1_afi`,
`qsm_sb`) hid the panel but kept its 351 px track; that space comes back.
`applyTypeGeometry` rewrote `SideGrid.RowHeight` as a wholesale literal, which would
have undone all of it on the next text-size change — it now calls the same
`simPanelHeight`, so the two cannot drift.

**"Path data" silently ignored typed input** (`5de4cf7`). The box had no callback, so
the only way to set the working directory was the Browse dialog — exactly the defect
`tControls/typingAPathIntoAFileBoxLoadsIt` pins for the per-input file boxes, one row
up in the same panel. It stayed invisible because **the wiring audit cannot flag a
control that is legitimately callback-free**: the box was named in
`tControls.InertByDesign` with the reason "written by Browse, read at load time" —
true when written, and wrong. `WD_PathTyped` validates with `exist(…,'dir')` before
reaching `dir()`, reports through `errordlg`, and treats an emptied box as a no-op.

**Six dead skeleton buttons, off-centre** (`b24da53`). The Simulation tools panel
showed six buttons for the ~8 s the opening function takes. All six were dead — no
callback, no reference outside `createComponents` — and `MethodMenu` deletes every
child of the panel before building the real ones. They were also the off-centre
ones, positioned `[13 … 227 …]` for the 252 px panel the `.fig` had rather than the
270 px the grid gives. **The "empty template looks wrong" report and the "Sim Tools
buttons look off-centre" report were one cause.** Replaced with a single muted
centred label, which needs no teardown because `MethodMenu`'s existing `delete`
disposes of it.

## Traps — each of these cost real time; do not relearn them

**Green tests are evidence only for the code paths they execute.** Burned four times
now. The suite was 26/26 while "Fit data" was wired to nothing; 50 tests were green
while nothing had ever opened a Sim window; `monteCarloBuildsItsPackingControls`
asserted three axes existed and passed against three *empty* ones; and 64 tests plus
all 11 CI jobs were green while the Options window rendered one pixel on screen.

**A window you cannot see is not a passing test.** Nothing asserted where a window
*ends up* — only that its components exist and are the right size.
`tMainApp/everyWindowLandsOnScreen` now does.

**Look at a screenshot.** Almost everything in the previous two paragraphs was found
by looking. Monte Carlo's packing plots came up empty with no error anywhere, and
the diffable inventory could not show it either — only the PNG did.

**A green suite that straddles an edit means nothing.** MATLAB loads `.m` files at
first call, so a run started before a change tests a mixture. One such run reported
63/63 on a tree still being edited. Re-run clean before believing it.

**`HandleVisibility='callback'` breaks `axes(h)` from outside a callback.** MATLAB
will not make such a figure current, so `bar`/`plot` silently open a *new* figure and
draw there. GUIDE never hit this because `gui_mainfcn` is itself a callback context.
`Sim_MonteCarlo_Diffusion_GUI` lifts the restriction while it populates and restores
it after.

**`findobj` cannot see the Sim windows.** All five are `HandleVisibility='callback'`,
so from a test body `findobj` returns empty and the assertion passes vacuously. Use
`findall`. `MainApp.m:1164` works only because it runs inside a callback.

**Character units are a font metric.** A `Position` in `Units='characters'` is a
different rectangle on every machine — measured here, 1 char = 7.035 × 15.0 px. It
made a table fit its panel on macOS and overflow by 15 px on Linux, and put an axes
60 px below its panel. Convert by dividing measured pixels by the parent's **inner**
size (solve for it from a sibling whose normalized position the `.fig` stored), not
its outer rect, which differs by the title band.

**The OS lies about its own appearance; MATLAB does not.** `defaults read -g
AppleInterfaceStyle` answered `Dark` on a desktop that was demonstrably Light
(`NSApp.effectiveAppearance` = Aqua). `system` asks MATLAB's theme setting, then a
probe `uifigure`, and the OS only below R2025a. This *reverses* what D9 recorded; see
**D9a**.

**Blocking is an ordering claim, not a duration.** `verifyGreaterThan(elapsed, 1)`
measures how fast the *closer* is; a correct implementation failed CI at 0.616 s.
Record when the window was closed on the caller's clock and assert the call returned
after it — and assert the closer fired at all, or the test passes having closed
nothing.

**Wait for the layout to finish, not for a duration.** `geomAudit` re-runs the audit
until it finds nothing or a 10 s deadline expires. On `qsm_sb`, placeholders clear at
~1.7 s, at which point three tables measure 17 px — under the 20 px floor — and reach
27 px only at ~2.9 s. (`geomAudit.m:38` still justifies the deadline as "~6x the worst
convergence measured here (qsm_sb, 1.6 s)", which predates that second measurement;
the deadline is fine, the ratio in the comment is not.)

**`get(h,'Style')` on native components is worse than useless** — it throws on
checkboxes and buttons, and on a dropdown or table silently returns a *uistyle style
table*. Dispatch on `class(h)`. Inside the legacy Sim figures, `Style` is fine.

**`set(h,'BackgroundColor','remove')` does not un-set a colour** — it freezes it.

**`isfield(handles,'X')` is invisible to a `handles.X` rewrite**, because the field
name is a string literal. After the state moved to app properties, one such guard was
permanently *false* and cursor mode could never be switched off — inside a `try/catch`
that swallowed into a stubbed dialog. `isprop(app,…)` is equally wrong in the other
direction (permanently true). `isempty(app.DataCursor)` is the only correct
translation.

**`regexprep(txt,'(?m)^\s*%.*$','')` eats the whole file.** `\s` matches newlines, so
the match runs away: `MainApp.m` went 85766 characters → 39. The first version of
`theGuideShimIsGone` scanned that empty string and passed with a `handles.` site
deliberately reintroduced. Drop comments line-by-line, and give the test a
denominator.

**The options payload is frozen bit-for-bit.** `Model.options` lands in saved
`FitResults`; numeric options render in a **text** field and format with
`sprintf('%g')`, so **the formatting is the stored value**. `Test/GUI/tDSL.m` pins
this for all 22 models; `Test/GUI/KNOWN_BUGS.md` has the three preserved defects.

**A 1 px diff in the Sim goldens is noise, not a change.**
`charmed_SingleVoxelCurve`'s first `UIControl` renders at `@162,783` or `@161,783`
depending on the run — measured by capturing the *identical* tree twice and getting
both. If a Sim golden differs by one pixel on one control, recapture before
investigating. Anything larger, or in more than one control, is real.

**Overflow inside a `Scrollable` container is not a defect** — but it is also how the
Sim panel bug hid: reachable by scrolling, invisible on open.

**`-batch` stdout is not trustworthy for probe output.** `GUI_animation` uses
`cprintf`, whose control characters swallow later lines — a probe that printed five
models' measurements showed one. Write probe results to a file with `fprintf(fid,…)`.

**A `.fig` is a MAT v5 file.** `load(path,'-mat')` gives `hgS_070000` —
`type`/`properties`/`children`, recursively — without running any `CreateFcn`.
Properties stored *empty* matter: `RowName={}` is what suppresses a table's row
numbers, and omitting it silently numbers them.

## The F1 conversion, for a future reader

**`handles.X` was never an alias for `app.X`.** The shim wrapped every tagged
component in a `UIControlPropertiesConverter` that TRANSLATED GUIDE property names.
Each site needed a translation, not a rename:

| GUIDE, through the shim | native |
|---|---|
| `set(uilabel,'String',x)` | `uilabel.Text = x` — uilabel has no `String`; `set` throws |
| `set(uibutton,'TooltipString',x)` | `uibutton.Tooltip = x` — **not** `.Text`, which is the caption |
| `get(dropdown,'String')` | `.Items` |
| `get(dropdown,'Value')` | an index **only because of `ItemsData`** — see ADR D11 |
| `uipanel`/`uifigure` `Visible`/`Position` | unchanged; containers were never adapter-wrapped |

**Runtime state is on the app now** — `Tool`, `CurrentData`, `DataCursor`, `ModelDir`,
`DefaultMethodFile`, `Opened`. Every `guidata` publish went with them, including the
two cross-window write-backs in `DrawPlot` and `UpdatePopUp`, and `BrowserSet`
resolves the app with `ancestor(obj.Parent,'figure').RunningAppInstance` instead of
`guidata(findobj('Name','qMRLab'))`.

**`matlab.apps.AppBase` stays.** `convertToGUIDECallbackArguments` was *not* inherited
from it — it is a free function at
`toolbox/matlab/appdesigner/runtime/convertToGUIDECallbackArguments.m`. AppBase
supplies `createCallbackFcn`, `registerApp`, `runStartupFcn` and `getRunningApp`, all
still used. Retiring the shim and dropping AppBase are unrelated questions.

**Removing the shim did not unwire anything — it wired things more directly.** All
callbacks are installed natively by `createCallbackFcn` in `createComponents`; the
adapter merely mirrored them, and for dropdowns it *nulled* the native
`ValueChangedFcn` and drove `ClickedFcn` instead. See ADR D12 for the one
user-visible behaviour change that follows.

## Working practice that paid off

- **Prove a new test fails against the broken code.** Every test added across these
  sessions was run against a mutant first — the shim deleted, `uiwait` removed, the
  popup seeding commented out, the parked build restored. Four would otherwise have
  been vacuous.
- **Measure, then write the number down.** The unit conversions, the launch profile,
  the per-row table height and the slot arithmetic above are counts, not estimates.
  Where a count was guessed, it was wrong.
- **Fix the cause, not the symptom.** The dead skeleton buttons were two reported
  defects with one cause; the squished tables were one report with two mechanisms and
  needed two commits. Check which you have before writing either.
- **Run one model, not the suite, while iterating.** Full suite once before a commit:
  ~15 min for `Test/GUI`.
- **Always `cd` to the repo in a `-batch` call.** A backgrounded chain that loses the
  working directory fails with a confusing "Unrecognized function" instead.
- **Capture goldens before an appearance change, not after.**
  `Test/GUI/captureGoldens.m` for the main and options windows, `captureSimGoldens.m`
  for the Sim windows; both write a PNG *and* a diffable inventory via
  `captureFigure.m`. They land in `Test/GUI/evidence/`, which is **gitignored** — they
  are a before/after pair you compare while making a change, nothing reads them, and
  as commits they are 22 MB of review noise whose pixels shift with the machine that
  rendered them. Capture your own baseline before you start; do not expect to find one
  in the tree.
- Guard Python slice-rewrites: assert the anchor matches exactly once before
  replacing. An empty slice once turned `str.replace` into "insert between every
  character" and destroyed `OptionsWindow.m`.

## Map of the code

```
qMRLab.m                                        65  shim (mcc/list_models pin it)
src/Common/GUI/Custom_OptionsGUI.m             139  entry point for batch scripts
src/Common/GUI/+qmrlab/+gui/MainApp.m         1913  main window
                              OptionsWindow.m 1145  per-model options
                              OptionsRenderer.m 290  buttons DSL -> grid, native
                              Theme.m          362  light/dark + semantic tokens
                              TypeScale.m      341  user text size
src/Common/tools/parseButtons.m                172  pure DSL parse, Octave-clean
src/Common/tools/qmrlabUIColor.m                38  token transport for vendored code
src/Common/tools/FileBrowser/MethodBrowser.m        file boxes + working directory
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

`Test/GUI/` — 67 tests: `tCapabilities` (15, platform assumptions), `tSimWindows`
(12, the Sim add-on windows), `tMainApp` (11), `tControls` (9), `tAPI` (8,
entry-point contracts), `tTheme` (7), `tDSL` (5, the DSL contract). Helpers:
`geomAudit`, `captureGoldens`, `captureSimGoldens`, `captureFigure`, `resizeCheck`,
`probeTheme`.
