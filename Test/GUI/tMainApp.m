classdef tMainApp < matlab.uitest.TestCase
% tMainApp  Regression tests for the migrated qMRLab main window.
%
%   Each test here pins a defect found during the GUIDE -> App Designer migration.
%   Every one of them was silent: the app opened, so a smoke test that only checks
%   for exceptions reported success while the behaviour was broken.
%
%   See Test/GUI/STAGE_A_FINDINGS.md and docs/adr/0001-gui-migration.md.
%
%   Run with:  runtests('Test/GUI/tMainApp.m')

    properties (Constant)
        % Chosen deliberately: inversion_recovery is the simple case (has an
        % `equation` method, so the Fitting panel is shown); qsm_sb is the
        % pathological one (16 option rows, and the only model that uses
        % linkGUIState); b0_dem has no `equation`, which takes the other layout
        % branch entirely.
        SimpleModel = 'inversion_recovery';
        LinkedModel = 'qsm_sb';
        NoEqnModel  = 'b0_dem';
    end

    methods (TestClassSetup)
        function requireGraphics(testCase)
            try
                f = uifigure('Visible', 'off');
                delete(f);
            catch ME
                testCase.assumeFail(['No usable graphics environment: ' ME.message]);
            end
        end
    end

    methods (TestMethodSetup)
        function cleanSlate(testCase)
            tMainApp.closeEverything();
            testCase.addTeardown(@tMainApp.closeEverything);
        end
    end

    methods (Test)

        function opensForSimpleModel(testCase)
            qMRLab(feval(testCase.SimpleModel));
            drawnow;
            testCase.verifyNotEmpty(tMainApp.mainFigure(), 'Main window did not open.');
        end

        function survivesCloseAndReopen(testCase)
            % Root cause of "runs but badly broken": FileBrowserList is cached in
            % root appdata and holds graphics handles into the window. After a
            % close, the next launch walked those dead handles and died inside
            % BrowserSet.Visible. The teardown path has to clear the shared store,
            % which is why qMRLab.m's modal branch does exactly that.
            qMRLab(feval(testCase.SimpleModel)); drawnow;
            tMainApp.closeEverything();

            % Assert it does not THROW. A warning about an optional asset is not a
            % relaunch failure, and verifyWarningFree would conflate the two.
            try
                qMRLab(feval(testCase.NoEqnModel));
            catch ME
                testCase.verifyFail(sprintf('Reopen after close threw: %s (%s line %d)', ...
                    ME.message, ME.stack(1).name, ME.stack(1).line));
            end
            drawnow;
            testCase.verifyNotEmpty(tMainApp.mainFigure());
        end

        function survivesReopeningTheSameModel(testCase)
            qMRLab(feval(testCase.LinkedModel)); drawnow;
            tMainApp.closeEverything();
            try
                qMRLab(feval(testCase.LinkedModel));
            catch ME
                testCase.verifyFail(sprintf('Same-model reopen threw: %s (%s line %d)', ...
                    ME.message, ME.stack(1).name, ME.stack(1).line));
            end
            drawnow;
            testCase.verifyNotEmpty(tMainApp.mainFigure());
        end

        function optionsWindowRendersEveryModel(testCase)
            % The layout defect that produced 44 findings in the Stage A triage:
            % a uipanel inside a uifigure is pixel-united, so GUIDE-era normalized
            % Position values collapsed the options panel and everything derived
            % from its pixel size afterwards.
            for model = string(list_models())'
                qMRLab(feval(model)); drawnow;
                opts = tMainApp.optionsFigure();
                testCase.assertNotEmpty(opts, sprintf('%s: options window missing.', model));
                defects = geomAudit(opts);
                testCase.verifyEmpty(defects, sprintf('%s: %d layout defect(s): %s', ...
                    model, numel(defects), strjoin({defects.Detail}, '; ')));
                tMainApp.closeEverything();
            end
        end

        function windowSurvivesResize(testCase)
            % The layout used to be 40 absolute pixel Positions under
            % AutoResizeChildren, which scales children proportionally -- so at a
            % small window the method dropdown was squashed below usable height and
            % the sidebar became unreadable. A grid keeps the sidebar at a fixed
            % width and gives the canvas the remainder.
            qMRLab(feval(testCase.SimpleModel)); drawnow;
            fig = tMainApp.mainFigure();
            testCase.assertNotEmpty(fig);

            % From the design size upward. The window clamps below this -- see
            % MainApp.clampToMinimum and the Stage E note there.
            sizes = [1126 837; 1400 900; 1920 1080; 1280 800];
            for k = 1:size(sizes, 1)
                fig.Position(3:4) = sizes(k, :);
                % Let the layout settle. Normalized children reflow asynchronously
                % and imtool3D relayouts its own pixel children from a resize
                % callback, so a single drawnow is not enough -- measuring too early
                % produces defects that come and go with window size.
                drawnow; pause(0.6); drawnow;
                label = sprintf('at %dx%d', sizes(k,1), sizes(k,2));

                % Deliberately NOT a full-tree geomAudit here. Inside FitDataPanel the
                % data browser and the viewer toolbar are still positioned in pixels
                % by code that runs at runtime: they follow the window as it grows,
                % but their fixed-width rails cannot compress, so shrinking reports
                % overlaps that are real but out of scope until Stage E rewrites
                % those generators onto grids. What this test pins is the part D1
                % actually changed -- the top-level grid.
                sidebar = getpixelposition(tMainApp.byTag(fig, 'SimPanel'));
                testCase.verifyGreaterThan(sidebar(3), 200, sprintf( ...
                    '%s: sidebar squeezed to %.0f px; the grid should hold it fixed.', ...
                    label, sidebar(3)));

                drop = getpixelposition(tMainApp.byTag(fig, 'MethodSelection'));
                testCase.verifyGreaterThanOrEqual(drop(4), 18, ...
                    sprintf('%s: method dropdown collapsed to %.1f px tall.', label, drop(4)));

                canvas = getpixelposition(tMainApp.byTag(fig, 'FitDataPanel'));
                testCase.verifyGreaterThan(canvas(3), 400, ...
                    sprintf('%s: data panel only %.0f px wide.', label, canvas(3)));
            end
        end

        function modelSwitchingDoesNotLeakHandles(testCase)
            % The options panel used to be rebuilt by re-entering the whole opening
            % function, which re-created the protocol panels without ever deleting
            % them. Handle count grew for the life of the window.
            qMRLab(feval(testCase.SimpleModel)); drawnow;
            fig = tMainApp.mainFigure();
            testCase.assertNotEmpty(fig);

            before = numel(findall(fig));
            for k = 1:5
                qMRLab(feval(testCase.NoEqnModel));   drawnow;
                qMRLab(feval(testCase.SimpleModel));  drawnow;
            end
            after = numel(findall(fig));

            testCase.verifyLessThanOrEqual(after, before * 1.1, sprintf( ...
                'Handle count grew from %d to %d over 10 model switches.', before, after));
        end

    end

    methods (Static)
        function h = byTag(root, tag)
            h = findall(root, 'Tag', tag);
            if numel(h) > 1, h = h(1); end
        end

        function fig = mainFigure()
            fig = findall(groot, 'Type', 'figure', 'Name', 'qMRLab');
            if numel(fig) > 1, fig = fig(1); end
        end

        function fig = optionsFigure()
            fig = findall(groot, 'Type', 'figure', 'Name', 'OptionsGUI');
            if numel(fig) > 1, fig = fig(1); end
        end

        function closeEverything()
            % Deleting the figure is not enough on two counts: the app object stays
            % registered as the running singleton, and root appdata outlives the
            % window. Both have to go or the next launch inherits dead handles.
            figs = findall(groot, 'Type', 'figure');
            for k = 1:numel(figs)
                f = figs(k);
                if isprop(f, 'RunningAppInstance') && ~isempty(f.RunningAppInstance)
                    try, delete(f.RunningAppInstance); catch, end %#ok<NOCOM>
                end
            end
            delete(findall(groot, 'Type', 'figure'));

            stale = getappdata(0);
            for f = fieldnames(stale)'
                rmappdata(0, f{1});
            end
            drawnow;
        end
    end
end
