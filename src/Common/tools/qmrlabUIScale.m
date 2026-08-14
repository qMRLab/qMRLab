function s = qmrlabUIScale()
%qmrlabUIScale  The app's current text-size factor, or 1 when the GUI is not up.
%
%   Deliberately a plain function over root appdata rather than a call into
%   +qmrlab/+gui: it is read by src/Common/tools code that must keep working
%   headless and by vendored External/imtool3D_td (which reads the same key
%   inline, so it acquires no qMRLab dependency and still runs standalone).
%
%   See also: qmrlab.gui.TypeScale
    s = getappdata(0, 'qMRLabTypeScale');
    if isempty(s) || ~isnumeric(s) || ~isscalar(s) || ~isfinite(s) || s <= 0
        s = 1;
    end
end
