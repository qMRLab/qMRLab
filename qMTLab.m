function varargout = qMTLab(varargin)
% QMTLAB MATLAB code for qMTLab.fig
% GUI to simulate/fit qMT data 

% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% 
% -- MTSAT functionality: P. Beliveau, 2017
% ----------------------------------------------------------------------------------------------------
% If you use qMTLab in your work, please cite :

% Cabana, JF. et al (2016).
% Quantitative magnetization transfer imaging made easy with qMTLab
% Software for data simulation, analysis and visualization.
% Concepts in Magnetic Resonance Part A
% ----------------------------------------------------------------------------------------------------

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @qMTLab_OpeningFcn, ...
    'gui_OutputFcn',  @qMTLab_OutputFcn, ...
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


% --- Executes just before qMTLab is made visible.
function qMTLab_OpeningFcn(hObject, eventdata, handles, varargin)
clc;
% startup;
qMTLabDir = fileparts(which(mfilename()));
addpath(genpath(qMTLabDir));
handles.root = qMTLabDir;
handles.method = '';
handles.CurrentData = [];
handles.FitDataDim = [];
handles.FitDataSize = [];
handles.FitDataSlice = [];
handles.dcm_obj = [];
handles.output = hObject;
guidata(hObject, handles);

% LOAD DEFAULTS
load(fullfile(handles.root,'Common','Parameters','DefaultMethod.mat'));
ii=1;
% PanelOff('MTSAT', handles);
switch Method
    case 'bSSFP'
        ii = 1;
        PanelOff('MTSAT', handles);
    case 'SIRFSE'
        ii = 2;
    case 'SPGR'
        ii = 3;
    case 'MTSAT'
        ii = 4;
%          SetActive('MTSAT', handles);
end
set(handles.MethodMenu, 'Value', ii);
Method = GetMethod(handles);
% cd(fullfile(handles.root, Method));
LoadDefaultOptions(fullfile(handles.root,Method,'Parameters'));
LoadSimVaryOpt(fullfile(handles.root,'Common','Parameters'), 'DefaultSimVaryOpt.mat', handles);
LoadSimRndOpt(fullfile(handles.root, 'Common','Parameters'), 'DefaultSimRndOpt.mat',  handles);


% SET WINDOW AND PANELS
movegui(gcf,'center')
CurrentPos = get(gcf, 'Position');
NewPos     = CurrentPos;
NewPos(1)  = CurrentPos(1) - 40;
set(gcf, 'Position', NewPos);

SetActive('FitData', handles);
OpenOptionsPanel_Callback(hObject, eventdata, handles);

% FileBrowser Tag: FitDataPanel
FitDataPanelObj = findobj('Tag', 'FitDataFileBrowserPanel') % FitDataFileBrowser is the parent panel
FullFilename = 'MethodsFileList.txt';
% open FullFileName - determine nb lines in file
fileID = fopen(FullFilename, 'r');
ReadLine = fgetl(fileID);            
NbLines = 0;
while ischar(ReadLine)
	%numFields = length(strfind(ReadLine,' '));          
	ReadLine = fgetl(fileID);
	NbLines = NbLines + 1;
end
fclose(fileID);

%initialize list of BrowserSet items
MethodsList = repmat(MethodBrowser(FitDataPanelObj),1,NbLines);
            
% Create displayed objects in the file browser
fileID = fopen(FullFilename, 'r');
ReadLine = fgetl(fileID);            
NbLines = 0;
while ischar(ReadLine)
	numFields = length(strfind(ReadLine,' ')); 
    Params = strsplit(string(ReadLine),' ');
    MethodsList(NbLines+1) = MethodBrowser(FitDataPanelObj, handles, Params);
    MethodsList(NbLines+1).VisibleOff();
    ReadLine = fgetl(fileID);
    NbLines = NbLines + 1;
end
fclose(fileID);

for i=1:NbLines
    if MethodsList(i).IsMethod(Method) == 0
        MethodsList(i).VisibleOn();
    end
end

setappdata(0, 'MethodsListed', MethodsList);


% Outputs from this function are returned to the command line.
function varargout = qMTLab_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% Executes when user attempts to close qMTLab.
function SimGUI_CloseRequestFcn(hObject, eventdata, handles)
h = findobj('Tag','OptionsGUI');
delete(h);
delete(hObject);
% cd(handles.root);
AppData = getappdata(0);
Fields = fieldnames(AppData);
for k=1:length(Fields)
    rmappdata(0, Fields{k});
end






%###########################################################################################
%                                 COMMON FUNCTIONS
%###########################################################################################

% METHODMENU
function MethodMenu_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
% cd(fullfile(handles.root, Method));
handles.method = fullfile(handles.root,Method);
PathName = fullfile(handles.method,'Parameters');
LoadDefaultOptions(PathName);
% Update Options Panel
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    delete(h);
    OpenOptionsPanel_Callback(hObject, eventdata, handles)
end

function MethodMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% GET METHOD
function Method = GetMethod(handles)
contents =  cellstr(get(handles.MethodMenu, 'String'));
Method   =  contents{get(handles.MethodMenu, 'Value')};
setappdata(0, 'Method', Method);
handles.method = fullfile(handles.root, Method);
guidata(gcf,handles);
ClearAxes(handles);
PanelOff('MTSAT', handles);

        MethodsList = getappdata(0, 'MethodsListed');
        MethodsSize = size(MethodsList);
        NbMethods = MethodsSize(2);
        for i=1:NbMethods
            if MethodsList(i).IsMethod(Method) == 0
                MethodsList(i).VisibleOn();
            else
                MethodsList(i).VisibleOff();
            end
        end
        
        
switch Method
    case 'bSSFP'
        set(handles.SimCurveAxe1, 'Visible', 'on');
        set(handles.SimCurveAxe2, 'Visible', 'on');
        set(handles.SimCurveAxe,  'Visible', 'off');
    case 'MTSAT'
        %SetActive('MTSAT', handles);
        set(handles.SimCurveAxe1, 'Visible', 'off');
        set(handles.SimCurveAxe2, 'Visible', 'off');
        set(handles.SimCurveAxe,  'Visible', 'on');
    otherwise
        set(handles.SimCurveAxe1, 'Visible', 'off');
        set(handles.SimCurveAxe2, 'Visible', 'off');
        set(handles.SimCurveAxe,  'Visible', 'on');
