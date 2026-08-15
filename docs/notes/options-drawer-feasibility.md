# Feasibility: an in-window Options drawer instead of a second window

*Investigation only — nothing here is implemented, and no decision is recorded.
Written 2026-08-15 while F1 was in progress, because the maintainer asked whether
the separate Options window could become a collapsible panel in the main window.*

A working demo was built against the real interface on a throwaway copy of the
tree. It confirmed the layout half is easy: `RootGrid` is `{270, '1x'}`, appending
a third column shifts nothing, `OptionsRenderer.render(model, parent, changedFcn)`
already takes a container and needed **zero** changes, and collapse/expand is one
property assignment (`ColumnWidth{3}` between `0` and a width) so ADR D7 holds.
Measured cost: a fixed 400 px drawer takes 49% of the viewer at the default 1126 px
window, 34.7% at 1470, 18% at 2560 — i.e. it wants to be width-aware.

What follows is the full survey of the parts the demo could NOT settle: the
`uiwait` contract, the standalone-window requirement, and the test/golden impact.

---

# Is a collapsible drawer in the main window possible instead of a separate Options window?

## 1. Verdict

**Possible, with caveats — and the caveats are not in the layout.** The drawer itself is three edits to `MainApp.m` and a property write; the mechanism (`RootGrid.ColumnWidth{3} = 0`) is already shipped in this repo at `OptionsWindow.m:538,542` and is MathWorks' own idiom. What makes it a real project is that **the drawer can only ever be an *additional* host, never a replacement**: `Custom_OptionsGUI`'s blocking contract structurally requires a top-level figure (§4), so you end up maintaining the options UI in two hosts, and every test, golden and lookup that finds the options UI finds it as a figure by `Name`/`Tag`. Net: do it if you want one window, but budget for a shell split and a golden re-baseline, not for a layout patch. If the actual complaint is "the options window is in my way", §6 fixes most of that for ~20 lines and zero test churn.

There is no supported collapsible container in MATLAB to lean on. `matlab.ui.container.internal.Accordion` is Sealed/Hidden/undocumented with no `uiaccordion()` constructor and is byte-identical between R2026a and R2026b (frozen); `matlab.ui.container.SidePanel` — literally this feature — has a controller and a JS widget but **no model class and no constructor**, i.e. unreleased plumbing years above the D5 floor. Under D5 the drawer is a zeroed grid column or it is nothing.

## 2. What it would actually be

A third `RootGrid` column whose width toggles between `0` and a constant. No rectangle is computed, so D7 holds.

```matlab
% applyResponsiveLayout (MainApp.m:1199)
app.RootGrid.ColumnWidth = {270, '1x', 0};              % was {270, '1x'}
app.DrawerHost = uipanel(app.RootGrid, 'BorderType','none', 'Visible','off');
app.DrawerHost.Layout.Row = 1;  app.DrawerHost.Layout.Column = 3;

% applyTypeGeometry (MainApp.m:1140) -- MUST become 3-element, see §3.1
app.RootGrid.ColumnWidth = {270*g, '1x', app.DrawerPx*g};

% the toggle, replacing OpenOptionsPanel_Callback (MainApp.m:918)
open = (app.DrawerPx == 0);
if open && isempty(allchild(app.DrawerHost))            % lazy: nothing built while closed
    qmrlab.gui.OptionsRenderer.render(getappdata(0,'Model'), app.DrawerHost, app.OptChanged);
end
app.DrawerPx = 270 * open;
app.DrawerHost.Visible = matlab.lang.OnOffSwitchState(open);   % NOT optional -- see §3.4
app.RootGrid.ColumnWidth{3} = app.DrawerPx * qmrlab.gui.TypeScale.geomFactor();
```

Two things it must *not* be: a whole-cell reassignment (`ColumnWidth = {270,'1x'}` with a child still in column 3 makes MATLAB silently append an implicit `'1x'` column and the drawer reappears at full stretch), and animated (stepping the width in a timer is runtime geometry maths — D7).

