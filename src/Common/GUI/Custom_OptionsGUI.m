function varargout = Custom_OptionsGUI(varargin)
% Custom_OPTIONSGUI MATLAB code for Custom_OptionsGUI.fig
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Francis Cabana, 2016
% Modified  : Agah Karakuzu, 2018
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
    if (isempty(getenv('ISCITEST')) || ~str2double(getenv('ISCITEST'))) && (isempty(getenv('ISDOC')) || ~str2double(getenv('ISDOC')))
        varargin{end+1}='wait';
    end
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


function OptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function is called each time the Options Panel is opened.
%
% OptionsPanel is a non-modal window with the <uipanel29> ID in handles
% Note that what word "PANEL" refers to may be ambigious.
%
% handles.OptionsPanel is to access non-modal uipanel29 window. In this
% window, there are 3 sub-windows for Protocol, FitOpt and Options located
% on the left half, right half upper and right half lower, respectively.
%
% i.e. uipanel29 is the main options panel. It has 3 children (sub-panels):
%
% OptionsPanel (right half lower, by default)
% ProtEditPanel (left half, by default)
% FitOptEditPanel   (right half upper, by default)
%
% Whereas in the buttons context, a PANEL refers to a container object that
% scopes multiple UIObjects (i.e. button groups).
% See GenerateButtonsWithPanels.m for a beter understanding.
%


% varargin contians command line arguments to this UI.
% i)  Should be containg the object for the first model on the dropdown list
% ii) Should be contaning UIFigure object belonging to the main qMRLab window

% Check if command line arguments contain wait command as the last one.
% TRAVIS env triggers this. If this is the case, Options Panel
% execution will be blocked. See if wait statement at the end of this fun.

% INITIALIZE OPTIONSGUI PANEL
% =======================================================================

if any(strcmp(varargin,'wait'))
    wait=true;
    varargin(strcmp(varargin,'wait'))=[];
else
    wait=false;
end

% Choose dedault command line output for OptionsGUI

handles.output = hObject;

% Get root dir for where this script is located

handles.root = fileparts(which(mfilename()));

% Handle to caller GUI

handles.caller = [];

% If called from GUI, set position to dock left

if (length(varargin)>1 && ~isempty(varargin{2}) && ~isfield(handles,'opened'))

    handles.caller = varargin{2};

    CurrentPos = get(hObject, 'Position');

    CallerPos = get(handles.caller, 'Position');

    NewPos = [CallerPos(1)+CallerPos(3), CallerPos(2)+CallerPos(4)-CurrentPos(4), CurrentPos(3), CurrentPos(4)];

    set(hObject, 'Position', NewPos);
end

handles.opened = 1;

% GET/SET MODEL
% =======================================================================

% Retrieve model parameters from the shared data scope of UIs, if varargin
% does not contain any command line arguments.

% If it contains, the first argument must be a Model as assigned by mainApp
% (inversion_recovery as for Aug 2018).

if isempty(varargin)

    Model = getappdata(0,'Model');

else

    Model = varargin{1};

end

% Assign this model to the shared data scope of UIs.
setappdata(0,'Model',Model);


% Assign OptionsGUI title with the Model name
set(handles.uipanel29,'Title',[strrep(Model.ModelName, '_', ' ') ' options'])

% POPULATE FITOPTEDIT SUB-PANEL
% ======================================================================

% Note that this panel and equation member function are codependent.

% Get the length of the fitted parameters

Nparam = length(Model.xnames);

% FitOptTable related conditional block