end

% SET DEFAULT METHODMENU
function DefaultMethodBtn_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
save(fullfile(handles.root,'Common','Parameters','DefaultMethod.mat'),'Method');

% SIMCURVE
function SimCurveBtn_Callback(hObject, eventdata, handles)
contents =  cellstr(get(handles.MethodMenu, 'String'));
Method   =  contents{get(handles.MethodMenu, 'Value')};
if ~strcmp(Method, 'MTSAT')
    SetActive('SimCurve', handles);
end

% SIMVARY
function SimVaryBtn_Callback(hObject, eventdata, handles)
contents =  cellstr(get(handles.MethodMenu, 'String'));
Method   =  contents{get(handles.MethodMenu, 'Value')};
if ~strcmp(Method, 'MTSAT')
    SetActive('SimVary', handles);
end

% SIMRND
function SimRndBtn_Callback(hObject, eventdata, handles)
contents =  cellstr(get(handles.MethodMenu, 'String'));
Method   =  contents{get(handles.MethodMenu, 'Value')};
if ~strcmp(Method, 'MTSAT')
    SetActive('SimRnd', handles);
end

% SET ACTIVE PANEL
function SetActive(panel, handles)
setappdata(0, 'CurrentPanel', panel);
Panels = {'SimCurve', 'SimVary', 'SimRnd', 'FitData', 'MTSAT'};

if (strcmp(panel,'MTSAT'))    
    for ii = 1:length(Panels)
        if ii < 4
            PanelOff(Panels{ii}, handles);
        else 
            PanelOn(Panels{ii}, handles);
        end
    end
    
else 
    for ii = 1:length(Panels)
        if (strcmp(panel,Panels{ii}))
            PanelOn(Panels{ii}, handles);
        else
            PanelOff(Panels{ii}, handles);
        end
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
    case 'MTSAT'
        MTSAT_OptionsGUI(gcf);
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

% SETAPPDATA
function SetAppData(varargin)
for k=1:nargin; setappdata(0, inputname(k), varargin{k}); end

% RMAPPDATA
function RmAppData(varargin)
for k=1:nargin; rmappdata(0, varargin{k}); end

% CLEARAXES
function ClearAxes(handles)
cla(handles.SimCurveAxe1);
cla(handles.SimCurveAxe2);
cla(handles.SimCurveAxe);
cla(handles.SimVaryAxe);
cla(handles.SimRndAxe);
h = findobj(gcf,'Type','axes','Tag','legend');
delete(h);




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
if strcmp(Method, 'MTSAT')
    PanelOn('MTSAT', handles);
end

% WORKING DIRECTORY
function WDLoad_Callback(hObject, eventdata, handles)
WD = uigetdir;
if WD == 0, return; end
set(handles.WDBox,'String',WD);

% Clear previous file paths
set(handles.B1mapFileBox,'String', '');
set(handles.B0mapFileBox,'String', '');
set(handles.R1mapFileBox,'String', '');
set(handles.MaskFileBox,'String', '');
set(handles.MTdataFileBox,'String', '');

%Check for files and set fields automatically
dirData = dir(WD);
dirIndex = [dirData.isdir];
fileList = {dirData(~dirIndex).name}';

for i = 1:length(fileList)
    if strcmp(fileList{i}, 'Protocol.mat')
        Prot = load(fullfile(WD,'Protocol.mat'));
        SetAppData(Prot);
    elseif strcmp(fileList{i}, 'FitOpt.mat')        
        FitOpt = load(fullfile(WD,'FitOpt.mat'));
        SetAppData(FitOpt);
    elseif strcmp(fileList{i}(1:end-4), 'MTdata') 
        FullFile = fullfile(WD,fileList{i});
        MTdataLoad(FullFile, handles)
    elseif strcmp(fileList{i}(1:end-4), 'Mask') 
        FullFile = fullfile(WD,fileList{i});
        MaskLoad(FullFile, handles)
    elseif strcmp(fileList{i}(1:end-4), 'R1map') 
        FullFile = fullfile(WD,fileList{i});
        R1mapLoad(FullFile, handles)
    elseif strcmp(fileList{i}(1:end-4), 'B1map') 
        FullFile = fullfile(WD,fileList{i});
        B1mapLoad(FullFile, handles)
    elseif strcmp(fileList{i}(1:end-4), 'B0map') 
        FullFile = fullfile(WD,fileList{i});
        B0mapLoad(FullFile, handles)
    end
end
OpenOptionsPanel_Callback(hObject, eventdata, handles);

function WDBox_Callback(hObject, eventdata, handles)

% MTDATA
function MTdataLoad_Callback(hObject, eventdata, handles)
WD = get(handles.WDBox,'String');
[FileName,PathName] = uigetfile({'*.nii';'*.mat'},'Select MTdata file',WD);
if PathName == 0, return; end
FullFile = fullfile(PathName,FileName);
MTdataLoad(FullFile, handles);

function MTdataLoad(FullFile, handles)
MTdata = [];
set(handles.MTdataFileBox,'String',FullFile);
[~,~,ext] = fileparts(FullFile);
if strcmp(ext,'.mat');
    load(FullFile);
elseif strcmp(ext,'.nii') || strcmp(ext,'.gz');
    nii = load_nii(FullFile);
    MTdata = nii.img;
end
SetAppData(MTdata);

% -- MTdataLoad_MTSAT() 
% PBeliveau modification, temporarily to load tiff files.
function MTdataLoad_MTSAT(FullFile, handles)
MTdata = [];
set(handles.MT_FileBox,'String',FullFile);
if isempty(FullFile) 
    return; 
end
MTdata = LoadImage(FullFile);
SetAppData(MTdata);

