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
%   Because MATLAB's own default could not be pinned down. Measured with macOS in
%   Dark: a bare uifigure reported "Light Theme", while the app's figure in the
%   same process reported "Dark Theme" -- and nothing in qMRLab sets it. Whatever
%   drives that difference (desktop appearance setting, App Designer registration,
%   sampling at process start), it is not something to inherit silently: the same
%   code would then look different in the IDE, in -batch and in the compiled
%   standalone. adopt() therefore assigns fig.Theme every time, from a mode this
%   class resolves, so the result is the same everywhere.
%
%   'system' still has to ask the OS itself, for the same reason. That is the one
%   piece of the old hand-rolled detection worth keeping -- and it is kept ONCE,
%   here, rather than duplicated in MainApp and OptionsWindow as it was.
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
            if strcmp(m, 'system'); m = C.osAppearance(); end
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
                    c = [0.149 0.549 0.867];
                    if dark; c = [0.267 0.647 0.941]; end
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

        function m = osAppearance()
        %OSAPPEARANCE  Ask the operating system. MUST NOT THROW.
        %
        %   The one surviving piece of the ~130 lines this replaces -- and it is
        %   needed, because MATLAB does not reliably follow the OS: measured with
        %   macOS in Dark, a fresh uifigure still reported "Light Theme".
        %
        %   Kept in ONE place. It used to be copied verbatim into MainApp and
        %   OptionsWindow, so the two windows could in principle disagree.
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