if ~isprop(Model, 'voxelwise') || (isprop(Model, 'voxelwise') && Model.voxelwise ~= 0)

    FitOptTable(:,1) = Model.xnames(:);

    if isprop(Model,'fx') && ~isempty(Model.fx), FitOptTable(:,2) = mat2cell(logical(Model.fx(:)),ones(Nparam,1)); end

    if isprop(Model,'st') && ~isempty(Model.st)

        FitOptTable(:,3) = mat2cell(Model.st(:),ones(Nparam,1));

    end

    if isprop(Model,'lb') && ~isempty(Model.lb) && isprop(Model,'ub') && ~isempty(Model.ub)

        FitOptTable(:,4) = mat2cell(Model.lb(:),ones(Nparam,1));
        FitOptTable(:,5) = mat2cell(Model.ub(:),ones(Nparam,1));

    end

    set(handles.FitOptTable,'Data',FitOptTable)

    % Add TooltipString
    try

        modelheader=iqmr_header.header_parse(which(Model.ModelName));
        modelheader=modelheader.output';
        set(handles.FitOptTable,'TooltipString', sprintf('%-10s: %s\n',modelheader{:}));

    catch

        warning('Problem with adding TooltipString');

    end
end

% MODEL PROPERTY ADAPTIVE DYNAMIC SUBPANELS
% ======================================================================

% Hide FittingOptions panel if equation is not a member funciton.
% Give the space to the Options initially. If there is no options, then
% remove that one too and leave Protocol only.

% If there is no protocol neither then just close the whole thing :D

% Denoising, noise level: No Protocol
% B1 dam has nothing.
% vfa_t1 has no options.


chld = allchild(handles.uipanel29);

% FitOpt panel is not present

if not(ismember('equation',methods(Model))) && not(isempty(fieldnames(Model.options))) && not(isempty(Model.Prot))

    set(chld(3),'Visible','off');
    set(handles.OptionsPanel, 'Position', [0.5140 0.0158 0.4667 0.9735]);

end

% FitOpt and protocol not present
if not(ismember('equation',methods(Model))) && not(isempty(fieldnames(Model.options))) && (isempty(Model.Prot) || isempty(fieldnames(Model.Prot)))

    set(chld(3),'Visible','off');
    set(chld(2),'Visible','off');
    set(handles.OptionsPanel, 'Position', [0.5140 0.0158 0.4667 0.9735]);

end




% Nothing is present

if (isempty(Model.Prot) || isempty(fieldnames(Model.Prot))) && not(ismember('equation',methods(Model)))

    set(chld(2),'Visible','off');
    set(chld(3),'Visible','off');

end


% POPULATE OPTIONSPANEL
% =======================================================================

if ~isempty(Model.buttons)

    % Delete UIObjects from the previous instance
    delete(findobj('Parent',handles.OptionsPanel,'Type','uipanel'))

    % Generate UIObjects for options panel based on the "buttons" attribute
    % of the current model in the scope. Below function passes OptionsPanel
    % handle, and retrives the updated one with buttons (if present) on it.

    if isprop(Model,'tips')
        handles.OptionsPanel_handle = GenerateButtonsWithPanels(Model.buttons,handles.OptionsPanel, Model.tips);
    else
        handles.OptionsPanel_handle = GenerateButtonsWithPanels(Model.buttons,handles.OptionsPanel, []);

    end

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
    % Noted some concerns @ issue #253
    SetOpt(handles);
end

% POPULATE PROTOCOL PANEL
% =======================================================================

