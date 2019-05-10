function varargout = Sim_Single_Voxel_Curve_GUI(varargin)
% SIM_SINGLE_VOXEL_CURVE_GUI MATLAB code for Sim_Single_Voxel_Curve_GUI.fig
%      SIM_SINGLE_VOXEL_CURVE_GUI, by itself, creates a new SIM_SINGLE_VOXEL_CURVE_GUI or raises the existing
%      singleton*.
%
%      H = SIM_SINGLE_VOXEL_CURVE_GUI returns the handle to a new SIM_SINGLE_VOXEL_CURVE_GUI or the handle to
%      the existing singleton*.
%
%      SIM_SINGLE_VOXEL_CURVE_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIM_SINGLE_VOXEL_CURVE_GUI.M with the given input arguments.
%
%      SIM_SINGLE_VOXEL_CURVE_GUI('Property','Value',...) creates a new SIM_SINGLE_VOXEL_CURVE_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Sim_Single_Voxel_Curve_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Sim_Single_Voxel_Curve_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Sim_Single_Voxel_Curve_GUI

% Last Modified by GUIDE v2.5 10-Jul-2017 21:03:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Sim_Single_Voxel_Curve_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Sim_Single_Voxel_Curve_GUI_OutputFcn, ...
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

% --- Executes just before Sim_Single_Voxel_Curve_GUI is made visible.
function Sim_Single_Voxel_Curve_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
set(findobj('Name','qMRLab'),'pointer', 'watch'); drawnow;

Model = varargin{1}; 
setappdata(0,'Model',Model);

if ~isfield(handles,'opened')
    handles.output = hObject;
    handles.Model = varargin{1};
    % OPTIONS
    if isprop(handles.Model,'Sim_Single_Voxel_Curve_buttons') 
        opts = handles.Model.Sim_Single_Voxel_Curve_buttons; 
    else
        opts = {'SNR',50};
    end
    
    % Generate Buttons
    handles.options = GenerateButtonsWithPanels(opts,handles.OptionsPanel);
       
     % Create CALLBACK for buttons
    ff = fieldnames(handles.options);
    for ii=1:length(ff)
        switch get(handles.options.(ff{ii}),'Style')
%             case 'popupmenu'
%                 val =  find(cell2mat(cellfun(@(x) strcmp(x,Model.options.(ff{ii})),get(handles.OptionsPanel_handle.(ff{ii}),'String'),'UniformOutput',0)));
%                 set(handles.OptionsPanel_handle.(ff{ii}),'Value',val);
%             case 'checkbox'
%                 set(handles.OptionsPanel_handle.(ff{ii}),'Value',Model.options.(ff{ii}));
%             case 'edit'
%                 set(handles.OptionsPanel_handle.(ff{ii}),'String',Model.options.(ff{ii}));
            case 'togglebutton'
                set(handles.options.(ff{ii}),'Callback',@(src,event) ModelSimOptions_Callback(handles));
        end     
    end

    Nparam = length(handles.Model.xnames);
    FitOptTable(:,1)=handles.Model.xnames(:);
    if isprop(handles.Model,'st') && ~isempty(handles.Model.st)
        FitOptTable(:,2)=mat2cell(handles.Model.st(:),ones(Nparam,1));
    elseif isprop(handles.Model,'lb') && ~isempty(handles.Model.lb) && isprop(handles.Model,'ub') && ~isempty(handles.Model.ub)
        FitOptTable(:,2) = mat2cell(mean([handles.Model.lb(:), handles.Model.ub(:)],2),ones(Nparam,1));
    end
    set(handles.ParamTable,'Data',FitOptTable)
    
%     % launch plot
%     UpdatePlot_Callback(hObject, eventdata, handles)
    
    
    % opened
    handles.opened = true;
end
% Update handles structure
guidata(hObject, handles);
set(findobj('Name','qMRLab'),'pointer', 'arrow'); drawnow;

% --- Executes on button press in UpdatePlot.
function UpdatePlot_Callback(hObject, eventdata, handles)
Model_new = getappdata(0,'Model');
if ~isempty(Model_new) && strcmp(class(Model_new),class(handles.Model))
    handles.Model = Model_new;
end
set(findobj('Name','Single Voxel Curve'),'pointer', 'watch'); drawnow;
if isgraphics(handles.SimCurveAxe)
    axes(handles.SimCurveAxe)
end

xtable = get(handles.ParamTable,'Data');
x=cell2mat(xtable(~cellfun(@isempty,xtable(:,2)),2))';

FitResults = Sim_Single_Voxel_Curve(handles.Model,x,button_handle2opts(handles.options));
hold off;

% put results in table
ff = fieldnames(FitResults);
for ii=1:length(ff)
    index = strcmp(xtable(:,1),ff{ii});
    if find(index)
        xtable{index,3} = FitResults.(ff{ii})(1);
        xtable{index,4} = round((FitResults.(ff{ii})(1) - xtable{index,2})/xtable{index,2}*100);
    else
        xtable{end+1,1} = ff{ii};
        xtable{end,3} = FitResults.(ff{ii})(1);
    end
end

% CRLB
SNR = str2double(get(handles.options.SNR,'String'));
[~,~,~,F] = SimCRLB(handles.Model,handles.Model.Prot.(handles.Model.MRIinputs{1}).Mat,x,1/SNR);

for ii=1:sum(~handles.Model.fx)
    ll=find(~handles.Model.fx);
    xtable{ll(ii),5}=F(ii)*100;
end
set(handles.ParamTable,'Data',xtable);
set(findobj('Name','Single Voxel Curve'),'pointer', 'arrow'); drawnow;

% --- Executes on button press in Options panel.
function ModelSimOptions_Callback(handles)
xtable = get(handles.ParamTable,'Data');
x=cell2mat(xtable(~cellfun(@isempty,xtable(:,2)),2))';
xnew = SimOpt(handles.Model,x,button_handle2opts(handles.options));
if ~isempty(xnew) % update the ParamTable in the GUI
    Nparam = length(handles.Model.xnames);
    xtable(1:Nparam,2) = mat2cell(xnew',ones(Nparam,1));
    set(handles.ParamTable,'Data',xtable);
end


% --- Outputs from this function are returned to the command line.
function varargout = Sim_Single_Voxel_Curve_GUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
