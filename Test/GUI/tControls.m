classdef tControls < matlab.uitest.TestCase
% tControls  Does anything actually HAPPEN when you click?
%
%   WHY THIS FILE EXISTS
%
%   The suite was 26/26 green while the "Fit data" button -- the primary action of
%   the whole application -- was wired to nothing. Clicking it did precisely
%   nothing, silently, and no test noticed.
%
%   Every other test asserts something ABOUT the window: that it opens, that its
%   panels are the right size, that the Datasets panel has one row per input, that
%   the handle count stays flat across model switches. Not one of them presses a
%   button. A control wired to nothing satisfies all of them.
%
%   So the standing rule needed a second clause. It read:
%
%       Green tests are strong evidence for BEHAVIOUR and weak evidence for
%       APPEARANCE.
%
%   That is only true of behaviour the tests DRIVE. Opening a window exercises
%   construction and says nothing about what the window does when used:
%
%       Green tests are evidence only for the code paths they execute. A callback
%       that is never invoked is untested however many tests pass.
%
%   HOW TO TELL A DEAD CONTROL FROM A LIVE ONE
%
%   Not by reading the component's own callback property. MATLAB's migration
%   runtime (convertToGUIDECallbackArguments -> UIControlPropertiesConverter) wraps
%   every tagged component in a uicontrol-compatibility adapter and REWRITES that
%   property: the redirect strategy installs its own forwarder
%   (@obj.handleCallbackFired) and moves the real callback into the adapter. So the
%   native property is misleading in both directions -- measured on the live app:
%
%       FitGO            (dead)  ButtonPushedFcn = <a forwarder>   -- looks wired
%       MethodSelection  (live)  ValueChangedFcn = <empty>         -- looks dead
%
%   The authority is the adapter, reached through guidata: handles.<Tag>.Callback.
%   Verified against both revisions -- 3 dead before the fix, 0 after.
%
%   That same adapter is why the GUIDE-era property names in the callback bodies
%   (String, ForegroundColor, numeric Value) still work: it translates them. Only
%   code that reaches a component WITHOUT going through handles -- findobj, or a
%   stored handle in a class like BrowserSet -- sees the raw native component and
%   has to use the native property names. That is exactly where the second bug in
%   this file's regression set lived.
%
%   See also: tMainApp, docs/adr/0001-gui-migration.md

    properties (Constant)
        SimpleModel = 'inversion_recovery';

        % Adapter Style values that denote something a user can operate. A uilabel
        % is adapter-wrapped too and reports 'text'; it has no callback by design.
        Interactive = {'pushbutton','togglebutton','popupmenu','checkbox', ...
                       'edit','listbox','slider','radiobutton'};
    end

    properties
        StubDir char = ''
        DataDir char = ''
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
            tControls.closeEverything();
            testCase.addTeardown(@tControls.closeEverything);
        end
    end

    methods (Test)

        function everyControlIsWired(testCase)
            % The whole "clicking does nothing" class, in one assertion.
            %
            % No allow-list: every control in this window exists to do something,
            % so an empty callback is a defect rather than a design choice.
            qMRLab(feval(testCase.SimpleModel));
            drawnow;

            fig = tControls.mainFigure();
            testCase.assertNotEmpty(fig, 'Main window did not open.');

            dead = tControls.deadControlsIn(fig);
            testCase.verifyEmpty(dead, sprintf( ...
                ['These controls are wired to nothing -- clicking them does nothing ' ...
                 'and no error is raised:\n  %s'], strjoin(dead, '\n  ')));
        end

        function fitButtonProducesResults(testCase)
            % The regression test for the bug a user reported: load data, press
            % "Fit data", nothing happens.
            %
            % This drives the real gesture rather than calling the callback
            % directly, because the defect was in the WIRING -- invoking
            % FitGO_Callback by hand would have passed against the broken app.
            testCase.stubBlockingDialogs();
            model = tControls.tinyDataFor(testCase, testCase.SimpleModel);

            qMRLab(model.Model, model.Files);
            drawnow;
            fig = tControls.mainFigure();
            testCase.assertNotEmpty(fig, 'Main window did not open.');

            if isappdata(0, 'FitResults'); rmappdata(0, 'FitResults'); end

            btn = findall(fig, 'Tag', 'FitGO');
            testCase.assertNotEmpty(btn, 'The Fit data button does not exist.');
            testCase.press(btn(1));
            drawnow;

            testCase.verifyTrue(isappdata(0, 'FitResults'), ...
                'Pressing "Fit data" produced no FitResults.');
            FR = getappdata(0, 'FitResults');
            testCase.verifyNotEmpty(FR.fields, 'The fit returned no output maps.');
        end

        function loadingASingleFileDoesNotThrow(testCase)
            % qMRLab(Model, data) is the documented way to open the GUI on data,
            % and it threw: BrowserSet.DataLoad assigned into an empty handle
            % because the warning label it looks up by Tag carried no Tag.
            %
            % Every single-file load came through that line -- the per-input "+"
            % button, Clear, and this API. Only the folder-at-a-time path
            % (Download example / Browse) escaped it, by passing warnmissing = 0,
            % which is why the app looked healthy.
            model = tControls.tinyDataFor(testCase, testCase.SimpleModel);

            testCase.verifyWarningFree(@() qMRLab(model.Model, model.Files), ...
                'qMRLab(Model, data) failed to load a single file.');
            drawnow;

            D = getappdata(0, 'Data');
            testCase.assertTrue(isfield(D, testCase.SimpleModel), 'No data was stored.');
            testCase.verifyNotEmpty(D.(testCase.SimpleModel).IRData, ...
                'The input file loaded as empty.');

            % The SUCCESS path specifically. sanityCheck returns a message when the
            % data is wrong and 0x0 double [] when it is right, and uilabel.Text
            % rejects []. So the warning label threw precisely when nothing was
            % wrong -- the branch a happy-path test walks straight past unless it
            % checks that the label is now clear.
            warn = findall(tControls.mainFigure(), 'Tag', ...
                ['WarnBut_DataConsistency_' testCase.SimpleModel]);
            testCase.assertNotEmpty(warn, 'The warning label is missing.');
            testCase.verifyEmpty(char(warn(1).Text), sprintf( ...
                'Valid data still shows the warning "%s".', char(warn(1).Text)));
            testCase.verifyEqual(char(warn(1).Visible), 'off', ...
                'The warning label is visible although the data is valid.');
        end

        function typingAPathIntoAFileBoxLoadsIt(testCase)
            % The file box was wired to obj.FileBox_callback(), a method that has
            % never existed on BrowserSet, so typing or pasting a path threw
            % noSuchMethodOrField. Nothing caught it because the wiring named a
            % method rather than being empty -- everyControlIsWired sees a callback
            % and is satisfied. Only invoking it finds this.
            model = tControls.tinyDataFor(testCase, testCase.SimpleModel);
            qMRLab(model.Model);
            drawnow;

            box = tControls.fileBoxFor(testCase.SimpleModel, 'REQUIRED');
            testCase.assumeNotEmpty(box, 'Could not find the IRData file box.');
            box.Value = model.Files.IRData;
            testCase.verifyWarningFree(@() feval(box.ValueChangedFcn, box, []), ...
                'Typing a path into the file box failed.');

            D = getappdata(0, 'Data');
            testCase.verifyNotEmpty(D.(testCase.SimpleModel).IRData, ...
                'The typed path did not load the file.');
        end

        function dataConsistencyWarningIsReachable(testCase)
            % Two independent consumers -- BrowserSet.DataLoad and
            % OptionsWindow.SetOpt -- find this label by exactly this Tag. Both
            % were no-ops for the life of the migration because the label was
            % created without one, so the warning has never been shown to anyone.
            % Pin the Tag: it is an interface between three files.
            qMRLab(feval(testCase.SimpleModel));
            drawnow;

            tag = ['WarnBut_DataConsistency_' testCase.SimpleModel];
            h = findall(tControls.mainFigure(), 'Tag', tag);
            testCase.assertNotEmpty(h, sprintf( ...
                'No component carries the Tag "%s" that its two consumers look up.', tag));
            testCase.verifyTrue(isprop(h(1), 'Text'), ...
                'The consumers set Text on this component; it has no Text property.');
        end

    end

    methods

        function stubBlockingDialogs(testCase)
            % FitGo_FitData asks, through questdlg, whether to start a parallel
            % pool. A modal dialog cannot be answered in a headless run, so shadow
            % it for the duration of the test. Scoped and reverted in teardown --
            % never left on the path, where it would silence the real function.
            testCase.StubDir = fullfile(tempname, 'stubs');
            mkdir(testCase.StubDir);
            fid = fopen(fullfile(testCase.StubDir, 'questdlg.m'), 'w');
            fprintf(fid, 'function out = questdlg(varargin)\nout = ''No'';\nend\n');
            fclose(fid);
            addpath(testCase.StubDir, '-begin');
            testCase.addTeardown(@() rmpath(testCase.StubDir));
        end

    end

    methods (Static)

        function names = deadControlsIn(fig)
            % A control is dead when its adapter has no Callback. See the class
            % comment for why the component's own property cannot be trusted.
            names = {};
            h = guidata(fig);
            if isempty(h) || ~isstruct(h); return; end
            for f = fieldnames(h)'
                o = h.(f{1});
                % handles carries more than components -- the imtool3D object, the
                % model directory, cached data, and object ARRAYS, on which isprop
                % returns a vector rather than a scalar.
                if ~isscalar(o) || ~isobject(o); continue; end
                if ~isprop(o, 'Callback') || ~isprop(o, 'Style'); continue; end
                style = '';
                try, style = o.Style; catch, continue; end %#ok<NOCOM>
                if ~any(strcmp(style, tControls.Interactive)); continue; end
                if isempty(o.Callback)
                    names{end+1} = sprintf('%s (%s)', f{1}, style); %#ok<AGROW>
                end
            end
            names = sort(names);
        end

        function out = tinyDataFor(testCase, modelName)
            % A fit small enough to run inside a test, through the real file
            % loading path -- writing .mat files and handing over their paths,
            % rather than poking appdata, because the loading path is under test.
            out.Model = feval(modelName);
            out.Dir = fullfile(tempname, 'data');
            mkdir(out.Dir);
            testCase.addTeardown(@() rmdir(out.Dir, 's'));

            nTI = size(out.Model.Prot.IRData.Mat, 1);
            IRData = rand(4, 4, 1, nTI) * 100;  %#ok<NASGU>
            Mask   = ones(4, 4);                %#ok<NASGU>
            save(fullfile(out.Dir, 'IRData.mat'), 'IRData');
            save(fullfile(out.Dir, 'Mask.mat'),   'Mask');

            out.Files.IRData = fullfile(out.Dir, 'IRData.mat');
            out.Files.Mask   = fullfile(out.Dir, 'Mask.mat');
        end

        function box = fileBoxFor(~, marker)
            % The per-input file boxes carry no Tag -- BrowserSet keeps them in a
            % private property and reaches them through the object, not findobj. They
            % are identifiable by their placeholder text, which BrowserSet seeds with
            % 'REQUIRED ...' or 'OPTIONAL' according to the input.
            box = [];
            panel = findall(tControls.mainFigure(), 'Tag', 'FitDataFileBrowserPanel');
            if isempty(panel); return; end
            fields = findall(panel(1), '-isa', 'matlab.ui.control.EditField');
            for k = 1:numel(fields)
                if ~strcmp(fields(k).Visible, 'on'); continue; end
                if startsWith(char(fields(k).Value), marker)
                    box = fields(k); return
                end
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
            for k = {'Model', 'Data', 'FileBrowserList', 'MethodList', 'Method', 'FitResults'}
                if isappdata(0, k{1}); rmappdata(0, k{1}); end
            end
            drawnow;
        end
    end
end
