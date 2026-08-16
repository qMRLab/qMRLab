classdef Theme
%Theme  qMRLab's light/dark appearance.
%
%   qmrlab.gui.Theme.adopt(fig)        set the figure's theme and register it
%   qmrlab.gui.Theme.choose(mode)      'light' | 'dark' | 'system'; persist + re-apply
%   qmrlab.gui.Theme.current()         the resolved mode, 'light' or 'dark'
%   qmrlab.gui.Theme.mode()            the CHOSEN mode, which may be 'system'
%   qmrlab.gui.Theme.token(name)       a semantic colour for the resolved mode
%   qmrlab.gui.Theme.attachMenu(fig)   builds View > Appearance
%   qmrlab.gui.Theme.publish()         exports tokens for non-GUI consumers
%
%   THE CONTRACT
%
%       Chrome colours come from MATLAB. This class supplies only the few colours
%       that carry MEANING, and decides light vs dark.
%
%   A uifigure themes its own components -- measured on R2026b, an untouched panel
%   goes [0.961 0.961 0.961] light to [0.129 0.129 0.129] dark, and a label's
%   FontColor [0.129] to [0.851]. So the app should state almost no colours at all.
%   What it must state is the handful that mean something: the accent on the
%   primary action, the red on a data-consistency warning, the grey that marks an
%   input optional. Those are TOKENS here and are chosen per mode, because a colour
%   that reads well on white can vanish on near-black.
%
%   WHY THE FIGURE'S THEME IS ALWAYS SET EXPLICITLY
%
%   So that the IDE, -batch and the compiled standalone cannot disagree, and so
%   the View > Appearance menu has something to change. A figure left alone takes
%   MATLAB's own appearance -- right on the desktop, and simply light where there
%   is no desktop -- but a window built before a theme change would then keep the
%   old one. adopt() assigns fig.Theme every time, from the one mode this class
%   resolves.
%
%   WHAT 'SYSTEM' ASKS, AND WHAT IT DELIBERATELY ASKS LAST
%
%   MATLAB first; the operating system only where MATLAB has no answer to give.
%   That order is the reverse of what this class did until the OS was caught
%   lying. Measured 2026-08-14 with the macOS desktop in LIGHT:
%
%       defaults read -g AppleInterfaceStyle    ->  "Dark"      (stale key)
%       NSApp.effectiveAppearance               ->  Aqua        (the live truth)
%       MATLAB theme setting, and a bare uifigure ->  light
%
%   The key outlived the appearance it described, and reading it first is what
%   painted every qMRLab window dark on a light desktop.
%
%   That measurement also revises what Stage D2 recorded here. "A bare uifigure
%   reported Light Theme with macOS in Dark" was this same stale key read the
%   other way round: the desktop was Light and MATLAB was telling the truth. What
%   remains true is the conclusion -- resolve once, assign explicitly -- so only
%   the SOURCE changed, not the contract.
%
%   The query is kept ONCE, here, rather than duplicated in MainApp and
%   OptionsWindow as it was.
%
%   See also: qmrlab.gui.TypeScale, qmrlabUIColor, Test/GUI/tTheme.m

    properties (Constant)
        Modes  = {'light', 'dark', 'system'}
        Labels = {'Light', 'Dark', 'Match system'}

        PrefGroup = 'qMRLab'
        PrefName  = 'Appearance'
        EnvVar    = 'QMRLAB_THEME'
        StoreKey  = 'qMRLabTheme'      % root appdata: transport for non-GUI code
        AdoptKey  = 'qmrlabThemeAdopted'
    end

    methods (Static)

        % ----------------------------------------------------------------- apply
        function adopt(figs)
        %ADOPT  Theme the given figure(s) and register them for later changes.
            C = qmrlab.gui.Theme;
            if nargin < 1 || isempty(figs); return; end
            figs = figs(isgraphics(figs));
            resolved = C.current();
            for k = 1:numel(figs)
                try
                    figs(k).Theme = resolved;
                catch
                    % Pre-R2025a, or a figure type without Theme. The app still
                    % works; it just will not be dark.
                end
                setappdata(figs(k), C.AdoptKey, true);
                C.markMenu(figs(k));
            end
            C.publish();
        end

        function choose(mode)
        %CHOOSE  Set the appearance, persist it, and re-theme every adopted window.
            C = qmrlab.gui.Theme;
            mode = C.validate(mode);

            % Picking "Match system" is a user saying look again -- the desktop
            % may have changed appearance since this last resolved, and the
            % answer is cached because it costs a figure to obtain.
            if strcmp(mode, 'system'); C.systemAppearance(true); end

            C.state(mode);
            C.writeMode(mode);
            C.publish();

            figs = findall(groot, 'Type', 'figure');
            figs = figs(arrayfun(@(f) isappdata(f, C.AdoptKey), figs));
            C.adopt(figs);

            % Vendored subtrees paint themselves from the published tokens at
            % construction and cannot repaint. Tell whoever can.
            for k = 1:numel(figs)
                r = getappdata(figs(k), 'qmrlabThemeRepaint');
                if ~isempty(r)
                    try, r(); catch ME
                        warning('qMRLab:Theme:Repaint', 'Theme repaint failed: %s', ME.message);
                    end
                end
            end
            drawnow;
        end

        % ---------------------------------------------------------------- values
        function m = mode()
        %MODE  What the user CHOSE: light, dark, or system.
            m = qmrlab.gui.Theme.state();
        end

        function m = current()
        %CURRENT  What that resolves to right now: light or dark.
            C = qmrlab.gui.Theme;
            m = C.state();
            if strcmp(m, 'system'); m = C.systemAppearance(); end
        end

        function c = token(name)
        %TOKEN  A colour that carries meaning, for the resolved mode.
        %
        %   Deliberately short. Every colour here has to justify itself as
        %   SEMANTIC -- if the answer to "what does this colour mean" is "it is the
        %   normal background", it does not belong in this list, it belongs deleted
        %   so MATLAB can theme it.
            C = qmrlab.gui.Theme;
            dark = strcmp(C.current(), 'dark');

            switch lower(name)
                case 'accent'          % the primary action: Fit data, Help
                    % ONE value in both modes, deliberately. The lighter dark-mode
                    % variant this used to carry ([0.267 0.647 0.941]) could not
                    % carry white text: 2.66:1, under the 3:1 floor. This value
                    % gives 3.57:1 for its white label in either mode, and still
                    % separates from both grounds (3.28:1 on light, 4.51:1 on dark).
                    c = [0.149 0.549 0.867];
                case 'ontheaccent'     % text drawn on top of the accent
                    c = [1 1 1];
                case 'warning'         % data will not fit as configured
                    c = [0.800 0.200 0.200];
                    if dark; c = [1 0.435 0.435]; end
                case 'success'
                    c = [0.180 0.600 0.180];
                    if dark; c = [0.400 0.800 0.400]; end
                case 'muted'           % an OPTIONAL input, a placeholder
                    c = [0.400 0.400 0.400];
                    if dark; c = [0.650 0.650 0.650]; end
                case 'viewerchrome'    % imtool3D's rails and info strip
                    c = [0.940 0.940 0.940];
                    if dark; c = [0.180 0.180 0.180]; end
                case 'viewertext'
                    c = [0 0 0];
                    if dark; c = [0.900 0.900 0.900]; end
                otherwise
                    error('qMRLab:Theme:UnknownToken', 'No colour token named "%s".', name);
            end
        end

        function paint(h, prop, role)
        %PAINT  Set a themed colour AND remember why, so it can be re-resolved.
        %
        %   Assigning token(...) directly is what a component does once, at
        %   construction -- and it then keeps that colour forever, because nothing
        %   records which token it came from. Measured after choose('dark'):
        %   token('accent') was [0.267 0.647 0.941] while FitGO still painted
        %   [0.149 0.549 0.867]. Ten components were frozen that way, and the theme
        %   test did not see it because it sampled panels, which the theme handles
        %   itself, rather than the components this class paints.
        %
        %   Same idiom TypeScale uses: it stamps the AUTHORED font size and
        %   recomputes base*factor on every apply, never reading back the live
        %   value. Here the stamp is the ROLE and the recompute is token(role).
            if isempty(h) || ~isgraphics(h) || ~isprop(h, prop); return; end
            setappdata(h, ['qmrlabThemeRole_' prop], role);
            set(h, prop, qmrlab.gui.Theme.token(role));
        end

        function repaint(fig)
        %REPAINT  Re-resolve every stamped colour under fig.
            if isempty(fig) || ~isgraphics(fig); return; end
            props = {'BackgroundColor', 'FontColor', 'ForegroundColor'};
            for h = findall(fig)'
                for k = 1:numel(props)
                    role = getappdata(h, ['qmrlabThemeRole_' props{k}]);
                    if isempty(role) || ~isprop(h, props{k}); continue; end
                    try
                        set(h, props{k}, qmrlab.gui.Theme.token(role));
                    catch
                    end
                end
            end
        end

        function publish()
        %PUBLISH  Export the resolved mode and tokens for code that must not depend
        %   on +qmrlab/+gui -- vendored External/imtool3D_td, and src/Common/tools
        %   helpers that have to keep working headless. Same idea as TypeScale's
        %   ScaleKey, read through qmrlabUIColor.
            C = qmrlab.gui.Theme;
            s.mode = C.current();
            for n = {'accent','onTheAccent','warning','success','muted','viewerChrome','viewerText'}
                s.(n{1}) = C.token(n{1});
            end
            setappdata(0, C.StoreKey, s);
        end

        % ------------------------------------------------------------------ menu
        function attachMenu(fig)
        %ATTACHMENU  View > Appearance. Shares the View menu with TypeScale.
            C = qmrlab.gui.Theme;
            if ~isgraphics(fig) || ~isempty(findall(fig, 'Tag', 'AppearanceMenu')); return; end

            m = findall(fig, 'Type', 'uimenu', 'Text', 'View');
            if isempty(m); m = uimenu(fig, 'Text', 'View'); else; m = m(1); end
            s = uimenu(m, 'Text', 'Appearance', 'Tag', 'AppearanceMenu');
            for k = 1:numel(C.Modes)
                uimenu(s, 'Text', C.Labels{k}, 'Tag', ['Appearance_' C.Modes{k}], ...
                          'MenuSelectedFcn', @(~,~) qmrlab.gui.Theme.choose(C.Modes{k}));
            end
            C.markMenu(fig);
        end

        function markMenu(fig)
            C = qmrlab.gui.Theme;
            cur = C.mode();
            onoff = {'off', 'on'};
            for k = 1:numel(C.Modes)
                it = findall(fig, 'Tag', ['Appearance_' C.Modes{k}]);
                if ~isempty(it)
                    set(it, 'Checked', onoff{1 + strcmp(cur, C.Modes{k})});
                end
            end
        end

    end

    methods (Static, Access = private)

        function m = systemAppearance(refresh)
        %SYSTEMAPPEARANCE  What 'system' resolves to. MUST NOT THROW.
        %
        %   Asks MATLAB, and reaches the operating system only if MATLAB has
        %   nothing to say. See the header of this file for the measurement that
        %   put the OS last: its stored appearance key can outlive the appearance,
        %   and believing it made the whole app dark on a light desktop.
        %
        %   Cached. Step 2 costs a figure, and current() runs on every token
        %   lookup -- the version this replaces forked a `defaults` process each
        %   time. choose('system') is what refreshes it.
            persistent resolved
            if nargin && refresh; resolved = ''; end
            if ~isempty(resolved); m = resolved; return; end

            m = '';

            % 1. MATLAB itself is pinned to an appearance. Match it: looking
            %    unlike every other MATLAB window is the complaint this answers.
            try
                s = settings;
                v = lower(char(string(s.matlab.appearance.MATLABTheme.ActiveValue)));
                if any(strcmp(v, {'light', 'dark'})); m = v; end
            catch
            end

            % 2. MATLAB is on 'system' too, so let it resolve: a bare uifigure
            %    comes up in whatever the desktop actually is. This is the step
            %    that reads the LIVE appearance instead of a stored key.
            if isempty(m)
                try
                    probe = uifigure('Visible', 'off');
                    cleanup = onCleanup(@() delete(probe)); %#ok<NASGU>
                    v = lower(char(string(probe.Theme.BaseColorStyle)));
                    if any(strcmp(v, {'light', 'dark'})); m = v; end
                catch
                end
            end

            % 3. No graphics at all, or a release older than figure themes.
            if isempty(m); m = qmrlab.gui.Theme.queryOS(); end

            resolved = m;
        end

        function m = queryOS()
        %QUERYOS  The operating system's STORED appearance. MUST NOT THROW.
        %
        %   Last resort, and deliberately not trusted before MATLAB: on macOS this
        %   key is written when the appearance changes and is not guaranteed to
        %   still describe it. Kept because below R2025a a figure has no Theme to
        %   read, and the tokens still have to pick a side.
            m = 'light';
            try
                if ispc
                    [st, out] = system(['reg query "HKCU\Software\Microsoft\Windows' ...
                        '\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme']);
                    if st == 0 && contains(out, '0x0'); m = 'dark'; end
                elseif ismac
                    % Absent key means Light; that is how macOS reports it.
                    [st, out] = system('defaults read -g AppleInterfaceStyle 2>/dev/null');
                    if st == 0 && contains(lower(out), 'dark'); m = 'dark'; end
                end
            catch
            end
        end

        function out = state(varargin)
        %STATE  In-process authority, seeded once. Same reasoning as TypeScale: in
        %   the compiled standalone no preference survives a restart.
            persistent chosen
            if isempty(chosen); chosen = qmrlab.gui.Theme.readMode(); end
            if nargin; chosen = varargin{1}; end
            out = chosen;
        end

        function m = readMode()
            C = qmrlab.gui.Theme;
            m = 'system';
            try
                v = getenv(C.EnvVar);
                if ~isempty(v); m = C.validate(v); return; end
            catch
            end
            try
                m = C.validate(getpref(C.PrefGroup, C.PrefName, 'system'));
            catch
            end
        end

        function writeMode(m)
            try
                setpref(qmrlab.gui.Theme.PrefGroup, qmrlab.gui.Theme.PrefName, m);
            catch
            end
        end

        function m = validate(v)
            C = qmrlab.gui.Theme;
            m = 'system';
            if isempty(v); return; end
            v = lower(char(string(v)));
            hit = strcmp(v, C.Modes);
            if any(hit); m = C.Modes{hit}; end
        end

    end
end
