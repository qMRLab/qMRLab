function varargout = qMRILab(varargin)
% qMRILAB MATLAB code for qMRILab.fig
% GUI to simulate/fit qMRI data

% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
%
% -- MTSAT functionality: P. Beliveau, 2017
% -- File Browser changes: P. Beliveau 2017
% ----------------------------------------------------------------------------------------------------
% If you use qMRILab in your work, please cite :

% Cabana, JF. et al (2016).
% Quantitative magnetization transfer imaging made easy with qMRILab
% Software for data simulation, analysis and visualization.
% Concepts in Magnetic Resonance Part A
% ----------------------------------------------------------------------------------------------------

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @qMRILab_OpeningFcn, ...
    'gui_OutputFcn',  @qMRILab_OutputFcn, ...
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


% --- Executes just before qMRILab is made visible.
function qMRILab_OpeningFcn(hObject, eventdata, handles, varargin)
clc;
% startup;
qMRILabDir = fileparts(which(mfilename()));
addpath(genpath(qMRILabDir));
handles.root = qMRILabDir;
handles.method = '';
handles.CurrentData = [];
handles.FitDataDim = [];
handles.FitDataSize = [];
handles.FitDataSlice = [];
handles.dcm_obj = [];
MethodList = {}; SetAppData(MethodList);
handles.output = hObject;
guidata(hObject, handles);

% LOAD DEFAULTS
load(fullfile(handles.root,'Common','Parameters','DefaultMethod.mat'));

% add custom models
ModelDir=[qMRILabDir filesep 'Models'];
addModelMenu(hObject, eventdata, handles, handles.ChooseMethod,ModelDir);

% Set Default
set(handles.MethodMenu, 'String', Method);

% cd(fullfile(handles.root, Method));
LoadSimVaryOpt(fullfile(handles.root,'Common','Parameters'), 'DefaultSimVaryOpt.mat', handles);
LoadSimRndOpt(fullfile(handles.root, 'Common','Parameters'), 'DefaultSimRndOpt.mat',  handles);


% SET WINDOW AND PANELS
movegui(gcf,'center')
CurrentPos = get(gcf, 'Position');
NewPos     = CurrentPos;
NewPos(1)  = CurrentPos(1) - 40;
set(gcf, 'Position', NewPos);

SetActive('FitData', handles);
MethodMenu_Callback(hObject, eventdata, handles,Method);

% Outputs from this function are returned to the command line.
function varargout = qMRILab_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% Executes when user attempts to close qMRILab.
function qMRILab_CloseRequestFcn(hObject, eventdata, handles)
h = findobj('Tag','OptionsGUI');
delete(h);
delete(hObject);
% cd(handles.root);
AppData = getappdata(0);
Fields = fieldnames(AppData);
for k=1:length(Fields)
    rmappdata(0, Fields{k});
end

function addModelMenu(hObject, eventdata, handles, parent,folderinit)
% list folders
folders=sct_tools_ls([folderinit filesep '*'], 0, 1, 1);
Nfolders = length(folders);
for iff = 1:Nfolders
    child = uimenu(parent,'Label',folders{iff});
    addModelMenu(hObject, eventdata, handles,child,[folderinit filesep folders{iff}]);
end

% list methods
methods=sct_tools_ls([folderinit filesep '*.m'], 0, 1, 2);
MethodList = GetAppData('MethodList');
MethodList = {MethodList{:} methods{:}};
SetAppData(MethodList)
for im = 1:length(methods)
    uimenu(parent,'Label',methods{im},'Callback', @(x,y) MethodMenu_Callback(hObject,eventdata,guidata(hObject),strrep(methods{im},'.m','')));
end




%###########################################################################################
%                                 COMMON FUNCTIONS
%###########################################################################################

% METHODMENU
function MethodMenu_Callback(hObject, eventdata, handles,Method)
SetAppData(Method)
set(handles.MethodMenu,'String',Method)
handles.method = fullfile(handles.root,'Models_Functions',[Method 'fun']);
if ismember(Method,{'bSSFP','SIRFSE','SPGR'})
    set(handles.uipanel35,'Visible','on') % show the simulation panel
    PathName = fullfile(handles.method,'Parameters');
    LoadDefaultOptions(PathName);
else
    % Update Options Panel
    set(handles.uipanel35,'Visible','off') % hide the simulation panel
end

% Update Options Panel
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    delete(h);
end
OpenOptionsPanel_Callback(hObject, eventdata, handles)

MethodList = getappdata(0, 'MethodList');
MethodList = strrep(MethodList, '.m', '');
if ~isfield(handles,'FileBrowserList');
    % Create File Browser uicontrols for all methods if doesn't exist
    MethodCount = numel(MethodList);
    FitDataPanelObj = findobj('Tag', 'FitDataFileBrowserPanel');
    FileBrowserList = repmat(MethodBrowser(FitDataPanelObj),1,MethodCount);
    handles.FileBrowserList = FileBrowserList;
else 
    handles.FileBrowser.Visible('off'); % hide the current FileBrowser item
end

% Create browser panel b uttons
switch Method
    case 'bSSFP'
        MRIinputs = {'Mask' 'MTdata' 'R1map'};
    case 'SIRFSE'
        MRIinputs = {'Mask' 'MTdata'};
    case 'SPGR'
        MRIinputs = {'Mask' 'MTdata' 'R1map' 'B1map' 'B0map'};
    otherwise
        Model = getappdata(0,'Model');
        MRIinputs = Model.MRIinputs;
end

MethodNum = find(strcmp(MethodList, Method));
if strcmp(handles.FileBrowserList(MethodNum).GetMethod, 'unassigned')
	% create file browser uicontrol with specific inputs
    handles.FileBrowserList(MethodNum) = MethodBrowser(handles.FitDataFileBrowserPanel,handles,{Method MRIinputs{:}});
end
handles.FileBrowser = handles.FileBrowserList(MethodNum); % no need to delete, reference to list object.
handles.FileBrowser.Visible('on');
guidata(hObject, handles);

function MethodMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% SET DEFAULT METHODMENU
function DefaultMethodBtn_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
save(fullfile(handles.root,'Common','Parameters','DefaultMethod.mat'),'Method');

% SIMCURVE
function SimCurveBtn_Callback(hObject, eventdata, handles)
SetActive('SimCurve', handles);

% SIMVARY
function SimVaryBtn_Callback(hObject, eventdata, handles)
SetActive('SimVary', handles);

% SIMRND
function SimRndBtn_Callback(hObject, eventdata, handles)
SetActive('SimRnd', handles);

