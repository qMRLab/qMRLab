function varargout = Sim_Sensitivity_Analysis_GUI(varargin)
% SIM_SENSITIVITY_ANALYSIS_GUI MATLAB code for Sim_Sensitivity_Analysis_GUI.fig
%      SIM_SENSITIVITY_ANALYSIS_GUI, by itself, creates a new SIM_SENSITIVITY_ANALYSIS_GUI or raises the existing
%      singleton*.
%
%      H = SIM_SENSITIVITY_ANALYSIS_GUI returns the handle to a new SIM_SENSITIVITY_ANALYSIS_GUI or the handle to
%      the existing singleton*.
%
%      SIM_SENSITIVITY_ANALYSIS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIM_SENSITIVITY_ANALYSIS_GUI.M with the given input arguments.
%
%      SIM_SENSITIVITY_ANALYSIS_GUI('Property','Value',...) creates a new SIM_SENSITIVITY_ANALYSIS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Sim_Sensitivity_Analysis_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Sim_Sensitivity_Analysis_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Sim_Sensitivity_Analysis_GUI

% Last Modified by GUIDE v2.5 27-Jul-2017 17:23:32
if moxunit_util_platform_is_octave, warndlg('Graphical user interface not available on octave... use command lines instead'); return; end

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Sim_Sensitivity_Analysis_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @Sim_Sensitivity_Analysis_GUI_OutputFcn, ...
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

% --- Executes just before Sim_Sensitivity_Analysis_GUI is made visible.
function Sim_Sensitivity_Analysis_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.Model = varargin{1};
if ~isfield(handles,'opened')
    % clear axe
    axes(handles.SimVaryAxe)

    % fill table
    Nparam=length(handles.Model.xnames);
    FitOptTable(:,1)=handles.Model.xnames(:);
    if isprop(handles.Model,'fx') && ~isempty(handles.Model.fx),    FitOptTable(:,2)=mat2cell(~logical(handles.Model.fx(:)),ones(Nparam,1)); end
    
    if isprop(handles.Model,'ub') && ~isempty(handles.Model.ub)
        FitOptTable(:,4)=mat2cell(handles.Model.lb(:),ones(Nparam,1));
        FitOptTable(:,5)=mat2cell(handles.Model.ub(:),ones(Nparam,1));
    end
    if isprop(handles.Model,'st') && ~isempty(handles.Model.st)
        FitOptTable(:,3)=mat2cell(handles.Model.st(:),ones(Nparam,1));
    elseif size(FitOptTable,2)==5
        FitOptTable(:,3) = mat2cell(mean(cat(2,handles.Model.lb(:),handles.Model.ub(:)),2),ones(Nparam,1));
    else
        FitOptTable(:,3) = mat2cell(ones(Nparam,1),ones(Nparam,1));
    end
    
    if size(FitOptTable,2)<5
        FitOptTable(:,4)=mat2cell(cell2mat(FitOptTable(:,3))/2,ones(Nparam,1));
        FitOptTable(:,5)=mat2cell(cell2mat(FitOptTable(:,3))*2,ones(Nparam,1));
    end
    set(handles.SimVaryOptTable,'Data',FitOptTable)
    % fill parameters
    set(handles.SimVaryPlotX,'String',handles.Model.xnames')
    set(handles.SimVaryPlotY,'String',handles.Model.xnames')
    
    % Options
    if isprop(handles.Model,'Sim_Single_Voxel_Curve_buttons')
        opts = handles.Model.Sim_Single_Voxel_Curve_buttons;
    else
        opts = {'SNR',50};
    end
    if isprop(handles.Model,'Sim_Sensitivity_Analysis_buttons'), opts = cat(2,opts,handles.Model.Sim_Sensitivity_Analysis_buttons); 
    else
        opts = cat(2,opts,{'# of run',20});
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


% UIWAIT makes Sim_Sensitivity_Analysis_GUI wait for user response (see UIRESUME)
% uiwait(handles.Simu);


% --- Outputs from this function are returned to the command line.
function varargout = Sim_Sensitivity_Analysis_GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function OpenMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to OpenMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
file = uigetfile('*.fig');
if ~isequal(file, 0)
    open(file);
end

% --------------------------------------------------------------------
function PrintMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to PrintMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
printdlg(handles.Simu)

% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.Simu,'Name') '?'],...
    ['Close ' get(handles.Simu,'Name') '...'],...
    'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.Simu)


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
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
% eventdata  reserved - to be defined in a future version of MATLAB
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
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SimVaryUpdate.
function SimVaryUpdate_Callback(hObject, eventdata, handles)
Model_new = getappdata(0,'Model');
if ~isempty(Model_new) && strcmp(class(Model_new),class(handles.Model))
    handles.Model = Model_new;
end
FitOptTable = get(handles.SimVaryOptTable,'Data'); FitOptTable(:,2)=mat2cell(~[FitOptTable{:,2}]',ones(size(FitOptTable,1),1), 1);
FitOptTable = cell2struct(FitOptTable,{'xnames','fx','st','lb','ub'},2);
Opts = button_handle2opts(handles.options);
handles.SimVaryResults = handles.Model.Sim_Sensitivity_Analysis(FitOptTable,Opts);
SetSimVaryResults(handles)
guidata(hObject, handles);


% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
if isfield(handles,'SimVaryResults')
    Method = class(handles.Model);
    [FileName,PathName] = uiputfile([Method '_SimResults.mat']);
    if PathName == 0, return; end
    SimVaryResults = handles.SimVaryResults;
    save(fullfile(PathName,FileName),'SimVaryResults')
end

% --- Executes on button press in Options panel.
function ModelSimOptions_Callback(handles)
xtable = get(handles.SimVaryOptTable,'Data');
x=cell2mat(xtable(~cellfun(@isempty,xtable(:,3)),3))';
xnew = SimOpt(handles.Model,x,button_handle2opts(handles.options));
if ~isempty(xnew) % update the ParamTable in the GUI
    Nparam = length(handles.Model.xnames);
    xtable(1:Nparam,3) = mat2cell(xnew',ones(Nparam,1));  
    set(handles.SimVaryOptTable,'Data',xtable); 
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


function SimVaryOptTable_CellEditCallback(hObject, eventdata, handles)
