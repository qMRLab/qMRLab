# Local patches to imtool3D_td

`External/imtool3D_td/` is vendored from Tanguy Duval's fork of Justin Solomon's
imtool3D (BSD; see `LICENSE`). qMRLab carries a small, deliberately minimal set of
local changes so the viewer can be embedded in an App Designer `uifigure`.

Keep this file in sync when patching, and re-apply the list after any upstream pull.

## Why any patch is needed

qMRLab hosts imtool3D inside its main window (`qMRLab.m:114`). As that window moves
from a GUIDE `figure` to a `uifigure`, three constructor lines that happened to work
by relying on `gca` and legacy defaults stop working. None of these are upstream
bugs in a legacy figure — they are latent assumptions that a `uifigure` exposes.

## The patches

### 1. `:295` — `Panels.Large` must not auto-resize its children

```matlab
tool.handles.Panels.Large = uipanel(..., 'Tag','imtool3D', 'AutoResizeChildren','off');
```

imtool3D lays its own children out in pixels from a resize callback (`:407`). In a
`uifigure`, a container with `AutoResizeChildren='on'` manages children itself, and
MATLAB warns that the resize callback will never execute.

### 2. `:320` — hold the tool's own axes, not `gca`

```matlab
tool.handles.I = imshow(zeros(3,3),[0 1],'Parent',tool.handles.Axes); hold(tool.handles.Axes,'on');
```

Was `hold on`, which applies to `gca`. In a legacy figure `imshow(...,'Parent',ax)`
also makes `ax` current, so `hold on` reached the right axes. In a `uifigure` it does
not, so the hold landed elsewhere and the next `imshow` cleared the axes — which
invalidated `tool.handles.I`.

Symptom without this patch:
`Invalid or deleted object` at `imtool3D:344` (`set(tool.handles.I,'ButtonDownFcn',fun)`).

### 3. `:328` — parent the mask image explicitly

```matlab
tool.handles.mask = imshow(im,'Parent',tool.handles.Axes);
```

Was `imshow(im)`, resolving its target through `gca`.

Symptom without this patch:
`Invalid or deleted object` at `imtool3D:1613` (`showSlice`, setting `CData` on the mask).

## Verification

`Test/GUI/tCapabilities.m` → `imtool3DConstructsInsideUIFigurePanel` builds the tool
inside a `uifigure` panel and exercises the API qMRLab depends on. It fails without
these patches and passes with them, in both a `uifigure` and a legacy `figure`.

## Not patched (yet)

- Appearance constants are still hardcoded: `BackgroundColor 'k'` / `ForegroundColor 'w'`
  at `:304`, `:308`, `:335`, `:338`, `:339`, `:371`; axes `XColor`/`YColor 'r'` at `:329`;
  and the `FontSize 9` sweep at `:610`, `:614`. Stage D of the migration parameterizes
  these so the viewer can follow the app theme.
- `src/ind2rgb8` ships `.mexa64` / `.mexmaci64` / `.mexw64` but no `.mexmaca64`, so on
  Apple Silicon it falls back to the `try/catch` branch at `:1610`. Harmless but slower.
