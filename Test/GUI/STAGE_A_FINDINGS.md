# Stage A findings — GUI migration capability probe

Run on **MATLAB R2026b Prerelease Update 1 (26.2.0.3281582)** and **R2026a**, `maca64`
(Apple Silicon), headless via `matlab -batch`. Reproduce with:

```matlab
startup
runtests('Test/GUI/tCapabilities.m')      % 15/15 expected
```

Status: **15 / 15 green on both R2026b and R2026a.**

## Headline result

**imtool3D constructs and works inside an App Designer `uifigure` panel.** This was
the single highest-risk assumption in the migration plan — if it had failed, the
whole "keep the viewer embedded" decision would have collapsed and the project would
have needed a viewer rewrite.

It needs **three one-line patches**, documented in
[`External/imtool3D_td/QMRLAB_PATCHES.md`](../../External/imtool3D_td/QMRLAB_PATCHES.md).
After patching, inside a `uifigure` panel: 37 `uicontrol`s and 3 `axes` render, and
`setCurrentSlice`, `setMask`/`getMask`, `setviewplane`, `getClimits`, `getImageSize`
and `getHandles` all behave. The same patches were regression-checked in a legacy
`figure` (axes/image/mask valid, 37 uicontrols, slice and mask round-trip).

One of the three was **not** predicted by the plan and is worth calling out:

> `imtool3D.m:320` ended with `hold on`, which applies to `gca`. In a legacy figure
> `imshow(...,'Parent',ax)` also makes `ax` current, so this reached the right axes.
> In a `uifigure` it does not — the hold landed elsewhere, the next `imshow` cleared
> the axes, and `tool.handles.I` was invalidated. Fixed with `hold(tool.handles.Axes,'on')`.

This is the archetype of the whole migration: not a missing feature, but a latent
`gca`/`gcf` assumption that only a `uifigure` exposes.

## Confirmed as predicted

| Behaviour | Result |
|---|---|
| `uicontrol` parents into a `uifigure` | works |
| `uicontrol` parents into a `uipanel` inside a `uifigure` | works — this is how the viewer is hosted |
| `uicontrol` parents into a `uigridlayout` | **rejected** — so the new layout grids at *panel* granularity |
| legacy `axes` + `imshow` inside a `uifigure` | works |
| `uipanel` in a `uifigure` | pixel-united; a normalized-looking `Position` silently collapses it to sub-pixel — **plan defect #1 reproduced** |
| `uifigure` `HandleVisibility` | defaults `'off'`, hiding the window from `findobj`; `'on'` restores it — **plan defect #2 reproduced** |
| `uilabel` / `uibutton` `FontUnits` | absent — confirms `TypeScale` has to exist |
| `uifigure.Theme` | present, but does **not** override explicitly-set colors — confirms D2 must strip colors first |
| `uigridlayout` `Scrollable` | works (returns a `matlab.lang.OnOffSwitchState`, not a char) |
| `guidata` on a `uifigure` | works — the `handles` shim survives Stage B |
| `uiwait` / `uiresume` / `waitstatus` on a `uifigure` | works — the `Model = qMRLab(...)` modal contract survives |
| `matlab.uitest` driving a `uicontrol` | refused, `MATLAB:uiautomation:Driver:GestureNotSupportedForClass` |
| `set(slider,'Min',3)` | does not error; **silently resolves to `MinorTicks = 3`** and leaves `Limits` untouched |

## New facts

- `feature('AppDesignerPlainTextFileFormat')` returns **1 on R2026b but 0 on R2026a**.
  The plain-text `.m` + `.xml` app format is therefore an R2026b-only capability, not
  "R2026a/b+" as originally assumed. Had we adopted it, the GUI's floor would have been
  a single prerelease. The programmatic `classdef` decision sidesteps this entirely —
  it runs wherever `uigridlayout` does.
- `matlab.uitest.TestCase.forInteractiveUse` **cannot be constructed from inside a
  running test** (`MATLAB:uitest:TestCase:InteractiveUseOnly`). GUI test classes must
  therefore derive from `matlab.uitest.TestCase` and call gestures on `testCase`
  directly. `Test/GUI/tCapabilities.m` now does this, and it is the pattern all
  later GUI tests should follow.
- `imtool3D.getClimits()` returns a **1×1 cell** (per-volume), not a 2-vector.

## Not yet answered

- **Does the embedded viewer relayout on resize?** Inconclusive headlessly:
  `SizeChangedFcn` does not fire for invisible figures — verified to also be true in a
  *legacy* figure, so this is a batch-mode artifact, not a defect. Needs an
  interactive session with a visible window.
- **`runBranchTriage`** has not been run against `origin/mb/appmigration` yet; that
  needs the branch checked out.

## Branch triage: a ninth defect

`origin/mb/appmigration` deletes `qMRLab.m` in favour of `qMRLab.mlapp`. But
`src/Common/list_models.m:3` locates the model directory with `which('qMRLab.m')`,
which then finds nothing:

```
which qMRLab.m    : ""
which qMRLab      : ".../qMRLab.mlapp"
list_models       : 0 models        <-- 22 models exist on disk
```

The app itself survives because its own path lookup goes through `mfilename()`, which
inside a class method resolves to the class and therefore to the `.mlapp`. But
`list_models` is used by the tests, the documentation generator and the standalone
build — all of which silently see an empty model list.