% SET ACTIVE PANEL
function SetActive(panel, handles)
setappdata(0, 'CurrentPanel', panel);
Panels = {'SimCurve', 'SimVary', 'SimRnd', 'FitData'};

for ii = 1:length(Panels)
    if (strcmp(panel,Panels{ii}))
        PanelOn(Panels{ii}, handles);
    else
        PanelOff(Panels{ii}, handles);
    end
end

function PanelOn(panel, handles)
eval(sprintf('set(handles.%sPanel, ''Visible'', ''on'')', panel));
eval(sprintf('set(handles.%sBtn,''BackgroundColor'', [0.73,0.83,0.96])', panel));

function PanelOff(panel, handles)
eval(sprintf('set(handles.%sPanel, ''Visible'', ''off'')', panel));
eval(sprintf('set(handles.%sBtn,''BackgroundColor'', [0.94,0.94,0.94])', panel));

% OPEN OPTIONS
function OpenOptionsPanel_Callback(hObject, eventdata, handles)
Method = GetAppData('Method');
switch Method
    case 'bSSFP'
        bSSFP_OptionsGUI(gcf);
    case 'SPGR'
        SPGR_OptionsGUI(gcf);
    case 'SIRFSE'
        SIRFSE_OptionsGUI(gcf);
    otherwise
        if isappdata(0,'Model') && strcmp(class(getappdata(0,'Model')),Method) % if same method, load the current class with parameters
            Model = getappdata(0,'Model');
        else % otherwise create a new object of this method
            modelfun  = str2func(Method);
            Model = modelfun();
        end
        Custom_OptionsGUI(gcf,Model);
end

% UPDATE OPTIONS
function UpdateOptions(Sim,Prot,FitOpt)
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    OptionsGUIhandles = guidata(h);
    set(OptionsGUIhandles.SimFileName,   'String',  Sim.FileName);
    set(OptionsGUIhandles.ProtFileName,  'String',  Prot.FileName);
    set(OptionsGUIhandles.FitOptFileName,'String',  FitOpt.FileName);
end

% SimSave
function SimSave_Callback(hObject, eventdata, handles)
[FileName,PathName] = uiputfile(fullfile(handles.method,'SimResults','SimResults.mat'));
if PathName == 0, return; end
CurrentPanel = GetAppData('CurrentPanel');
switch CurrentPanel
    case 'SimCurve'
        SimCurveSaveResults(PathName, FileName, handles);
    case 'SimVary'
        SimVarySaveResults(PathName,  FileName, handles);
    case 'SimRnd'
        SimRndSaveResults(PathName,   FileName, handles);
end

% SimLoad
function SimLoad_Callback(hObject, eventdata, handles)
[Filename,Pathname] = uigetfile(fullfile('*.mat'));
if Pathname == 0, return; end
load(fullfile(Pathname,Filename));

switch FileType
    case 'SimCurveResults'
        SetActive('SimCurve', handles)
        SimCurveLoadResults(Pathname, Filename, handles);
    case 'SimVaryResults'
        SetActive('SimVary', handles)
        SimVaryLoadResults(Pathname, Filename, handles);
    case 'SimRndResults'
        SetActive('SimRnd', handles)
        SimRndLoadResults(Pathname, Filename, handles);
    otherwise
        errordlg('Invalid simulation results file');
end

% SimGO
function SimGO_Callback(hObject, eventdata, handles)
CurrentPanel = GetAppData('CurrentPanel');
switch CurrentPanel
    case 'SimCurve'
        SimCurveGO(handles);
    case 'SimVary'
        SimVaryGO(handles);
    case 'SimRnd'
        SimRndGO(handles);
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

% CLEARAXES
% function ClearAxes(handles)
% cla(handles.SimCurveAxe1);
% cla(handles.SimCurveAxe2);
% cla(handles.SimCurveAxe);
% cla(handles.SimVaryAxe);
% cla(handles.SimRndAxe);
% h = findobj(gcf,'Type','axes','Tag','legend');
% delete(h);




% ##############################################################################################
%                                SINGLE VOXEL SIM
% ##############################################################################################

% SIMULATE DATA
function SimCurveGO(handles)
[Method,Prot,Sim] = GetAppData('Method','Prot','Sim');
switch Method
    case 'bSSFP';   MTdata = bSSFP_sim(Sim, Prot, 1);
    case 'SIRFSE';  MTdata = SIRFSE_sim(Sim, Prot, 1);
    case 'SPGR';    MTdata = SPGR_sim(Sim, Prot, 1);
end
SetAppData(MTdata);
SimCurveUpdate(handles);

% POP FIG
function SimCurvePopFig_Callback(hObject, eventdata, handles)
FileName =  get(handles.SimCurveFileName,'String');
Method   =  GetAppData('Method');
figure('Name',FileName);
switch Method
    case 'bSSFP'
        axe1 = handles.SimCurveAxe1;
        axe2 = handles.SimCurveAxe2;
        subplot(2,1,1);
        handles.SimCurveAxe1 = gca;
        subplot(2,1,2);
        handles.SimCurveAxe2 = gca;
        guidata(hObject, handles);
        SimCurvePlotResults(handles);
        handles.SimCurveAxe1 = axe1;
        handles.SimCurveAxe2 = axe2;
        guidata(hObject, handles);
    otherwise
        SimCurvePlotResults(handles);
end

% UPDATE FIT
function SimCurveUpdate_Callback(hObject, eventdata, handles)
SimCurveUpdate(handles);

function SimCurveUpdate(handles)
MTdata = GetAppData('MTdata');
SimCurveResults = SimCurveFitData(MTdata);
SimCurveSetFitResults(SimCurveResults, handles);
axes(handles.SimCurveAxe);
SimCurvePlotResults(handles);
SimCurveSaveResults(fullfile(handles.method,'SimResults'), 'SimCurveTempResults.mat', handles)

% SET FIT RESULTS TABLE
function SimCurveSetFitResults(SimCurveResults, handles)
SetAppData(SimCurveResults);
[Method, Sim, Prot] = GetAppData('Method','Sim','Prot');
Param = Sim.Param;
switch Method
    case 'bSSFP'
        names = {'F  '; 'kr '; 'R1f'; 'R1r'; 'T2f '; 'M0f'};
        input = [Param.F; Param.kr; Param.R1f; Param.R1r; Param.T2f; Param.M0f];
    case 'SIRFSE'
        names = {'F  '; 'kr '; 'R1f'; 'R1r'; 'Sf '; 'Sr '; 'M0f'};
        [Sr,Sf] = computeSr(Param, Prot);
        input = [Param.F; Param.kr;  Param.R1f; Param.R1r; Sf; Sr; Param.M0f];
    case 'SPGR'
        names = {'F  '; 'kr '; 'R1f'; 'R1r'; 'T2f '; 'T2r'};
        input = [Param.F; Param.kr;  Param.R1f; Param.R1r; Param.T2f; Param.T2r];
