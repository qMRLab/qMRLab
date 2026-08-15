classdef tSimWindows < matlab.unittest.TestCase
% tSimWindows  Characterisation tests for the five GUIDE Sim add-on windows.
%
%   Written BEFORE Stage F2 rewrites them, and that is the whole point: 50 tests
%   reached none of these five windows, so a rewrite would have had nothing to
%   contradict it. Stage D1 shipped an empty Datasets panel with every test
%   green; this is a much bigger blast radius -- ~1170 lines, 299 `handles.`
%   references, five `.fig` files.
%
%   These are CHARACTERISATION tests: they pin what the windows do today,
%   measured, not what they ought to do. Two of them pin DEFECTS in their broken
%   form and say so -- theOptimizeProtocolTableIsHeadedByParameterNames and
%   singleVoxelCurveKeepsTheModelItWasFirstOpenedWith. F2 is free to fix those,
%   deliberately, by changing the test in the same commit; it is not free to lose
%   them silently.
%
%   What is NOT pinned, and why: the exact geometry defect count. It is [0 0 0 0 1]
%   on macOS and [0 0 0 2 3] on the Linux CI runner, and every extra is an axes
%   plot box whose extent follows font metrics. The audit test asserts the kinds
%   that mean the same thing everywhere and prints the rest.
%
%   WHAT MAKES THESE WINDOWS HARD TO REACH FROM A TEST
%
%   - Every one carries HandleVisibility='callback', so findobj CANNOT see them
%     from a test body. findobj returns empty and the assertion passes vacuously,
%     which is exactly the failure mode this file exists to prevent. Use findall.
%   - All five share Tag='Simu'. Disambiguate by Name.
%   - They are GUIDE singletons: a second call raises the existing figure and
%     re-enters the opening function with handles.opened already set, skipping
%     the population block. Delete between models.
%   - guidata returns a COPY of the handles struct. A handle captured before a
%     callback never sees what that callback wrote back; re-fetch after invoking.
%
%   Run with:  runtests('Test/GUI/tSimWindows.m')

    properties (Constant)
        % charmed is the only model that declares all five Sim methods, so it is
        % the one model that can exercise every window (charmed.m:299,326,331,336,372).
        Model = 'charmed';

        % Name is the only way to tell the five apart -- Tag is 'Simu' for all of
        % them. Two are named after their window and three after their .fig.
        Windows = { 'Sim_Single_Voxel_Curve_GUI',       'Single Voxel Curve'
                    'Sim_Sensitivity_Analysis_GUI',     'Sensitivity Analysis'
                    'Sim_Multi_Voxel_Distribution_GUI', 'Multi Voxel Distribution'
                    'Sim_Optimize_Protocol_GUI',        'SimOptProt'
                    'Sim_MonteCarlo_Diffusion_GUI',     'SimMCdiff' }
    end

    methods (TestClassSetup)
        function requireGraphics(testCase)
            try
                f = uifigure('Visible', 'off'); delete(f);
            catch ME
                testCase.assumeFail(['No usable graphics environment: ' ME.message]);
            end
        end
    end

    methods (TestMethodSetup)
        function cleanSlate(testCase)
            tSimWindows.closeEverything();
            testCase.addTeardown(@tSimWindows.closeEverything);
        end
    end

    methods (Test)

        function everyDeclaredWindowOpensWithTheSimTag(testCase)
            % The floor: all five construct without throwing and produce a figure
            % under the Tag the main window tears down by (MainApp.m:1164). F2
            % must keep Tag='Simu' or closing qMRLab stops closing them.
            model = feval(testCase.Model);
            for k = 1:size(tSimWindows.Windows, 1)
                fig = tSimWindows.open(testCase, k, model);
                testCase.verifyEqual(fig.Tag, 'Simu', sprintf( ...
                    '%s: figure Tag is ''%s'', not ''Simu''.', ...
                    tSimWindows.Windows{k,1}, fig.Tag));
            end
        end

        function theWindowsAreInvisibleToFindobj(testCase)
            % Pinned because it silently turns an assertion into a vacuous pass,
            % and because a rewrite that "fixes" HandleVisibility would change
            % what MainApp.m:1164 tears down. If F2 makes them visible, this test
            % should be changed on purpose, not discovered by a stale test.
            model = feval(testCase.Model);
            fig = tSimWindows.open(testCase, 1, model);
            testCase.verifyEqual(fig.HandleVisibility, 'callback');
            testCase.verifyEmpty(findobj('Tag', 'Simu'), ...
                'findobj now reaches the Sim windows; the tests may be passing vacuously.');
            testCase.verifyNotEmpty(findall(groot, 'Tag', 'Simu'));
        end

        function theSidebarOffersExactlyTheWindowsTheModelDeclares(testCase)
            % The sidebar buttons are built at RUNTIME by MethodMenu
            % (MainApp.m:290-294) from methods() whose name contains 'Sim_' and
            % that have a matching _GUI file on the path -- not from static
            % components, and NOT from Model.voxelwise. They carry no Tag, so
            % they can only be found by class and label.
            qMRLab(feval(testCase.Model)); drawnow;
            fig = tSimWindows.mainFigure();
            testCase.assertNotEmpty(fig, 'Main window did not open.');
            panel = findall(fig, 'Tag', 'SimPanel');
            testCase.assertNotEmpty(panel, 'SimPanel is missing.');
            testCase.verifyEqual(panel(1).Visible, matlab.lang.OnOffSwitchState('on'), ...
                'charmed declares five Sim methods but the panel is hidden.');

            labels = sort(tSimWindows.sidebarLabels(panel(1)));
            expected = sort({'Single Voxel Curve'; 'Sensitivity Analysis'; ...
                             'Multi Voxel Distribution'; 'Optimize Protocol'; ...
                             'MonteCarlo Diffusion'});
            testCase.verifyEqual(labels, expected, ...
                'The sidebar no longer offers exactly charmed''s five Sim windows.');
        end

        function aSidebarButtonActuallyOpensItsWindow(testCase)
            % The path a user takes, and the one no test had ever driven. These
            % are uicontrols, which matlab.uitest refuses to press
            % (tCapabilities/uitestCannotDriveLegacyUIControl), so the callback is
            % invoked directly -- and unlike the components reached through
            % `handles`, these never pass through the migration converter, so
            % their own Callback property IS the authority.
            qMRLab(feval(testCase.Model)); drawnow;
            fig = tSimWindows.mainFigure();
            testCase.assertNotEmpty(fig);
            panel = findall(fig, 'Tag', 'SimPanel');
            testCase.assertNotEmpty(panel);

            buttons = findall(panel(1), '-isa', 'matlab.ui.control.UIControl');
            testCase.assertNotEmpty(buttons, 'No runtime Sim buttons were built.');
            labels = arrayfun(@(b) string(b.String), buttons);
            hit = buttons(labels == "Single Voxel Curve");
            testCase.assertNotEmpty(hit, 'No "Single Voxel Curve" button.');

            cb = get(hit(1), 'Callback');
            testCase.assertNotEmpty(cb, 'The sidebar button is wired to nothing.');
            cb(hit(1), []);
            drawnow;

            opened = findall(groot, 'Type', 'figure', 'Name', 'Single Voxel Curve');
            testCase.verifyNotEmpty(opened, ...
                'Pressing the sidebar button did not open the Single Voxel Curve window.');
        end

        function singleVoxelCurveShowsTheModelParameters(testCase)
            % The table is read back BY COLUMN INDEX when the fit runs
            % (Sim_Single_Voxel_Curve_GUI.m:127-134,141-144), so renaming or
            % reordering a column silently misfiles the CRLB rather than erroring.
            model = feval(testCase.Model);
            fig = tSimWindows.open(testCase, 1, model);
            h = guidata(fig);

            testCase.assertTrue(isfield(h, 'ParamTable'), 'No ParamTable in handles.');
            testCase.verifyEqual(h.ParamTable.ColumnName(:)', ...
                {'Name', 'Input', 'Fitted', 'Pct. error', 'Pct. CRLB'}, ...
                'The parameter table headers changed; the fit reads these by index.');
            testCase.verifyEqual(h.ParamTable.Data(:,1), model.xnames(:), ...
                'Column 1 must list the model parameter names.');
            % Columns 3-5 are deliberately empty until Update Fit runs.
            testCase.verifySize(h.ParamTable.Data, [numel(model.xnames) 2]);
        end

        function sensitivityAnalysisSeedsItsPlotAxesFromTheModel(testCase)
            % The .fig ships both popupmenus with an EMPTY String; :78-79 fills
            % them from Model.xnames. An empty popup after construction is
            % precisely the "opened without error, renders nothing" failure that
            % an exception-counting smoke test cannot see.
            model = feval(testCase.Model);
            fig = tSimWindows.open(testCase, 2, model);
            h = guidata(fig);

            testCase.verifyEqual(cellstr(h.SimVaryPlotX.String), model.xnames(:), ...
                'The X plot selector is not seeded from the model.');
            testCase.verifyEqual(cellstr(h.SimVaryPlotY.String), model.xnames(:), ...
                'The Y plot selector is not seeded from the model.');
            testCase.verifyEqual(h.SimVaryOptTable.ColumnName(:)', ...
                {'Variable', 'Vary', 'Nominal', 'Min', 'Max'});
            testCase.verifyEqual(h.SimVaryOptTable.Data(:,1), model.xnames(:));

            % Two-phase contract: results only exist after Update, and the plot
            % callback guards on the field (:277-282).
            testCase.verifyFalse(isfield(h, 'SimVaryResults'), ...
                'SimVaryResults exists before Update ran.');
        end

        function multiVoxelDistributionOffersItsPlotTypes(testCase)
            % Eight fixed plot types, and a parameter table whose first column is
            % LOGICAL (the Vary checkboxes) rather than the parameter names --
            % unlike the other two tables, which is easy to get wrong in a rewrite.
            model = feval(testCase.Model);
            fig = tSimWindows.open(testCase, 3, model);
            h = guidata(fig);

            testCase.verifyEqual(cellstr(h.SimRndPlotType.String)', ...
                {'Input parameters', 'Fit results', 'Input vs. Fit', 'Error', ...
                 'Pct error', 'RMSE', 'NRMSE', 'MPE'});
            testCase.verifyEqual(h.SimRndVaryOptTable.ColumnName(:)', ...
                {'Vary', 'Mean', 'Std', 'Min', 'Max'});
            testCase.verifyEqual(h.SimRndVaryOptTable.RowName(:), model.xnames(:), ...
                'The rows must be labelled with the model parameters.');
            testCase.verifyEqual(cellstr(h.SimRndPlotX.String), model.xnames(:));
        end

        function theOptimizeProtocolTableIsHeadedByParameterNames(testCase)
            % PINS A DEFECT, deliberately. Every other window puts the parameter
            % names in a COLUMN; this one puts them in the column HEADERS and
            % holds a 1xN row of values, because it is built by GenerateButtons
            % (:69) rather than GenerateButtonsWithPanels. F2 may well want to
            % make this consistent -- if so, change this test in that commit.
            model = feval(testCase.Model);
            fig = tSimWindows.open(testCase, 4, model);
            h = guidata(fig);

            testCase.verifyEqual(h.ParamTable.ColumnName(:), model.xnames(:), ...
                'Optimize Protocol heads its table with the parameter names.');
            testCase.verifySize(h.ParamTable.Data, [1 numel(model.xnames)]);
        end

        function monteCarloBuildsItsPackingControls(testCase)
            % The odd one out: no options struct at all -- it drives axon packing
            % from named sliders, and it is the only window with more than one
            % axes. A rewrite that keeps the figure but loses the sliders would
            % otherwise pass everything above.
            model = feval(testCase.Model);
            fig = tSimWindows.open(testCase, 5, model);
            h = guidata(fig);

            for slider = {'slider_Naxons', 'slider_dmean', 'slider_dvar', 'slider_gap'}
                testCase.verifyTrue(isfield(h, slider{1}), sprintf( ...
                    'Monte Carlo lost its %s control.', slider{1}));
            end
            testCase.verifyNotEmpty(cellstr(h.preset_packing.String), ...
                'The packing preset list is empty; nothing can be loaded.');
            testCase.verifyNotEmpty(h.tableVolumes.Data, ...
                'The volume fractions table is empty.');
            testCase.verifyGreaterThanOrEqual( ...
                numel(findall(fig, '-isa', 'matlab.graphics.axis.Axes')), 3, ...
                'Monte Carlo draws the packing and the distribution; both axes must exist.');
        end

        function theOptionControlsMatchTheDslTheModelDeclares(testCase)
            % Three of the five build their options column with the same
            % generator the main options window uses, so the DSL contract tDSL
            % pins applies here too -- the *lbl companions included. Optimize
            % Protocol is NOT in this list: it uses GenerateButtons, which names
            % handles differently, and Monte Carlo has no options struct.
            model = feval(testCase.Model);

            fig = tSimWindows.open(testCase, 1, model);
            testCase.verifyEqual(tSimWindows.optionNames(fig), {'SNR'}, ...
                'Single Voxel Curve falls back to {''SNR'',50} when the model declares nothing.');

            fig = tSimWindows.open(testCase, 2, model);
            testCase.verifyEqual(tSimWindows.optionNames(fig), {'Nofrun'; 'SNR'}, ...
                'Sensitivity Analysis concatenates the single-voxel options with its own.');

            fig = tSimWindows.open(testCase, 3, model);
            testCase.verifyEqual(tSimWindows.optionNames(fig), {'Nofvoxels'; 'SNR'});
        end

        function noSimWindowCollapsesOrOverflowsItsPanels(testCase)
            % This asserted exact defect COUNTS per window until CI showed why that
            % cannot work: measured on macOS the five audit [0 0 0 0 1], and on the
            % Linux runner Optimize Protocol reports 2 and Monte Carlo 3. Every one
            % of the extras is an AXES whose plot box sits outside its panel by tens
            % of pixels -- axes extents follow font metrics, so that number is a
            % property of the machine, not of the window.
            %
            % So the assertion is on what a rewrite can actually break, and what
            % means the same thing on every platform:
            %
            %   Collapsed / Unsettled  a container that is sub-pixel or was never
            %                          laid out. Broken anywhere, for anything.
            %   Overflow of a PANEL or TABLE   a real containment failure.
            %   Overflow of an AXES    reported, not asserted: this is the
            %                          font-metric noise above, and Monte Carlo has
            %                          had one on macOS since before F2 touched it.
            model = feval(testCase.Model);
            for k = 1:size(tSimWindows.Windows, 1)
                fig = tSimWindows.open(testCase, k, model);
                defects = geomAudit(fig);
                name = tSimWindows.Windows{k,1};

                unsettled = defects(ismember({defects.Kind}, {'Collapsed', 'Unsettled'}));
                testCase.verifyEmpty(unsettled, sprintf('%s: %s', name, ...
                    tSimWindows.describe(unsettled)));

                overflow = defects(strcmp({defects.Kind}, 'Overflow'));
                notAxes  = overflow(~contains({overflow.Type}, 'Axes'));

                % The allowance that used to sit here, for Optimize Protocol's
                % ParamTable overflowing on Linux only, is gone: F2 rebuilt that
                % window and the cause with it. The table was positioned in
                % CHARACTER units, which are a font metric, so it fitted on macOS
                % and did not on the runner. It is normalized now.

                testCase.verifyEmpty(notAxes, sprintf( ...
                    '%s: a panel or table is outside its parent: %s', name, ...
                    tSimWindows.describe(notAxes)));

                if ~isempty(overflow)
                    fprintf('  (%s: %d axes plot box(es) outside their panel)\n', ...
                        name, numel(overflow));
                end
            end
        end

        function singleVoxelCurveAdoptsTheModelItIsOpenedWith(testCase)
            % This pinned a DEFECT until F2 rebuilt the window, and the fix is why
            % the assertion is now the other way round.
            %
            % Sim_Single_Voxel_Curve_GUI.m:55-57 used to assign handles.Model
            % INSIDE the `~isfield(handles,'opened')` guard, unlike the other four
            % windows. MethodMenu does not tear the Sim windows down when the
            % method changes, so opening this window on one model and then on
            % another left it simulating the FIRST -- silently, with the new
            % model's name in the main window. The rebuild re-points the window on
            % every open.
            first = feval(testCase.Model);
            fig = tSimWindows.open(testCase, 1, first);
            testCase.assertClass(guidata(fig).Model, testCase.Model);

            % Re-open on a different model WITHOUT deleting the window, which is
            % what switching methods in the main window does.
            other = mono_t2();
            setappdata(0, 'Model', other);
            Sim_Single_Voxel_Curve_GUI(other);
            drawnow;

            fig = findall(groot, 'Type', 'figure', 'Name', 'Single Voxel Curve');
            testCase.assertNotEmpty(fig);
            handles = guidata(fig(1));
            testCase.verifyClass(handles.Model, 'mono_t2', ...
                'The window is still holding the model it was first opened with.');
            testCase.verifyEqual(handles.ParamTable.Data(:,1), other.xnames(:), ...
                'The parameter table still lists the previous model''s parameters.');
        end

    end

    methods (Static)
        function s = describe(defects)
            if isempty(defects); s = '(none)'; return; end
            parts = arrayfun(@(d) sprintf('[%s %s] %s', d.Kind, ...
                extractAfter(d.Type, find(d.Type == '.', 1, 'last')), d.Detail), ...
                defects, 'UniformOutput', false);
            s = strjoin(parts, '; ');
        end

        function fig = open(testCase, k, model)
            % Delete first: these are GUIDE singletons, so a second call would
            % raise the existing figure and skip its population block entirely.
            delete(findall(groot, 'Tag', 'Simu'));
            % The Update callbacks read the model back out of the shared store
            % rather than from handles, so it has to be there.
            setappdata(0, 'Model', model);
            feval(tSimWindows.Windows{k,1}, model);
            drawnow;
            fig = findall(groot, 'Type', 'figure', 'Name', tSimWindows.Windows{k,2});
            testCase.assertNotEmpty(fig, sprintf('%s opened no figure named ''%s''.', ...
                tSimWindows.Windows{k,1}, tSimWindows.Windows{k,2}));
            fig = fig(1);
        end

        function names = optionNames(fig)
            % The generator emits a <name>lbl companion for every option; the
            % payload is the set without them.
            h = guidata(fig);
            if ~isfield(h, 'options') || ~isstruct(h.options)
                names = {}; return
            end
            names = fieldnames(h.options);
            names = sort(names(~endsWith(names, 'lbl')));
        end

        function labels = sidebarLabels(panel)
            buttons = findall(panel, '-isa', 'matlab.ui.control.UIControl');
            labels = cell(numel(buttons), 1);
            for k = 1:numel(buttons)
                labels{k} = buttons(k).String;
            end
        end

        function fig = mainFigure()
            fig = findall(groot, 'Type', 'figure', 'Name', 'qMRLab');
            if numel(fig) > 1, fig = fig(1); end
        end

        function closeEverything()
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
