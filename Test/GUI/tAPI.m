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
            closer = tAPI.closeOnceWaiting();
            testCase.addTeardown(@() tAPI.killTimer(closer));

            started = tic;
            Model = qMRLab(feval(testCase.Model));
            elapsed = toc(started);

            testCase.verifyGreaterThan(elapsed, 1, ...
                'Model = qMRLab(...) returned without waiting for the window to close.');
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
        function fig = mainFigure()
            fig = findall(groot, 'Type', 'figure', 'Name', 'qMRLab');
            if numel(fig) > 1, fig = fig(1); end
        end

        function t = closeOnceWaiting()
            % Poll until the main window is blocked in uiwait, then delete it.
            % Deleting the figure (rather than clearing the shared store) is
            % deliberate: qMRLab.m reads the model out of that store after uiwait
            % returns, so wiping it here would race the code under test.
            t = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.5, ...
                      'StartDelay', 0.5, 'TasksToExecute', 240);
            t.TimerFcn = @(src, ~) tAPI.deleteIfWaiting(src);
            start(t);
        end

        function deleteIfWaiting(src)
            fig = tAPI.mainFigure();
            if ~isempty(fig) && isvalid(fig) && strcmp(get(fig, 'waitstatus'), 'waiting')
                stop(src);
                delete(fig);
            end
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