function MaskLoad_MTSAT(FullFile, handles)
Mask = [];
set(handles.Mask_FileBox,'String',FullFile);
if isempty(FullFile) 
    return; 
end
Mask = LoadImage(FullFile);
SetAppData(Mask);

function PDdataLoad_MTSAT(FullFile, handles)
PDdata = [];
set(handles.PD_FileBox,'String',FullFile);
if isempty(FullFile) 
    return; 
end
PDdata = LoadImage(FullFile);
SetAppData(PDdata);

function T1dataLoad_MTSAT(FullFile, handles)
T1data = [];
set(handles.T1_FileBox,'String',FullFile);
if isempty(FullFile) 
    return; 
end
T1data = LoadImage(FullFile);
SetAppData(T1data);



function MTdataFileBox_Callback(hObject, eventdata, handles)
% FullFile = get(handles.MTdataFileBox,'String');
% MTdataLoad(FullFile, handles);

% MASKDATA
function MaskLoad_Callback(hObject, eventdata, handles)
WD = get(handles.WDBox,'String');
[FileName,PathName,Index] = uigetfile({'*.nii';'*.mat'},'Select Mask file',WD);
if PathName == 0, return; end
FullFile = fullfile(PathName,FileName);
MaskLoad(FullFile, handles);

function MaskLoad(FullFile, handles)
Mask = [];
set(handles.MaskFileBox,'String',FullFile);
[pathstr,name,ext] = fileparts(FullFile) ;
if strcmp(ext,'.mat');
    load(FullFile);
elseif strcmp(ext,'.nii') || strcmp(ext,'.gz');
    nii = load_nii(FullFile);
    Mask = nii.img;
end
SetAppData(Mask);

function MaskFileBox_Callback(hObject, eventdata, handles)
% FullFile = get(handles.MaskFileBox,'String');
% MaskLoad(FullFile, handles);

% R1MAP DATA
function R1mapLoad_Callback(hObject, eventdata, handles)
WD = get(handles.WDBox,'String');
[FileName,PathName] = uigetfile({'*.nii';'*.mat'},'Select R1map file',WD);
if PathName == 0, return; end
FullFile = fullfile(PathName,FileName);
R1mapLoad(FullFile, handles);

function R1mapLoad(FullFile, handles)
R1map = [];
set(handles.R1mapFileBox,'String',FullFile);
[~,~,ext] = fileparts(FullFile) ;
if strcmp(ext,'.mat');
    load(FullFile);
elseif strcmp(ext,'.nii') || strcmp(ext,'.gz');
    nii = load_nii(FullFile);
    R1map = nii.img;
end
SetAppData(R1map);

function R1mapFileBox_Callback(hObject, eventdata, handles)
% FullFile = get(handles.R1mapFileBox,'String');
% R1mapLoad(FullFile, handles);

% B1 MAP
function B1mapLoad_Callback(hObject, eventdata, handles)
WD = get(handles.WDBox,'String');
[FileName,PathName] = uigetfile({'*.nii';'*.mat'},'Select B1map file',WD);
if PathName == 0, return; end
FullFile = fullfile(PathName,FileName);
B1mapLoad(FullFile, handles);

function B1mapLoad(FullFile, handles)
B1map = [];
set(handles.B1mapFileBox,'String',FullFile);
[~,~,ext] = fileparts(FullFile) ;
if strcmp(ext,'.mat');
    load(FullFile);
elseif strcmp(ext,'.nii') || strcmp(ext,'.gz');
    nii = load_nii(FullFile);
    B1map = nii.img;
end
SetAppData(B1map);

function B1mapFileBox_Callback(hObject, eventdata, handles)
% FullFile = get(handles.R1mapFileBox,'String');
% B1mapLoad(FullFile, handles);

% B0 MAP
function B0mapLoad_Callback(hObject, eventdata, handles)
WD = get(handles.WDBox,'String');
[FileName,PathName] = uigetfile({'*.nii';'*.mat'},'Select B0map file',WD);
if PathName == 0, return; end
FullFile = fullfile(PathName,FileName);
B0mapLoad(FullFile, handles);

function B0mapLoad(FullFile, handles)
B0map = [];
set(handles.B0mapFileBox,'String',FullFile);
[~,~,ext] = fileparts(FullFile) ;
if strcmp(ext,'.mat');
    load(FullFile);
elseif strcmp(ext,'.nii') || strcmp(ext,'.gz');
    nii = load_nii(FullFile);
    B0map = nii.img;
end
SetAppData(B0map);

function B0mapFileBox_Callback(hObject, eventdata, handles)
% FullFile = get(handles.B0mapFileBox,'String');
% B0mapLoad(FullFile, handles);

% VIEW MAPS
function DataView_Callback(hObject, eventdata, handles)
MTdataLoad(get(handles.MTdataFileBox,'String'), handles)
MTdata = GetAppData('MTdata');
if isempty(MTdata), errordlg('empty data'); return; end
n = ndims(MTdata);
Data.MTdata = mean(double(MTdata),n);
Data.fields = {'MTdata'};
handles.CurrentData = Data;
guidata(hObject,handles);
DrawPlot(handles);

function MaskView_Callback(hObject, eventdata, handles)
MaskLoad(get(handles.MaskFileBox,'String'), handles)
data = GetAppData('Mask');
if isempty(data), errordlg('empty data'); return; end
Data.Mask = double(data);
Data.fields = {'Mask'};
handles.CurrentData = Data;
guidata(hObject,handles);
DrawPlot(handles);

function R1mapView_Callback(hObject, eventdata, handles)
R1mapLoad(get(handles.R1mapFileBox,'String'), handles)
data = GetAppData('R1map');
if isempty(data), errordlg('empty data'); return; end
Data.R1map = double(data);
Data.fields = {'R1map'};
handles.CurrentData = Data;
guidata(hObject,handles);
DrawPlot(handles);

