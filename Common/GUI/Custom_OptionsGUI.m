function varargout = Custom_OptionsGUI(varargin)
% Custom_OPTIONSGUI MATLAB code for Custom_OptionsGUI.fig
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran�is Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMTLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @OptionsGUI_OutputFcn, ...
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


% --- Executes just before Custom_OptionsGUI is made visible.
function OptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.root = fileparts(which(mfilename()));
handles.CellSelect = [];
handles.caller = [];            % Handle to caller GUI
if (~isempty(varargin) && ~isfield(handles,'opened'))         % If called from GUI, set position to dock left
    handles.caller = varargin{1};
    CurrentPos = get(gcf, 'Position');
    CallerPos = get(handles.caller, 'Position');
    NewPos = [CallerPos(1)+CallerPos(3), CallerPos(2)+CallerPos(4)-CurrentPos(4), CurrentPos(3), CurrentPos(4)];
    set(gcf, 'Position', NewPos);
end
handles.opened = 1;

% Load model parameters
Model = varargin{2};
setappdata(0,'Model',Model);
Nparam = length(Model.xnames);

if ~isprop(Model, 'voxelwise') || (isprop(Model, 'voxelwise') && Model.voxelwise ~= 0)
    FitOptTable(:,1) = Model.xnames(:);
    if isprop(Model,'fx') && ~isempty(Model.fx), FitOptTable(:,2) = mat2cell(logical(Model.fx(:)),ones(Nparam,1)); end
    if isprop(Model,'st') && ~isempty(Model.st),
        FitOptTable(:,3) = mat2cell(Model.st(:),ones(Nparam,1));
    end
    if isprop(Model,'lb') && ~isempty(Model.lb) && isprop(Model,'ub') && ~isempty(Model.ub)
        FitOptTable(:,4) = mat2cell(Model.lb(:),ones(Nparam,1));
        FitOptTable(:,5) = mat2cell(Model.ub(:),ones(Nparam,1));
    end
    set(handles.FitOptTable,'Data',FitOptTable)
end

if ~isempty(Model.buttons)
    
    % Generate Buttons
    handles.OptionsPanel_handle = GenerateButtonsWithPanels(Model.buttons,handles.OptionsPanel);
    
    % Create CALLBACK for buttons and use value in Model.options (instead of the default one)
    ff = fieldnames(handles.OptionsPanel_handle);
    for ii=1:length(ff)
        set(handles.OptionsPanel_handle.(ff{ii}),'Callback',@(src,event) ModelOptions_Callback(handles));
        switch get(handles.OptionsPanel_handle.(ff{ii}),'Style')
            case 'popupmenu'
                val =  find(cell2mat(cellfun(@(x) strcmp(x,Model.options.(ff{ii})),get(handles.OptionsPanel_handle.(ff{ii}),'String'),'UniformOutput',0)));
                set(handles.OptionsPanel_handle.(ff{ii}),'Value',val);
            case 'checkbox'
                set(handles.OptionsPanel_handle.(ff{ii}),'Value',Model.options.(ff{ii}));
            case 'edit'
                set(handles.OptionsPanel_handle.(ff{ii}),'String',Model.options.(ff{ii}));
        end     
    end
    SetOpt(handles);
end

% Load Protocol
if ~isempty(Model.Prot)
    fields = fieldnames(Model.Prot); fields = fields(end:-1:1);
    N = length(fields);
    for ii = 1:N
        handles.(fields{ii}).panel = uipanel(handles.ProtEditPanel,'Title',fields{ii},'Units','normalized','Position',[.05 (ii-1)*.95/N+.05 .9 .9/N]);
        handles.(fields{ii}).table = uitable(handles.(fields{ii}).panel,'Data',Model.Prot.(fields{ii}).Mat,'Units','normalized','Position',[.05 .05*N .9 (1-.05*N)]);
        uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[.03 0 .94 .05*N],'Style','pushbutton','String','Load','Callback',@(hObject, eventdata) LoadProt_Callback(hObject, eventdata, handles,fields{ii}));
        set(handles.(fields{ii}).table,'ColumnEditable', true);
        if size(Model.Prot.(fields{ii}).Format,1) > 1
            set(handles.(fields{ii}).table,'RowName', Model.Prot.(fields{ii}).Format);
        else
            set(handles.(fields{ii}).table,'ColumnName',Model.Prot.(fields{ii}).Format);
        end
        handles.(fields{ii}).table.CellEditCallback = @(hObject,Prot) UpdateProt(fields{ii},Prot,handles);
    end
end

if ismethod(Model,'plotProt')
        uicontrol(handles.ProtEditPanel,'Units','normalized','Position',[.05 0 .9 .05],'Style','pushbutton','String','Plot Protocol','Callback','figure(''color'',''white''), Model = getappdata(0,''Model''); Model.plotProt;');
end
guidata(hObject, handles);


    


    
function varargout = OptionsGUI_OutputFcn(hObject, eventdata, handles) 
%varargout{1} = handles.output;

% #########################################################################
%                           SIMULATION PANEL
% #########################################################################


