function c = qmrlabUIColor(name)
%qmrlabUIColor  A qMRLab theme colour, or a sensible light-mode default.
%
%   c = qmrlabUIColor('viewerChrome')
%
%   Deliberately a plain function over root appdata rather than a call into
%   +qmrlab/+gui, for exactly the reason qmrlabUIScale is: it is read by
%   src/Common/tools code that must keep working headless, and by vendored
%   External/imtool3D_td, which reads the same key inline so it acquires no qMRLab
%   dependency and still runs standalone.
%
%   Returns the light-mode value when the GUI is not up, so a caller never has to
%   check first.
%
%   See also: qmrlab.gui.Theme, qmrlabUIScale

    fallback = struct( ...
        'mode',         'light', ...
        'accent',       [0.149 0.549 0.867], ...
        'onTheAccent',  [1 1 1], ...
        'warning',      [0.800 0.200 0.200], ...
        'success',      [0.180 0.600 0.180], ...
        'muted',        [0.400 0.400 0.400], ...
        'viewerChrome', [0.940 0.940 0.940], ...
        'viewerText',   [0 0 0]);

    s = getappdata(0, 'qMRLabTheme');
    if isempty(s) || ~isstruct(s); s = fallback; end

    if nargin < 1 || isempty(name); name = 'mode'; end
    if isfield(s, name)
        c = s.(name);
    elseif isfield(fallback, name)
        c = fallback.(name);
    else
        error('qMRLab:Theme:UnknownToken', 'No colour token named "%s".', name);
    end
end
