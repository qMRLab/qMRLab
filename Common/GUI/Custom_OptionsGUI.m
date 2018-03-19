function varargout = Custom_OptionsGUI(varargin)
% Custom_OPTIONSGUI MATLAB code for Custom_OptionsGUI.fig
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran???is Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMTLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------


% Begin initialization code - DO NOT EDIT
if moxunit_util_platform_is_octave, warndlg('Graphical user interface not available on octave... use command lines instead'); if nargout, varargout{1} = varargin{1}; end; return; end
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
    if isempty(getenv('ISTRAVIS')) || ~str2double(getenv('ISTRAVIS'))
        varargin{end+1}='wait';
    end
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Custom_OptionsGUI is made visible.
function OptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% WAIT IF OUTPUTS
if max(strcmp(varargin,'wait')), wait=true; varargin(strcmp(varargin,'wait'))=[]; else wait=false; end

handles.output = hObject;
handles.root = fileparts(which(mfilename()));
handles.caller = [];            % Handle to caller GUI

if (length(varargin)>1 && ~isempty(varargin{2}) && ~isfield(handles,'opened'))         % If called from GUI, set position to dock left
    handles.caller = varargin{2};
    CurrentPos = get(hObject, 'Position');
    CallerPos = get(handles.caller, 'Position');
    NewPos = [CallerPos(1)+CallerPos(3), CallerPos(2)+CallerPos(4)-CurrentPos(4), CurrentPos(3), CurrentPos(4)];
    set(hObject, 'Position', NewPos);
end
handles.opened = 1;

% POPULATE FITTING PANEL
% Load model parameters
Model = varargin{1}; 
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

% POPULATE OPTIONS PANEL
if ~isempty(Model.buttons)
    % delete old buttons
    delete(findobj('Parent',handles.OptionsPanel,'Type','uipanel'))
    % Generate Buttons
    handles.OptionsPanel_handle = GenerateButtonsWithPanels(Model.buttons,handles.OptionsPanel);
    
    % Create CALLBACK for buttons and use value in Model.options (instead of the default one)
    ff = fieldnames(handles.OptionsPanel_handle);
    for ii=1:length(ff)
        if strcmp(get(handles.OptionsPanel_handle.(ff{ii}),'type'),'uitable')
            set(handles.OptionsPanel_handle.(ff{ii}),'CellEditCallback',@(src,event) ModelOptions_Callback(handles));
            set(handles.OptionsPanel_handle.(ff{ii}),'Data',Model.options.(ff{ii}));
        else
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
    end
    SetOpt(handles);
end

% POPULATE PROTOCOL PANEL
if ~isempty(Model.Prot)
    fields = fieldnames(Model.Prot); fields = fields(end:-1:1);
    N = length(fields);
    for ii = 1:N
        handles.(fields{ii}).CellSelect = [];
        % Create PANEL
        handles.(fields{ii}).panel = uipanel(handles.ProtEditPanel,'Title',fields{ii},'Units','normalized','Position',[.05 (ii-1)*.95/N+.05 .9 .9/N]);
        
        % Create TABLE
        handles.(fields{ii}).table = uitable(handles.(fields{ii}).panel,'Data',Model.Prot.(fields{ii}).Mat,'Units','normalized','Position',[.05 .06*N .9 (1-.06*N)]);
        % add Callbacks
        set(handles.(fields{ii}).table,'CellEditCallback', @(hObject,Prot) UpdateProt(fields{ii},Prot,handles));
        set(handles.(fields{ii}).table,'CellSelectionCallback', @(hObject, eventdata) SeqTable_CellSelectionCallback(hObject, eventdata, handles, fields{ii}));
        set(handles.(fields{ii}).table,'ColumnEditable', true);
        
        if size(Model.Prot.(fields{ii}).Format,1) > 1
            set(handles.(fields{ii}).table,'RowName', Model.Prot.(fields{ii}).Format);
            set(handles.(fields{ii}).table,'ColumnName','');
        else
            set(handles.(fields{ii}).table,'ColumnName',Model.Prot.(fields{ii}).Format);
            % Create BUTTONS
            % ADD
            uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[.03 0.04*N .44 .02*N],'Style','pushbutton','String','Add','Callback',@(hObject, eventdata) PointAdd_Callback(hObject, eventdata, handles,fields{ii}));
            % REMOVE
            uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[.53 0.04*N .44 .02*N],'Style','pushbutton','String','Remove','Callback',@(hObject, eventdata) PointRem_Callback(hObject, eventdata, handles,fields{ii}));
            % Move up
            uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[.03 0.02*N .44 .02*N],'Style','pushbutton','String','Move up','Callback',@(hObject, eventdata) PointUp_Callback(hObject, eventdata, handles,fields{ii}));
            % Move down
            uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[.53 0.02*N .44 .02*N],'Style','pushbutton','String','Move down','Callback',@(hObject, eventdata) PointDown_Callback(hObject, eventdata, handles,fields{ii}));
            % LOAD
            uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[.03 0    .94 .02*N],'Style','pushbutton','String','Load','Callback',@(hObject, eventdata) LoadProt_Callback(hObject, eventdata, handles,fields{ii}));
        end

    end
