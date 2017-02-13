function varargout = MTSAT_OptionsGUI(varargin)
%MTSAT_OPTIONSGUI MATLAB code file for MTSAT_OptionsGUI.fig
%      MTSAT_OPTIONSGUI, by itself, creates a new MTSAT_OPTIONSGUI or raises the existing
%      singleton*.
%
%      H = MTSAT_OPTIONSGUI returns the handle to a new MTSAT_OPTIONSGUI or the handle to
%      the existing singleton*.
%
%      MTSAT_OPTIONSGUI('Property','Value',...) creates a new MTSAT_OPTIONSGUI using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to MTSAT_OptionsGUI_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      MTSAT_OPTIONSGUI('CALLBACK') and MTSAT_OPTIONSGUI('CALLBACK',hObject,...) call the
%      local function named CALLBACK in MTSAT_OPTIONSGUI.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help MTSAT_OptionsGUI

% Last Modified by GUIDE v2.5 17-Jan-2017 14:39:48

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @MTSAT_OptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @MTSAT_OptionsGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before MTSAT_OptionsGUI is made visible.
function MTSAT_OptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.root = fileparts(which(mfilename()));
handles.CellSelect = [];
handles.caller = [];            % Handle to caller GUI
if (~isempty(varargin))         % If called from GUI, set position to dock left
    handles.caller = varargin{1};
    CurrentPos = get(gcf, 'Position');
    CallerPos = get(handles.caller, 'Position');
    NewPos = [CallerPos(1)+CallerPos(3), CallerPos(2)+CallerPos(4)-CurrentPos(4), CurrentPos(3), CurrentPos(4)];
    set(gcf, 'Position', NewPos);
end
guidata(hObject, handles);
MTsatDefaultParameters();

function MTsatDefaultParameters()
MTparams(1) = pi()*5/180;
MTparams(2) = 0.031;
setappdata(0,'MTparams',MTparams);

PDparams(1) = pi()*5/180;
PDparams(2) = 0.031;
setappdata(0,'PDparams',PDparams);

T1params(1) = pi()*15/180;
T1params(2) = 0.011;
setappdata(0,'T1params',T1params);


% UIWAIT makes MTSAT_OptionsGUI wait for user response (see UIRESUME)
% uiwait(handles.OptionsGUI);


% --- Outputs from this function are returned to the command line.
function varargout = MTSAT_OptionsGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes when entered data in editable cell(s) in MT_Parameters.
function MT_Parameters_CellEditCallback(hObject, eventdata, handles)
MTParams = get(handles.MT_Parameters, 'Data');
setappdata(0, 'MTparams', MTParams);

% --- Executes when entered data in editable cell(s) in PD_Parameters.
function PD_Parameters_CellEditCallback(hObject, eventdata, handles)
PDParams = get(handles.PD_Parameters, 'Data');
setappdata(0, 'PDparams', PDParams);

% --- Executes when entered data in editable cell(s) in T1_Parameters.
function T1_Parameters_CellEditCallback(hObject, eventdata, handles)
T1Params = get(handles.T1_Parameters, 'Data');
setappdata(0, 'T1params', T1Params);
