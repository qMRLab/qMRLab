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
%   By reading the callback property FOR THE CONTROL'S CLASS, off the component
%   itself. That is a change from what this file used to say, and the reason is
%   worth keeping.
%
%   While the GUIDE shim was in place it was not that simple. The migration
%   runtime (convertToGUIDECallbackArguments -> UIControlPropertiesConverter)
%   wrapped every tagged component in a uicontrol-compatibility adapter, and for
%   DROPDOWNS PopupMenuRedirectStrategy nulled the native ValueChangedFcn and
%   carried the wiring on ClickedFcn instead. So the native property really was
%   misleading, and the authority really was handles.<Tag>.Callback:
%
%       FitGO            (dead)  ButtonPushedFcn = <a forwarder>   -- looked wired
%       MethodSelection  (live)  ValueChangedFcn = <empty>         -- looked dead
%
%   Stage F1 retires that shim. With no shim call, no adapter is ever built and
%   the wiring createComponents installs with createCallbackFcn is the wiring
%   that fires -- so the native property becomes the authority. But the audit
%   could not simply be re-pointed at it, because reading guidata was ALSO how
%   the old audit FOUND the controls. With no adapters in guidata its loop
%   inspects nothing and passes. It would have switched itself off in the commit
%   everyone would assume was safest.
%
%   So the audit was rewritten FIRST, deliberately, while the shim was still in
%   place, and it has to pass in both worlds -- that is the evidence that it
%   measures the app and not the adapter. See deadControlsIn for the walk, for
%   why a DropDown counts as wired on either property, and for why it returns a
%   denominator.
%
%   The adapter is also why GUIDE-era property names (String, TooltipString,
%   numeric Value) work in the callback bodies: it translates them. F1 translates
%   them for real -- uilabel.Text, uibutton.Tooltip, and a numeric dropdown Value
%   maintained through ItemsData by setPopUp. Code that reaches a component
%   WITHOUT going through handles always saw the raw native component and always
%   had to use native names; that is where the second bug in this file's
%   regression set lived, and F1 makes every path that path.
%
%   See also: tMainApp, docs/adr/0001-gui-migration.md

    properties (Constant)
        SimpleModel = 'inversion_recovery';

        % Controls that are deliberately inert: they carry no callback because
        % something else drives them. Each entry needs a reason, and the reason
        % has to be that the control is DRIVEN elsewhere -- not that it is
        % currently broken. Adding a Tag here to silence a failure is how this
        % test stops being worth running.
        InertByDesign = { ...
            'MainLogo'             % the qMRLab wordmark; an Image, not a control
            'WorkDir_FileNameArea' % Path data: written by Browse, read at load time
            'StudyID_TextID'       % Study ID: free text, read at fit time
            };
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

            [dead, inspected] = tControls.deadControlsIn(fig);

            % The denominator, asserted FIRST. Without it this test passes when it
            % inspects nothing at all -- which is exactly what its predecessor did
            % the moment the shim stopped seeding guidata. 25 is well under the
            % ~60 the native walk reaches on a loaded window, and well over
            % anything a broken walk would return.
            testCase.assertGreaterThan(numel(inspected), 25, sprintf( ...
                ['The wiring audit only inspected %d controls, so it is not ' ...
                 'measuring the window any more -- fix the audit before trusting ' ...
                 'a green result.'], numel(inspected)));

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

        function viewingAnInputAfterFittingDoesNotThrow(testCase)
            % A journey test: fit, then view an input. It drives DrawPlot,
            % UpdatePopUp and the viewer twice over, with the Volume list growing to
            % the output maps and shrinking back to the input.
            %
            % It is NOT a regression test for the setPopUp ordering hazard, though it
            % was written as one. Being accurate about that: the hazard is real at the
            % API level -- a stale Value index makes the NEXT Items assignment throw
            % MATLAB:badsubscript, proved directly against the adapter -- but this
            % test passes with and without the fix, and no user-reachable sequence was
            % found that produces a stale index, because DrawPlot always derives the
            % index from the NEW field list. setPopUp is hardening against a latent
            % hazard, not a repair of an observed failure, and the absence of a
            % failing test here is the evidence for that rather than an oversight.
            testCase.stubBlockingDialogs();
            model = tControls.tinyDataFor(testCase, testCase.SimpleModel);

            qMRLab(model.Model, model.Files);
            drawnow;
            fig = tControls.mainFigure();
            testCase.assertNotEmpty(fig);

            testCase.press(findall(fig, 'Tag', 'FitGO'));
            drawnow;
            source = findall(fig, 'Tag', 'SourcePop');
            testCase.assumeGreaterThan(numel(source(1).Items), 1, ...
                'The fit did not produce a multi-volume result; nothing to shrink.');

            view = tControls.viewButtonFor('IRData');
            testCase.assertNotEmpty(view, 'Could not find the IRData View button.');
            testCase.verifyWarningFree(@() feval(view.ButtonPushedFcn, view, []), ...
                'Viewing an input after a fit threw.');
            drawnow;

            source = findall(fig, 'Tag', 'SourcePop');
            testCase.verifyNotEmpty(source(1).Items, ...
                'The Volume dropdown was left with no entries.');
        end

        function emptyMaskFailsCleanlyWithoutWritingAnything(testCase)
            % A mask that excludes every voxel is an ordinary user mistake -- an
            % empty ROI, or a mask that does not overlap the data. It used to throw
            % "Unrecognized field name fields" from inside the map-saving loop, AFTER
            % having already created FitResults_<timestamp>/ and written into it. So
            % the user got a stack trace plus a junk directory beside their data.
            testCase.stubBlockingDialogs();
            model = tControls.tinyDataFor(testCase, testCase.SimpleModel);

            % An all-zero mask: valid input, no voxels to fit.
            Mask = zeros(4, 4); %#ok<NASGU>
            save(fullfile(model.Dir, 'Mask.mat'), 'Mask');

            here = pwd;
            cd(model.Dir);
            testCase.addTeardown(@() cd(here));

            qMRLab(model.Model, model.Files);
            drawnow;
            fig = tControls.mainFigure();
            testCase.assertNotEmpty(fig);

            testCase.verifyWarningFree(@() testCase.press(findall(fig, 'Tag', 'FitGO')), ...
                'Fitting an empty mask threw instead of reporting the problem.');

            testCase.verifyEmpty(dir(fullfile(model.Dir, 'FitResults*')), ...
                'A failed fit still wrote a FitResults directory to disk.');
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
            stubs = { 'questdlg', 'out = ''No'';' ; ...
                      'errordlg', 'out = [];' ; ...
                      'warndlg',  'out = [];' ; ...
                      'helpdlg',  'out = [];' };
            for k = 1:size(stubs, 1)
                fid = fopen(fullfile(testCase.StubDir, [stubs{k,1} '.m']), 'w');
                fprintf(fid, 'function out = %s(varargin)\n%s\nend\n', stubs{k,1}, stubs{k,2});
                fclose(fid);
            end
            addpath(testCase.StubDir, '-begin');
            testCase.addTeardown(@() rmpath(testCase.StubDir));
        end

    end

    methods (Static)

        function [names, inspected] = deadControlsIn(fig)
            % A control is dead when the callback property FOR ITS CLASS is empty.
            %
            %   Walks findall(fig), NOT guidata. The guidata walk this replaced
            %   asked isprop(o,'Callback') && isprop(o,'Style') -- both properties
            %   exist only on the migration ADAPTER. Once the shim stops seeding
            %   guidata those two guards `continue` on every field, the loop
            %   inspects nothing, and verifyEmpty passes. The one test written to
            %   catch "clicking does nothing" would have switched itself off in the
            %   commit that retired the shim, and reported success.
            %
            %   Hence the second return value. `inspected` is the DENOMINATOR, and
            %   everyControlIsWired asserts it is large. A wiring audit that
            %   inspects zero controls must fail, not pass.
            %
            %   Dispatch is on class(), never on Style: get(h,'Style') throws on a
            %   checkbox or button and, on a dropdown or table, silently returns a
            %   uistyle style TABLE.
            %
            %   A DropDown counts as wired on EITHER ValueChangedFcn or ClickedFcn.
            %   While the shim is present, PopupMenuRedirectStrategy nulls
            %   ValueChangedFcn and carries the wiring on ClickedFcn; with the shim
            %   gone the reverse holds. Accepting both is what lets this test pass
            %   in both worlds -- which is the evidence that it measures the app
            %   and not the adapter.
            names = {}; inspected = {};

            map = { 'matlab.ui.control.Button',           {'ButtonPushedFcn'}
                    'matlab.ui.control.StateButton',      {'ValueChangedFcn'}
                    'matlab.ui.control.DropDown',         {'ValueChangedFcn','ClickedFcn'}
                    'matlab.ui.control.CheckBox',         {'ValueChangedFcn'}
                    'matlab.ui.control.EditField',        {'ValueChangedFcn'}
                    'matlab.ui.control.NumericEditField', {'ValueChangedFcn'}
                    'matlab.ui.control.TextArea',         {'ValueChangedFcn'}
                    'matlab.ui.control.ListBox',          {'ValueChangedFcn'}
                    'matlab.ui.control.Slider',           {'ValueChangedFcn','ValueChangingFcn'}
                    'matlab.ui.control.Table',            {'CellEditCallback','CellSelectionCallback'}
                    'matlab.ui.control.Image',            {'ImageClickedFcn'} };

            % Legacy uicontrols (imtool3D's toolbar, and the Sim buttons
            % MethodMenu builds) are the ONE place Style is trustworthy and
            % necessary: a Style='text' uicontrol is a label and has no callback
            % by design. imtool3D contributes 40 uicontrols, of which five are
            % static text -- '(x,y) val', the Vol/Time/Slice readout, and the
            % L/U window-level captions. Requiring a Callback of those reports
            % five false defects. Native components need no such test because a
            % uilabel is simply not in the map above.
            legacyInteractive = {'pushbutton','togglebutton','popupmenu','checkbox', ...
                                 'edit','listbox','slider','radiobutton'};

            all = findall(fig);
            for k = 1:numel(all)
                o = all(k);
                if ~isvalid(o); continue; end
                isLegacy = isa(o, 'matlab.ui.control.UIControl');
                if isLegacy
                    style = '';
                    try, style = o.Style; catch, continue; end %#ok<NOCOM>
                    if ~any(strcmp(style, legacyInteractive)); continue; end
                    props = {'Callback'};
                else
                    row = find(strcmp(class(o), map(:,1)), 1);
                    if isempty(row); continue; end
                    props = map{row, 2};
                end

                % A hidden control is not a control the user can click. imtool3D
                % keeps a lot of its toolbar hidden per view.
                try
                    if strcmp(char(string(o.Visible)), 'off'); continue; end
                catch
                end
                if any(strcmp(o.Tag, tControls.InertByDesign)); continue; end

                name = o.Tag;
                if isempty(name)
                    try, name = char(string(o.Text)); catch, name = ''; end %#ok<NOCOM>
                end
                if isempty(name); name = '<untagged>'; end
                if isLegacy
                    label = sprintf('%s (uicontrol/%s)', name, style);
                else
                    label = sprintf('%s (%s)', name, strrep(class(o), 'matlab.ui.control.', ''));
                end
                inspected{end+1} = label; %#ok<AGROW>

                % The native property is now the authority. It was not while the
                % GUIDE shim existed -- the adapter moved the real callback into
                % itself and left a forwarder behind, so a control whose
                % createCallbackFcn line had been deleted still read as wired.
                % This audit carried a CodeAdapter branch for exactly that, and
                % F1 deleted the last convertToGUIDECallbackArguments call, so no
                % adapter is ever constructed and the branch is unreachable.
                wired = false;
                for pi = 1:numel(props)
                    if isprop(o, props{pi}) && ~isempty(o.(props{pi})); wired = true; break; end
                end
                if ~wired
                    names{end+1} = label; %#ok<AGROW>
                end
            end
            names = sort(names);
            inspected = sort(inspected);
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

        function btn = viewButtonFor(inputName)
            % The View buttons carry no Tag either. Anchor on the input's NAME label,
            % which is stable -- the file box next to it is not, because its
            % placeholder is replaced by the path once something is loaded.
            btn = [];
            panel = findall(tControls.mainFigure(), 'Tag', 'FitDataFileBrowserPanel');
            if isempty(panel); return; end
            rowY = [];
            labels = findall(panel(1), '-isa', 'matlab.ui.control.Label');
            for k = 1:numel(labels)
                if strcmp(labels(k).Text, inputName) && strcmp(labels(k).Visible, 'on')
                    rowY = labels(k).Position(2); break
                end
            end
            if isempty(rowY); return; end
            buttons = findall(panel(1), '-isa', 'matlab.ui.control.Button');
            for k = 1:numel(buttons)
                if ~strcmp(buttons(k).Text, 'View'); continue; end
                if abs(buttons(k).Position(2) - rowY) <= 4
                    btn = buttons(k); return
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
