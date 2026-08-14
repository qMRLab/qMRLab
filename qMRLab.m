function varargout = qMRLab(varargin)
%         __  __ ____  _          _
%    __ _|  \/  |  _ \| |    __ _| |__
%   / _` | |\/| | |_) | |   / _` | '_ \
%  | (_| | |  | |  _ <| |__| (_| | |_) |
%   \__, |_|  |_|_| \_\_____\__,_|_.__/
%      |_|
%
% qMRLab  Open the qMRLab graphical interface.
%
%   qMRLab                 open the window and return immediately
%   qMRLab(Model)          open it with a model preselected
%   qMRLab(Model, data)    ...and preload a struct of input volumes
%   Model = qMRLab(...)    BLOCK until the window closes, then return the
%                          configured model object
%
%   This file is a thin entry point. The interface itself lives in
%   src/Common/GUI/+qmrlab/+gui/MainApp.m.
%
%   Why this file exists as a real function file, rather than the app being
%   named qMRLab directly: three things pin this exact filename, and all three
%   break silently if it is absent --
%       Deploy/Compile/qMRLab_make_standalone.m   mcc -W main:qMRLab
%       src/Common/list_models.m:3                which('qMRLab.m')
%       Deploy/Documentation/GenerateDocumentation.m:3,81
%   On the earlier migration branch qMRLab.m was deleted in favour of a .mlapp,
%   and list_models() silently returned 0 models while 22 sat on disk.
%   See docs/adr/0001-gui-migration.md, decision D3.
%
% ----------------------------------------------------------------------------------------------------
% See the list of contributors: https://github.com/qMRLab/qMRLab/graphs/contributors
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :
%
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F.,
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab:
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
% ----------------------------------------------------------------------------------------------------

if logical(exist('OCTAVE_VERSION', 'builtin'))
    warndlg('Graphical user interface not available on octave... use command lines instead');
    return
end

app = qmrlab.gui.MainApp(varargin{:});

if nargout
    % Modal contract: block until the user closes the window, then hand back the
    % model they configured. The window is torn down by the time uiwait returns,
    % so the model has to be read from the shared store, not from the app.
    uiwait(app.qMRILab);

    varargout{1} = getappdata(0, 'Model');

    % Match the historical OutputFcn, which cleared the shared store on the way
    % out. This is load-bearing rather than tidiness: qMRLab caches browser
    % objects holding graphics handles, and leaving them behind makes the next
    % launch fail. See Test/GUI/STAGE_A_FINDINGS.md.
    stale = getappdata(0);
    for f = fieldnames(stale)'
        rmappdata(0, f{1});
    end
end

end