function B1mapView_Callback(hObject, eventdata, handles)
B1mapLoad(get(handles.B1mapFileBox,'String'), handles)
data = GetAppData('B1map');
if isempty(data), errordlg('empty data'); return; end
Data.B1map = double(data);
Data.fields = {'B1map'};
handles.CurrentData = Data;
guidata(hObject,handles);
DrawPlot(handles);

function B0mapView_Callback(hObject, eventdata, handles)
B0mapLoad(get(handles.B0mapFileBox,'String'), handles)
data = GetAppData('B0map');
if isempty(data), errordlg('empty data'); return; end
Data.B0map = double(data);
Data.fields = {'B0map'};
handles.CurrentData = Data;
guidata(hObject,handles);
DrawPlot(handles);

function StudyIDBox_Callback(hObject, eventdata, handles)



% ############################# FIT DATA ##################################
% FITDATA GO
function FitGO_Callback(hObject, eventdata, handles)
SetActive('FitData', handles);

% special exec for MTSAT option
Method = GetMethod(handles);
handles.method = fullfile(handles.root,Method);

if strcmp(Method, 'MTSAT')
    FitGo_MTSAT(hObject, eventdata, handles);
else
    FitGo_FitData(hObject, eventdata, handles);
end



% FitGo function for MTSAT
function FitGo_MTSAT(hObject, eventdata, handles)
%Set directory for fit results
WD = get(handles.WDBox,'String');
if isempty(WD)
    WD = pwd;
end
if (~exist(fullfile(WD,'MTSAT_Results'), 'file'))
    mkdir(WD,'MTSAT_Results');
end

MTdataLoad_MTSAT(get(handles.MT_FileBox,'String'), handles)
PDdataLoad_MTSAT(get(handles.PD_FileBox,'String'), handles)
T1dataLoad_MTSAT(get(handles.T1_FileBox,'String'), handles)

% Get data
[MTdata, Maskdata, PDdata, T1data] =  GetAppData('MTdata','Mask','PDdata','T1data');
[MTparams, PDparams, T1params] = GetAppData('MTparams', 'PDparams', 'T1params');

if ~isempty(MTdata) & ~isempty(PDdata) & ~isempty(T1data)
    data = struct;
    data.MTdata = double(MTdata);
    data.PDdata = double(PDdata);
    data.T1data = double(T1data);
    
    % optional 
    if ~isempty(Maskdata)
        data.Mask = double(Maskdata);
    end
    
    % execute MTSAT
    MTSATdata = MTSAT_exec(data, MTparams, PDparams, T1params);

    
% delimiting signal intensity range for display
Index=0;
Index = find(MTSATdata > 7);
MTSATdata(Index) = 7;

Index=0;
Index = find(MTSATdata < -3);
MTSATdata(Index) = -3;

% Display
Data.MTSATdata = double(MTSATdata);
Data.fields = {'MTSATdata'};
handles.CurrentData = Data;
guidata(hObject,handles);

setappdata(0,'MTSATresult',Data);

n = ndims(MTSATdata);
if n > 2
    Min = min(min(min(MTSATdata)));
    Max = max(max(max(MTSATdata)));
    ImSize = size(MTSATdata);
    set(handles.SliceNumberID, 'Value', 1);
    set(handles.SliceNumberID, 'Min', 1);
    set(handles.SliceNumberID, 'Max', ImSize(3));
    set(handles.SliceNumberID, 'Value', int32(ImSize(3)/2));
    set(handles.SliceNumberID, 'SliderStep', [1.0/ImSize(3), 2/ImSize(3)]);
 else
    Min = min(min(MTSATdata));
    Max = max(max(MTSATdata));
end

set(handles.MinValue, 'Min', Min);
set(handles.MinValue, 'Max', Max);
set(handles.MinValue, 'Value', Min+1);
set(handles.MaxValue, 'Min', Min);
set(handles.MaxValue, 'Max', Max);
set(handles.MaxValue, 'Value', Max-1);

guidata(hObject,handles);
DrawPlot(handles);

ax = gca;
MyColorMap = ax;
File = load('BrainColorMap.mat');
colormap(ax,File.cmap);

end





% Original FitGo function
function FitGo_FitData(hObject, eventdata, handles)
%Set directory for fit results
WD = get(handles.WDBox,'String');
if isempty(WD)
    WD = pwd;
end
if (~exist(fullfile(WD,'FitResults'), 'file'))
    mkdir(WD,'FitResults');
end

% Make sure we're using files that are actually in text boxes
MTdataLoad(get(handles.MTdataFileBox,'String'), handles)
MaskLoad(get(handles.MaskFileBox,'String'), handles)
B0mapLoad(get(handles.B0mapFileBox,'String'), handles)
B1mapLoad(get(handles.B1mapFileBox,'String'), handles)
R1mapLoad(get(handles.R1mapFileBox,'String'), handles)

% Get data
[MTdata, Mask, R1map, B1map, B0map] =  GetAppData('MTdata','Mask','R1map','B1map','B0map');
[Method, Prot, FitOpt] = GetAppData('Method','Prot','FitOpt');

% If SPGR with SledPike, check for Sf table
if (strcmp(Method,'SPGR') && (strcmp(FitOpt.model, 'SledPikeCW') || strcmp(FitOpt.model, 'SledPikeRP')))
    if (~isfield(Prot,'Sf') || isempty(Prot.Sf))
        errordlg('An Sf table needs to be computed for this protocol prior to fitting. Please use the protocol panel do do so.','Missing Sf table');
        return;
    end
end

% Build data structure
data   =  struct;
data.MTdata = double(MTdata);
data.Mask = double(Mask);
data.R1map = double(R1map);
data.B1map = double(B1map);
data.B0map = double(B0map);

% Do the fitting
FitResults = FitData(data,Prot,FitOpt,Method,1);

