classdef tTheme < matlab.unittest.TestCase
% tTheme  Does the appearance actually change, and does it change BACK?
%
%   Stage D2 replaced ~290 lines of hand-rolled theming -- an OS dark-mode probe
%   duplicated in both windows, two hardcoded palettes, and a sweep that repainted
%   a named list of components -- with fig.Theme plus a handful of semantic tokens.
%
%   The reason that works is that a uifigure themes its own components, and the
%   reason it did NOT work before is that 58 explicit colour assignments overrode
%   it. So the assertions here are about ABSENCE as much as presence: the app has
%   to stop stating colours, or the theme is inert again and nothing in the suite
%   would notice.
%
%   Both directions are tested on purpose. A one-way check passes against code that
%   paints dark and then cannot come back, which is exactly the failure mode of a
%   palette applied at construction.
%
%   What is NOT asserted here: whether it LOOKS right. See
%   Test/GUI/evidence/after_D2_*.png -- the compass letters sitting in white boxes
%   on a dark pane, and a logo invisible against its own background, were both
%   found by looking at a capture, not by a test.
%
%   See also: qmrlab.gui.Theme, qmrlabUIColor, Test/GUI/KNOWN_BUGS.md

    properties
        Restore
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
            testCase.Restore = qmrlab.gui.Theme.mode();
            testCase.addTeardown(@() qmrlab.gui.Theme.choose(testCase.Restore));
            tTheme.closeEverything();
            testCase.addTeardown(@tTheme.closeEverything);
        end
    end

    methods (Test)

        function themeReachesTheWindowBothWays(testCase)
            % The whole point of D2, in one assertion. The panels must actually
            % change colour, and change back.
            qmrlab.gui.Theme.choose('light');
            qMRLab(inversion_recovery); drawnow;
            fig = tTheme.mainFigure();
            testCase.assertNotEmpty(fig, 'Main window did not open.');

            light = tTheme.sample(fig);
            qmrlab.gui.Theme.choose('dark'); drawnow;
            dark = tTheme.sample(fig);
            qmrlab.gui.Theme.choose('light'); drawnow;
            back = tTheme.sample(fig);

            for f = fieldnames(light)'
                testCase.verifyNotEqual(dark.(f{1}), light.(f{1}), sprintf( ...
                    ['%s did not change between light and dark. Something is still ' ...
                     'stating this colour explicitly, which makes the theme inert.'], f{1}));
                testCase.verifyEqual(back.(f{1}), light.(f{1}), 'AbsTol', 0.01, sprintf( ...
                    '%s did not return to its light value; the theme only goes one way.', f{1}));
            end
        end

        function theAppStatesAlmostNoColoursOfItsOwn(testCase)
            % The structural guarantee behind the test above. 58 explicit colour
            % assignments were removed in D2; if they creep back the theme goes
            % quietly inert and only a screenshot would show it.
            %
            % A budget rather than zero: a filled accent button genuinely has to
            % state its own background and foreground, because the theme's font
            % colour is chosen for the theme's background and not for a blue chip.
            qMRLab(inversion_recovery); drawnow;
            fig = tTheme.mainFigure();
            testCase.assertNotEmpty(fig);

            named = qmrlab.gui.Theme.token('accent');
            warn  = qmrlab.gui.Theme.token('warning');
            muted = qmrlab.gui.Theme.token('muted');
            onAcc = qmrlab.gui.Theme.token('onTheAccent');
            allowed = [named; warn; muted; onAcc];

            offenders = {};
            comps = findall(fig, '-property', 'BackgroundColor');
            for k = 1:numel(comps)
                h = comps(k);
                if tTheme.underTag(h, 'imtool3D'); continue; end   % vendored
                v = get(h, 'BackgroundColor');
                if ~isnumeric(v) || numel(v) ~= 3; continue; end
                if any(all(abs(allowed - v) < 0.02, 2)); continue; end
                % Theme-supplied greys are fine; a stated white or mid grey is not.
                if isequal(round(v, 2), [1 1 1])
                    offenders{end+1} = sprintf('%s [%s] states white', ...
                        class(h), get(h, 'Tag')); %#ok<AGROW>
                end
            end
            testCase.verifyEmpty(offenders, sprintf( ...
                'Components stating a hardcoded white background:\n  %s', ...
                strjoin(offenders, '\n  ')));
        end

        function tokensAreExportedForVendoredCode(testCase)
            % External/imtool3D_td and src/Common/tools read colours through
            % qmrlabUIColor over root appdata, so they gain no dependency on
            % +qmrlab/+gui and still run standalone -- the same arrangement
            % qmrlabUIScale uses for text size. If publishing breaks, they silently
            % fall back to the light palette and a dark window grows light patches.
            qmrlab.gui.Theme.choose('dark');
            testCase.verifyEqual(qmrlabUIColor('mode'), 'dark');
            darkChrome = qmrlabUIColor('viewerChrome');

            qmrlab.gui.Theme.choose('light');
            testCase.verifyEqual(qmrlabUIColor('mode'), 'light');
            testCase.verifyNotEqual(qmrlabUIColor('viewerChrome'), darkChrome, ...
                'viewerChrome is the same in both modes; the export is not tracking.');
        end

        function theOsIsQueriedInExactlyOnePlace(testCase)
            % It used to be copied verbatim into MainApp AND OptionsWindow, so the
            % two windows could in principle disagree about the appearance. Pinned
            % because the duplicate is easy to reintroduce by copy-paste.
            root = fileparts(which('qMRLab.m'));
            hits = {};
            for f = [dir(fullfile(root, 'src', '**', '*.m'))']
                p = fullfile(f.folder, f.name);
                if contains(p, [filesep 'External' filesep]); continue; end
                txt = fileread(p);
                if contains(txt, 'AppleInterfaceStyle') || contains(txt, 'AppsUseLightTheme')
                    hits{end+1} = f.name; %#ok<AGROW>
                end
            end
            testCase.verifyEqual(sort(unique(hits)), {'Theme.m'}, sprintf( ...
                'OS appearance is queried in: %s. It belongs only in qmrlab.gui.Theme.', ...
                strjoin(unique(hits), ', ')));
        end

    end

    methods (Static)
        function s = sample(fig)
            s = struct();
            s.figure       = fig.Color;
            s.FitDataPanel = tTheme.bg(fig, 'FitDataPanel');
            s.SimPanel     = tTheme.bg(fig, 'SimPanel');
        end

        function c = bg(fig, tag)
            h = findall(fig, 'Tag', tag);
            c = [NaN NaN NaN];
            if ~isempty(h); c = h(1).BackgroundColor; end
        end

        function tf = underTag(h, tag)
            tf = false; p = h;
            while ~isempty(p) && ~isa(p, 'matlab.ui.Figure')
                if isprop(p, 'Tag') && strcmp(get(p, 'Tag'), tag); tf = true; return; end
                p = get(p, 'Parent');
            end
        end

        function fig = mainFigure()
            fig = findall(groot, 'Type', 'figure', 'Name', 'qMRLab');
            if numel(fig) > 1; fig = fig(1); end
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
            for k = {'Model', 'Data', 'FileBrowserList', 'MethodList', 'Method'}
                if isappdata(0, k{1}); rmappdata(0, k{1}); end
            end
            drawnow;
        end
    end
end