end
error =  100*(SimCurveResults.table - input)./input;
data  =  [names, num2cell(input), num2cell(SimCurveResults.table), num2cell(error)];
set(handles.SimCurveResultsTable, 'Data', data);

% SAVE SIM RESULTS
function SimCurveSaveResults(PathName, FileName, handles)
FileType = 'SimCurveResults';
[Sim,Prot,FitOpt,MTdata,MTnoise,SimCurveResults] =  GetAppData(...
    'Sim','Prot','FitOpt','MTdata','MTnoise','SimCurveResults');
save(fullfile(PathName,FileName), '-regexp', '^(?!(handles)$).');
set(handles.SimCurveFileName,'String',FileName);

% LOAD SIM RESULTS
function SimCurveLoadResults(PathName, FileName, handles)
load(fullfile(PathName,FileName));
if (~exist('SimCurveResults', 'var'))
    errordlg('Invalid fit simulation results file');
    return;
end
SetAppData(Sim, Prot, FitOpt, MTdata, MTnoise, SimCurveResults);
UpdateOptions(Sim, Prot, FitOpt);
SimCurveSetFitResults(SimCurveResults, handles);
axes(handles.SimCurveAxe);
SimCurvePlotResults(handles);
set(handles.SimCurveFileName, 'String', FileName);

% FIT DATA
function SimCurveResults = SimCurveFitData(MTdata)
[Sim,Prot,FitOpt,Method] = GetAppData('Sim', 'Prot', 'FitOpt', 'Method');

FitOpt.R1 = computeR1obs(Sim.Param);
MTnoise = [];
if (Sim.Opt.AddNoise)
    MTnoise = noise( MTdata, Sim.Opt.SNR );
    data = MTnoise;
else
    data = MTdata;
end

switch Method
    case 'bSSFP'
        Fit = bSSFP_fit(data, Prot, FitOpt );
        SimCurveResults = bSSFP_SimCurve(Fit, Prot, FitOpt );
    case 'SPGR'
        Fit = SPGR_fit(data, Prot, FitOpt );
        SimCurveResults = SPGR_SimCurve(Fit, Prot, FitOpt );
    case 'SIRFSE'
        Fit = SIRFSE_fit(data, Prot, FitOpt);
        SimCurveResults = SIRFSE_SimCurve(Fit, Prot, FitOpt );
end
SetAppData(MTnoise,SimCurveResults);

% PLOT DATA
function SimCurvePlotResults(handles)
[ Method,  Sim,  Prot,  MTdata,  MTnoise,  SimCurveResults] = GetAppData(...
    'Method','Sim','Prot','MTdata','MTnoise','SimCurveResults');
cla;
switch Method
    case 'bSSFP'
        axe(1) = handles.SimCurveAxe1;
        axe(2) = handles.SimCurveAxe2;
        cla(axe(1)); cla(axe(2));
        bSSFP_PlotSimCurve(MTdata,  MTnoise, Prot, Sim, SimCurveResults, axe);
    case 'SIRFSE'
        SIRFSE_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults);
    case 'SPGR'
        SPGR_PlotSimCurve(MTdata,   MTnoise, Prot, Sim, SimCurveResults);
end
grid('on');



% ##############################################################################################
%                                 VARY PARAMETER SIM
% ##############################################################################################

% SIMULATE DATA
function SimVaryGO(handles)
[Sim,Prot,FitOpt,Method] = GetAppData('Sim','Prot','FitOpt','Method');
SimVaryOpt = GetSimVaryOpt(handles);

opt = SimVaryOpt.table;
fields = {'F';'kr';'R1f';'R1r';'T2f';'T2r';'M0f';'SNR'};

% Data simulation
for ii = 1:8
    if opt(ii,1)
        SimVaryOpt.min  = opt(ii, 2);
        SimVaryOpt.max  = opt(ii, 3);
        SimVaryOpt.step = opt(ii, 4);
        SimVaryResults.(fields{ii}) = VaryParam(fields{ii},Sim,Prot,FitOpt,SimVaryOpt,Method);
    end
    if (getappdata(0, 'Cancel'));  break;  end
end

SetAppData(SimVaryResults);
SimVarySaveResults(fullfile(handles.method,'SimResults'), 'SimVaryTempResults.mat', handles);
SimVaryUpdatePopUp(handles);
axes(handles.SimVaryAxe);
SimVaryPlotResults(handles);


% ######################### SIMVARY OPTIONS ################################
% SAVE SimVaryOpt
function SimVaryOptSave_Callback(hObject, eventdata, handles)
SimVaryOpt = GetSimVaryOpt(handles);
SimVaryOpt.FileType = 'SimVaryOpt';
[FileName,PathName] = uiputfile(fullfile(handles.root,'Common','Parameters','SimVaryOpt.mat'));
if PathName == 0, return; end
save(fullfile(PathName,FileName),'-struct','SimVaryOpt');
setappdata(gcf, 'oldSimVaryOpt', SimVaryOpt);

% LOAD SimVaryOpt
function SimVaryOptLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Common','Parameters','*.mat'));
if PathName == 0, return; end
LoadSimVaryOpt(PathName, FileName, handles);

% RESET SimVaryOpt
function SimVaryOptReset_Callback(hObject, eventdata, handles)
SimVaryOpt = getappdata(gcf, 'oldSimVaryOpt');
SetSimVaryOpt(SimVaryOpt, handles);


% ########################### PLOT ########################################
% PLOT XAXIS MENU
function SimVaryPlotX_Callback(hObject, eventdata, handles)
axes(handles.SimVaryAxe);
SimVaryPlotResults(handles);

% PLOT YAXIS MENU
function SimVaryPlotY_Callback(hObject, eventdata, handles)
axes(handles.SimVaryAxe);
SimVaryPlotResults(handles);

% POP FIG
function SimVaryPopFig_Callback(hObject, eventdata, handles)
FileName = get(handles.SimVaryFileName,'String');
figure('Name',FileName);
SimVaryPlotResults(handles);


%############################ FUNCTIONS ###################################
% SAVE SIM RESULTS
function SimVarySaveResults(PathName, FileName, handles)
FileType = 'SimVaryResults';
[ Sim,  Prot,  FitOpt,  SimVaryOpt,  SimVaryResults] = GetAppData(...
    'Sim','Prot','FitOpt','SimVaryOpt','SimVaryResults');

