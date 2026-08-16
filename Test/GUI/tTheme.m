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

        function everyPaintedColourFollowsItsToken(testCase)
            % The assertion the first version of this file was missing, and the
            % reason a real bug shipped: it sampled FitDataPanel and SimPanel --
            % components MATLAB themes by itself -- so it passed while every colour
            % the APP paints was frozen at whatever token was current when the
            % window was built. Measured then: token('accent') said
            % [0.267 0.647 0.941] in dark while FitGO still painted the light value.
            %
            % Checks the LIVE property against the token, never the stamp: a later
            % direct assignment would leave the stamp intact and the colour wrong.
            qmrlab.gui.Theme.choose('light');
            qMRLab(inversion_recovery); drawnow;
            fig = tTheme.mainFigure();
            testCase.assertNotEmpty(fig);

            for mode = {'dark', 'light'}
                qmrlab.gui.Theme.choose(mode{1}); drawnow;
                bad = {};
                for h = findall(fig)'
                    for p = {'BackgroundColor', 'FontColor', 'ForegroundColor'}
                        role = getappdata(h, ['qmrlabThemeRole_' p{1}]);
                        if isempty(role) || ~isprop(h, p{1}); continue; end
                        want = qmrlab.gui.Theme.token(role);
                        got  = get(h, p{1});
                        if ~isnumeric(got) || numel(got) ~= 3 || any(abs(got - want) > 0.01)
                            bad{end+1} = sprintf('%s[%s].%s is %s, token ''%s'' is %s', ...
                                class(h), tTheme.tagOf(h), p{1}, mat2str(round(got,3)), ...
                                role, mat2str(round(want,3))); %#ok<AGROW>
                        end
                    end
                end
                testCase.verifyEmpty(bad, sprintf( ...
                    'In %s mode these painted colours do not match their token:\n  %s', ...
                    mode{1}, strjoin(bad, '\n  ')));
            end

            testCase.verifyGreaterThan(numel(tTheme.stamped(fig)), 8, ...
                'Almost nothing is stamped -- the check above would pass vacuously.');
        end

        function tokensClearTheContrastFloor(testCase)
            % A token that cannot be read is not a theme, it is a decoration. The
            % dark accent this shipped with ([0.267 0.647 0.941]) carried white text
            % at 2.66:1; the accent is one value in both modes now, at 3.57:1.
            ground = struct('light', [0.961 0.961 0.961], 'dark', [0.129 0.129 0.129]);
            for mode = {'light', 'dark'}
                qmrlab.gui.Theme.choose(mode{1});
                bg = ground.(mode{1});
                for t = {'accent', 'warning', 'success', 'muted'}
                    r = tTheme.contrast(qmrlab.gui.Theme.token(t{1}), bg);
                    testCase.verifyGreaterThanOrEqual(r, 3.0, sprintf( ...
                        '%s mode: token ''%s'' is %.2f:1 against the background.', ...
                        mode{1}, t{1}, r));
                end
                r = tTheme.contrast(qmrlab.gui.Theme.token('onTheAccent'), ...
                                    qmrlab.gui.Theme.token('accent'));
                testCase.verifyGreaterThanOrEqual(r, 3.0, sprintf( ...
                    '%s mode: text on the accent is %.2f:1.', mode{1}, r));
            end
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

        function systemFollowsMatlabAndNotAStoredOsKey(testCase)
            % Found by looking at the window, not by a test: on a macOS desktop
            % in LIGHT, every qMRLab window came up dark. The stored key said so
            % --  `defaults read -g AppleInterfaceStyle` answered "Dark" long
            % after the appearance changed -- while NSApp.effectiveAppearance was
            % Aqua and MATLAB itself resolved light. 'system' read the key first.
            %
            % So what is pinned here is the ORDER, not a colour: qMRLab follows
            % MATLAB, and reaches the OS only when MATLAB has no answer. Asserted
            % through the public surface because that order lives in a private
            % method, and driven by MATLAB's own setting because that is the one
            % input a test can change on any platform -- reading the live desktop
            % appearance is exactly what cannot be faked in CI.
            try
                theme = settings().matlab.appearance.MATLABTheme;
                theme.ActiveValue;
            catch ME
                testCase.assumeFail(['No MATLAB theme setting to drive: ' ME.message]);
            end
            % TemporaryValue is session-scoped: it cannot leak into the user's
            % preferences the way setpref would.
            testCase.addTeardown(@() tTheme.clearTemp(theme));

            theme.TemporaryValue = 'Dark';
            qmrlab.gui.Theme.choose('system');
            testCase.verifyEqual(qmrlab.gui.Theme.current(), 'dark', ...
                'MATLAB is in Dark and "match system" did not follow it.');

            theme.TemporaryValue = 'Light';
            qmrlab.gui.Theme.choose('system');
            testCase.verifyEqual(qmrlab.gui.Theme.current(), 'light', ...
                'MATLAB is in Light and "match system" did not follow it.');
        end

    end

    methods (Static)
        function clearTemp(theme)
            try
                if hasTemporaryValue(theme); clearTemporaryValue(theme); end
            catch
            end
        end

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

        function t = tagOf(h)
            t = ''; if isprop(h, 'Tag'); t = get(h, 'Tag'); end
        end

        function n = stamped(fig)
            n = {};
            for h = findall(fig)'
                for p = {'BackgroundColor', 'FontColor', 'ForegroundColor'}
                    if ~isempty(getappdata(h, ['qmrlabThemeRole_' p{1}]))
                        n{end+1} = p{1}; %#ok<AGROW>
                    end
                end
            end
        end

        function r = contrast(a, b)
            la = tTheme.luminance(a); lb = tTheme.luminance(b);
            r = (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
        end

        function y = luminance(c)
            ch = @(u) (u <= 0.03928) * (u / 12.92) + (u > 0.03928) * (((u + 0.055) / 1.055)^2.4);
            y = 0.2126*ch(c(1)) + 0.7152*ch(c(2)) + 0.0722*ch(c(3));
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