% Save info with results
FitResults.StudyID = get(handles.StudyIDBox,'String');
FitResults.WD = WD;
FitResults.Files.MTdata = get(handles.MTdataFileBox,'String');
FitResults.Files.Mask = get(handles.MaskFileBox,'String');
FitResults.Files.R1map = get(handles.R1mapFileBox,'String');
FitResults.Files.B1map = get(handles.B1mapFileBox,'String');
FitResults.Files.B0map = get(handles.B0mapFileBox,'String');
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
if ~exist(fullfile(WD,'FitResults')), mkdir(fullfile(WD,'FitResults')); end
save(fullfile(WD,'FitResults',filename),'-struct','FitResults');
set(handles.CurrentFitId,'String','FitResults.mat');

% Save nii maps
for i = 1:length(FitResults.fields)
    map = FitResults.fields{i};
    file = strcat(map,'.nii');
    [~,~,ext]=fileparts(FitResults.Files.MTdata);
    if strcmp(ext,'.mat')
        save_nii_v2(make_nii(FitResults.(map)),fullfile(WD,'FitResults',file),[],64);
    else
        save_nii_v2(FitResults.(map),fullfile(WD,'FitResults',file),FitResults.Files.MTdata,64);
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
FitOpt =  FitResults.FitOpt;
SetAppData(FitResults, Prot, FitOpt);

if (isfield(FitResults,'WD'))
    set(handles.WDBox,'String', FitResults.WD);
end
set(handles.StudyIDBox,'String', FitResults.StudyID);
if isfield(FitResults,'Files')
    set(handles.MTdataFileBox,'String', FitResults.Files.MTdata);
    set(handles.MaskFileBox,'String', FitResults.Files.Mask);
    set(handles.R1mapFileBox,'String', FitResults.Files.R1map);
    set(handles.B1mapFileBox,'String', FitResults.Files.B1map);
    set(handles.B0mapFileBox,'String', FitResults.Files.B0map);
    
    if exist(FitResults.Files.MTdata,'file')
        MTdataLoad(get(handles.MTdataFileBox,'String'), handles);
    end
end

SetActive('FitData', handles);
handles.CurrentData = FitResults;
guidata(hObject,handles);
DrawPlot(handles);

% Update Options Panel
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    OpenOptionsPanel_Callback(hObject, eventdata, handles)
end



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
        set(handles.SliceNumberID, 'Value', 1);
        set(handles.SliceNumberID, 'Min', 1);
        set(handles.SliceNumberID, 'Max', ImSize(3));
        set(handles.SliceNumberID, 'Value', int32(ImSize(3)/2));
        set(handles.SliceNumberID, 'SliderStep', [1.0/ImSize(3), 2/ImSize(3)]);
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
min = get(hObject, 'Value');
max = str2double(get(handles.MaxValue, 'String'));
set(handles.MinValue,'String',min);
caxis([min max]);
% RefreshColorMap(handles);

% MAX
function MaxValue_Callback(hObject, eventdata, handles)
min = str2double(get(handles.MinValue, 'String'));
max = str2double(get(handles.MaxValue, 'String'));
upper =  1.5 * max;
set(handles.MaxSlider, 'Value', max)
set(handles.MaxSlider, 'max',   upper);
caxis([min max]);
% RefreshColorMap(handles);

function MaxSlider_Callback(hObject, eventdata, handles)
min = str2double(get(handles.MinValue, 'String'));
max = get(hObject, 'Value');
set(handles.MaxValue,'String',max);
caxis([min max]);
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
[MTdata, Mask, R1map, B1map, B0map] =  GetAppData('MTdata','Mask','R1map','B1map','B0map');
[Method, Prot, FitOpt] = GetAppData('Method','Prot','FitOpt');

% Get selected voxel
S = size(MTdata);
if isempty(handles.dcm_obj) || isempty(getCursorInfo(handles.dcm_obj))
    disp('<strong>Select a voxel in the image using cursor</strong>')
else
    info_dcm = getCursorInfo(handles.dcm_obj);
    x = info_dcm.Position(1);
    y = 1+ S(2) - info_dcm.Position(2);
    z = str2double(get(handles.SliceValue,'String'));
    index = sub2ind(S,x,y,z);
    
    % Build data structure
    data   =  struct;
    if length(S) == 3
        data.MTdata = double(squeeze(MTdata(x,y,:)));
    elseif length(S) == 4
        data.MTdata = double(squeeze(MTdata(x,y,z,:)));
    end
    data.Mask = [];
    if ~isempty(R1map), data.R1map = double(R1map(index)); else data.R1map = []; end
    if ~isempty(B1map), data.B1map = double(B1map(index)); else data.B1map = []; end
    if ~isempty(B0map), data.B0map = double(B0map(index)); else data.B0map = []; end
    
    % Do the fitting
    Fit = FitData(data,Prot,FitOpt,Method,0);
    % Fit.F = FitResults.F(index);
    % Fit.kr = FitResults.kr(index);
    % Fit.kf = FitResults.kf(index);
    % Fit.R1f = FitResults.R1f(index);
    % Fit.R1r = FitResults.R1r(index);
    
    Sim.Opt.AddNoise = 0;
    % Create axe
    figure(68)
    set(68,'Name',['Fitting results of voxel [' num2str([x y z]) ']'],'NumberTitle','off');
    haxes = get(68,'children');
    if ~isempty(haxes)
        haxes = get(haxes(2),'children');
        set(haxes,'Color',[0.8 0.8 0.8]);
    end
    hold on;
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


% ############################ FUNCTIONS ##################################
function UpdateSlice(handles)
View =  get(handles.ViewPop,'Value');
switch View
    case 1
        x = 3;
    case 2
        x = 2;
    case 3
        x = 1;
end
dim = handles.FitDataDim;
if (dim==3)
    slice = handles.FitDataSlice(x);
    size = handles.FitDataSize(x);
    set(handles.SliceValue,  'String', slice);
    set(handles.SliceSlider, 'Min',    1);
    set(handles.SliceSlider, 'Max',    size);
    set(handles.SliceSlider, 'Value',  slice);
    Step = [1, 1] / size;
    set(handles.SliceSlider, 'SliderStep', Step);
else
    set(handles.SliceValue,  'String',1);
    set(handles.SliceSlider, 'Min',   0);
    set(handles.SliceSlider, 'Max',   1);
    set(handles.SliceSlider, 'Value', 1);
    set(handles.SliceSlider, 'SliderStep', [0 0]);
