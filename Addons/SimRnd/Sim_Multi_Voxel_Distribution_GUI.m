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
    FitOptTable(:,1)=handles.Model.xnames(:);
    if isprop(handles.Model,'fx') && ~isempty(handles.Model.fx),    FitOptTable(:,2)=mat2cell(~logical(handles.Model.fx(:)),ones(Nparam,1)); end
    if isprop(handles.Model,'st') && ~isempty(handles.Model.st)
        FitOptTable(:,3)=mat2cell(handles.Model.st(:),ones(Nparam,1));
    end
    if isprop(handles.Model,'ub') && ~isempty(handles.Model.ub)
        FitOptTable(:,4)=mat2cell((handles.Model.ub(:) - handles.Model.lb(:))/10,ones(Nparam,1));
    end
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


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)




% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)


file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)


printdlg(handles.figure1)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)


selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
    ['Close ' get(handles.figure1,'Name') '...'],...
    'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)



% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)

% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

set(hObject, 'String', {'plot(rand(5))', 'plot(sin(1:0.01:25))', 'bar(1:.5:10)', 'plot(membrane)', 'surf(peaks)'});


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


function SimRndVaryOptTable_CellEditCallback(hObject, eventdata, handles)

function SimRndUpdatePopUp(handles)
[RndParam, SimRndResults, SimRndStats] = GetAppData('RndParam','SimRndResults','SimRndStats');
axes(handles.SimRndAxe);
colormap('default');
set(handles.SimRndPlotX, 'Value', 1);
set(handles.SimRndPlotY, 'Value', 1);
PlotTypeFields = cellstr(get(handles.SimRndPlotType, 'String'));
PlotType = PlotTypeFields{get(handles.SimRndPlotType, 'Value')};
switch PlotType
    case 'Input parameters'
        XdataFields = fieldnames(RndParam);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Fit results'
        XdataFields = SimRndResults.fields;
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Input vs. Fit'
        XdataFields = fieldnames(RndParam);
        set(handles.SimRndPlotX, 'String', XdataFields);
        YdataFields = SimRndResults.fields;
        set(handles.SimRndPlotY, 'String', YdataFields);
    case 'Error'
        XdataFields = fieldnames(SimRndStats.Error);
        set(handles.SimRndPlotX, 'String', XdataFields);
        set(handles.SimRndPlotY, 'String', 'Voxels count');
    case 'Pct error'
        XdataFields = fieldnames(SimRndStats.PctError);
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
SimRndPlotResults(handles);

% --- Executes on selection change in SimRndPlotX.
function SimRndPlotX_Callback(hObject, eventdata, handles)
SimRndPlotResults(handles);

% --- Executes on selection change in SimRndPlotType.
function SimRndPlotType_Callback(hObject, eventdata, handles)
SimRndUpdatePopUp(handles);
SimRndPlotResults(handles);





% --- Executes on button press in SimRndVaryUpdate.
function SimRndVaryUpdate_Callback(hObject, eventdata, handles)
% Read Table
SimRndOpt = get(handles.SimRndVaryOptTable,'Data'); SimRndOpt(:,2)=mat2cell(~[SimRndOpt{:,2}]',ones(size(SimRndOpt,1),1), 1);
SimRndOpt = cell2struct(SimRndOpt,{'xnames','fx','Mean','Std'},2);
RndParam = GetRndParam(handles);
handles.SimRndResults = handles.Model.Sim_Multi_Voxel_Distribution(Sim, Prot, FitOpt, SimRndOpt, RndParam);
handles.SimRndStats = AnalyzeResults(RndParam, handles.SimRndResults);
guidata(hObject, handles);


function SimRndStats = AnalyzeResults(Input, Results)
Fields = intersect(fieldnames(Input), fieldnames(Results));
for ii = 1:length(Fields)
    n = length(Input.(Fields{ii}));
    SimRndStats.Error.(Fields{ii})    = Results.(Fields{ii}) - Input.(Fields{ii}) ;
    SimRndStats.PctError.(Fields{ii}) = 100*(Results.(Fields{ii}) - Input.(Fields{ii})) ./ Input.(Fields{ii});
    SimRndStats.MPE.(Fields{ii})      = 100/n*sum((Results.(Fields{ii}) - Input.(Fields{ii})) ./ Input.(Fields{ii}));
    SimRndStats.RMSE.(Fields{ii})     = sqrt(sum((Results.(Fields{ii}) - Input.(Fields{ii})).^2 )/n);
    SimRndStats.NRMSE.(Fields{ii})    = SimRndStats.RMSE.(Fields{ii}) / (max(Input.(Fields{ii})) - min(Input.(Fields{ii})));
end



function RndParam = GetRndParam(table,NumVoxels)
n    = NumVoxels;
Vary = table(:,2);
Mean = table(:,3);
Std  = table(:,4);
fields = table(:,1);
for ii = 1:length(fields)
    if(Vary(ii)); RndParam.(fields{ii}) = abs(Mean(ii) + Std(ii)*(randn(n,1)));
    else          RndParam.(fields{ii}) = Mean(ii)*(ones(n,1));
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