save(fullfile(PathName,FileName), '-regexp', '^(?!(handles)$).');
set(handles.SimVaryFileName, 'String', FileName);

% LOAD SIM RESULTS
function SimVaryLoadResults(PathName, FileName, handles)
load(fullfile(PathName, FileName));
if (~exist('SimVaryResults','var'))
    errordlg('Invalid simulation results file');
    return;
end
set(handles.SimVaryFileName,'String', FileName);
SetAppData(Sim, Prot, FitOpt, SimVaryOpt, SimVaryResults)
SetSimVaryOpt(SimVaryOpt, handles);
UpdateOptions(Sim, Prot, FitOpt);
SimVaryUpdatePopUp(handles);
axes(handles.SimVaryAxe);
SimVaryPlotResults(handles);

% GET GetSimVaryOpt Get SimVaryOpt from table
function SimVaryOpt = GetSimVaryOpt(handles)
data = get(handles.SimVaryOptTable,'Data');
table(:,2:4) =  cell2mat(data(:,2:4));
table(:,1)   =  cell2mat(data(:,1));
SimVaryOpt.table =  table;
SimVaryOpt.runs  =  str2double(get(handles.SimVaryOptRuns,'String'));
SetAppData(SimVaryOpt);

% SET SetSimVaryOpt Set SimVaryOpt table data
function SetSimVaryOpt(SimVaryOpt, handles)
data = [num2cell(logical(SimVaryOpt.table(:,1))), num2cell(SimVaryOpt.table(:,2:4))];
set(handles.SimVaryOptTable, 'Data',   data);
set(handles.SimVaryOptRuns,  'String', SimVaryOpt.runs);
SetAppData(SimVaryOpt);

function SimVaryOptRuns_Callback(hObject, eventdata, handles)
GetSimVaryOpt(handles);

% LOAD LoadSimVaryOpt SimVaryOpt
function LoadSimVaryOpt(PathName, FileName, handles)
SimVaryOpt = load(fullfile(PathName, FileName));
if (~any(strcmp('FileType',fieldnames(SimVaryOpt))) || ~strcmp(SimVaryOpt.FileType,'SimVaryOpt') )
    errordlg('Invalid options file');
    return;
end
SetSimVaryOpt(SimVaryOpt, handles);
setappdata(gcf, 'oldSimVaryOpt', SimVaryOpt);

% UPDATE POPUP Update the PopUp menus
function SimVaryUpdatePopUp(handles)
[FitOpt, SimVaryResults] = GetAppData('FitOpt','SimVaryResults');
fieldsX = fieldnames(SimVaryResults);
fieldsY = FitOpt.names;
set(handles.SimVaryPlotX, 'Value',  1);
set(handles.SimVaryPlotY, 'Value',  1);
set(handles.SimVaryPlotX, 'String', fieldsX);
set(handles.SimVaryPlotY, 'String', fieldsY);

% PLOT RESULTS
function SimVaryPlotResults(handles)
[Sim, SimVaryResults] = GetAppData('Sim','SimVaryResults');
Param     =  Sim.Param;
Xcontents =  cellstr(get(handles.SimVaryPlotX,   'String'));
Xaxis     =  Xcontents{get(handles.SimVaryPlotX, 'Value')};
Ycontents =  cellstr(get(handles.SimVaryPlotY,   'String'));
Yaxis     =  Ycontents{get(handles.SimVaryPlotY, 'Value')};

Xmin =  SimVaryResults.(Xaxis).x(1)   - SimVaryResults.(Xaxis).step;
Xmax =  SimVaryResults.(Xaxis).x(end) + SimVaryResults.(Xaxis).step;
X    =  SimVaryResults.(Xaxis).x;
Y    =  SimVaryResults.(Xaxis).(Yaxis).mean;
E    =  SimVaryResults.(Xaxis).(Yaxis).std;

cla;
hold on;
if (strcmp(Xaxis,Yaxis))
    plot([Xmin Xmax], [Xmin Xmax], 'k-');
elseif (any(strcmp(Yaxis,fieldnames(Param))))
    plot([Xmin Xmax],[Param.(Yaxis) Param.(Yaxis)], 'k-');
end
errorbar(X, Y, E, 'bo');

xlabel(sprintf('Input %s',  Xaxis), 'FontWeight', 'Bold');
ylabel(sprintf('Fitted %s', Yaxis), 'FontWeight', 'Bold');
xlim([Xmin Xmax]);
hold off;
grid('on');




% ##############################################################################################
%                              RANDOM PARAMETERS SIM
% ##############################################################################################

%############################# SIMULATION #################################
% SIMULATE DATA
function SimRndGO(handles)
SimRndOpt = GetSimRndOpt(handles);
[ Sim,  Prot,  FitOpt,  RndParam,  Method] = GetAppData(...
    'Sim','Prot','FitOpt','RndParam','Method');
if (isempty(RndParam)); RndParam = GetRndParam(handles); end

SimRndResults  =  VaryRndParam(Sim,Prot,FitOpt,SimRndOpt,RndParam,Method);
SetAppData(SimRndResults);
AnalyzeResults(RndParam, SimRndResults, handles);
SimRndSaveResults(fullfile(handles.method,'SimResults'), 'SimRndTempResults.mat', handles)


%########################### RANDOM OPTIONS ###############################
% SAVE SimRndOpt
function SimRndOptSave_Callback(hObject, eventdata, handles)
SimRndOpt = GetSimRndOpt(handles);
SimRndOpt.FileType  =  'SimRndOpt';
[FileName,PathName] =  uiputfile(fullfile(handles.root,'Common','Parameters','SimRndOpt.mat'));
if PathName == 0, return; end
save(fullfile(PathName,FileName), '-struct', 'SimRndOpt');
setappdata(gcf, 'oldSimRndOpt', SimRndOpt);

% LOAD SimRndOpt
function SimRndOptLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Common','Parameters','*.mat'));
if PathName == 0, return; end
LoadSimRndOpt(PathName, FileName, handles);

% RESET SimRndOpt
function SimRndOptReset_Callback(hObject, eventdata, handles)
SimRndOpt = getappdata(0, 'oldSimRndOpt');
SetSimRndOpt(SimRndOpt, handles);

% SimRndOpt TABLE EDIT
function SimRndOptTable_CellEditCallback(hObject, eventdata, handles)
SimRndOptEdit(handles);

% NUMVOXELS
function SimRndOptVoxels_Callback(hObject, eventdata, handles)
SimRndOptEdit(handles);