end

function UpdatePopUp(handles)
axes(handles.FitDataAxe);
Data   =  handles.CurrentData;
fields =  Data.fields;
set(handles.SourcePop, 'String', fields);
handles.FitDataSize = size(Data.(fields{1}));
handles.FitDataDim = ndims(Data.(fields{1}));
dim = handles.FitDataDim;
if (dim==3)
        set(handles.ViewPop,'String',{'Axial','Coronal','Sagittal'});
        handles.FitDataSlice = floor(handles.FitDataSize/2);
else
        set(handles.ViewPop,'String','Axial');
        handles.FitDataSlice = 1;
end
guidata(gcbf, handles);
%UpdateSlice(handles);

function GetPlotRange(handles)
Current = GetCurrent(handles);
values=Current(:); values(isinf(values))=[]; values(isnan(values))=[];

% special for MTSAT - keep negative values - do not take percentile of SI
%set(handles.MethodMenu, 'Value', ii);
Method = GetMethod(handles);

if strcmp(Method, 'MTSAT')
    Min = min(min(values));
    Max = max(max(values));
    
    set(handles.MinValue, 'Min', Min);
    set(handles.MinValue, 'Max', Max);
    set(handles.MinValue, 'String', Min);
    set(handles.MinValue, 'Value', Min);
    set(handles.MaxValue, 'Min', Min);
    set(handles.MaxValue, 'Max', Max);
    set(handles.MaxValue, 'String', Max);
    set(handles.MaxValue, 'Value', Max);
else   
    Min = prctile(values,5); % 5 percentile of the data to prevent extreme values
    Max = prctile(values,95);% 95 percentile of the data to prevent extreme values
    if (Min == Max)
        Max = Max + 1;
    end
    if (Min > Max)
        temp = Min;
        Min = Max;
        Max = temp;
    end

    if (Min < 0)
        set(handles.MinSlider, 'Min',    1.5*Min);
    else
        set(handles.MinSlider, 'Min',    0.5*Min);
    end

    if (Max < 0)
        set(handles.MaxSlider, 'Max',    0.5*Max);
    else
        set(handles.MaxSlider, 'Max',    1.5*Max);
    end
    set(handles.MinSlider, 'Max',    Max);
    set(handles.MaxSlider, 'Min',    Min);
    set(handles.MinValue,  'String', Min);
    set(handles.MaxValue,  'String', Max);
    set(handles.MinSlider, 'Value',  Min);
    set(handles.MaxSlider, 'Value',  Max);
end

guidata(gcbf, handles);