if ~isempty(Model.Prot)

    fields = fieldnames(Model.Prot); fields = fields(end:-1:1);

    N = length(fields);

    for ii = 1:N

        handles.(fields{ii}).CellSelect = [];
        
        % Create PANEL
        % Panels function as a namespace for protocols. 
        % Unlike options panel, here they are REQUIRED. 
        
        handles.(fields{ii}).panel = uipanel(handles.ProtEditPanel,'Title',fields{ii},'Units','normalized','Position',[.05 (ii-1)*.95/N+.05 .9 .9/N]);
        handles.(fields{ii}).table = uitable(handles.(fields{ii}).panel,'Data',Model.Prot.(fields{ii}).Mat,'Units','normalized','Position',[.05 .08*N .9 (1-.08*N)]);
        
        % TODO: Condition to be improved.
        if isprop(Model,'tabletip')
        
        tbl_cur = Model.tabletip.table_name;
        tip_cur = {Model.tabletip.tip};
        
        if ismember(fields{ii},tbl_cur)
            
            [~,tbidx] = ismember(fields{ii},tbl_cur);
            set(handles.(fields{ii}).table,'Tooltip',char(tip_cur{tbidx}));    
        
        end
        
        end
        
        
        % add Callbacks

        set(handles.(fields{ii}).table,'CellEditCallback', @(hObject,Prot) UpdateProt(fields{ii},Prot,handles));

        set(handles.(fields{ii}).table,'CellSelectionCallback', @(hObject, eventdata) SeqTable_CellSelectionCallback(hObject, eventdata, handles, fields{ii}));

        set(handles.(fields{ii}).table,'ColumnEditable', true);

        if size(Model.Prot.(fields{ii}).Format,1) > 1
            set(handles.(fields{ii}).table,'RowName', Model.Prot.(fields{ii}).Format);
            set(handles.(fields{ii}).table,'ColumnName','');
        else
            set(handles.(fields{ii}).table,'ColumnName',Model.Prot.(fields{ii}).Format);
            
            if isprop(Model,'tabletip')
        
                tbl_cur = Model.tabletip.table_name;
                tip_cur = {Model.tabletip.tip};
                
                if ismember(fields{ii},tbl_cur)
                    
                    [~,tbidx] = ismember(fields{ii},tbl_cur);
                    Tip = struct();
                    Tip.tip = tip_cur{tbidx};
                    if isfield(Model.tabletip,'link')
                        Tip.link = cell2mat(Model.tabletip.link);
                    else
                        Tip.link = [];
                    end
                    
                    uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[0.468 0 .066 .061*N],'Style','pushbutton','String','?','BackGroundColor', [0, 0.65, 1],'Callback',@(hObject, eventdata) PointHelp_Callback(hObject, eventdata, handles,Tip));
                end
                
            end
            
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
            uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[.03 0      .44 .02*N],'Style','pushbutton','String','Load','Callback',@(hObject, eventdata) LoadProt_Callback(hObject, eventdata, handles,fields{ii}));
            % Create
            uicontrol(handles.(fields{ii}).panel,'Units','normalized','Position',[.53 0      .44 .02*N],'Style','pushbutton','String','Create','Callback',@(hObject, eventdata) CreateProt_Callback(hObject, eventdata, handles,fields{ii}));
        end
        
        % Make buttons invisible on condition.
        if isprop(Model,'ProtStyle')
            
            prot_names  = Model.ProtStyle.prot_namespace;
            styles = {Model.ProtStyle.style};
            [~,prtidx] = ismember(fields{ii},prot_names);
           
            if strcmp(styles(prtidx),'TableNoButton') && length(handles.(fields{ii}).panel.Children)>1
             
              for chil_iter = 1:length(handles.(fields{ii}).panel.Children)
                  
                  if isa(handles.(fields{ii}).panel.Children(chil_iter),'matlab.ui.control.UIControl')
                  if strcmp(handles.(fields{ii}).panel.Children(chil_iter).Style,'pushbutton')
                      handles.(fields{ii}).panel.Children(chil_iter).Visible = 'off';
                  end
                  end
              end
              
            end
        end
    
        
     end
end

if ismethod(Model,'plotProt')
        uicontrol(handles.ProtEditPanel,'Units','normalized','Position',[.05 0 .9 .05],'Style','pushbutton','String','Plot Protocol','Callback','figure(''color'',''white''), Model = getappdata(0,''Model''); Model.plotProt;');
end
guidata(hObject, handles);

% Wait if output
if wait
uiwait(hObject)
end






