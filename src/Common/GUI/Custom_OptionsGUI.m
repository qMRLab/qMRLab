function varargout = Custom_OptionsGUI(varargin)
%CUSTOM_OPTIONSGUI  Open a model's options panel; return the model it configured.
%
%   Custom_OptionsGUI(Model)              open the panel and return immediately
%   Custom_OptionsGUI(Model, callerFig)   ...positioned beside a calling window
%   Model = Custom_OptionsGUI(Model)      BLOCK until the panel closes, then
%                                         return the model the user configured
%
%   THIS FILE IS AN ENTRY POINT, NOT AN IMPLEMENTATION. The panel itself is
%   src/Common/GUI/+qmrlab/+gui/OptionsWindow.m, and nothing inside qMRLab calls
%   this file -- MainApp and MethodBrowser construct that class directly.
%
%   WHY IT SURVIVES THE MIGRATION ANYWAY
%
%   Because the NAME is written into files this repository does not own, which is
%   decision D3's argument (qMRLab.m) applied to a harder case. qMRgenBatch emits
%   `Model = Custom_OptionsGUI(Model);` into every batch script it generates, from
%   src/Common/genBatchUser.qmr and Test/BatchGen_Templates/genBatchNoAssert.qmr,
%   and those scripts are what users save, edit and re-run for years. Every
%   model's published page also tells them to type it by name to write a
%   .qmrlab.mat protocol (Deploy/Documentation/Notes/docGenericNotes.json).
%
%   Deleting it was not a no-op: CI's BatchExample_test went down with "Undefined
%   function 'Custom_OptionsGUI' for input arguments of type 'amico'", and every
%   batch script already on a user's disk would have failed the same way -- which
%   no edit to a template can reach. The generated line is therefore left exactly
%   as it was, and this forwards it.
%
%   See also: qmrlab.gui.OptionsWindow, qMRLab, qMRgenBatch
%
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Francis Cabana, 2016.  Modified: Agah Karakuzu, 2018.
% ----------------------------------------------------------------------------------------------------

% Octave has no GUI, and qMRgenBatch emits the call unconditionally for every
% model there (qMRgenBatch.m:234 selects the no-assert template on Octave). Hand
% the model straight back so the generated line is a no-op instead of an error.
% This guard is why the entry point has to be a plain function file: a classdef
% in a package cannot be reached from Octave at all.
if logical(exist('OCTAVE_VERSION', 'builtin'))
    warndlg('Graphical user interface not available on octave... use command lines instead');
    if nargout, varargout{1} = passthrough(varargin); end
    return
end

% UNATTENDED CALLERS DO NOT OPEN A WINDOW AT ALL.
%
% This is the one deliberate departure from the GUIDE-era entry point, and it is
% forced. That version opened a legacy figure, which MATLAB renders on Linux with
% no display; this one would open a uifigure, which does not -- .github/workflows/
% matlab.yml:123 says so in as many words, and the job that runs batch scripts
% (matlab.yml:44-56) has no Xvfb step, deliberately: the GUI suite is kept a
% separate job "so an interface flake can never block a science PR" (:119-127).
%
% So constructing the window here would trade "Undefined function
% 'Custom_OptionsGUI'" for a display error on the same line, in the same job.
% Returning the model untouched is what the old code's ISCITEST branch was
% reaching for anyway -- it built the panel and then immediately deleted it.
%
% What this gives up: opening the panel used to round a model's numeric options
% through sprintf('%g') (ADR D8), so two of the 22 models came back altered --
% qsm_sb's LambdaL1 0.0009210553177 -> 0.000921055. Batch runs now fit the
% unrounded values. The only assertion over them is a 5% relative comparison
% (Test/BatchGen_Templates/genBatchNoAssert.qmr:76), which a 3e-7 relative
% change cannot reach.
if envIsTrue('ISCITEST') || envIsTrue('ISDOC')
    warning('qMRLab:OptionsGUI:Unattended', ...
        ['ISCITEST/ISDOC is set: returning the model without opening the options ' ...
         'panel. Run >>setenv(''ISCITEST'','''') to change this behavior.']);
    if nargout, varargout{1} = passthrough(varargin); end
    return
end

% 'wait' is deliberately NOT forwarded, even though OptionsWindow parses it.
% Measured: qmrlab.gui.OptionsWindow(Model, [], 'wait') threw
% MATLAB:class:InvalidHandle from OptionsWindow.m:50, because the flag made the
% opening function block inside itself and then keep going once the user had
% deleted the very figure it waited on. That ordering is fixed now, but blocking
% is owned out here regardless, exactly as qMRLab.m owns it for the main window.
varargin(strcmp(varargin, 'wait')) = [];

% A live panel is REPLACED rather than reused. OptionsWindow.m:1069-1077 returns
% a running instance without re-running its opening function, so the model just
% passed in would never be adopted and this would hand back whichever model the
% existing window holds -- silently, with no error. GUIDE did not do that: its
% singleton re-entered the opening function every time (gui_mainfcn.m:220).
% Closing first is the shortest way to keep that contract.
existing = findall(groot, 'Type', 'figure', 'Name', 'OptionsGUI');
for k = 1:numel(existing)
    if isprop(existing(k), 'RunningAppInstance') && ~isempty(existing(k).RunningAppInstance)
        try, delete(existing(k).RunningAppInstance); catch, end %#ok<NOCOM>
    end
end
delete(existing);

app = qmrlab.gui.OptionsWindow(varargin{:});

if ~nargout
    return
end

% Blocking is what an output argument MEANS here: the caller wants a model the
% user has not configured yet.
if isvalid(app) && isvalid(app.OptionsGUI)
    uiwait(app.OptionsGUI);
end

% The window is gone by the time uiwait returns, so the model comes from the
% shared store rather than from the app -- the same read qMRLab.m does for its
% own modal contract. Clearing it afterwards is the historical OutputFcn
% behaviour and is load-bearing: a Model left at the root is inherited by the
% next launch.
varargout{1} = getappdata(0, 'Model');
if isempty(varargout{1})
    varargout{1} = passthrough(varargin);
end
if isappdata(0, 'Model')
    rmappdata(0, 'Model');
end

end

% ----------------------------------------------------------------------
function m = passthrough(args)
%PASSTHROUGH  The model that came in, or empty if none did.
    m = [];
    if ~isempty(args); m = args{1}; end
end

function tf = envIsTrue(name)
%ENVISTRUE  A flag counts as set only if present AND numerically true.
%
%   The GUIDE-era test was `~str2double(getenv(name))`, which THROWS on any value
%   that is not a number: str2double gives NaN and MATLAB:nologicalnan follows.
%   Treating a non-numeric value as unset cannot break a script that worked
%   before, because such a script crashed here.
    v = str2double(getenv(name));
    tf = ~isnan(v) && v ~= 0;
end