function DrawPlot(handles)
set(handles.SourcePop, 'Value',  1);
set(handles.ViewPop,   'Value',  1);
UpdatePopUp(handles);
GetPlotRange(handles);
Current = GetCurrent(handles);
% imagesc(flipdim(Current',1));
imagesc(rot90(Current));
axis equal off;
RefreshColorMap(handles)

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

function RefreshColorMap(handles)
val  = get(handles.ColorMapStyle, 'Value');
maps = get(handles.ColorMapStyle, 'String'); 
colormap(maps{val});
colorbar('location', 'South', 'Color', 'white');
min = str2double(get(handles.MinValue, 'String'));
max = str2double(get(handles.MaxValue, 'String'));
caxis([min max]);

function Current = GetCurrent(handles)
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
View = get(handles.ViewPop,'Value');
Slice = str2double(get(handles.SliceValue,'String'));
Data = handles.CurrentData;
data = Data.(Source);
switch View
    case 1;  Current = squeeze(data(:,:,Slice));
    case 2;  Current = squeeze(data(:,Slice,:));
    case 3;  Current = squeeze(data(Slice,:,:));
end
    

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
function StudyIDBox_CreateFcn(hObject, eventdata, handles)
function MTdataFileBox_CreateFcn(hObject, eventdata, handles)
function MaskFileBox_CreateFcn(hObject, eventdata, handles)
function R1mapFileBox_CreateFcn(hObject, eventdata, handles)
function B1mapFileBox_CreateFcn(hObject, eventdata, handles)
function B0mapFileBox_CreateFcn(hObject, eventdata, handles)
function WDBox_CreateFcn(hObject, eventdata, handles)


% --- Executes on button press in WorkDir_Browse.
function WorkDir_Browse_Callback(hObject, eventdata, handles)
WD = uigetdir;
if WD == 0, return; end
set(handles.WorkDir_FileBox,'String',WD);

% Clear previous file paths
set(handles.Mask_FileBox,'String', '');
set(handles.MT_FileBox,'String', '');
set(handles.PD_FileBox,'String', '');
set(handles.T1_FileBox,'String', '');

%Check for files and set fields automatically
dirData = dir(WD);
dirIndex = [dirData.isdir];
fileList = {dirData(~dirIndex).name}';

for i = 1:length(fileList)
    if strfind(fileList{i}, 'Protocol.mat')
        Prot = load(fullfile(WD,'Protocol.mat'));
        SetAppData(Prot);
    elseif strfind(fileList{i}(1:end-4), 'MTdata') 
        FullFile = fullfile(WD,fileList{i});
        MTdataLoad_MTSAT(FullFile, handles);
    elseif strfind(fileList{i}(1:end-4), 'Mask') 
        FullFile = fullfile(WD,fileList{i});
        MaskLoad_MTSAT(FullFile, handles)
    elseif strfind(fileList{i}(1:end-4), 'PDdata') 
        FullFile = fullfile(WD,fileList{i});
        PDdataLoad_MTSAT(FullFile, handles)
    elseif strfind(fileList{i}(1:end-4), 'T1data') 
        FullFile = fullfile(WD,fileList{i});
        T1dataLoad_MTSAT(FullFile, handles)
    end
end
% MT = getappdata(0,'MTdata');
% n = ndims(MT);
% % if n > 2 
%     MT = getappdata(0,'MTdata'); SizeMT = size(MT);
%     PD = getappdata(0,'PDdata'); SizePD = size(PD);
%     T1 = getappdata(0,'T1data'); SizeT1 = size(T1);
%     if ~(SizeMT(3) == SizePD(3)) || ~(SizeMT(3) == SizeT1(3))
%         errordlg('volumes of different sizes loaded'); return;
%     end
%     
%     % reset slice number slider for a volume
%     set(handles.SliceNumberID, 'Value', 1);
%     set(handles.SliceNumberID, 'Min', 1);
%     set(handles.SliceNumberID, 'Max', SizeMT(3));
%     set(handles.SliceNumberID, 'Value', int32(SizeMT(3)/2));
%     set(handles.SliceNumberID, 'SliderStep', [1.0/SizeMT(3), 2.0/SizeMT(3)]);
%     set(handles.SliceNumberID, 'Visible', 'on');
% else
%     % remove slice number slider for an image
%     set(handles.SliceNumberID, 'Value', 1);
%     set(handles.SliceNumberID, 'Min', 1);
%     set(handles.SliceNumberID, 'Max', 1);
%     set(handles.SliceNumberID, 'Visible', 'off');
    
% end


% --- Executes on button press in Mask_Browse.
function Mask_Browse_Callback(hObject, eventdata, handles)
WD = get(handles.WorkDirFileBox,'String');
[FileName,PathName] = uigetfile({'*.nii;*.mat;*.dcm;*.gz;*.raw;*.tif;*.tiff'},'Select MT image file',WD);
if PathName == 0, return; end
FullFile = fullfile(PathName,FileName);
MTdataLoad_MTSAT(FullFile, handles);
% define internal variables
MTdata = getappdata(0,'MTdata');
Data.MTdata = double(MTdata);
Data.fields = {'MTdata'};
handles.CurrentData = Data;
setappdata(0,'MTdata',Data)

% display image
Min = min(min(min(MTdata)));
Max = max(max(max(MTdata)));
set(handles.MinValue, 'Min', Min);
set(handles.MinValue, 'Max', Max);
set(handles.MinValue, 'Value', Min+1);
set(handles.MaxValue, 'Min', Min);
set(handles.MaxValue, 'Max', Max);
set(handles.MaxValue, 'Value', Max-1);

% if 3D, select slice number, or else use image
DrawPlot(handles);    

ax = gca;  
MyColorMap = ax;
File = load('BrainColorMap.mat');
colormap(ax,File.cmap);
guidata(hObject,handles);



% --- Executes on button press in MT_Browse.
function MT_Browse_Callback(hObject, eventdata, handles)
WD = get(handles.WorkDir_FileBox,'String');
[FileName,PathName] = uigetfile({'*.nii;*.mat;*.dcm;*.gz;*.raw;*.tif;*.tiff'},'Select MT image file',WD);
if PathName == 0, return; end
FullFile = fullfile(PathName,FileName);
MTdataLoad_MTSAT(FullFile, handles);

% define internal variables
MTdata = getappdata(0,'MTdata');
Data.MTdata = double(MTdata);
Data.fields = {'MTdata'};
handles.CurrentData = Data;
setappdata(0,'MTdata',Data)

% --- Executes on button press in PD_Browse.
function PD_Browse_Callback(hObject, eventdata, handles)
WD = get(handles.WorkDir_FileBox,'String');
[FileName,PathName] = uigetfile({'*.nii;*.mat;*.dcm;*.gz;*.raw;*.tif;*.tiff'},'Select MT image file',WD);
if PathName == 0, return; end
FullFile = fullfile(PathName,FileName);
PDdataLoad_MTSAT(FullFile, handles);

% define internal variables
PDdata = getappdata(0,'PDdata');
Data.PDdata = double(PDdata);
Data.fields = {'PDdata'};
handles.CurrentData = Data;
setappdata(0,'PDdata',Data)


% --- Executes on button press in T1_Browse.
function T1_Browse_Callback(hObject, eventdata, handles)
WD = get(handles.WorkDir_FileBox,'String');
[FileName,PathName] = uigetfile({'*.nii;*.mat;*.dcm;*.gz;*.raw;*.tif;*.tiff'},'Select MT image file',WD);
if PathName == 0, return; end
FullFile = fullfile(PathName,FileName);
T1dataLoad_MTSAT(FullFile, handles);

% define internal variables
T1data = getappdata(0,'T1data');
Data.T1data = double(T1data);
Data.fields = {'T1data'};
handles.CurrentData = Data;
setappdata(0,'T1data',Data)


function WorkDir_FileBox_Callback(hObject, eventdata, handles)
% hObject    handle to WorkDir_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WorkDir_FileBox as text
%        str2double(get(hObject,'String')) returns contents of WorkDir_FileBox as a double


% --- Executes during object creation, after setting all properties.
function WorkDir_FileBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WorkDir_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Mask_FileBox_Callback(hObject, eventdata, handles)
% hObject    handle to Mask_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Mask_FileBox as text
%        str2double(get(hObject,'String')) returns contents of Mask_FileBox as a double


% --- Executes during object creation, after setting all properties.
function Mask_FileBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Mask_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MT_FileBox_Callback(hObject, eventdata, handles)
% hObject    handle to MT_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MT_FileBox as text
%        str2double(get(hObject,'String')) returns contents of MT_FileBox as a double


% --- Executes during object creation, after setting all properties.
function MT_FileBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MT_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function PD_FileBox_Callback(hObject, eventdata, handles)
% hObject    handle to PD_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PD_FileBox as text
%        str2double(get(hObject,'String')) returns contents of PD_FileBox as a double


% --- Executes during object creation, after setting all properties.
function PD_FileBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PD_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function T1_FileBox_Callback(hObject, eventdata, handles)
% hObject    handle to T1_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of T1_FileBox as text
%        str2double(get(hObject,'String')) returns contents of T1_FileBox as a double


% --- Executes during object creation, after setting all properties.
function T1_FileBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to T1_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit35_Callback(hObject, eventdata, handles)
% hObject    handle to edit35 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit35 as text
%        str2double(get(hObject,'String')) returns contents of edit35 as a double


% --- Executes during object creation, after setting all properties.
function edit35_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit35 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in T1_View.
function T1_View_Callback(hObject, eventdata, handles)
T1dataLoad_MTSAT(get(handles.T1_FileBox,'String'), handles);
T1data = GetAppData('T1data');
if isempty(T1data), errordlg('empty data'); return; end
n = ndims(T1data);
T1data = imrotate(T1data,90);
Data.T1data = double(T1data);
Data.fields = {'T1data'};
handles.CurrentData = Data;

% adjust signal intensity range
if n > 2 
    Min = min(min(min(T1data)));
    Max = max(max(max(T1data)));    
    ImSize = size(T1data);
    set(handles.SliceNumberID, 'Value', 1);
    set(handles.SliceNumberID, 'Min', 1);
    set(handles.SliceNumberID, 'Max', ImSize(3));
    set(handles.SliceNumberID, 'Value', int32(ImSize(3)/2));
    set(handles.SliceNumberID, 'SliderStep', [1.0/ImSize(3), 2/ImSize(3)]);
 else
    Min = min(min(T1data));
    Max = max(max(T1data));
end

set(handles.MinValue, 'Min', Min);
set(handles.MinValue, 'Max', Max);
set(handles.MinValue, 'Value', Min+1);
set(handles.MaxValue, 'Min', Min);
set(handles.MaxValue, 'Max', Max);
set(handles.MaxValue, 'Value', Max-1);
guidata(hObject, handles);
DrawPlot(handles);

% --- Executes on button press in PD_View.
function PD_View_Callback(hObject, eventdata, handles)
PDdataLoad_MTSAT(get(handles.PD_FileBox,'String'), handles);
PDdata = GetAppData('PDdata');
if isempty(PDdata), errordlg('empty data'); return; end
n = ndims(PDdata);
PDdata = imrotate(PDdata,90);
Data.PDdata = double(PDdata);
Data.fields = {'PDdata'};
handles.CurrentData = Data;

% adjust signal intensity range
if n > 2 
    Min = min(min(min(PDdata)));
    Max = max(max(max(PDdata)));    
    ImSize = size(PDdata);
    set(handles.SliceNumberID, 'Value', 1);
    set(handles.SliceNumberID, 'Min', 1);
    set(handles.SliceNumberID, 'Max', ImSize(3));
    set(handles.SliceNumberID, 'Value', int32(ImSize(3)/2));
    set(handles.SliceNumberID, 'SliderStep', [1.0/ImSize(3), 2/ImSize(3)]);
 else
    Min = min(min(PDdata));
    Max = max(max(PDdata));
end

set(handles.MinValue, 'Min', Min);
set(handles.MinValue, 'Max', Max);
set(handles.MinValue, 'Value', Min+1);
set(handles.MaxValue, 'Min', Min);
set(handles.MaxValue, 'Max', Max);
set(handles.MaxValue, 'Value', Max-1);
guidata(hObject, handles);
DrawPlot(handles);



% --- Executes on button press in MT_View.
function MT_View_Callback(hObject, eventdata, handles)
MTdataLoad_MTSAT(get(handles.MT_FileBox,'String'), handles);
MTdata = GetAppData('MTdata');
if isempty(MTdata), errordlg('empty data'); return; end
n = ndims(MTdata);
MTdata = imrotate(MTdata,90);
Data.MTdata = double(MTdata);
Data.fields = {'MTdata'};
handles.CurrentData = Data;

% adjust signal intensity range
if n > 2 
    Min = min(min(min(MTdata)));
    Max = max(max(max(MTdata)));    
    ImSize = size(MTdata);
    set(handles.SliceNumberID, 'Value', 1);
    set(handles.SliceNumberID, 'Min', 1);
    set(handles.SliceNumberID, 'Max', ImSize(3));
    set(handles.SliceNumberID, 'Value', int32(ImSize(3)/2));
    set(handles.SliceNumberID, 'SliderStep', [1.0/ImSize(3), 2/ImSize(3)]);
 else
    Min = min(min(MTdata));
    Max = max(max(MTdata));
end

set(handles.MinValue, 'Min', Min);
set(handles.MinValue, 'Max', Max);
set(handles.MinValue, 'Value', Min+1);
set(handles.MaxValue, 'Min', Min);
set(handles.MaxValue, 'Max', Max);
set(handles.MaxValue, 'Value', Max-1);
guidata(hObject, handles);
DrawPlot(handles);

% --- Executes on button press in Mask_View.
function Mask_View_Callback(hObject, eventdata, handles)
% hObject    handle to Mask_View (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes when uibuttongroup1 is resized.
function uibuttongroup1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to uibuttongroup1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu20.
function popupmenu20_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu20 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu20


% --- Executes during object creation, after setting all properties.
function popupmenu20_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function SliceNumberID_Callback(hObject, eventdata, handles)
% hObject    handle to SliceNumberID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function SliceNumberID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SliceNumberID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function SliceNumber_FileBox_Callback(hObject, eventdata, handles)
% hObject    handle to SliceNumber_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SliceNumber_FileBox as text
%        str2double(get(hObject,'String')) returns contents of SliceNumber_FileBox as a double


% --- Executes during object creation, after setting all properties.
function SliceNumber_FileBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SliceNumber_FileBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton173.
function pushbutton173_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton173 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton174.
function pushbutton174_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton174 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton175.
function pushbutton175_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton175 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton170.
function pushbutton170_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton170 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton171.
function pushbutton171_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton171 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton172.
function pushbutton172_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton172 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function slider4_Callback(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider5_Callback(hObject, eventdata, handles)
% hObject    handle to slider5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton169.
function pushbutton169_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton169 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in popupmenu21.
function popupmenu21_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu21 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu21


% --- Executes during object creation, after setting all properties.
function popupmenu21_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in MTSATBtn.
function MTSATBtn_Callback(hObject, eventdata, handles)
% hObject    handle to MTSATBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
