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
Nparam=length(Model.xnames);

if ~isprop(Model, 'voxelwise') || (isprop(Model, 'voxelwise') && Model.voxelwise ~= 0)
    FitOptTable(:,1)=Model.xnames(:);
    if isprop(Model,'fx') && ~isempty(Model.fx),    FitOptTable(:,2)=mat2cell(logical(Model.fx(:)),ones(Nparam,1)); end
    if isprop(Model,'st') && ~isempty(Model.st),
        FitOptTable(:,3)=mat2cell(Model.st(:),ones(Nparam,1));
        FitOptTable(:,4)=mat2cell(Model.lb(:),ones(Nparam,1));
        FitOptTable(:,5)=mat2cell(Model.ub(:),ones(Nparam,1));
    end
    set(handles.FitOptTable,'Data',FitOptTable)
end

% Load model specific options
opts=Model.buttons;

if ~isempty(opts)
    N = length(opts)/2;
    nboptions = max(25,2*N);
    [I,J]=ind2sub([1 nboptions],1:2*N); Iw = 0.8/max(I); I=(0.1+0.8*(I-1)/max(I)); 
    Jh = 0.1; J=(J-1)/nboptions*0.85; J=1-J-0.07;
    for i = 1:N
        if isfield(Model.options,genvarname(opts{2*i-1})), val = Model.options.(genvarname(opts{2*i-1})); else val = opts{2*i}; end % retrieve previous value
        if islogical(opts{2*i})
            OptionsPanel_handle(i) = uicontrol('Style','checkbox','String',opts{2*i-1},'ToolTipString',opts{2*i-1},...
                'Parent',handles.OptionsPanel,'Units','normalized','Position',[I(2*i-1) J(2*i-1) Iw Jh/2],...
                'Value',val,'HorizontalAlignment','center');
        elseif isnumeric(opts{2*i})
            uicontrol('Style','Text','String',[opts{2*i-1} ':'],'ToolTipString',opts{2*i-1},...
                'Parent',handles.OptionsPanel,'Units','normalized','HorizontalAlignment','left','Position',[I(2*i-1) J(2*i-1) Iw/2 Jh/2]);
            OptionsPanel_handle(i) = uicontrol('Style','edit',...
                'Parent',handles.OptionsPanel,'Units','normalized','Position',[(I(2*i-1)+Iw/2) J(2*i-1) Iw/2 Jh/2],'String',val);
        elseif iscell(opts{2*i})
            uicontrol('Style','Text','String',[opts{2*i-1} ':'],'ToolTipString',opts{2*i-1},...
                'Parent',handles.OptionsPanel,'Units','normalized','HorizontalAlignment','left','Position',[I(2*i-1) J(2*i-1) Iw/3 Jh/2]);
            if iscell(val), val = 1; else val =  find(cell2mat(cellfun(@(x) strcmp(x,val),opts{2*i},'UniformOutput',0))); end % retrieve previous value
            OptionsPanel_handle(i) = uicontrol('Style','popupmenu',...
                'Parent',handles.OptionsPanel,'Units','normalized','Position',[(I(2*i-1)+Iw/3) J(2*i-1) 2.2*Iw/3 Jh/2],'String',opts{2*i},'Value',val);
            
        end
    end
    
    
    % Create CALLBACK for buttons
    setappdata(0,'Model',Model);
    handles.OptionsPanel_handle=OptionsPanel_handle;
    for ih=1:length(OptionsPanel_handle)
        set(OptionsPanel_handle(ih),'Callback',@(src,event) ModelOptions_Callback(handles))
    end
    SetOpt(handles);
end

% Load Protocol
if ~isempty(Model.Prot)
    fields=fieldnames(Model.Prot); fields = fields(end:-1:1);
    N=length(fields);
    for ii=1:N
        handles.(fields{ii}).panel = uipanel(handles.ProtEditPanel,'Title',fields{ii},'Units','normalized','Position',[.05 (ii-1)*.95/N+.05 .9 .9/N]);
        handles.(fields{ii}).table = uitable(handles.(fields{ii}).panel,'Data',Model.Prot.(fields{ii}).Mat,'Units','normalized','Position',[.05 .05*N .9 (1-.05*N)]);
        uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[.03 0 .94 .05*N],'Style','pushbutton','String','Load','Callback',@(hObject, eventdata) LoadProt_Callback(hObject, eventdata, handles,fields{ii}));
        handles.(fields{ii}).table.ColumnEditable = true;
        if size(Model.Prot.(fields{ii}).Format,1)>1
            handles.(fields{ii}).table.RowName = Model.Prot.(fields{ii}).Format;
        else
            handles.(fields{ii}).table.ColumnName = Model.Prot.(fields{ii}).Format;
        end
        handles.(fields{ii}).table.CellEditCallback = @(hObject,Prot) UpdateProt(fields{ii},Prot);
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
% fitting options
fittingtable = get(handles.FitOptTable,'Data'); % Get options
Model = getappdata(0,'Model');
Model.xnames = fittingtable(:,1)';

if ~isprop(Model, 'voxelwise') || (isprop(Model, 'voxelwise') && Model.voxelwise ~= 0)
    if size(fittingtable,2)>1, Model.fx = cell2mat(fittingtable(:,2)'); end
    if size(fittingtable,2)>2
        Model.st = cell2mat(fittingtable(:,3)');
        Model.lb = cell2mat(fittingtable(:,4)');
        Model.ub = cell2mat(fittingtable(:,5)');
        % check that starting point > lb and < ub
        Model.st = max([Model.st; Model.lb],[],1);
        Model.st = min([Model.st; Model.ub],[],1);
        fittingtable(:,3) = mat2cell(Model.st(:),ones(length(Model.st),1));
        set(handles.FitOptTable,'Data',fittingtable);
    end
end
% ModelOptions
opts = Model.buttons;
N=length(opts)/2;
for i=1:N
    if islogical(opts{2*i})
        optionvalue = get(handles.OptionsPanel_handle(i),'Value');
    elseif isnumeric(opts{2*i})
        optionvalue = str2num(get(handles.OptionsPanel_handle(i),'String'));
    elseif iscell(opts{2*i})
        optionvalue = opts{2*i}{get(handles.OptionsPanel_handle(i),'Value')};
    end
    Model.options.(genvarname(opts{2*i-1}))=optionvalue;
end
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
setappdata(0,'Model',Model);


function UpdateProt(MRIinput,Prot)
Model = getappdata(0,'Model');
Model.Prot.(MRIinput).Mat = Prot.Source.Data;
setappdata(0,'Model',Model);


% #########################################################################
%                           MODEL OPTIONS PANEL
% #########################################################################

function ModelOptions_Callback(handles)
Model = SetOpt(handles);
OptionsGUI_OpeningFcn(handles.output, [], handles, handles.caller,Model)


% --- Executes on button press in Helpbutton.
function Helpbutton_Callback(hObject, eventdata, handles)
% hObject    handle to Helpbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
doc(class(getappdata(0,'Model')))


% --- Executes on button press in Default.
function Default_Callback(hObject, eventdata, handles)
oldModel = getappdata(0,'Model');
modelfun = str2func(class(oldModel));
Model = modelfun();
Model.Prot = oldModel.Prot;
setappdata(0,'Model',Model);
set(handles.ParametersFileName,'String','Parameters Filename');
OptionsGUI_OpeningFcn(hObject, eventdata, handles, handles.caller,Model)

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
