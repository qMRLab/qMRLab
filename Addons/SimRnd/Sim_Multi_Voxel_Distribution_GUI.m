function varargout = Sim_Multi_Voxel_Distribution_GUI(varargin)
% Sim_Multi_Voxel_Distribution MATLAB code for Sim_Multi_Voxel_Distribution.fig

% Edit the above text to modify the response to help Sim_Multi_Voxel_Distribution

% Last Modified by GUIDE v2.5 06-Jul-2017 17:14:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Sim_Multi_Voxel_Distribution_OpeningFcn, ...
    'gui_OutputFcn',  @Sim_Multi_Voxel_Distribution_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
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

% --- Executes just before Sim_Multi_Voxel_Distribution is made visible.
function Sim_Multi_Voxel_Distribution_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.Model = varargin{1};
if ~isfield(handles,'opened')
    % clear axe
    axes(handles.SimRndAxe)
    % fill table
    Nparam=length(handles.Model.xnames);
    if isprop(handles.Model,'fx') && ~isempty(handles.Model.fx),    FitOptTable(:,1)=mat2cell(~logical(handles.Model.fx(:)),ones(Nparam,1)); end
    if isprop(handles.Model,'st') && ~isempty(handles.Model.st)
        FitOptTable(:,2)=mat2cell(handles.Model.st(:),ones(Nparam,1));
    end
    if isprop(handles.Model,'ub') && ~isempty(handles.Model.ub)
        FitOptTable(:,3)=mat2cell((handles.Model.ub(:) - handles.Model.lb(:))/10,ones(Nparam,1));
        FitOptTable(:,4)=mat2cell(handles.Model.lb(:),ones(Nparam,1));
        FitOptTable(:,5)=mat2cell(handles.Model.ub(:),ones(Nparam,1));
    end
    set(handles.SimRndVaryOptTable,'RowName',handles.Model.xnames(:))
    set(handles.SimRndVaryOptTable,'Data',FitOptTable)
    % fill parameters
    set(handles.SimRndPlotX,'String',handles.Model.xnames')
    set(handles.SimRndPlotY,'String','Voxels count')
    
    % Options
    handles.options = GenerateButtons({'SNR',50,'# of voxels',100},handles.OptionsPanel,.3,1);    
    handles.opened = 1;
end
% Update handles structure
guidata(hObject, handles);


% UIWAIT makes Sim_Multi_Voxel_Distribution wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Sim_Multi_Voxel_Distribution_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure



% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in SimVaryPlotX.
function SimVaryPlotX_Callback(hObject, eventdata, handles)
SimVaryPlotResults(handles)

% --- Executes during object creation, after setting all properties.
function SimVaryPlotX_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SimVaryPlotX (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in SimVaryPlotY.
function SimVaryPlotY_Callback(hObject, eventdata, handles)
SimVaryPlotResults(handles)

% --- Executes during object creation, after setting all properties.
function SimVaryPlotY_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SimVaryPlotY (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
if isfield(handles,'SimVaryResults')
    Method = class(handles.Model);
    [FileName,PathName] = uiputfile([Method '_SimResults.mat']);
    if PathName == 0, return; end
    SimVaryResults = handles.SimVaryResults;
    save(fullfile(PathName,FileName),'SimVaryResults')
end

function Load_Callback(hObject, eventdata, handles)
Method = class(handles.Model);
[FileName,PathName] = uigetfile([Method '_SimResults.mat']);
if PathName == 0, return; end
load(fullfile(PathName,FileName));
handles.SimVaryResults = SimVaryResults;
SetSimVaryResults(handles)
guidata(hObject, handles);

function SetSimVaryResults(handles)
ff=fieldnames(handles.SimVaryResults);
set(handles.SimVaryPlotX,'String',ff);
ff=fieldnames(handles.SimVaryResults.(ff{1}));
set(handles.SimVaryPlotY,'String',ff(~ismember(ff,{'x','fit'})));
SimVaryPlotResults(handles)



function SimVaryPlotResults(handles)
if isfield(handles,'SimVaryResults')
    Xaxis = get(handles.SimVaryPlotX,'String'); Xaxis = Xaxis{get(handles.SimVaryPlotX,'Value')};
    Yaxis = get(handles.SimVaryPlotY,'String'); Yaxis = Yaxis{get(handles.SimVaryPlotY,'Value')};
    SimVaryPlot(handles.SimVaryResults,Xaxis,Yaxis)
end

% --- Executes on button press in SimRndVaryUpdate.
function SimRndVaryUpdate_Callback(hObject, eventdata, handles)
% Read Table
SimRndOpt = get(handles.SimRndVaryOptTable,'Data'); SimRndOpt(:,1)=mat2cell(~[SimRndOpt{:,1}]',ones(size(SimRndOpt,1),1), 1);
SimRndOpt = cell2struct(SimRndOpt,{'fx','Mean','Std','Min','Max'},2);
[SimRndOpt.xnames] = deal(handles.Model.xnames{:});
NumVoxels = str2num(get(handles.options.x0x23OfVoxels,'String'));
Opt.SNR = str2num(get(handles.options.SNR,'String'));
handles.RndParam = GetRndParam(SimRndOpt,NumVoxels);
handles.SimRndResults = handles.Model.Sim_Multi_Voxel_Distribution(handles.RndParam, Opt);
SimRndPlotResultsgui(handles);
guidata(hObject, handles);


function SimRndUpdatePopUp(handles)
axes(handles.SimRndAxe);
colormap('default');
set(handles.SimRndPlotX, 'Value', 1);
set(handles.SimRndPlotY, 'Value', 1);
PlotTypeFields = cellstr(get(handles.SimRndPlotType, 'String'));
PlotType = PlotTypeFields{get(handles.SimRndPlotType, 'Value')};
switch PlotType
    case 'Input parameters'
        XdataFields = fieldnames(handles.RndParam);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Fit results'
        XdataFields = handles.SimRndResults.fields;
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Input vs. Fit'
        XdataFields = fieldnames(handles.RndParam);
        set(handles.SimRndPlotX, 'String', XdataFields);
        YdataFields = handles.SimRndResults.fields;
        set(handles.SimRndPlotY, 'String', YdataFields);
    case 'Error'
        XdataFields = fieldnames(handles.SimRndResults.Error);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Pct error'
        XdataFields = fieldnames(handles.SimRndResults.PctError);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'RMSE'
        set(handles.SimRndPlotX, 'String', 'Parameters');
        set(handles.SimRndPlotY, 'String', 'RMSE');
    case 'NRMSE'
        set(handles.SimRndPlotX, 'String', 'Parameters');
        set(handles.SimRndPlotY, 'String', 'NRMSE');
    case 'MPE'
        set(handles.SimRndPlotX, 'String', 'Parameters');
        set(handles.SimRndPlotY, 'String', 'MPE');
end
guidata(gcbf,handles);


% --- Executes on selection change in SimRndPlotY.
function SimRndPlotY_Callback(hObject, eventdata, handles)
SimRndPlotResultsgui(handles);

% --- Executes on selection change in SimRndPlotX.
function SimRndPlotX_Callback(hObject, eventdata, handles)
SimRndPlotResultsgui(handles);

% --- Executes on selection change in SimRndPlotType.
function SimRndPlotType_Callback(hObject, eventdata, handles)
SimRndUpdatePopUp(handles);
SimRndPlotResultsgui(handles);

function SimRndPlotResultsgui(handles)
PlotTypeFields  = cellstr(get(handles.SimRndPlotType, 'String'));
PlotType = PlotTypeFields{get(handles.SimRndPlotType, 'Value')};
XdataFields    =     cellstr(get(handles.SimRndPlotX, 'String'));
Xdata          = XdataFields{get(handles.SimRndPlotX, 'Value')};
YdataFields    =     cellstr(get(handles.SimRndPlotY, 'String'));
Ydata          = YdataFields{get(handles.SimRndPlotY, 'Value')};
SimRndPlotResults(handles.RndParam,handles.SimRndResults,PlotType,Xdata,Ydata);


function RndParam = GetRndParam(table,NumVoxels)
n    = NumVoxels;
for ii = 1:length(table)
    if~(table(ii).fx); RndParam.(table(ii).xnames) = min(table(ii).Max, max(table(ii).Min,table(ii).Mean + table(ii).Std*(randn(n,1))));
    else          RndParam.(table(ii).xnames) = table(ii).Mean*(ones(n,1));
    end
end



% GETAPPDATA
function varargout = GetAppData(varargin)
for k=1:nargin; varargout{k} = getappdata(0, varargin{k}); end

%SETAPPDATA
function SetAppData(varargin)
for k=1:nargin; setappdata(0, inputname(k), varargin{k}); end

% RMAPPDATA
function RmAppData(varargin)
for k=1:nargin; rmappdata(0, varargin{k}); end

% --- Executes during object creation, after setting all properties.
function SimRndVaryOptTable_CellEditCallback(hObject, eventdata, handles)
function SimRndPlotType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function SimRndPlotX_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function SimRndPlotY_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