% GET RND OPT
function SimRndOpt = GetSimRndOpt(handles)
data = get(handles.SimRndOptTable, 'Data');
table(:,2:3) =  cell2mat(data(:,2:3));
table(:,1)   =  cell2mat(data(:,1));
SimRndOpt.table     =  table;
SimRndOpt.NumVoxels =  str2double(get(handles.SimRndOptVoxels, 'String'));
SetAppData(SimRndOpt);

% SET RND OPT
function SetSimRndOpt(SimRndOpt,handles)
data = [num2cell(logical(SimRndOpt.table(:,1))), num2cell(SimRndOpt.table(:,2:3))];
set(handles.SimRndOptTable,  'Data',   data);
set(handles.SimRndOptVoxels, 'String', SimRndOpt.NumVoxels);
SetAppData(SimRndOpt);

% LOAD RND OPT
function LoadSimRndOpt(PathName, FileName, handles)
FullFile = fullfile(PathName,FileName);
if PathName == 0, return; end
SimRndOpt = load(FullFile);
if (~any(strcmp('FileType',fieldnames(SimRndOpt))) || ~strcmp(SimRndOpt.FileType,'SimRndOpt') )
    errordlg('Invalid random parameters options file');
    return;
end
SetSimRndOpt(SimRndOpt,handles);
setappdata(0, 'oldSimRndOpt', SimRndOpt);

% RND OPT EDIT
function SimRndOptEdit(handles)
RndParam = GetRndParam(handles);
SetAppData(RndParam);

% GETRNDPARAM
function SimRndGetParam_Callback(hObject, eventdata, handles)
SimRndOptEdit(handles)
SimRndUpdatePopUp(handles);
SimRndPlotResults(handles);

% GET RANDOM PARAMETERS
function RndParam = GetRndParam(handles)
Sim   = GetAppData('Sim');
Param = Sim.Param;
SimRndOpt = GetSimRndOpt(handles);
n    = SimRndOpt.NumVoxels;
Vary = SimRndOpt.table(:,1);
Mean = SimRndOpt.table(:,2);
Std  = SimRndOpt.table(:,3);
fields = {'F','kr','R1f','R1r','T2f','T2r','M0f'};
for ii = 1:length(fields)
    if(Vary(ii)); RndParam.(fields{ii}) = abs(Mean(ii) + Std(ii)*(randn(n,1)));
    else          RndParam.(fields{ii}) = Param.(fields{ii})*(ones(n,1));
    end
end
SetAppData(RndParam);


% ########################### SIM RESULTS #################################
% SAVE SIM RESULTS
function SimRndSaveResults(PathName, FileName, handles)
FileType = 'SimRndResults';
[ Sim,  Prot,  FitOpt,  SimRndOpt,  RndParam,  SimRndResults] = GetAppData(...
    'Sim','Prot','FitOpt','SimRndOpt','RndParam','SimRndResults');
save(fullfile(PathName,FileName),'Sim','Prot','FitOpt','SimRndOpt','RndParam','SimRndResults','FileType');
set(handles.SimRndFileName, 'String', FileName);

% LOAD SIM RESULTS
function SimRndLoadResults(PathName, FileName, handles)
load(fullfile(PathName,FileName));
if (~exist('SimRndResults','var'))
    errordlg('Invalid random simulation results file');
    return;
end
set(handles.SimRndFileName,'String', FileName);
SetAppData(Sim,Prot,FitOpt,SimRndOpt,RndParam,SimRndResults);
SetSimRndOpt(SimRndOpt,handles)
UpdateOptions(Sim,Prot,FitOpt);
AnalyzeResults(RndParam, SimRndResults, handles);

% ANALYZE SIM RESULTS
function SimRndStats = AnalyzeResults(Input, Results, handles)
Fields = intersect(fieldnames(Input), fieldnames(Results));
for ii = 1:length(Fields)
    n = length(Input.(Fields{ii}));
    SimRndStats.Error.(Fields{ii})    = Results.(Fields{ii}) - Input.(Fields{ii}) ;
    SimRndStats.PctError.(Fields{ii}) = 100*(Results.(Fields{ii}) - Input.(Fields{ii})) ./ Input.(Fields{ii});
    SimRndStats.MPE.(Fields{ii})      = 100/n*sum((Results.(Fields{ii}) - Input.(Fields{ii})) ./ Input.(Fields{ii}));
    SimRndStats.RMSE.(Fields{ii})     = sqrt(sum((Results.(Fields{ii}) - Input.(Fields{ii})).^2 )/n);
    SimRndStats.NRMSE.(Fields{ii})    = SimRndStats.RMSE.(Fields{ii}) / (max(Input.(Fields{ii})) - min(Input.(Fields{ii})));
end
SetAppData(SimRndStats);
SimRndUpdatePopUp(handles);
SimRndPlotResults(handles);


% ############################## FIGURE ###################################
% UPDATE POPUP MENU
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

% PLOT DATA
function SimRndPlotResults(handles)
[RndParam, SimRndResults, SimRndStats] = GetAppData('RndParam','SimRndResults','SimRndStats');
PlotTypeFields  = cellstr(get(handles.SimRndPlotType, 'String'));
PlotType = PlotTypeFields{get(handles.SimRndPlotType, 'Value')};
XdataFields    =     cellstr(get(handles.SimRndPlotX, 'String'));
Xdata          = XdataFields{get(handles.SimRndPlotX, 'Value')};
YdataFields    =     cellstr(get(handles.SimRndPlotY, 'String'));
Ydata          = YdataFields{get(handles.SimRndPlotY, 'Value')};