function varargout = OptionsGUI_OutputFcn(hObject, eventdata, handles)
if nargout
    varargout{1} = getappdata(0,'Model');
    rmappdata(0,'Model');
    if ~isempty(getenv('ISCITEST')) && isempty(getenv('ISDOC'))
        warning('Environment Variable ''ISCITEST''=1: close window immediately. run >>setenv(''ISCITEST'','''') to change this behavior.');
        delete(findobj('Name','OptionsGUI'));
    end
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
        if isfield(Model.options,'fittingconstraints_FixR1fT2f')  && Model.options.fittingconstraints_FixR1fT2f && (~isfield(Model.options,'Model') || ~any(strcmp(Model.options.Model,{'SledPikeRP', 'SledPikeCW'})))
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

% SANITY CHECK
Data = getappdata(0, 'Data');
if ~isempty(Data) && isfield(Data,class(Model))
    ErrMsg = Model.sanityCheck(Data.(class(Model)));
    hWarnBut = findobj('Tag',['WarnBut_DataConsistency_' class(Model)]);
    if ~isempty(ErrMsg)
        set(hWarnBut,'String',ErrMsg)
        set(hWarnBut,'TooltipString',ErrMsg)
        set(hWarnBut,'Visible','on')
    else
        set(hWarnBut,'String','')
        set(hWarnBut,'TooltipString','')
        set(hWarnBut,'Visible','off')
    end
end

% SAVE
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
FileFormat = '*.mat;*.xls;*.xlsx;*.txt';
if strcmp(MRIinput,'DiffusionData')
    FileFormat = ['*.bvec;*.scheme;' FileFormat];
end
[FileName,PathName] = uigetfile({FileFormat},'Load Protocol Matrix');
if PathName == 0, return; end
fullfilepath = [PathName, FileName];
Prot = ProtLoad(fullfilepath);
if Prot == 0, return; end
if ~isnumeric(Prot), errordlg('Invalid protocol file'); return; end
set(handles.(MRIinput).table,'Data',Prot)
Model = getappdata(0,'Model');
Model.Prot.(MRIinput).Mat = Prot;
UpdateProt(MRIinput,Prot,handles)

function CreateProt_Callback(hObject, eventdata, handles, MRIinput)
Model = getappdata(0,'Model');
Fmt = Model.Prot.(MRIinput).Format; if ischar(Fmt), Fmt = {Fmt}; end
answer = inputdlg(Fmt,'Enter values, vectors or Matlab expressions',[1 100]);
if isempty(answer), return; end
Prot = cellfun(@str2num,answer,'uni',0);
Prot = cellfun(@(x) x(:),Prot,'uni',0);
Nlines = max(cell2mat(cellfun(@length,Prot,'uni',0)));
Model.Prot.(MRIinput).Mat = NaN(Nlines,length(Fmt));
for ic = 1:length(Fmt)
    if length(Prot{ic})>1
        Lmax = length(Prot{ic}); % if vector, fill as many as possible
    else
        Lmax = Nlines; % if scalar, all lines get this value
    end
    if isempty(Prot{ic}), Prot{ic} = NaN; end
    Model.Prot.(MRIinput).Mat(1:Lmax,ic) = Prot{ic};
end
Prot = Model.Prot.(MRIinput).Mat;
set(handles.(MRIinput).table,'Data',Prot)
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

answer = questdlg('What do you want to set to default?','Reset protocol?','Reset options','Reset options AND protocol','Reset protocol','Reset options');
if strfind(answer,'options')
    newModel = Model;
    newModel.Prot = oldModel.Prot;
else
    newModel = oldModel;
end
if strfind(answer,'protocol')
    newModel.Prot = Model.Prot;
end

setappdata(0,'Model',newModel);
set(handles.ParametersFileName,'String','Parameters Filename');
OptionsGUI_OpeningFcn(hObject, eventdata, handles, newModel, handles.caller)

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

% SHOW PROT HELP 
function PointHelp_Callback(hObject,eventdata, handles, Tip)
if ~isempty(Tip.link)
    web(Tip.link)
end
helpdlg(Tip.tip)



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
