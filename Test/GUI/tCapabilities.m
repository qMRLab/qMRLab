classdef tCapabilities < matlab.uitest.TestCase
%   (matlab.uitest.TestCase derives from matlab.unittest.TestCase and adds the
%   app gestures; forInteractiveUse cannot be constructed from inside a test.)
% tCapabilities  Pins the MATLAB graphics behaviours the App Designer migration relies on.
%
%   Every assertion here encodes an assumption made by the GUI migration plan.
%   The point is not to test qMRLab -- it is to fail loudly on the day MathWorks
%   changes one of these behaviours, instead of letting the GUI break silently.
%
%   Several of these contradict the intuitive expectation. Read the comments
%   before "fixing" a failure: a failure may mean the platform improved, in
%   which case the corresponding workaround in src/Common/GUI can be deleted.
%
%   Run with:  runtests('Test/GUI/tCapabilities.m')
%   Run on BOTH R2026a and R2026b before relying on the results.

    properties
        Fig     % a uifigure, recreated per test method
    end

    methods (TestClassSetup)
        function requireGraphics(testCase)
            % uifigure needs a display. Skip the whole class when headless
            % rather than reporting a wall of failures.
            try
                f = uifigure('Visible', 'off');
                delete(f);
            catch ME
                testCase.assumeFail(['No usable graphics environment: ' ME.message]);
            end
        end

        function reportEnvironment(~)
            fprintf('\n--- tCapabilities environment ---\n');
            fprintf('  MATLAB release      : %s\n', version('-release'));
            fprintf('  Computer            : %s\n', computer('arch'));
            try
                plainText = feature('AppDesignerPlainTextFileFormat');
            catch
                plainText = NaN;   % feature flag absent on this release
            end
            fprintf('  Plain-text app format: %s\n', mat2str(plainText));
            fprintf('---------------------------------\n');
        end
    end

    methods (TestMethodSetup)
        function makeFigure(testCase)
            testCase.Fig = uifigure('Visible', 'off');
            testCase.addTeardown(@() delete(testCase.Fig));
        end
    end

    methods (Test)

        % ---------------------------------------------------------------
        % Legacy component hosting. The whole "keep imtool3D embedded"
        % decision rests on these three.
        % ---------------------------------------------------------------

        function uicontrolAcceptsUIFigureParent(testCase)
            h = uicontrol(testCase.Fig, 'Style', 'pushbutton', 'String', 'ok');
            testCase.verifyTrue(isgraphics(h), ...
                'uicontrol can no longer be parented to a uifigure.');
        end

        function uicontrolAcceptsUIPanelInUIFigure(testCase)
            % This is exactly how imtool3D is embedded (qMRLab.m:114).
            p = uipanel(testCase.Fig);
            h = uicontrol(p, 'Style', 'pushbutton', 'String', 'ok');
            testCase.verifyTrue(isgraphics(h), ...
                'uicontrol can no longer be parented to a uipanel inside a uifigure.');
        end

        function uicontrolRejectsGridLayoutParent(testCase)
            % Consequence: the new layout grids at PANEL granularity. Any panel
            % that still hosts legacy children cannot itself be a grid.
            g = uigridlayout(testCase.Fig);
            testCase.verifyError( ...
                @() uicontrol(g, 'Style', 'pushbutton'), ...
                ?MException, ...
                'uicontrol now accepts a uigridlayout parent -- the panel-granularity workaround can be simplified.');
        end

        function legacyAxesAndImshowWorkInUIFigure(testCase)
            % imtool3D draws with axes + imshow, not uiaxes.
            p  = uipanel(testCase.Fig);
            ax = axes('Parent', p);
            im = imshow(rand(16), 'Parent', ax);
            testCase.verifyTrue(isgraphics(ax) && isgraphics(im), ...
                'Legacy axes/imshow no longer work inside a uifigure.');
        end

        % ---------------------------------------------------------------
        % Silent traps. Each of these fails without throwing, which is why
        % the branch looked healthy while 10 of 22 models were broken.
        % ---------------------------------------------------------------

        function uipanelInUIFigureIsPixelUnited(testCase)
            % Defect #1 in the plan. A GUIDE-era normalized Position assigned to
            % a uipanel inside a uifigure collapses it to sub-pixel size -- with
            % no error -- and downstream pixel arithmetic then goes negative.
            p = uipanel(testCase.Fig);
            testCase.verifyEqual(p.Units, 'pixels', ...
                'uipanel in a uifigure is no longer pixel-united; the Position rewrite may be unnecessary.');

            p.Position = [0.514 0.0158 0.4667 0.9735];   % looks normalized, is not
            pos = getpixelposition(p);
            testCase.verifyLessThan(pos(3), 2, ...
                'Expected a normalized-looking Position to collapse the panel.');
        end

        function uifigureHidesItsHandleByDefault(testCase)
            % Defect #2. qMRLab has 34 findobj sites and 4 external guidata
            % write-backs that all address windows by Name/Tag.
            testCase.verifyEqual(testCase.Fig.HandleVisibility, 'off', ...
                'uifigure HandleVisibility default changed.');

            testCase.Fig.Name = 'tCapabilities probe window';
            testCase.verifyEmpty(findobj('Name', 'tCapabilities probe window'), ...
                'Expected a HandleVisibility=off uifigure to be invisible to findobj.');

            testCase.Fig.HandleVisibility = 'on';
            testCase.verifyNotEmpty(findobj('Name', 'tCapabilities probe window'), ...
                'HandleVisibility=on no longer restores findobj discoverability.');
        end

        function sliderMinSilentlyPartialMatches(testCase)
            % App Designer sliders expose Limits, not Min/Max. set(sl,'Min',x)
            % does not error -- it partial-matches MinorTicks.
            %
            % This is now a FORWARD-LOOKING capability probe: the six lines it was
            % written for were in GetPlotRange.m, deleted in F1, and qMRLab today
            % has no uislider at all (grep -rn uislider src -> zero). It stays
            % because the trap is silent and the next slider added would meet it.
            sl = uislider(testCase.Fig);
            testCase.verifyFalse(isprop(sl, 'Min'), 'uislider gained a Min property.');

            limitsBefore = sl.Limits;
            try
                set(sl, 'Min', 3);
                threw = false;
            catch
                threw = true;
            end
            if ~threw
                testCase.verifyEqual(sl.Limits, limitsBefore, ...
                    'set(slider,''Min'',x) unexpectedly modified Limits.');
                fprintf('  NOTE: set(slider,''Min'',3) silently resolved to MinorTicks = %s\n', ...
                    mat2str(sl.MinorTicks));
            end
        end

        % ---------------------------------------------------------------
        % Modernization prerequisites.
        % ---------------------------------------------------------------

        function nativeTextComponentsHaveNoFontUnits(testCase)
            % Moving off uicontrol REMOVES the only working font adaptivity in
            % the codebase (qMRLab.m:245 uses FontUnits='normalized'), which is
            % why qmrlab.gui.TypeScale has to exist.
            lbl = uilabel(testCase.Fig);
            btn = uibutton(testCase.Fig);
            testCase.verifyFalse(isprop(lbl, 'FontUnits'), ...
                'uilabel gained FontUnits -- TypeScale may be replaceable.');
            testCase.verifyFalse(isprop(btn, 'FontUnits'), ...
                'uibutton gained FontUnits -- TypeScale may be replaceable.');
        end

        function uifigureSupportsTheme(testCase)
            testCase.assumeTrue(isprop(testCase.Fig, 'Theme'), ...
                'This release has no uifigure Theme property.');
            testCase.Fig.Theme = 'dark';
            testCase.verifyNotEmpty(testCase.Fig.Theme);
        end

        function themeDoesNotOverrideExplicitColors(testCase)
            % Why D2 has to STRIP colors first: qMRLab.fig sets
            % Color=[0.247 0.247 0.247] and 19 of 40 components carry a
            % non-factory BackgroundColor.
            testCase.assumeTrue(isprop(testCase.Fig, 'Theme'), ...
                'This release has no uifigure Theme property.');
            explicit = [0.9 0.1 0.1];
            p = uipanel(testCase.Fig, 'BackgroundColor', explicit);
            testCase.Fig.Theme = 'dark';
            drawnow;
            testCase.verifyEqual(p.BackgroundColor, explicit, 'AbsTol', 1e-6, ...
                'Theme now overrides explicitly-set colors.');
        end

        function gridLayoutIsScrollable(testCase)
            % Replaces src/Common/GUI/attachScrollPanelTo.m (Java, dead since R2021a).
            g = uigridlayout(testCase.Fig);
            g.Scrollable = 'on';
            % NB: Scrollable is a matlab.lang.OnOffSwitchState, not a char.
            testCase.verifyTrue(logical(g.Scrollable), ...
                'uigridlayout no longer honours Scrollable.');
        end

        % ---------------------------------------------------------------
        % GUIDE-compatibility surface the shim still depends on.
        % ---------------------------------------------------------------

        function guidataWorksOnUIFigure(testCase)
            s.marker = 42;
            guidata(testCase.Fig, s);
            testCase.verifyEqual(guidata(testCase.Fig), s, ...
                'guidata no longer works on a uifigure -- the handles shim breaks.');
        end

        function uiwaitAndWaitstatusWorkOnUIFigure(testCase)
            % The Model = qMRLab(...) modal contract depends on this pair.
            t = timer('StartDelay', 0.5, 'TimerFcn', @(~,~) uiresume(testCase.Fig));
            testCase.addTeardown(@() delete(t));
            start(t);
            uiwait(testCase.Fig, 5);
            testCase.verifyEqual(get(testCase.Fig, 'waitstatus'), 'inactive', ...
                'uiwait/uiresume/waitstatus no longer round-trip on a uifigure.');
        end

        % ---------------------------------------------------------------
        % Test-infrastructure limits.
        % ---------------------------------------------------------------

        function uitestCannotDriveLegacyUIControl(testCase)
            % This is why the options renderer must go native BEFORE any options
            % interaction test can exist, and why imtool3D needs geometry
            % assertions rather than gestures.
            h = uicontrol(testCase.Fig, 'Style', 'pushbutton', 'String', 'ok');
            testCase.verifyError(@() press(testCase, h), ...
                'MATLAB:uiautomation:Driver:GestureNotSupportedForClass', ...
                'matlab.uitest can now drive uicontrol -- legacy components became testable.');
        end

        % ---------------------------------------------------------------
        % The load-bearing one.
        % ---------------------------------------------------------------

        function imtool3DConstructsInsideUIFigurePanel(testCase)
            % The single highest-risk assumption in the entire migration.
            testCase.assumeNotEmpty(which('imtool3D'), 'imtool3D is not on the path.');

            p = uipanel(testCase.Fig, 'AutoResizeChildren', 'off');
            tool = imtool3D(rand(32, 32, 5), [0 0 1 1], p);
            testCase.addTeardown(@() delete(tool));

            H = tool.getHandles();
            testCase.verifyTrue(isgraphics(H.Axes), 'imtool3D built no axes.');
            testCase.verifyNotEmpty(findall(p, 'Type', 'uicontrol'), ...
                'imtool3D built no uicontrols inside the uifigure panel.');

            % Exercise the API surface qMRLab actually uses.
            tool.setCurrentSlice(2);
            testCase.verifyEqual(tool.getCurrentSlice(), 2);
        end

    end
end