switch PlotType
    case 'Input parameters'
        hist(RndParam.(Xdata), 30);
        xlabel(['Input ', Xdata], 'FontWeight', 'Bold');
        ylabel(Ydata, 'FontWeight',' Bold');
    case 'Fit results'
        hist(SimRndResults.(Xdata), 30);
        xlabel(['Fitted ', Xdata], 'FontWeight','Bold');
        ylabel(Ydata, 'FontWeight','Bold');
    case 'Input vs. Fit'
        plot(RndParam.(Xdata), SimRndResults.(Ydata),'.');
        xlabel(['Input ' , Xdata], 'FontWeight','Bold');
        ylabel(['Fitted ', Ydata], 'FontWeight','Bold');
    case 'Error'
        hist(SimRndStats.Error.(Xdata), 30);
        xlabel(['Error ', Xdata], 'FontWeight','Bold');
        ylabel(Ydata, 'FontWeight','Bold');
    case 'Pct error'
        hist(SimRndStats.PctError.(Xdata), 30);
        xlabel(['Pct Error ', Xdata], 'FontWeight','Bold');
        ylabel(Ydata, 'FontWeight','Bold');
    case 'RMSE'
        Fields = fieldnames(SimRndStats.RMSE);
        for ii = 1:length(Fields)
            dat(ii) = SimRndStats.RMSE.(Fields{ii});
        end
        bar(diag(dat),'stacked');
        set(gca,'Xtick',1:5,'XTickLabel', Fields);
        legend(Fields);
        xlabel('Fitted parameters', 'FontWeight','Bold');
        ylabel('Root Mean Squared Error', 'FontWeight','Bold');
    case 'NRMSE'
        Fields = fieldnames(SimRndStats.NRMSE);
        for ii = 1:length(Fields)
            dat(ii) = SimRndStats.NRMSE.(Fields{ii});
        end
        bar(diag(dat),'stacked');
        set(gca,'Xtick',1:5,'XTickLabel', Fields);
        legend(Fields);
        xlabel('Fitted parameters', 'FontWeight','Bold');
        ylabel('Normalized Root Mean Squared Error', 'FontWeight','Bold');
    case 'MPE'
        Fields = fieldnames(SimRndStats.MPE);
        for ii = 1:length(Fields)
            dat(ii) = SimRndStats.MPE.(Fields{ii});
        end
        bar(diag(dat),'stacked');
        set(gca,'Xtick',1:5,'XTickLabel', Fields);
        legend(Fields);
        xlabel('Fitted parameters', 'FontWeight','Bold');
        ylabel('Mean Percentage Error', 'FontWeight','Bold');
end


% ########################### PLOT RESULTS ################################
function SimRndPopFig_Callback(hObject, eventdata, handles)
FileName = get(handles.SimRndFileName,'String');
figure('Name', FileName);
SimRndPlotResults(handles);

function SimRndPlotType_Callback(hObject, eventdata, handles)
SimRndUpdatePopUp(handles);
SimRndPlotResults(handles);

function SimRndPlotX_Callback(hObject, eventdata, handles)
SimRndPlotResults(handles);

function SimRndPlotY_Callback(hObject, eventdata, handles)
SimRndPlotResults(handles);




% ##############################################################################################
%                                    FIT DATA
% ##############################################################################################

% FITDATA
function FitDataBtn_Callback(hObject, eventdata, handles)
contents =  cellstr(get(handles.MethodMenu, 'String'));
Method   =  contents{get(handles.MethodMenu, 'Value')};
SetActive('FitData', handles);


% ############################# FIT DATA ##################################
% FITDATA GO
function FitGO_Callback(hObject, eventdata, handles)
SetActive('FitData', handles);
Method = GetMethod(handles);
handles.method = fullfile(handles.root,Method);
FitGo_FitData(hObject, eventdata, handles);






% Original FitGo function
function FitGo_FitData(hObject, eventdata, handles)

% Get data
data =  GetAppData('Data');
[Method, Prot, FitOpt] = GetAppData('Method','Prot','FitOpt');

% If SPGR with SledPike, check for Sf table
if (strcmp(Method,'SPGR') && (strcmp(FitOpt.model, 'SledPikeCW') || strcmp(FitOpt.model, 'SledPikeRP')))
    if (~isfield(Prot,'Sf') || isempty(Prot.Sf))
        errordlg('An Sf table needs to be computed for this protocol prior to fitting. Please use the protocol panel do do so.','Missing Sf table');
        return;
    end
end

% Do the fitting
if ismember(Method,{'bSSFP','SIRFSE','SPGR'})
    FitResults = FitData(data,Prot,FitOpt,Method,1);
else
    Model = getappdata(0,'Model');
    FitResults = FitDataCustom(data,Model,1);
    FitResults.Model = Model;
end

% Save info with results
FitResults.StudyID = handles.FileBrowser.getStudyID;
FitResults.WD = handles.FileBrowser.getWD;
if isempty(FitResults.WD), FitResults.WD = pwd; end
FitResults.Files = handles.FileBrowser.getFileName;
SetAppData(FitResults);

% Kill the waitbar in case of a problem occured
wh=findall(0,'tag','TMWWaitbar');
delete(wh);

% Save fit results
if(~isempty(FitResults.StudyID))
    filename = strcat(FitResults.StudyID,'.mat');
else
    filename = 'FitResults.mat';
end
if ~exist(fullfile(FitResults.WD,'FitResults','dir')), mkdir(fullfile(FitResults.WD,'FitResults')); end
save(fullfile(FitResults.WD,'FitResults',filename),'-struct','FitResults');
set(handles.CurrentFitId,'String','FitResults.mat');

% Save nii maps
fn = fieldnames(FitResults.Files);
mainfile = FitResults.Files.(fn{1});
for i = 1:length(FitResults.fields)
    map = FitResults.fields{i};
    file = strcat(map,'.nii');
    [~,~,ext]=fileparts(mainfile);
    if strcmp(ext,'.mat')
        save_nii_v2(make_nii(FitResults.(map)),fullfile(FitResults.WD,'FitResults',file),[],64);
    else
        save_nii_v2(FitResults.(map),fullfile(FitResults.WD,'FitResults',file),mainfile,64);
    end
end

% Show results
handles.CurrentData = FitResults;
guidata(hObject,handles);
DrawPlot(handles);


% FITRESULTSSAVE
function FitResultsSave_Callback(hObject, eventdata, handles)
FitResults = GetAppData('FitResults');
[FileName,PathName] = uiputfile('*.mat');
if PathName == 0, return; end
save(fullfile(PathName,FileName),'-struct','FitResults');
set(handles.CurrentFitId,'String',FileName);


% FITRESULTSLOAD
function FitResultsLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile('*.mat');
if PathName == 0, return; end
set(handles.CurrentFitId,'String',FileName);
FitResults = load(fullfile(PathName,FileName));
if isfield(FitResults,'Protocol')
    Prot   =  FitResults.Protocol;
else
    Prot   =  FitResults.Prot;
end
if isfield(FitResults,'FitOpt'), FitOpt =  FitResults.FitOpt; SetAppData(FitResults, Prot, FitOpt); Method = FitResults.Protocol.Method; end
if isfield(FitResults,'Model')
    Method = class(FitResults.Model);
    Model = FitResults.Model;
    SetAppData(FitResults,Model);
end

% find model value in the method menu list
val = find(strcmp(get(handles.MethodMenu,'String'),Method));
set(handles.MethodMenu,'Value',val)

MethodMenu_Callback(hObject, eventdata, handles,Method)
handles = guidata(hObject); % update handle

