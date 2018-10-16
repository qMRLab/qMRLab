function varargout = Sim_Multi_Voxel_Distribution_GUI(varargin)
% Sim_Multi_Voxel_Distribution MATLAB code for Sim_Multi_Voxel_Distribution.fig

% Edit the above text to modify the response to help Sim_Multi_Voxel_Distribution

% Last Modified by GUIDE v2.5 27-Jul-2017 17:23:57

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
    %axes(handles.SimRndAxe)
    % fill table
    Nparam=length(handles.Model.xnames);
    if isprop(handles.Model,'fx') && ~isempty(handles.Model.fx),    FitOptTable(:,1)=mat2cell(~logical(handles.Model.fx(:)),ones(Nparam,1)); end
    if isprop(handles.Model,'st') && ~isempty(handles.Model.st)
        FitOptTable(:,2)=mat2cell(handles.Model.st(:),ones(Nparam,1));
    elseif isprop(handles.Model,'ub') && ~isempty(handles.Model.ub)
        FitOptTable(:,2)=mat2cell((handles.Model.ub(:) + handles.Model.lb(:))/2,ones(Nparam,1));
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
    opts = {'# of voxels',100};
    if isprop(handles.Model,'Sim_Single_Voxel_Curve_buttons'), opts = cat(2,opts,handles.Model.Sim_Single_Voxel_Curve_buttons); 
    else
        opts = cat(2,opts,{'SNR',50});
    end
    handles.options = GenerateButtonsWithPanels(opts,handles.OptionsPanel);

    handles.opened = 1;
    % Create CALLBACK for buttons
    ff = fieldnames(handles.options);
    for ii=1:length(ff)
        %set(handles.OptionsPanel_handle.(ff{ii}),'Callback',@(src,event) ModelOptions_Callback(handles));
        switch get(handles.options.(ff{ii}),'Style')
            case 'togglebutton'
                set(handles.options.(ff{ii}),'Callback',@(src,event) ModelSimOptions_Callback(handles));
        end     
    end
end
% Update handles structure
guidata(hObject, handles);


% UIWAIT makes Sim_Multi_Voxel_Distribution wait for user response (see UIRESUME)
% uiwait(handles.Simu);


% --- Outputs from this function are returned to the command line.
function varargout = Sim_Multi_Voxel_Distribution_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure



% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in SimRndVaryUpdate.
function SimRndVaryUpdate_Callback(hObject, eventdata, handles)
% Read Table
Model_new = getappdata(0,'Model');
if ~isempty(Model_new) && strcmp(class(Model_new),class(handles.Model))
    handles.Model = Model_new;
end
SimRndOpt = get(handles.SimRndVaryOptTable,'Data'); SimRndOpt(:,1)=mat2cell(~[SimRndOpt{:,1}]',ones(size(SimRndOpt,1),1), 1);
SimRndOpt = cell2struct(SimRndOpt,{'fx','Mean','Std','Min','Max'},2);
[SimRndOpt.xnames] = deal(handles.Model.xnames{:});
Opt = button_handle2opts(handles.options);
handles.RndParam = GetRndParam(SimRndOpt,Opt.Nofvoxels);
handles.SimRndResults = handles.Model.Sim_Multi_Voxel_Distribution(handles.RndParam, Opt);
SimRndPlotResultsgui(handles);
guidata(hObject, handles);

% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
if isfield(handles,'SimRndResults')
    Method = class(handles.Model);
    [FileName,PathName] = uiputfile([Method '_SimRndResults.mat']);
    if PathName == 0, return; end
    SimRndResults = handles.SimRndResults;
    RndParam      = handles.RndParam;
    save(fullfile(PathName,FileName),'SimRndResults','RndParam')
end

% --- Executes on button press in Options panel.
function ModelSimOptions_Callback(handles)
xtable = get(handles.SimRndVaryOptTable,'Data');
x=cell2mat(xtable(~cellfun(@isempty,xtable(:,3)),3))';
xnew = SimOpt(handles.Model,x,button_handle2opts(handles.options));
if ~isempty(xnew) % update the ParamTable in the GUI
    Nparam = length(handles.Model.xnames);  
    xtable(1:Nparam,3) = mat2cell(xnew',ones(Nparam,1));  
    set(handles.SimRndVaryOptTable,'Data',xtable); 
end


function Load_Callback(hObject, eventdata, handles)
Method = class(handles.Model);
[FileName,PathName] = uigetfile([Method '_SimResults.mat']);
if PathName == 0, return; end
load(fullfile(PathName,FileName));
handles.SimRndResults = SimRndResults;
handles.RndParam      = RndParam;
SimRndPlotResultsgui(handles)
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