`OptionsRenderer` needs **zero** changes. `tDSL.m:166` already calls `OptionsRenderer.render(m, uipanel(uf))` for all 22 models with no window, no app object and no chrome, and asserts the resulting handles struct is field-, class- and value-identical to the legacy generator. The content is already host-agnostic; only the shell is window-bound.

## 3. The four things that make it non-trivial *here*

**1. `MainApp.m:1140` destroys the third column, on a path no resize test covers.**
`app.RootGrid.ColumnWidth = {270*g, '1x'};` is a wholesale 2-element literal inside `applyTypeGeometry`, which fires on every **text-size preference** change (registered at `:703`), not on resize. Add a drawer as column 3 and it dies the first time a user picks View ▸ Text size — and because a child still claims `Layout.Column = 3`, the grid re-adds the column implicitly at `'1x'`, so the failure is "the drawer suddenly ate half the window", not an error. `MainApp.m:1147` (`ViewerGrid.ColumnWidth = {200*g,'1x'}`) is the identical hazard and is the reason not to put the drawer inside `ViewerGrid`. `MainApp.m:1141`'s 9-element `SideGrid.RowHeight` is the same trap for anyone who adds a toggle *row* to the sidebar — put the toggle in the existing View menu or relabel `OpenOptionsPanel` at row 9 instead.

**2. The width budget: the drawer costs the viewer, and the payload does not fit.**
`FitDataPanel` width = `W − 294` (`RootGrid` padding 8+8, spacing 8, sidebar 270). The window audits clean at **700×520** today (`tMainApp.m:158-176`, on `mp2rage`, seven inputs). The options column's measured usable minimum is ~250 px (`OptionsRenderer.m:44-48` records a fixed 150 px label truncating `0.000921055` to `0.0009210` in it), and the Fitting table alone is 251 px of fixed columns (`OptionsWindow.m:880`). The *full* payload is `uipanel29` at 550 px (`OptionsWindow.m:866`).

- Options-only drawer (~270 px + 8 spacing): new floor ≈ **978 px** to preserve today's canvas. At 700 wide with it open, `ViewerHost` goes negative → `Collapsed` defects.
- Full payload drawer (~558 px): new floor ≈ **1258 px** — wider than the 1126 design size.

And note what that means: 1126 + 558 ≈ 1684 versus the two windows' 1126 + 573 = 1699. **The drawer saves a window, not pixels.** On the laptop where two windows overlap, the drawer instead squeezes the map — arguably the worse failure, since the maintainer's stated workflow is *look at the map*. The honest mitigation is that "closed" is the default and `ColumnWidth{3} = 0` restores today's geometry exactly.

**3. Every consumer of the options UI keys on a top-level figure — and one of them fails silently.**
`MainApp.m:302, :1116, :1177` (`findobj('Tag','OptionsGUI')`), `Custom_OptionsGUI.m:88` (`findall(groot,'Type','figure','Name','OptionsGUI')`), `tMainApp.m:370-373`, `runBranchTriage.m:119-120`, `MethodBrowser.m:250` (which guesses with `gcf`). The dangerous one is `captureGoldens.m:100`: `findall(groot, 'Tag', 'OptionsGUI')` has **no `Type` filter**, so a drawer panel keeping that Tag is silently matched, `opts.Visible='on'` even works, and the failure surfaces at `captureFigure.m:38` (`fig.Name` — a uipanel has none). That throw is caught by `captureGoldens.m:67-70`, so the run writes `<model>_ERROR.txt`, prints `(no Options window for %s)` and the options goldens quietly stop existing. That is exactly the vacuous-green failure mode HANDOVER names three times.