This demonstrates, rather than merely infers, the constraint behind the Stage B3
decision: **`qMRLab.m` must remain a real function file on disk.**
`Deploy/Documentation/GenerateDocumentation.m:3,81` and `mcc -W main:qMRLab` pin the
same filename.

## Stage A2 verdict: kill criterion NOT tripped

Full sharded triage, 22 models x 2 windows on R2026b, one MATLAB process per model.
Merged report: `Test/GUI/branch_triage_R2026b.md`.

```
41 rows · 38 captures · 21 ok · 17 with defects · 3 errors
44 defects: 35 Collapsed, 8 Overflow, 1 OffFigure
```

**Every single defect is in one subtree, and the main window is clean for all 22 models.**

| Cluster | Models | Path |
|---|---|---|
| Collapsed | 17 | `Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel` |
| Collapsed | 7 | `Figure > Panel[uipanel29] > Panel[OptionsPanel]` |
| Overflow | 7 | `Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel` |
| OffFigure | 1 | `Figure > Panel[uipanel29] > Panel[OptionsPanel] > Panel` |

The 3 errors (`denoising_mppca`, `mtv`, `qsm_sb`) are the same cause reaching further:
`ColumnWidth must be an array containing 'fit', 'auto', positive` — `GenerateButtonsWithPanels.m:345`
computes `widthpx` from a parent that has already collapsed, so it goes negative.

### Root cause: two lines

`createComponents` sets the panel correctly in pixels:

```matlab
app.OptionsPanel.Position = [283 14 256 567];      % line 957 -- correct
```

then two runtime assignments overwrite it with a GUIDE-era **normalized** value, and a
`uipanel` inside a `uifigure` is pixel-united:

```matlab
set(app.OptionsPanel, 'Position', [0.5140 0.0158 0.4667 0.9735]);   % lines 635 and 644
```

The panel collapses to 0.5 x 0.016 px. Everything `GenerateButtonsWithPanels` then
computes from `getpixelposition(parent)` is garbage, which produces the 17 collapsed
child panels, the 8 overflows, and the 3 `ColumnWidth` throws.

### What it actually looks like

`Test/GUI/evidence/inversion_recovery_options.png`: Protocol tables render, the Add /
Remove / Move up / Move down / Load / Create rows render, and the Fitting table renders
*better than the original GUIDE app* — full `Start` / `Lower` / `Upper` headers instead
of the truncated `S…` / `L…` / `U…`. Only the Options panel is blank, where
`method: Magnitude` and `fitModel: Barral` should be.

### Verdict

The kill criterion was: *more than 8 defects that are not one-line position/property
fixes ⇒ abandon the salvage.* There is **one** root cause, it **is** a position fix, and
the main window needs nothing. **Salvage confirmed; proceed to Stage B.**

## A tenth defect: cached browser state outlives the window

Found while building the triage harness, and it is a genuine user-visible bug rather
than a test artifact. Launch qMRLab, close it, launch it again in the same MATLAB
session, and the second launch dies:

```
Invalid or deleted object.
    BrowserSet.Visible          (line 174)   % obj.NameText.Visible = Visibility
    MethodBrowser.Visible       (line 149)
    qMRLab.MethodMenu           (line 392)
    qMRLab.qMRLab_OpeningFcn    (line 815)
```

`FileBrowserList` holds `MethodBrowser`/`BrowserSet` objects, which hold graphics
handles into the figure that was just destroyed. On relaunch, `MethodMenu` iterates
that list and sets `Visible` on dead handles.

Deleting the figure is not enough, and **wiping root appdata is not enough either** —
both were tried and the failure persists, so the cache survives by some third route
that has not been isolated. Root-causing it is deferred to Stage C: this code is
rewritten there anyway, and the important part for now is that the *path* is real.

Consequences:

- **Stage C owes a regression test** for open → close → reopen within one session.
  Real users do this and nothing covers it.
- `qMRLab_CloseRequestFcn`'s root-appdata wipe (`qMRLab.m:207-211`) is **load-bearing,
  not housekeeping**. Any teardown that bypasses it — a crash, an error during
  startup, a programmatic delete — leaves the session in a state where every
  subsequent launch fails until `clear all`.
- **Any GUI test fixture needs process-level isolation**, not just figure teardown.
  `Test/GUI/runBranchTriage.m` now emits per-run JSON so it can be sharded one MATLAB
  process per model and merged afterwards.

> Recorded because two plausible hypotheses were wrong first — a stale App Designer
> singleton, then the `gca` viewer bug. Neither survived a stack trace:
> `getRunningSingleton` resolves via `findall(groot,…,'-property','RunningAppInstance')`,
> so deleting the figure genuinely does deregister the app, and the failure reproduces
> with the viewer patches applied. Measure before theorizing.

## Files added

| File | Purpose |
|---|---|
| `Test/GUI/tCapabilities.m` | Pins every platform assumption the migration relies on; fails loudly if MathWorks changes one |
| `Test/GUI/geomAudit.m` | Walks a figure for *silent* geometry failures (collapsed containers, children outside their parent) and captures a PNG |
| `Test/GUI/runBranchTriage.m` | Drives `geomAudit` over all 22 models × 2 windows and writes a markdown report; implements the Stage A2 kill criterion |
| `External/imtool3D_td/QMRLAB_PATCHES.md` | Records the vendored-code patches so they survive an upstream pull |
