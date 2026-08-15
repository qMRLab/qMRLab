classdef tAPI < matlab.unittest.TestCase
% tAPI  The public calling convention of qMRLab.m.
%
%   qMRLab has always had a dual contract, and it is easy to break silently
%   during a GUI migration because nothing in the repo exercises it:
%
%       qMRLab(...)          non-blocking; returns nothing
%       Model = qMRLab(...)  BLOCKS until the window closes, then returns the
%                            model the user configured, and clears the shared store
%
%   Under GUIDE this fell out of gui_mainfcn appending a 'wait' sentinel, an
%   OutputFcn that returned the model rather than a figure handle, and a
%   CloseRequestFcn that called uiresume. None of that machinery exists in App
%   Designer, so qMRLab.m reimplements it and these tests pin it.
%
%   Run with:  runtests('Test/GUI/tAPI.m')

    properties (Constant)
        Model = 'inversion_recovery';
        BlockTimeout = 120; % generous: opening instantiates a model and builds two windows
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
            tAPI.reset();
            testCase.addTeardown(@tAPI.reset);
        end
    end

    methods (Test)

        function nonBlockingFormReturnsImmediately(testCase)
            % With no output requested the call must not wait for the user.
            started = tic;
            qMRLab(feval(testCase.Model));
            elapsed = toc(started);

            testCase.verifyLessThan(elapsed, testCase.BlockTimeout, ...
                'qMRLab(...) with no output appears to have blocked.');
            testCase.verifyNotEmpty(tAPI.mainFigure(), 'Window did not open.');
        end

        function outputFormBlocksThenReturnsTheModel(testCase)
            % Close the window from a timer while the call is blocked. Delete only
            % the figure -- clearing the shared store here would race the shim,
            % which reads the model out of it after uiwait returns.
            % Close only once the call is genuinely blocked. A fixed delay races
            % startup -- opening takes ~15 s, and deleting the figure mid-build
            % leaves the opening function setting properties on dead handles.
            % waitstatus == 'waiting' is the precise signal that uiwait is engaged.
            started = tic;
            closer = tAPI.closeOnceWaiting('qMRLab', started);
            testCase.addTeardown(@() tAPI.killTimer(closer));

            Model = qMRLab(feval(testCase.Model));
            elapsed = toc(started);

            tAPI.whyOrderingNotDuration(testCase, closer, elapsed, 'Model = qMRLab(...)');
            testCase.verifyClass(Model, testCase.Model, ...
                'Expected the configured model object, not a figure handle or empty.');
        end

        function outputFormClearsTheSharedStore(testCase)
            % Load-bearing rather than tidiness: qMRLab caches browser objects
            % holding graphics handles into the window it just destroyed, and the
            % next launch walks them. See Test/GUI/STAGE_A_FINDINGS.md.
            closer = tAPI.closeOnceWaiting();
            testCase.addTeardown(@() tAPI.killTimer(closer));

            % Request an output so the modal branch runs, then discard it.
            unusedModel = qMRLab(feval(testCase.Model)); %#ok<NASGU>
            leftovers = fieldnames(getappdata(0));

            testCase.verifyEmpty(leftovers, sprintf( ...
                'Shared store still holds: %s', strjoin(leftovers', ', ')));
        end

        function optionsEntryPointBlocksThenReturnsTheModel(testCase)
            % Custom_OptionsGUI carries the same dual contract as qMRLab.m, for a
            % harder reason: qMRgenBatch writes `Model = Custom_OptionsGUI(Model)`
            % into scripts that users keep, so the blocking form is the one form
            % that is guaranteed to be running on someone's machine.
            %
            % Nothing exercised it, and it was broken twice over -- the file had
            % been deleted outright, and forwarding the old 'wait' sentinel to
            % OptionsWindow throws MATLAB:class:InvalidHandle because the opening
            % function resumes into applyTheme on the figure it waited to be
            % deleted. Both are only reachable with an output argument requested.
            % Restore whatever the caller had, rather than assuming CI's value:
            % this suite runs on developer machines too.
            wasCI = getenv('ISCITEST'); wasDoc = getenv('ISDOC');
            testCase.addTeardown(@() setenv('ISCITEST', wasCI));
            testCase.addTeardown(@() setenv('ISDOC', wasDoc));
            setenv('ISCITEST', ''); setenv('ISDOC', '');

            started = tic;
            closer = tAPI.closeOnceWaiting('OptionsGUI', started);
            testCase.addTeardown(@() tAPI.killTimer(closer));

            Model = Custom_OptionsGUI(feval(testCase.Model));
            elapsed = toc(started);

            tAPI.whyOrderingNotDuration(testCase, closer, elapsed, ...
                'Model = Custom_OptionsGUI(...)');
            testCase.verifyClass(Model, testCase.Model, ...
                'Expected the configured model object back.');
        end

        function optionsEntryPointIsAFileOnDisk(testCase)
            % Same class of pin as entryPointIsAFileOnDisk below, and the same
            % failure: the name is written into generated batch scripts and into
            % every model's published page, neither of which this repo can edit.
            testCase.verifyNotEmpty(which('Custom_OptionsGUI.m'), ...
                'Custom_OptionsGUI.m must remain a real function file on disk.');
        end

        function everyFunctionTheBatchTemplatesCallStillExists(testCase)
            % The regression that cost a CI cycle: Custom_OptionsGUI.m was deleted
            % while three .qmr templates still emitted calls to it, so every batch
            % script qMRgenBatch produced -- and every one users had already
            % generated -- died with "Undefined function 'Custom_OptionsGUI'".
            % BatchExample_test does catch it, but only after downloading datasets
            % and fitting them, and it names the model rather than the cause.
            %
            % A name the template ASSIGNS is a variable being indexed, not a call
            % (`Model(...)`, `expected(...)`), so those are excluded -- that is the
            % whole reason this is a heuristic rather than a parse.
            root = fileparts(which('qMRLab.m'));
            templates = [dir(fullfile(root, 'src', '**', '*.qmr'));
                         dir(fullfile(root, 'Test', '**', '*.qmr'));
                         dir(fullfile(root, 'Deploy', '**', '*.qmr'))];
            testCase.assertNotEmpty(templates, 'No .qmr batch templates found.');

            missing = {};
            for f = templates'
                txt   = fileread(fullfile(f.folder, f.name));
                lines = strsplit(txt, newline);

                for k = 1:numel(lines)
                    line = strtrim(lines{k});
                    if isempty(line) || startsWith(line, '%') || contains(line, '*-')
                        continue    % blank, comment, or a qMRgenBatch placeholder
                    end
                    called = regexp(line, '(?<![\w.])([A-Za-z]\w*)\s*\(', 'tokens');
                    for c = called
                        name = c{1}{1};
                        if iskeyword(name) || tAPI.assignedIn(txt, name); continue; end
                        if isempty(which(name)) && exist(name, 'builtin') ~= 5
                            missing{end+1} = sprintf('%s:%d %s()', f.name, k, name); %#ok<AGROW>
                        end
                    end
                end
            end

            testCase.verifyEmpty(missing, sprintf( ...
                'Batch templates emit calls to functions that no longer exist: %s', ...
                strjoin(unique(missing), '; ')));
        end

        function entryPointIsAFileOnDisk(testCase)
            % mcc -W main:qMRLab, list_models.m:3 (which('qMRLab.m')) and
            % GenerateDocumentation.m:3,81 all pin this exact filename. Deleting it
            % in favour of a .mlapp previously made list_models() return 0 models
            % while 22 sat on disk.
            testCase.verifyNotEmpty(which('qMRLab.m'), ...
                'qMRLab.m must remain a real function file on disk.');
            testCase.verifyNumElements(list_models(), 22, ...
                'list_models() resolves the model directory through which(''qMRLab.m'').');
        end

    end

    methods (Static)
        function tf = assignedIn(txt, name)
            % A name the template ASSIGNS is a variable being indexed, not a
            % call: genBatchNoAssert.qmr sets `expected = FitResults_old.(f)` and
            % reads it back as `expected(crMask==1)` twenty lines later, which is
            % indistinguishable from a call by shape alone.
            tf = ~isempty(regexp(txt, ...
                ['(?m)^[^%\n]*\<' name '\>\s*(\([^)\n]*\))?\s*=(?!=)'], 'once'));
        end

        function fig = mainFigure()
            fig = findall(groot, 'Type', 'figure', 'Name', 'qMRLab');
            if numel(fig) > 1, fig = fig(1); end
        end

        function t = closeOnceWaiting(name, origin)
            % Poll until the named window is blocked in uiwait, then delete it,
            % recording WHEN on the caller's clock so a test can assert ordering
            % rather than duration. See whyOrderingNotDuration below.
            % Deleting the figure (rather than clearing the shared store) is
            % deliberate: qMRLab.m reads the model out of that store after uiwait
            % returns, so wiping it here would race the code under test.
            if nargin < 1, name = 'qMRLab'; end
            if nargin < 2, origin = tic; end
            t = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.5, ...
                      'StartDelay', 0.5, 'TasksToExecute', 240);
            t.UserData = struct('name', name, 'origin', origin, 'closedAt', []);
            t.TimerFcn = @(src, ~) tAPI.deleteIfWaiting(src);
            start(t);
        end

        function deleteIfWaiting(src)
            u = src.UserData;
            fig = findall(groot, 'Type', 'figure', 'Name', u.name);
            if numel(fig) > 1, fig = fig(1); end
            if ~isempty(fig) && isvalid(fig) && strcmp(get(fig, 'waitstatus'), 'waiting')
                stop(src);
                u.closedAt = toc(u.origin);
                src.UserData = u;
                delete(fig);
            end
        end

        function whyOrderingNotDuration(testCase, closer, elapsed, what)
            % Both blocking tests used to assert `elapsed > 1`, which measures how
            % fast the CLOSER is, not whether the call blocked. CI caught it: the
            % options window reached uiwait quickly, the poller deleted it on its
            % first tick, and the whole call took 0.616 s -- a correct blocking
            % implementation failing a test that never described blocking.
            %
            % Blocking is an ORDERING claim: the call must not return until after
            % the window was closed. That holds however fast either one is.
            info = closer.UserData;
            testCase.assertNotEmpty(info.closedAt, sprintf( ...
                ['%s: the poller never saw the window in uiwait, so nothing was ' ...
                 'closed and this test proved nothing.'], what));
            testCase.verifyGreaterThanOrEqual(elapsed, info.closedAt, sprintf( ...
                '%s returned %.3f s in, before the window was closed at %.3f s.', ...
                what, elapsed, info.closedAt));
        end

        function killTimer(t)
            try
                if isvalid(t), stop(t); delete(t); end
            catch
            end
        end

        function reset()
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