**4. `geomAudit` both refuses the drawer and punishes getting it wrong.**
`geomAudit.m:25-29` is `arguments fig matlab.ui.Figure` — it cannot be handed a uipanel at all, so `tMainApp.m:83-97` (audits the options *figure* for all 22 models) must be rewritten to audit the main figure with the drawer explicitly opened. Worse: a collapsed drawer left `Visible='on'` at 0 px trips `Collapsed` (20 px floor, `geomAudit.m:34`), and `geomAudit` re-audits until clean or a 10 s `SETTLE_DEADLINE` — across ~35 in-suite call sites. So collapse **must** set `Visible='off'` *and* the track, which is precisely what `OptionsWindow.m:536-543` already does for the optional Prot/FitOpt panels.

> **Surveys disagree here, so take this side.** The MATLAB-source survey argues MathWorks' own drawer (`FigureUtilities.m:309-323`) touches `ColumnWidth` only and that `Visible='off'` "buys nothing and costs a second piece of state". In *this* repo it buys a green `geomAudit` and avoids ~35 × 10 s of wall clock on a red build. Follow the repo's own precedent, not MathWorks'.

Related, same paragraph: today the options subtree is torn down by deleting a whole figure (`MainApp.m:302-308`, `:1177-1184`). A drawer has no figure to delete, so teardown becomes `delete(allchild(host))` or `tMainApp.m:300-317` (`modelSwitchingDoesNotLeakHandles`, ≤10% growth over 10 switches) goes monotonic — and it will now *see* the options subtree, which it cannot today.

## 4. The blocking-contract problem

`Custom_OptionsGUI(Model)` with an output argument blocks on `uiwait(app.OptionsGUI)` (`Custom_OptionsGUI.m:104-105`) and its name is emitted verbatim into every generated batch script.

**Recommendation: leave `Custom_OptionsGUI.m` byte-identical and keep `qmrlab.gui.OptionsWindow` as a real `uifigure`. The drawer is an additional host, not a replacement.**

The argument is structural, not conservative: **generated batch scripts run with no main window.** There is no main figure to `uiwait` and no `RootGrid` to render into, so the blocking form must be able to construct its own top-level figure or it cannot exist. Everything else on the list fails concretely:

- `uiwait` the main figure → forces a full `MainApp` launch (the ~8 s empty shell, imtool3D, MethodBrowser, GUI_animation) into a headless batch script, returns only when the user quits the whole app, and collides with `MainApp.m:1104-1106`, which already owns a `uiwait`/`waitstatus` on that figure for `qMRLab.m`'s own modal contract.
- `waitfor` on a pane property / a Done button → changes the published gesture. `src/Common/genBatchUser.qmr:26` literally emits *"You need to close GUI to move on."* into every script already on users' disks; a drawer has no close box, so a user following that comment collapses the drawer and hangs with nothing to close. `tAPI.m:215-225`'s poller also reads `get(fig,'waitstatus')` — a figure property.

So the work is a **shell split**, not a port: extract `qmrlab.gui.OptionsPane` taking a *container* (everything that parents into `uipanel29`/`ShellGrid`/`RightGrid`/`OptionsHost`), and leave `OptionsWindow` as a thin figure shell owning `Name`/`Tag`/`HandleVisibility`/`movegui`/`registerApp`/`uiwait`/the caller-docking arithmetic at `:443-453`. The dual host is cheap only because both sides talk to the same `setappdata(0,'Model')` bus (D4).

**Name the newly-reachable hazard:** with a drawer open, a batch script calling `Custom_OptionsGUI` finds no figure named `OptionsGUI` at `:88`, opens a second independent editor, and two live UIs share one root-appdata `Model`. That is the ADR's explicitly-unaddressed "multiple concurrent instances", newly reachable in a way it is not today.

## 5. What it costs

