function varargout = SIRFSE_OptionsGUI(varargin)
% SIRFSE_OPTIONSGUI MATLAB code for SIRFSE_OptionsGUI.fig
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
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


% --- Executes just before SIRFSE_OptionsGUI is made visible.
function OptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
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

% Load model parameters
ModelOpt = varargin{2};
Nparam=length(ModelOpt.xnames);
FitOptTable(:,1)=ModelOpt.xnames(:);
[FitOptTable{:,2}]=deal(0);
FitOptTable(:,3)=mat2cell(ModelOpt.st(:),ones(Nparam,1));
FitOptTable(:,4)=mat2cell(ModelOpt.lb(:),ones(Nparam,1));
FitOptTable(:,5)=mat2cell(ModelOpt.ub(:),ones(Nparam,1));
set(handles.FitOptTable,'Data',FitOptTable)
set(handles.ProtFormat,'String',ModelOpt.ProtFormat)

% Load model specific options
opts=ModelOpt.buttons;

if ~isempty(opts)
    N = length(opts)/2;
    [I,J]=ind2sub([1 15],1:2*N); Iw = 1/max(I); I=(I-1)/max(I); Jh = 1/max(J); J=(J-1)/max(J); J=1-J-Jh;
    for i = 1:N
        if islogical(opts{2*i})
            OptionsPanel_handle(i) = uicontrol('Style','checkbox','String',opts{2*i-1},...
                'Parent',handles.OptionsPanel,'Units','normalized','Position',[I(2*i-1) J(2*i-1) Iw Jh/2],...
                'Value',opts{2*i},'HorizontalAlignment','center');
        elseif isnumeric(opts{2*i})
            uicontrol('Style','Text','String',opts{2*i-1},...
                'Parent',handles.OptionsPanel,'Units','normalized','Position',[I(2*i-1) J(2*i-1) Iw/2 Jh/2]);
            OptionsPanel_handle(i) = uicontrol('Style','edit',...
                'Parent',handles.OptionsPanel,'Units','normalized','Position',[(I(2*i-1)+Iw/2) J(2*i-1) Iw/2 Jh/2],'String',opts{2*i});
        elseif iscell(opts{2*i})
            uicontrol('Style','Text','String',opts{2*i-1},...
                'Parent',handles.OptionsPanel,'Units','normalized','Position',[I(2*i-1) J(2*i-1) Iw Jh/2]);
            OptionsPanel_handle(i) = uicontrol('Style','popupmenu',...
                'Parent',handles.OptionsPanel,'Units','normalized','Position',[I(2*i) J(2*i) Iw Jh],'String',opts{2*i});
            
        end
    end
    
    
    % Create CALLBACK for buttons
    handles.opts=opts;
    handles.OptionsPanel_handle=OptionsPanel_handle;
    for ih=1:length(OptionsPanel_handle)
        set(OptionsPanel_handle(ih),'Callback',@(src,event) ModelOptions_Callback(handles))
    end
    ModelOptions_Callback(handles);
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
function FitOpt = GetOpt(handles)
% fitting options
data = get(handles.FitOptTable,'Data'); % Get options
FitOpt.names = data(:,1)';
FitOpt.fx = cell2mat(data(:,2)');
FitOpt.st = cell2mat(data(:,3)');
FitOpt.lb = cell2mat(data(:,4)');
FitOpt.ub = cell2mat(data(:,5)');
% ModelOptions
% create options
opts = handles.opts;
N=length(opts)/2;
for i=1:N
    if islogical(opts{2*i})
        optionvalue = get(handles.OptionsPanel_handle(i),'Value');
    elseif isnumeric(opts{2*i})
        optionvalue = str2num(get(handles.OptionsPanel_handle(i),'String'));
    elseif iscell(opts{2*i})
        optionvalue = opts{2*i}{get(handles.OptionsPanel_handle(i),'Value')};
    end
    FitOpt.(matlab.lang.makeValidName(handles.opts{2*i-1}))=optionvalue;
end

% FitOptTable CellEdit
function FitOptTable_CellEditCallback(hObject, eventdata, handles)
FitOpt = GetOpt(handles);
setappdata(0,'FitOpt',FitOpt);

function FitOptTable_CreateFcn(hObject, eventdata, handles)

% #########################################################################
%                           PROTOCOL PANEL
% #########################################################################

% LOAD
function ProtLoad_Callback(hObject, eventdata, handles)
[FileName,PathName,filterindex] = uigetfile({'*.mat';'*.xls;*.xlsx';'*.txt;*.scheme'},'Load Protocol Matrix');
if PathName == 0, return; end
switch filterindex
    case 1
        Prot = load(fullfile(PathName,FileName));
    case 2
        Prot = xlsread(fullfile(PathName,FileName));
    case 3
        Prot = txt2mat(fullfile(PathName,FileName));
end
setappdata(0,'Prot',Prot);
set(handles.ProtFileName,'String',FileName);

% #########################################################################
%                           MODEL OPTIONS PANEL
% #########################################################################

function ModelOptions_Callback(handles)
FitOpt = GetOpt(handles);
setappdata(0,'FitOpt',FitOpt);