if isfield(FitResults,'WD'), handles.FileBrowser.setWD(FitResults.WD); end
if isfield(FitResults,'StudyID'), handles.FileBrowser.setStudyID(FitResults.StudyID); end
if isfield(FitResults,'Files'),
    for ifile = fieldnames(FitResults.Files)'
        handles.FileBrowser.setFileName(ifile{1},FitResults.Files.(ifile{1}))
    end
end

SetActive('FitData', handles);
handles.CurrentData = FitResults;
guidata(hObject,handles);
DrawPlot(handles);



% #########################################################################
%                            PLOT DATA
% #########################################################################

function ColorMapStyle_Callback(hObject, eventdata, handles)
val  =  get(handles.ColorMapStyle, 'Value');
maps =  get(handles.ColorMapStyle, 'String');
colormap(maps{val});

function Auto_Callback(hObject, eventdata, handles)
GetPlotRange(handles);
RefreshPlot(handles);

% SOURCE
function SourcePop_Callback(hObject, eventdata, handles)
GetPlotRange(handles);
RefreshPlot(handles);

% MIN
function MinValue_Callback(hObject, eventdata, handles)
min   =  str2double(get(hObject,'String'));
max = str2double(get(handles.MaxValue, 'String'));

% special treatment for MTSAT visualisation
CurMethod = getappdata(0, 'Method');
if strcmp(CurMethod, 'MTSAT')
    if n > 2
        Min = min(min(min(MTdata)));
        Max = max(max(max(MTdata)));
        ImSize = size(MTdata);
    else
        Min = min(min(MTdata));
        Max = max(max(MTdata));
    end
    set(handles.MinValue, 'Min', Min);
    set(handles.MinValue, 'Max', Max);
    set(handles.MinValue, 'Value', Min+1);
else
    lower =  0.5 * min;
    set(handles.MinSlider, 'Value', min);
    set(handles.MinSlider, 'min',   lower);
    caxis([min max]);
    % RefreshColorMap(handles);
end

function MinSlider_Callback(hObject, eventdata, handles)
maxi = str2double(get(handles.MaxValue, 'String'));
mini = min(get(hObject, 'Value'),maxi-eps);
set(hObject,'Value',mini)
set(handles.MinValue,'String',mini);
caxis([mini maxi]);
% RefreshColorMap(handles);

% MAX
function MaxValue_Callback(hObject, eventdata, handles)
mini = str2double(get(handles.MinValue, 'String'));
maxi = str2double(get(handles.MaxValue, 'String'));
upper =  1.5 * maxi;
set(handles.MaxSlider, 'Value', maxi)
set(handles.MaxSlider, 'max',   upper);
caxis([mini maxi]);
% RefreshColorMap(handles);

function MaxSlider_Callback(hObject, eventdata, handles)
mini = str2double(get(handles.MinValue, 'String'));
maxi = max(mini +eps,get(hObject, 'Value'));
set(hObject,'Value',maxi)
set(handles.MaxValue,'String',maxi);
caxis([mini maxi]);
% RefreshColorMap(handles);

% VIEW
function ViewPop_Callback(hObject, eventdata, handles)
UpdatePopUp(handles);
RefreshPlot(handles);
xlim('auto');
ylim('auto');

% SLICE
function SliceValue_Callback(hObject, eventdata, handles)
Slice = str2double(get(hObject,'String'));
set(handles.SliceSlider,'Value',Slice);
View =  get(handles.ViewPop,'Value');
handles.FitDataSlice(View) = Slice;
guidata(gcbf,handles);
RefreshPlot(handles);

function SliceSlider_Callback(hObject, eventdata, handles)
Slice = get(hObject,'Value');
Slice = max(1,round(Slice));
set(handles.SliceSlider, 'Value', Slice);
set(handles.SliceValue, 'String', Slice);
View =  get(handles.ViewPop,'Value');
handles.FitDataSlice(View) = Slice;
guidata(gcbf,handles);
RefreshPlot(handles);

% OPEN FIG
function PopFig_Callback(hObject, eventdata, handles)
xl = xlim;
yl = ylim;
figure();
xlim(xl);
ylim(yl);
RefreshPlot(handles);

% SAVE FIG
function SaveFig_Callback(hObject, eventdata, handles)
[FileName,PathName] = uiputfile(fullfile('FitResults','NewFig.fig'));
if PathName == 0, return; end
xl = xlim;
yl = ylim;
h = figure();
xlim(xl);
ylim(yl);
RefreshPlot(handles);
savefig(fullfile(PathName,FileName));
delete(h);

% HISTOGRAM FIG
function Histogram_Callback(hObject, eventdata, handles)
Current = GetCurrent(handles);
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
ii = find(Current);
nVox = length(ii);
data = reshape(Current(ii),1,nVox);
figure();
hist(data,20);
xlabel(Source);
ylabel('Counts');

% PLOT DATA FIT
function ViewDataFit_Callback(hObject, eventdata, handles)
% Get data
data =  getappdata(0,'Data'); MRIinput = fieldnames(data);
[Method, Prot, FitOpt] = GetAppData('Method','Prot','FitOpt');

% Get selected voxel
S = size(data.(MRIinput{1}));
if isempty(handles.dcm_obj) || isempty(getCursorInfo(handles.dcm_obj))
    disp('<strong>Select a voxel in the image using cursor</strong>')