**Files.** `MainApp.m`: `:1199` and `:1140` (the two `ColumnWidth` literals), `:918-927` (button → toggle), `:302-308` (delete-and-rebuild → `pane.show(Model)`), and two *deletions* — `:1116-1118` (a drawer dies with its figure) and `:1174-1184` (whose justifying comment at `:1174`, "OptionsGUI is absolute-pixel throughout … so it is rebuilt rather than resized", is already stale: E3 made both the renderer and the shell grid-managed). New `+qmrlab/+gui/OptionsPane.m` (~600 lines moved out of `OptionsWindow.m`); `OptionsWindow.m` shrinks to a shell. `MethodBrowser.m:250` needs a dispatcher so it stops guessing with `gcf`. `OptionsRenderer.m`, `parseButtons.m`, `button_handle2opts.m`: untouched.

**Prerequisite, not extra cost.** F1 must land first: `convertToGUIDECallbackArguments` is called 4× in `OptionsWindow.m`, and it resolves the app's figure via a depth-1 `RunningAppInstance` search — from a pane it would return an *arbitrary* running app's `guidata` rather than erroring.

**Tests.** Rewrite `tMainApp.m:83-97` + `:370-373`. `tMainApp.m:300-317` survives and gets stronger (and will catch the new teardown). `tControls.m:106-131` and `tTheme.m:73-148` widen to cover the option widgets for the first time — a genuine gain (`OptionsWindow.m:910-911`'s accent stamps are currently untested), and possibly new failures to fix. `tAPI.m:89-126` and `tCapabilities.m:211-219` unchanged, and they are what proves the standalone survived. New: open/collapse/reopen, plus `geomAudit` in *both* states. Plus the capability probe in §"open questions".

**Goldens.** 36 `*_options.txt` and 37 `*_options.png` across six evidence directories. `captureFigure.m` is figure-bound in three places: `:18` `exportapp`, `:38` `fig.Name`, `:106` `getpixelposition(h,true)` (figure-relative, so *every* inventory line shifts by the drawer's origin → pure rebaseline noise). Cheapest preservation, and it is free: **keep pointing the `*_options` series at the standalone window**, which has to survive anyway, and add a new `*_drawer.png` of the whole main window with the drawer open. That also buys an assertion — standalone and drawer must inventory identically apart from the root — which is the cheapest guard against the two hosts drifting. Capture a `before_drawer` baseline with *today's* tooling before touching anything.

**CI.** Nothing new required, but the zero-width probe wants the `release:` matrix leg D5 already calls for: CI currently runs R2026a twice and never R2026b (`.github/workflows/matlab.yml:134-147`).

## 6. What I'd do instead

**First, fix the irritation without a drawer — ~20 lines, no test rewrite, no golden churn. Then re-ask the question.**

1. **Stop destroying and rebuilding the window.** `MainApp.m:302-308` deletes the whole options figure and reconstructs it on *every model switch*; `:1174-1184` does it again on every text-size change, justified by a comment that is no longer true. The window vanishing and reappearing under the cursor — losing scroll position, focus and z-order every time — is a large part of what "juggling two windows" feels like. Replace with a live `show(Model)`.
2. **Fix the docking.** `OptionsWindow.m:447-453` places the window at `CallerPos(1)+CallerPos(3)` — flush right of a 1126 px main window, needing 1699 px of desktop. On any laptop, `movegui(...,'onscreen')` at `:364` then slams it back **on top of the main window**. That is the concrete "it's in my way": it lands over the map. Dock to whichever side has room, and remember the last position.
3. **Give `MethodBrowser.m:250` a real handle** instead of `gcf`.

That is the same `OptionsPane`-free, F1-independent work, and it is measurable: do it, use it for a week, and see whether one window is still wanted.

**If it is**, do the drawer *after* F1, as `OptionsPane` + dual host, at `RootGrid` column 3 (append, don't insert — no existing `Layout.Column` changes). **Not** in `ViewerGrid` (steals from the viewer, plus the `:1147` hazard) and **not** in `FitDataGrid` (`:1318-1319` span `Layout.Column = [1 3]`, hard-coded to the column *count*, so a 4th column leaves the Datasets browser and viewer silently stopping short of the drawer).

**Don't chase a draggable divider.** There is no splitter, divider or resizable split anywhere in the uifigure component set. The only two frameworks that have one are AppContainer (`Collapsible`/`Resizable`/`PreferredWidth` — but it is the toolstrip shell, not a uifigure, so it cannot host `Custom_OptionsGUI`'s standalone contract) and GUI Layout Toolbox (`+uix`), which works by measuring the parent and writing pixel `Position` onto each child — the exact runtime rectangle arithmetic D7 banned, plus a second vendored third-party dependency to patch. If width adjustment is wanted, copy MathWorks' own answer: ± buttons stepping the column by 10 px (`stats/mlearnapps/.../FigureUtilities.m:328-337`), or two or three preset widths on the toggle. Both are pure property assignment.

---

## Open questions — not settleable without running MATLAB

**Q1. Is `ColumnWidth{k} = 0` legal at the R2020b floor?** This is the one hard dependency. The validator that permits it (`PropertyHandling.isPositiveNumber`, whose comment says "positive" but whose code says `value >= 0`) looks like it always meant that, but it cannot be dated from R2026a/R2026b alone. Probe belongs in `tCapabilities.m` beside `gridLayoutIsScrollable` (`:191-198`):

```matlab
f = uifigure('Visible','off'); c = onCleanup(@() delete(f));
g = uigridlayout(f,[1 2]); uilabel(g); uilabel(g);   % content-driven, so this also pins implicit columns
ok = true; try, g.ColumnWidth{2} = 0; catch, ok = false; end
testCase.verifyTrue(ok && isequal(g.ColumnWidth{2}, 0), ...
    'This release rejects a zero-width grid column; the drawer cannot collapse.');
```
Assert the **readback**, not just the absence of an error — a release that coerced 0 to 1 would pass a bare try/catch. Use numeric `0`, not `'0x'` (the `'0x'` → 0 px conversion lives in a controller whose vintage is also undateable).

**Q2. Does a collapsed-but-visible drawer actually trip `geomAudit`, and does it burn the 10 s deadline?** Build the 3-column `RootGrid` by hand with a `Visible='on'` uipanel in the zeroed column, then `t=tic; d=geomAudit(fig); toc(t)` and inspect `d.Kind`. Expect `Collapsed` and ~10 s. Repeat with `Visible='off'`; expect empty and <2 s. This decides §3.4's disagreement empirically.

**Q3. Does the golden tooling survive a container root?** `exportapp(uipanel(uifigure('Visible','off')), 'x.png')` and `getframe` of the same. Both are expected to fail; confirming it settles whether `captureFigure` must be generalized or the standalone-window route is used.

**Q4. Does a `Scrollable` options grid re-measure correctly after collapse → expand?** The client claims to recompute `'fit'` tracks from scratch on every `ColumnWidth` write, but that is read from a minified bundle, not measured. Render **`qsm_sb`** (the model HANDOVER records as settling only at ~2.9 s) into a drawer host, zero the column, `drawnow`, restore, `drawnow`, then `geomAudit` and diff the inventory against the standalone window's. Also check the scroll *position* taken while collapsed is not restored as garbage.

**Q5. What does an eagerly-built drawer cost at launch?** A zero-width column does not skip construction, controller creation or view-peer push — collapsing buys nothing at startup. Time `qMRLab(mp2rage)` with the drawer host empty versus pre-rendered, against the ~8 s already measured. If it is material, lazy construction on first open (as sketched in §2) is mandatory rather than optional — and `OptionsRenderer.render` already begins with `delete(allchild(parent))`, so it is built for exactly that.

**One thing that needs no probe:** do not put anything owning an `axes` in the drawer. A zero-width cell hands its child a zero bounds, which is the same state that made imtool3D throw on a non-finite `PlotBoxAspectRatio` and took down 9–10 CI tests. The options renderer builds only native widgets, so the drawer as scoped is safe; a preview axes in it would not be.