% ############################ PARAMETERS #################################


% ########################## SIM OPTIONS ##################################



% #########################################################################
%                           FIT OPTIONS PANEL
% #########################################################################

% GETFITOPT Get Fit Option from table
function Model = SetOpt(handles)
% READ FITTING TABLE
fittingtable = get(handles.FitOptTable,'Data'); % Get options
Model = getappdata(0,'Model');
Model.xnames = fittingtable(:,1)';

if ~isprop(Model, 'voxelwise') || (isprop(Model, 'voxelwise') && Model.voxelwise ~= 0)
    FitOptTable(:,1) = Model.xnames(:);
    Nparam = size(FitOptTable,1);
    if isprop(Model,'fx') && ~isempty(Model.fx), FitOptTable(:,2) = mat2cell(logical(Model.fx(:)),ones(Nparam,1)); end
    if isprop(Model,'st') && ~isempty(Model.st)
        FitOptTable(:,3) = mat2cell(Model.st(:),ones(Nparam,1));
    end
    if isprop(Model,'lb') && ~isempty(Model.lb) && isprop(Model,'ub') && ~isempty(Model.ub)
        FitOptTable(:,4) = mat2cell(Model.lb(:),ones(Nparam,1));
        FitOptTable(:,5) = mat2cell(Model.ub(:),ones(Nparam,1));
    end
    set(handles.FitOptTable,'Data',FitOptTable)
end


% READ BUTTONS
Model.options = button_handle2opts(handles.OptionsPanel_handle);

if ismethod(Model,'UpdateFields')
    Model = Model.UpdateFields();
end
setappdata(0,'Model',Model);


% FitOptTable CellEdit
function FitOptTable_CellEditCallback(hObject, eventdata, handles)
Model = SetOpt(handles);
OptionsGUI_OpeningFcn(handles.output, [], handles, handles.caller,Model)

function FitOptTable_CreateFcn(hObject, eventdata, handles)

% #########################################################################
%                           PROTOCOL PANEL
% #########################################################################

function DefaultProt_Callback(hObject, eventdata, handles)
Model = getappdata(0,'Model');
modelfun = str2func(class(Model));
defaultModel = modelfun();
Model.Prot = defaultModel.Prot;
setappdata(0,'Model',Model);
set(handles.ProtFileName,'String','Protocol Filename');
OptionsGUI_OpeningFcn(hObject, eventdata, handles, handles.caller,Model)

function LoadProt_Callback(hObject, eventdata, handles, MRIinput)
[FileName,PathName] = uigetfile({'*.mat';'*.xls;*.xlsx';'*.txt;*.scheme'},'Load Protocol Matrix');
if PathName == 0, return; end
fullfilepath = [PathName, FileName];
Prot = ProtLoad(fullfilepath);
if ~isnumeric(Prot), errordlg('Invalid protocol file'); return; end
set(handles.(MRIinput).table,'Data',Prot)
Model = getappdata(0,'Model');
Model.Prot.(MRIinput).Mat = Prot;
UpdateProt(MRIinput,Prot,handles)


function UpdateProt(MRIinput,Prot,handles)
Model = getappdata(0,'Model');
if isnumeric(Prot)
    Model.Prot.(MRIinput).Mat = Prot;
else
    Model.Prot.(MRIinput).Mat = Prot.Source.Data;
end
if ismethod(Model,'UpdateFields')
    Model = Model.UpdateFields();
end
setappdata(0,'Model',Model);
OptionsGUI_OpeningFcn(handles.output, [], handles, handles.caller,Model)



% #########################################################################
%                           MODEL OPTIONS PANEL
% #########################################################################

function ModelOptions_Callback(handles)
Model = SetOpt(handles);
OptionsGUI_OpeningFcn(handles.output, [], handles, handles.caller,Model)

% --- Executes on button press in Helpbutton.
function Helpbutton_Callback(hObject, eventdata, handles)
doc(class(getappdata(0,'Model')))

% --- Executes on button press in Default.
function Default_Callback(hObject, eventdata, handles)
oldModel = getappdata(0,'Model');
modelfun = str2func(class(oldModel));
Model = modelfun();
Model.Prot = oldModel.Prot;
setappdata(0,'Model',Model);
set(handles.ParametersFileName,'String','Parameters Filename');
OptionsGUI_OpeningFcn(hObject, eventdata, handles, handles.caller, Model)

% --- Executes on button press in Load.
function Load_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile('*.mat');
if PathName == 0, return; end
load(fullfile(PathName,FileName));
oldModel = getappdata(0,'Model');
if ~isa(Model,class(oldModel))
    errordlg(['Invalid protocol file. Select a ' class(oldModel) ' parameters file']);
    return;
end
setappdata(0,'Model',Model)
set(handles.ParametersFileName,'String',FileName);
OptionsGUI_OpeningFcn(hObject, eventdata, handles, handles.caller,Model)

% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
Model = getappdata(0,'Model');
[file,path] = uiputfile(['qMRILab_' class(Model) 'Parameters.mat'],'Save file name');
save(fullfile(path,file),'Model')