else
    info_dcm = getCursorInfo(handles.dcm_obj);
    x = info_dcm.Position(1);
    y = 1+ S(2) - info_dcm.Position(2);
    z = str2double(get(handles.SliceValue,'String'));
    index = sub2ind(S,x,y,z);
    
    for ii=1:length(MRIinput)
        if ~isempty(data.(MRIinput{ii}))
            data.(MRIinput{ii}) = squeeze(data.(MRIinput{ii})(x,y,z,:));
        end
    end
    if isfield(data,'Mask'), data.Mask = []; end
    
    Sim.Opt.AddNoise = 0;
    % Create axe
    figure(68)
    set(68,'Name',['Fitting results of voxel [' num2str([x y z]) ']'],'NumberTitle','off');
    haxes = get(68,'children'); haxes = haxes(strcmp(get(haxes,'Type'),'axes'));
    
    if ~isempty(haxes)
        % turn gray old plots
        haxes = get(haxes(min(end,2)),'children');
        set(haxes,'Color',[0.8 0.8 0.8]);
        hAnnotation = get(haxes,'Annotation');
        % remove their legends
        for ih=1:length(hAnnotation)
            hLegendEntry = get(hAnnotation{ih},'LegendInformation');
            set(hLegendEntry,'IconDisplayStyle','off');
        end
    end
    hold on;
    
    % Do the fitting
    if ismember(Method,{'bSSFP','SIRFSE','SPGR'})
        Fit = FitData(data,Prot,FitOpt,Method,0);
    else
        Model = getappdata(0,'Model');
        Fit = Model.fit(data) % Display fitting results in command window
        Model.plotmodel(Fit,data);
    end
    
    % Start Fitting
    switch Method
        case 'bSSFP'
            %         Fit.T2f = FitResults.T2f(index);
            %         Fit.M0f = FitResults.M0f(index);
            SimCurveResults = bSSFP_SimCurve(Fit, Prot, FitOpt );
            axe(1) = subplot(2,1,1);
            axe(2) = subplot(2,1,2);
            bSSFP_PlotSimCurve(data.MTdata, data.MTdata, Prot, Sim, SimCurveResults, axe);
            title(sprintf('Voxel %d : F=%0.2f; kf=%0.2f; R1f=%0.2f; R1r=%0.2f; T2f=%0.2f; M0f=%0.2f; Residuals=%f', ...
                index, Fit.F,Fit.kf,Fit.R1f,Fit.R1r,Fit.T2f,Fit.M0f,Fit.resnorm), ...
                'FontSize',10);
        case 'SPGR'
            %         Fit.T2f = FitResults.T2f(index);
            %         Fit.T2r = FitResults.T2r(index);
            SimCurveResults = SPGR_SimCurve(Fit, Prot, FitOpt );
            SPGR_PlotSimCurve(data.MTdata, data.MTdata, Prot, Sim, SimCurveResults);
            title(sprintf('Voxel %d : F=%0.2f; kf=%0.2f; R1f=%0.2f; R1r=%0.2f; T2f=%0.2f; T2r=%f; Residuals=%f', ...
                index, Fit.F,Fit.kf,Fit.R1f,Fit.R1r,Fit.T2f,Fit.T2r,Fit.resnorm),...
                'FontSize',10);
        case 'SIRFSE'
            %         Fit.Sf = FitResults.Sf(index);
            %         Fit.Sr = FitResults.Sr(index);
            %         Fit.M0f = FitResults.M0f(index);
            SimCurveResults = SIRFSE_SimCurve(Fit, Prot, FitOpt );
            SIRFSE_PlotSimCurve(data.MTdata, data.MTdata, Prot, Sim, SimCurveResults);
            title(sprintf('Voxel %d : F=%0.2f; kf=%0.2f; R1f=%0.2f; R1r=%0.2f; Sf=%0.2f; Sr=%f; M0f=%0.2f; Residuals=%f',...
                index, Fit.F,Fit.kf,Fit.R1f,Fit.R1r,Fit.Sf,Fit.Sr,Fit.M0f,Fit.resnorm), ...
                'FontSize',10);
    end
    
    % update legend
    legend('Location','NorthEast')
end


% OPEN VIEWER
function Viewer_Callback(hObject, eventdata, handles)
FitResults = GetAppData('FitResults');
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
file = fullfile(handles.root,strcat(Source,'.nii'));
nii = make_nii(FitResults.(Source));
save_nii(nii,file);
nii_viewer(file);


% PAN
function PanBtn_Callback(hObject, eventdata, handles)
pan;
set(handles.ZoomBtn,'Value',0);
set(handles.CursorBtn,'Value',0);
zoom off;
datacursormode off;

% ZOOM
function ZoomBtn_Callback(hObject, eventdata, handles)
zoom;
set(handles.PanBtn,'Value',0);
set(handles.CursorBtn,'Value',0);
pan off;
datacursormode off;

% CURSOR
function CursorBtn_Callback(hObject, eventdata, handles)
datacursormode;
set(handles.ZoomBtn,'Value',0);
set(handles.PanBtn,'Value',0);
zoom off;
pan off;
fig = gcf;
handles.dcm_obj = datacursormode(fig);
guidata(gcbf,handles);


function RefreshPlot(handles)
Current = GetCurrent(handles);
xl = xlim;
yl = ylim;
% imagesc(flipdim(Current',1));
imagesc(rot90(Current));
axis equal off;
RefreshColorMap(handles)
xlim(xl);
ylim(yl);


% ######################## CREATE FUNCTIONS ##############################
function SimVaryOptRuns_CreateFcn(hObject, eventdata, handles)
function SimVaryPlotX_CreateFcn(hObject, eventdata, handles)
function SimVaryPlotY_CreateFcn(hObject, eventdata, handles)
function SimVaryOptTable_CellEditCallback(hObject, eventdata, handles)
function SimRndOptVoxels_CreateFcn(hObject, eventdata, handles)
function SimRndPlotX_CreateFcn(hObject, eventdata, handles)
function SimRndPlotY_CreateFcn(hObject, eventdata, handles)
function SimRndPlotType_CreateFcn(hObject, eventdata, handles)
function CurrentFitId_CreateFcn(hObject, eventdata, handles)
function ColorMapStyle_CreateFcn(hObject, eventdata, handles)
function SourcePop_CreateFcn(hObject, eventdata, handles)
function View_CreateFcn(hObject, eventdata, handles)
function MinValue_CreateFcn(hObject, eventdata, handles)
function MaxValue_CreateFcn(hObject, eventdata, handles)
function MinSlider_CreateFcn(hObject, eventdata, handles)
function MaxSlider_CreateFcn(hObject, eventdata, handles)
function SliceSlider_CreateFcn(hObject, eventdata, handles)
function SliceValue_CreateFcn(hObject, eventdata, handles)
function ViewPop_CreateFcn(hObject, eventdata, handles)
function FitDataAxe_CreateFcn(hObject, eventdata, handles)
function edit35_Callback(hObject, eventdata, handles)
function edit35_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function uibuttongroup1_SizeChangedFcn(hObject, eventdata, handles)
function popupmenu20_Callback(hObject, eventdata, handles)
function popupmenu20_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pushbutton173_Callback(hObject, eventdata, handles)
function pushbutton174_Callback(hObject, eventdata, handles)
function pushbutton175_Callback(hObject, eventdata, handles)
function pushbutton170_Callback(hObject, eventdata, handles)
function pushbutton171_Callback(hObject, eventdata, handles)
function pushbutton172_Callback(hObject, eventdata, handles)
function slider4_Callback(hObject, eventdata, handles)
function slider4_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider5_Callback(hObject, eventdata, handles)
function slider5_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function popupmenu21_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function MethodqMT_Callback(hObject, eventdata, handles)
function ChooseMethod_Callback(hObject, eventdata, handles)
