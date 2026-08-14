classdef TypeScale
%TypeScale  qMRLab's user-chosen text size.
%
%   qmrlab.gui.TypeScale.adopt(fig, relayoutFcn)  register window(s); scale + remember
%   qmrlab.gui.TypeScale.apply(h)                 rescale the subtree under h (idempotent)
%   qmrlab.gui.TypeScale.choose(step)             'small'|'medium'|'large'; persist + re-apply
%   qmrlab.gui.TypeScale.current()                active step name
%   qmrlab.gui.TypeScale.factor(step)             0.85 | 1.00 | 1.25
%   qmrlab.gui.TypeScale.geomFactor()             max(1, factor) -- geometry grows, never shrinks
%   qmrlab.gui.TypeScale.attachMenu(fig)          builds View > Text size
%   qmrlab.gui.TypeScale.publish()                exports the factor for non-GUI consumers
%
%   THE CONTRACT, IN ONE LINE:
%       FontSize = <the size the author wrote> * factor
%
%   The authored size is stamped into the component's own appdata the first time
%   apply() sees it, and is NEVER re-read from the live value.
%
%   DO NOT "simplify" this to fontsize(fig, scale=f). That built-in multiplies the
%   CURRENT value and rounds to integers: measured on the live main window, a
%   1.25x then 0.8x round trip leaves 32 of 145 components wrong (max error
%   0.667 px). Base-anchored multiplication measures 134/134 exact, error 0.
%   It is also R2022a, above the R2020b floor set in docs/adr/0001-gui-migration.md.
%
%   Scope: FontSize only. Geometry is handled by each window's own relayout
%   callback (see MainApp.applyTypeGeometry), grow-only, at container level.
%   No component's Position is ever multiplied -- every widget the runtime
%   generators produce is 'Units','normalized', and multiplying a normalized
%   rectangle is exactly the mistake that produced all 44 Stage A defects.
%
%   See also: qmrlabUIScale, Test/GUI/tTypeScale.m, Test/GUI/textFitAudit.m

    properties (Constant)
        % 'large' (1.25) is implemented and correct -- FontSize scales exactly and
        % applyTypeGeometry grows the grid and the window. It is NOT OFFERED yet
        % because two areas still position their children in fixed pixels, so
        % larger text overflows boxes that do not grow with it:
        %   src/Common/tools/FileBrowser/{MethodBrowser,BrowserSet}.m
        %       "Browse", "Study ID:", "Download example" -- e.g. [130 y 55 25]
        %   the viewer control strip in FitResultsPlotPanel
        %       "3D viewer", "Histogram", "Quality Assurance", "Current file :"
        % Verified by capture at 1.25: all of the above clip or overlap.
        %
        % The design assumed every generated widget is 'Units','normalized' --
        % true of GenerateButtonsWithPanels, false of the file browser, which was
        % rewritten with pixel positions during the migration.
        %
        % Stage E moves both onto grids. Restore 'large' then; the machinery for it
        % is already here and tested (see Test/GUI/tTypeScale.m).
        StepNames  = {'small','medium'}
        StepLabels = {'Small','Medium'}
        Factors    = [0.85 1.00]

        BaseKey    = 'qmrlabFontBase'            % per-component: the authored size
        AdoptKey   = 'qmrlabTypeScaleAdopted'    % per-figure: follows preference changes
        RelayoutKey= 'qmrlabTypeScaleRelayout'   % per-figure: optional geometry callback
        ScaleKey   = 'qMRLabTypeScale'           % root appdata: transport for non-GUI code

        PrefGroup  = 'qMRLab'
        PrefName   = 'TextSize'
        EnvVar     = 'QMRLAB_TEXT_SCALE'

        % Vendored subtrees that scale THEMSELVES from ScaleKey at construction
        % time (geometry and type together) and must not be traversed here.
        % Same skip-by-Tag idiom as Test/GUI/geomAudit.m.
        SkipTags   = {'imtool3D'}
    end

    methods (Static)

        % ---------------------------------------------------------------- apply
        function apply(h)
        %APPLY  Rescale every chrome component under h. Safe to call at any time.
            C = qmrlab.gui.TypeScale;
            if nargin < 1 || isempty(h), return; end
            h = h(isgraphics(h));
            if isempty(h), return; end

            f = C.factor(C.current());
            C.publish();

            for k = 1:numel(h)
                objs = C.chromeUnder(h(k));
                for j = 1:numel(objs)
                    o = objs(j);
                    b = getappdata(o, C.BaseKey);
                    if isempty(b)
                        b = get(o, 'FontSize');          % first sight: record the AUTHORED size
                        setappdata(o, C.BaseKey, b);
                    end
                    want = b * f;                        % ALWAYS base*f, never current*f
                    if get(o, 'FontSize') ~= want
                        set(o, 'FontSize', want);        % FontUnits untouched: scaling is unit-invariant
                    end
                end
                fig = ancestor(h(k), 'figure');
                if ~isempty(fig), setappdata(fig, C.AdoptKey, true); end
            end
        end

        % ---------------------------------------------------------------- adopt
        function adopt(figs, relayoutFcn)
        %ADOPT  Register window(s) so they follow later preference changes, and scale now.
        %   relayoutFcn (optional) is invoked before apply() on every preference
        %   change, so the window can grow its own fixed-pixel geometry.
            C = qmrlab.gui.TypeScale;
            if nargin < 1 || isempty(figs), return; end
            figs = figs(isgraphics(figs));
            for k = 1:numel(figs)
                setappdata(figs(k), C.AdoptKey, true);
                if nargin > 1 && ~isempty(relayoutFcn)
                    setappdata(figs(k), C.RelayoutKey, relayoutFcn);
                end
                C.apply(figs(k));
            end
        end

        % --------------------------------------------------------------- choose
        function choose(step)
        %CHOOSE  Set the text size, persist it, and re-apply to every adopted window.
            C = qmrlab.gui.TypeScale;
            step = C.validate(step);
            C.state(step);        % in-memory authority: the only store that works in the standalone
            C.writeStep(step);    % best effort; a no-op where prefdir is absent or read-only
            C.publish();

            % Geometry first: a window may rebuild satellites (OptionsGUI), so
            % re-enumerate before scaling type.
            figs = C.adoptedFigures();
            for k = 1:numel(figs)
                if ~isgraphics(figs(k)), continue; end
                r = getappdata(figs(k), C.RelayoutKey);
                if ~isempty(r)
                    try
                        r();
                    catch ME
                        warning('qMRLab:TypeScale:Relayout', ...
                                'Text-size relayout failed: %s', ME.message);
                    end
                end
            end
            drawnow;

            figs = C.adoptedFigures();
            for k = 1:numel(figs)
                if ~isgraphics(figs(k)), continue; end
                C.apply(figs(k));
                C.markMenu(figs(k));
            end
        end

        function larger(),  qmrlab.gui.TypeScale.nudge(+1); end
        function smaller(), qmrlab.gui.TypeScale.nudge(-1); end
        function reset(),   qmrlab.gui.TypeScale.choose('medium'); end

        % --------------------------------------------------------------- values
        function step = current()
            step = qmrlab.gui.TypeScale.state();
        end

        function f = factor(step)
            C = qmrlab.gui.TypeScale;
            if nargin < 1, step = C.current(); end
            f = C.Factors(strcmp(C.validate(step), C.StepNames));
        end

        function g = geomFactor()
        %GEOMFACTOR  Geometry multiplier. Grow-only: shrinking the layout would
        %   re-expose the sub-minimum overlap D1 clamps against, and buys nothing.
            g = max(1, qmrlab.gui.TypeScale.factor());
        end

        function publish()
        %PUBLISH  Export the factor for code that must not depend on this package:
        %   GenerateButtonsWithPanels (via qmrlabUIScale) and vendored imtool3D.
            C = qmrlab.gui.TypeScale;
            setappdata(0, C.ScaleKey, C.factor(C.current()));
        end

        % ----------------------------------------------------------------- menu
        function attachMenu(fig)
        %ATTACHMENU  View > Text size, with Cmd/Ctrl accelerators.
        %
        %   DO NOT add a WindowKeyPressFcn here. imtool3D takes ownership of it
        %   during construction (imtool3D.m:621) and that property is
        %   single-valued: overwriting it silently deletes the viewer's entire
        %   shortcut set -- spacebar (show/hide mask), B/S (brushes), Z (undo),
        %   L (lock), arrows (4th/5th dim), 1-4 (label select). Menu accelerators
        %   are modifier chords and never reach shortcutCallback.
            C = qmrlab.gui.TypeScale;
            if ~isgraphics(fig) || ~isempty(findall(fig, 'Tag', 'TextSizeMenu')), return; end
            accel = {'-', '0', '='};
            m = uimenu(fig, 'Text', 'View');
            s = uimenu(m, 'Text', 'Text size', 'Tag', 'TextSizeMenu');
            for k = 1:numel(C.StepNames)
                uimenu(s, 'Text', C.StepLabels{k}, ...
                          'Tag', ['TextSize_' C.StepNames{k}], ...
                          'Accelerator', accel{k}, ...
                          'MenuSelectedFcn', @(~,~) qmrlab.gui.TypeScale.choose(C.StepNames{k}));
            end
            C.markMenu(fig);
        end

        function markMenu(fig)
            C = qmrlab.gui.TypeScale;
            cur = C.current();
            onoff = {'off', 'on'};
            for k = 1:numel(C.StepNames)
                it = findall(fig, 'Tag', ['TextSize_' C.StepNames{k}]);
                if ~isempty(it)
                    set(it, 'Checked', onoff{1 + strcmp(cur, C.StepNames{k})});
                end
            end
        end

        % ------------------------------------------------------------ utilities
        function wa = workArea(fig)
        %WORKAREA  Usable size of the monitor holding fig, in device-independent px.
        %   The ONLY use of screen metrics in this design: it caps how large the
        %   window may be asked to become. It never chooses a font size.
            wa = [Inf Inf];
            try
                mp = get(groot, 'MonitorPositions');
                idx = 1;
                if nargin > 0 && isgraphics(fig)
                    p = get(fig, 'Position');
                    c = p(1:2) + p(3:4)/2;
                    for k = 1:size(mp, 1)
                        if c(1) >= mp(k,1) && c(1) <= mp(k,1)+mp(k,3) && ...
                           c(2) >= mp(k,2) && c(2) <= mp(k,2)+mp(k,4)
                            idx = k; break
                        end
                    end
                end
                wa = mp(idx, 3:4) * 0.96;   % leave room for OS chrome
            catch
            end
        end

        function figs = adoptedFigures()
            figs = findall(groot, 'Type', 'figure');
            if isempty(figs), return; end
            figs = figs(arrayfun(@(f) isappdata(f, qmrlab.gui.TypeScale.AdoptKey), figs));
        end
    end

    methods (Static, Access = private)

        function objs = chromeUnder(root)
        %CHROMEUNDER  Font-bearing CHROME under root.
        %   Excluded, deliberately:
        %     - anything with an axes ancestor, plus UIAxes, Legend and ColorBar.
        %       Legend/ColorBar are figure-parented peers of the axes, NOT
        %       descendants, so ancestor(o,'axes') misses them -- and
        %       RefreshColorMap.m:5 builds one at FontSize 14. Plot type is DATA:
        %       it lands in exported figures and papers, and a UI legibility
        %       preference must not change what a user saves.
        %     - SkipTags subtrees (imtool3D), which scale themselves.
            C = qmrlab.gui.TypeScale;
            objs = findall(root, '-property', 'FontSize');
            if isempty(objs), return; end

            drop = gobjects(0, 1);
            ax = findall(root, 'Type', 'axes');
            if ~isempty(ax), drop = [drop; findall(ax, '-property', 'FontSize')]; end
            for t = C.SkipTags
                sub = findall(root, 'Tag', t{1});
                if ~isempty(sub), drop = [drop; findall(sub, '-property', 'FontSize')]; end %#ok<AGROW>
            end
            if ~isempty(drop), objs = setdiff(objs, drop, 'stable'); end
            if isempty(objs), return; end

            isData = arrayfun(@(o) isa(o, 'matlab.ui.control.UIAxes') || ...
                                   isa(o, 'matlab.graphics.illustration.Legend') || ...
                                   isa(o, 'matlab.graphics.illustration.ColorBar'), objs);
            objs = objs(~isData);
        end

        function nudge(d)
            C = qmrlab.gui.TypeScale;
            i = find(strcmp(C.current(), C.StepNames)) + d;
            C.choose(C.StepNames{min(max(i, 1), numel(C.StepNames))});
        end

        function out = state(varargin)
        %STATE  In-process authority. Seeded once from env/pref; choose() overrides.
        %   Without this the compiled standalone -- where no PersonalValue and no
        %   .mlsettings survive a restart -- would lose the choice on the next apply().
            persistent step
            if isempty(step), step = qmrlab.gui.TypeScale.readStep(); end
            if nargin, step = varargin{1}; end
            out = step;
        end

        function step = readStep()
        %READSTEP  MUST NOT THROW. "Nothing stored" is the normal standalone path.
            C = qmrlab.gui.TypeScale;
            step = 'medium';
            try
                v = getenv(C.EnvVar);          % CI, Docker, read-only prefdir, support
                if ~isempty(v), step = C.validate(v); return; end
            catch
            end
            try
                step = C.validate(getpref(C.PrefGroup, C.PrefName, 'medium'));
            catch
            end
        end

        function writeStep(step)
        %WRITESTEP  setpref, not matlab.settings.
        %   matlab.settings is the modern API and is INERT in the compiled
        %   standalone: a factory group loads but no PersonalValue survives a
        %   restart (reproduced with a MathWorks-shipped setting), <toolbox>.mlsettings
        %   is not in inclusion_list_for_matlab_preferences.xml, and addpath is a
        %   hard error there so reloadFactoryFile is unusable. setpref round-trips
        %   in the deployed prefdir via matlabprefs.mat and costs two calls, no
        %   resources/settingsInfo.json, no CreateTreeFcn, no mcc -a flags.
            try
                setpref(qmrlab.gui.TypeScale.PrefGroup, qmrlab.gui.TypeScale.PrefName, step);
            catch
            end
        end

        function step = validate(v)
            C = qmrlab.gui.TypeScale;
            step = 'medium';
            if isempty(v), return; end
            v = char(string(v));
            hit = strcmpi(v, C.StepNames);
            if any(hit), step = C.StepNames{hit}; return; end
            n = str2double(v);                       % accept QMRLAB_TEXT_SCALE=1.25
            if isfinite(n)
                [~, i] = min(abs(C.Factors - n));
                step = C.StepNames{i};
            end
        end
    end
end