end

if ismethod(Model,'plotProt')
        uicontrol(handles.ProtEditPanel,'Units','normalized','Position',[.05 0 .9 .05],'Style','pushbutton','String','Plot Protocol','Callback','figure(''color'',''white''), Model = getappdata(0,''Model''); Model.plotProt;');
end
guidata(hObject, handles);

if wait
uiwait(hObject)
end


    


    
function varargout = OptionsGUI_OutputFcn(hObject, eventdata, handles) 
if nargout
    varargout{1} = getappdata(0,'Model');
    rmappdata(0,'Model');
    if getenv('ISTRAVIS'), warning('Environment Variable ''ISTRAVIS''=1: close window immediatly. run >>setenv(''ISTRAVIS'','''') to change this behavior.'); delete(findobj('Name','OptionsGUI')); end
end

function OptionsGUI_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
end

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

% Manage R1map and R1r in qmt_SPGR
    indR1map = cellfun(@(x) strcmp(x,'R1MAP'), fittingtable);
    indR1map(:,1)=false;
    if sum(indR1map(:))
        fittingtable{indR1map} = Model.st(strcmp(Model.xnames,'R1f'));
    end
    indR1f = cellfun(@(x) strcmp(x,'R1f'), fittingtable);
    indR1f(:,1)=false;
    if sum(indR1f(:))
    fittingtable{indR1f} = Model.st(strcmp(Model.xnames,'R1r'));
    end
    indT2f = cellfun(@(x) strcmp(x,'(R1f*T2f)/R1f'), fittingtable);
    indT2f(:,1)=false;
    if sum(indT2f(:))
    fittingtable{indT2f} = Model.st(strcmp(Model.xnames,'T2f'));
    end

if ~isprop(Model, 'voxelwise') || (isprop(Model, 'voxelwise') && Model.voxelwise ~= 0)
    if size(fittingtable,2)>1, Model.fx = cell2mat(fittingtable(:,2)'); end
    if size(fittingtable,2)>2
        if ~any(cellfun('isempty',fittingtable(:,3)))
            Model.st = cell2mat(fittingtable(:,3)');
            if isprop(Model,'lb') && isprop(Model,'ub')
                % check that starting point > lb and < ub
                Model.st = max([Model.st; Model.lb],[],1);
                Model.st = min([Model.st; Model.ub],[],1);
                fittingtable(:,3) = mat2cell(Model.st(:),ones(length(Model.st),1));
            end
        end
        if isprop(Model,'lb') && isprop(Model,'ub')
            Model.lb = cell2mat(fittingtable(:,4)');
            Model.ub = cell2mat(fittingtable(:,5)');
        end
        if isfield(Model.options,'fittingconstraints_UseR1maptoconstrainR1f') && Model.options.fittingconstraints_UseR1maptoconstrainR1f
            fittingtable{strcmp(fittingtable(:,1),'R1f'),3}='R1MAP';
        end
        if isfield(Model.options,'fittingconstraints_FixR1rR1f')  && Model.options.fittingconstraints_FixR1rR1f
            fittingtable{strcmp(fittingtable(:,1),'R1r'),3}='R1f';
        end
        if isfield(Model.options,'fittingconstraints_FixR1fT2f')  && Model.options.fittingconstraints_FixR1fT2f
            fittingtable{strcmp(fittingtable(:,1),'T2f'),3}='(R1f*T2f)/R1f';
        end
        set(handles.FitOptTable,'Data',fittingtable);
    end
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
OptionsGUI_OpeningFcn(handles.output, [], handles, Model, handles.caller)

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
OptionsGUI_OpeningFcn(hObject, eventdata, handles, Model, handles.caller)

function LoadProt_Callback(hObject, eventdata, handles, MRIinput)
[FileName,PathName] = uigetfile({'*.mat;*.xls;*.xlsx;*.txt;*.scheme'},'Load Protocol Matrix');
if PathName == 0, return; end
fullfilepath = [PathName, FileName];
Prot = ProtLoad(fullfilepath);
if ~isnumeric(Prot), errordlg('Invalid protocol file'); return; end
set(handles.(MRIinput).table,'Data',Prot)
Model = getappdata(0,'Model');
Model.Prot.(MRIinput).Mat = Prot;
UpdateProt(MRIinput,Prot,handles)


function UpdateProt(MRIinput,Prot,handles)
if ~isnumeric(Prot)
    h_table = Prot.Source;
    Prot = Prot.Source.Data;
else
    h_table = handles.(MRIinput).table;
end

% Color problematic lines in red
if ~isempty(find(isnan(Prot), 1))
    LinesColor = ones(size(Prot,1),3);
    LinesColor(2:2:end,:) = LinesColor(2:2:end,:)*0.9400;
    LinesColor(max(isnan(Prot),[],2),:) = repmat([.7 .5 .5],[sum(max(isnan(Prot),[],2)),1]);
    set(h_table,'BackgroundColor',LinesColor);
    return;
end

% if ok, load Prot into Model
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
OptionsGUI_OpeningFcn(handles.output, [], handles, Model, handles.caller)



% #########################################################################
%                           MODEL OPTIONS PANEL
% #########################################################################

function ModelOptions_Callback(handles)
Model = SetOpt(handles);
OptionsGUI_OpeningFcn(handles.output, [], handles, Model, handles.caller)

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
OptionsGUI_OpeningFcn(hObject, eventdata, handles, Model, handles.caller)

% --- Executes on button press in Load.
function Load_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile('*.mat');
if PathName == 0, return; end
Model = qMRloadObj(fullfile(PathName,FileName));
oldModel = getappdata(0,'Model');
if ~isa(Model,class(oldModel))
    errordlg(['Invalid protocol file. Select a ' class(oldModel) ' parameters file']);
    return;
end
setappdata(0,'Model',Model)
set(handles.ParametersFileName,'String',FileName);
OptionsGUI_OpeningFcn(hObject, eventdata, handles, Model, handles.caller)

% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
Model = getappdata(0,'Model');
[file,path] = uiputfile([class(Model) '.qmrlab.mat'],'Save file name');
if file
    Model.saveObj(fullfile(path,file))
end

% GENERATE SEQUENCE
function GenSeq_Callback(hObject, eventdata, handles, field)
Prot = GetProt(handles);
ti = get(handles.TiBox,'String');
td = get(handles.TdBox,'String');
[Prot.ti,Prot.td] = SIRFSE_GetSeq( eval(ti), eval(td) );
SetProt(Prot,handles);

% REMOVE POINT
function PointRem_Callback(hObject, eventdata, handles, field)
handles = guidata(hObject);
selected = handles.(field).CellSelect;
data = get(handles.(field).table,'Data');
nRows = size(data,1);
if (numel(selected)==0)
    data = data(1:nRows-1,:);
else
    data (selected(:,1), :) = [];
end
set(handles.(field).table,'Data',data);
UpdateProt(field,data,handles)


% ADD POINT
function PointAdd_Callback(hObject, eventdata, handles, field)
handles = guidata(hObject);
selected = handles.(field).CellSelect;
oldDat = get(handles.(field).table,'Data');
nRows = size(oldDat,1);
data = nan(nRows+1,size(oldDat,2));
if (numel(selected)==0)
    data(1:nRows,:) = oldDat;
else
    data(1:selected(1),:) = oldDat(1:selected(1),:);
    data(selected(1)+2:end,:) = oldDat(selected(1)+1:end,:);
end
set(handles.(field).table,'Data',data);
UpdateProt(field,data,handles)

% MOVE POINT UP
function PointUp_Callback(hObject, eventdata, handles, field)
handles = guidata(hObject);
selected = handles.(field).CellSelect;
data = get(handles.(field).table,'Data');
oldDat = data;
if (numel(selected)==0)
    return;
else
    data(selected(1)-1,:) = oldDat(selected(1),:);
    data(selected(1),:) = oldDat(selected(1)-1,:);
end
set(handles.(field).table,'Data',data);
UpdateProt(field,data,handles)


% MOVE POINT DOWN
function PointDown_Callback(hObject, eventdata, handles, field)
handles = guidata(hObject);
selected = handles.(field).CellSelect;
data = get(handles.(field).table,'Data');
oldDat = data;
if (numel(selected)==0)
    return;
else
    data(selected(1)+1,:) = oldDat(selected(1),:);
    data(selected(1),:) = oldDat(selected(1)+1,:);
end
set(handles.(field).table,'Data',data);
UpdateProt(field,data,handles)


% CELL SELECT
function SeqTable_CellSelectionCallback(hObject, eventdata, handles, field)
handles.(field).CellSelect = eventdata.Indices;
guidata(hObject,handles);