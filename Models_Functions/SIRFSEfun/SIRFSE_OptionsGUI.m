function varargout = SIRFSE_OptionsGUI(varargin)
% SIRFSE_OPTIONSGUI MATLAB code for SIRFSE_OptionsGUI.fig
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------


% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SIRFSE_OptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SIRFSE_OptionsGUI_OutputFcn, ...
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
function SIRFSE_OptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
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
guidata(hObject, handles);

% LOAD DEFAULTS (if not called from app)
if (isempty(varargin))
    PathName = fullfile(handles.root,'Parameters');
    LoadDefaultOptions(PathName);
end

Sim    =  getappdata(0, 'Sim');
Prot   =  getappdata(0, 'Prot');
FitOpt =  getappdata(0, 'FitOpt');

set(handles.SimFileName,    'String',  Sim.FileName);
set(handles.ProtFileName,   'String',  Prot.FileName);
set(handles.FitOptFileName, 'String',  FitOpt.FileName);

SetSim(Sim,handles);
SetProt(Prot,handles);
SetFitOpt(FitOpt,handles);

setappdata(gcf, 'oldSim',    Sim);
setappdata(gcf, 'oldProt',   Prot);
setappdata(gcf, 'oldFitOpt', FitOpt);


function varargout = SIRFSE_OptionsGUI_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



% #########################################################################
%                           SIMULATION PANEL
% #########################################################################

% SAVE
function SimSave_Callback(hObject, eventdata, handles)
Sim = GetSim(handles);
[FileName,PathName] = uiputfile(fullfile(handles.root,'Parameters','NewSim.mat'));
if PathName == 0, return; end
Sim.FileType = 'Sim';
Sim.FileName = FileName;
save(fullfile(PathName,FileName),'-struct','Sim');
setappdata(gcf,'oldSim',Sim);
set(handles.SimFileName,'String',FileName);

% LOAD
function SimLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Parameters','*.mat'));
if PathName == 0, return; end
Sim = load(fullfile(PathName,FileName));
if (~any(strcmp('FileType',fieldnames(Sim))) || ~strcmp(Sim.FileType,'Sim') )
    errordlg('Invalid simulation parameters file');
    return;
end
SetSim(Sim,handles);
setappdata(gcf,'oldSim',Sim);
set(handles.SimFileName,'String',FileName);

% RESET
function SimReset_Callback(hObject, eventdata, handles)
Sim = getappdata(gcf,'oldSim');
SetSim(Sim,handles);
set(handles.SimFileName,'String',Sim.FileName);

% DEFAULT
function SimDefault_Callback(hObject, eventdata, handles)
FileName = 'DefaultSim.mat';
Sim = load(fullfile(handles.root,'Parameters',FileName));
SetSim(Sim,handles);
setappdata(gcf,'oldSim', Sim);
set(handles.SimFileName,'String',FileName);

% GETSim Get Sim
function Sim = GetSim(handles)
data = get(handles.ParamTable,'Data');
Param.F = data(1);      Param.kf = data(2);     Param.kr = data(3);    
Param.R1f = data(4);    Param.R1r = data(5);    Param.T2f = data(6);
Param.T2r = data(7);    Param.M0f = data(8);    Param.G = data(9);
Param.T1f = 1/(Param.R1f);      Param.T1r = 1/(Param.R1r);      
Param.R2f = 1/(Param.T2f);      Param.R2r = 1/(Param.T2r);     
Param.M0r = Param.F*Param.M0f;
LineShapes = cellstr(get(handles.LineShapePopUp,'String'));
Param.lineshape  =  LineShapes{get(handles.LineShapePopUp,'Value')};
Sim.Opt.method   =  get(get(handles.SimEditPanel,'SelectedObject'),'Tag');
Sim.Opt.AddNoise =  get(handles.AddNoiseBox,'Value');
Sim.Opt.SNR      =  str2double(get(handles.SNR,'String'));
Sim.Param = Param;
Sim.FileName = get(handles.SimFileName, 'String');
setappdata(0,'Sim',Sim);

% SETSim Set Sim
function SetSim(Sim,handles)
Param = Sim.Param;
data = [Param.F;   Param.kf;  Param.kr; Param.R1f; Param.R1r; ...
        Param.T2f; Param.T2r; Param.M0f; Param.G];
set(handles.ParamTable, 'Data', data);
switch Param.lineshape
    case 'Gaussian';        ii = 1;
    case 'Lorentzian';      ii = 2;
    case 'SuperLorentzian'; ii = 3;
end
set(handles.LineShapePopUp, 'Value', ii);
set(handles.SimEditPanel,'SelectedObject',eval(sprintf('handles.%s', Sim.Opt.method)));
set(handles.AddNoiseBox,'Value', Sim.Opt.AddNoise);
set(handles.SNR,'String', Sim.Opt.SNR);
set(handles.SimFileName, 'String', Sim.FileName);
setappdata(0,'Sim',Sim);


% ############################ PARAMETERS #################################
% ParamTable CellEdit
function ParamTable_CellEditCallback(hObject, eventdata, handles)
Sim = GetSim(handles);
if (eventdata.Indices(1) == 2)
    Sim.Param.kr = Sim.Param.kf / Sim.Param.F;
elseif (eventdata.Indices(1) == 3)
    Sim.Param.kf = Sim.Param.kr * Sim.Param.F;
end
set(handles.SimFileName,'String','unsaved');
Sim.FileName = 'unsaved';
SetSim(Sim, handles);

% LineShapePopUp
function LineShapePopUp_Callback(hObject, eventdata, handles)
Sim = GetSim(handles);
contents = cellstr(get(handles.LineShapePopUp,'String'));
Sim.Param.lineshape = contents{get(handles.LineShapePopUp,'Value')};
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

% ComputeG.
function ComputeG_Callback(hObject, eventdata, handles)
Sim = GetSim(handles);
Sim.Param.G = computeG(0, Sim.Param.T2r, Sim.Param.lineshape);
SetSim(Sim, handles);

function LineShapePopUp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% ########################## SIM OPTIONS ##################################
function SimEditPanel_SelectionChangeFcn(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function AddNoiseBox_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function SNR_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function SNR_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% #########################################################################
%                           FIT OPTIONS PANEL
% #########################################################################

% SAVE
function FitOptSave_Callback(hObject, eventdata, handles)
FitOpt = GetFitOpt(handles);
[FileName,PathName] = uiputfile(fullfile(handles.root,'Parameters','NewFitOpt.mat'));
if PathName == 0, return; end
FitOpt.FileType = 'FitOpt';
FitOpt.FileName = FileName;
save(fullfile(PathName,FileName),'-struct','FitOpt');
setappdata(gcf,'oldFitOpt',FitOpt);
set(handles.FitOptFileName,'String',FileName);

% LOAD
function FitOptLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Parameters','*.mat'));
if PathName == 0, return; end
FitOpt = load(fullfile(PathName,FileName));

if (~any(strcmp('FileType',fieldnames(FitOpt))) || ~strcmp(FitOpt.FileType,'FitOpt') )
    errordlg('Invalid fit options file');
    return;
end
SetFitOpt(FitOpt,handles);
setappdata(gcf,'oldFitOpt',FitOpt);
set(handles.FitOptFileName,'String',FileName);

% RESET
function FitOptReset_Callback(hObject, eventdata, handles)
FitOpt = getappdata(gcf,'oldFitOpt');
SetFitOpt(FitOpt,handles);
set(handles.FitOptFileName,'String',FitOpt.FileName);

% DEFAULT
function FitOptDefault_Callback(hObject, eventdata, handles)
FileName = 'DefaultFitOpt.mat';
FitOpt = load(fullfile(handles.root,'Parameters',FileName));
SetFitOpt(FitOpt,handles);
setappdata(gcf,'oldFitOpt',FitOpt);
set(handles.FitOptFileName,'String',FileName);

% GETFITOPT Get Fit Option from table
function FitOpt = GetFitOpt(handles)
data = get(handles.FitOptTable,'Data'); % Get options
FitOpt.names = data(:,1)';
FitOpt.fx = cell2mat(data(:,2)');
FitOpt.st = cell2mat(data(:,3)');
FitOpt.lb = cell2mat(data(:,4)');
FitOpt.ub = cell2mat(data(:,5)');
FitOpt.R1reqR1f = get(handles.R1reqR1f, 'Value');
FitOpt.R1map = get(handles.R1mapBox, 'Value');
FitOpt.FileName = get(handles.FitOptFileName, 'String');
setappdata(0,'FitOpt',FitOpt);

% SETFITOPT Set Fit Option table data
function SetFitOpt(FitOpt,handles)
handles.FitOpt = FitOpt;
data = [FitOpt.names', num2cell(logical(FitOpt.fx')), num2cell(FitOpt.st'),...
                        num2cell(FitOpt.lb'), num2cell(FitOpt.ub')];
set(handles.FitOptTable,'Data', data);
set(handles.R1reqR1f,  'Value', FitOpt.R1reqR1f);
set(handles.R1mapBox, 'Value', FitOpt.R1map);
setappdata(0,'FitOpt',FitOpt);

% FitOptTable CellEdit
function FitOptTable_CellEditCallback(hObject, eventdata, handles)
FitOpt = GetFitOpt(handles);
if (~FitOpt.fx(3))
    set(handles.R1mapBox,'Value',0);
    FitOpt.R1map = false;
end
if (~FitOpt.fx(4))
    set(handles.R1reqR1f,'Value',0);
    FitOpt.R1reqR1f = false;
end
set(handles.FitOptFileName,'String','unsaved');
SetFitOpt(FitOpt,handles);

% R1reqR1f
function R1reqR1f_Callback(hObject, eventdata, handles)
if (get(hObject, 'Value'))
    data = get(handles.FitOptTable,'Data');
    data(4,2) =  num2cell(true);
    set(handles.FitOptTable,'Data', data)
end
set(handles.FitOptFileName,'String','unsaved');
GetFitOpt(handles);

% ComputeSr
function ComputeSr_Callback(hObject, eventdata, handles)
Sim  = getappdata(0, 'Sim');
Prot = getappdata(0, 'Prot');
Sr = computeSr(Sim.Param, Prot);

FitOpt = GetFitOpt(handles);
FitOpt.st(6) = Sr;
SetFitOpt(FitOpt, handles);
set(handles.FitOptFileName, 'String', 'unsaved');

% R1mapBox
function R1mapBox_Callback(hObject, eventdata, handles)
if (get(hObject, 'Value'))
    data = get(handles.FitOptTable,'Data');
    data(3,2) =  num2cell(true);
    set(handles.FitOptTable,'Data', data)
end
set(handles.FitOptFileName,'String','unsaved');
GetFitOpt(handles);




% #########################################################################
%                           PROTOCOL PANEL
% #########################################################################

% SAVE
function ProtSave_Callback(hObject, eventdata, handles)
Prot = GetProt(handles);
[FileName,PathName] = uiputfile(fullfile(handles.root,'Parameters','NewProtocol.mat'));
if PathName == 0, return; end
Prot.FileType = 'Protocol';
Prot.Method = 'SIRFSE';
Prot.FileName = FileName;
save(fullfile(PathName,FileName),'-struct','Prot');
setappdata(gcf,'oldProt',Prot);
set(handles.ProtFileName,'String',FileName);

% LOAD
function ProtLoad_Callback(hObject, eventdata, handles)
[FileName,PathName] = uigetfile(fullfile(handles.root,'Parameters','*.mat'));
if PathName == 0, return; end
Prot = load(fullfile(PathName,FileName));
if (~any(strcmp('FileType',fieldnames(Prot))) || ~strcmp(Prot.FileType,'Protocol') )
    errordlg('Invalid protocol file');
    return;
end
SetProt(Prot,handles);
setappdata(gcf,'oldProt',Prot);
set(handles.ProtFileName,'String',FileName);

% RESET
function ProtReset_Callback(hObject, eventdata, handles)
Prot = getappdata(gcf,'oldProt');
SetProt(Prot,handles);
set(handles.ProtFileName,'String',Prot.FileName);

% DEFAULT
function ProtDefault_Callback(hObject, eventdata, handles)
FileName = 'DefaultProt.mat';
Prot = load(fullfile(handles.root,'Parameters',FileName));
SetProt(Prot,handles);
setappdata(gcf,'oldProt', Prot);
set(handles.ProtFileName,'String',FileName);

% GETPROT Get Protocol
function Prot = GetProt(handles)
Seq = get(handles.SeqTable, 'Data');
Prot.ti = Seq(:,1);
Prot.td = Seq(:,2);

% Inversion pulse
Prot.InvPulse.Trf = str2double(get(handles.InvPulseTrf,'String'));
content = cellstr(get(handles.PulseShapePopUp,'String'));
Prot.InvPulse.shape = content{get(handles.PulseShapePopUp,'Value')};
% FSE options
SeqOpt = get(handles.SeqOptTable,'Data');
Prot.FSE.Trf    = SeqOpt(1);
Prot.FSE.Tr     = SeqOpt(2);
Prot.FSE.Npulse = SeqOpt(3);

Prot.FileName = get(handles.ProtFileName,'String');
setappdata(0,'Prot',Prot);

% SETPROT Set Protocol
function SetProt(Prot,handles)
set(handles.SeqTable, 'Data', [Prot.ti, Prot.td]);
set(handles.InvPulseTrf,'String',Prot.InvPulse.Trf);
switch Prot.InvPulse.shape
    case 'hard';      ii = 1;
    case 'gaussian';  ii = 2;
    case 'gausshann'; ii = 3;
    case 'sinc';      ii = 4;
    case 'sinchann';  ii = 5;
    case 'sincgauss'; ii = 6;
    case 'fermi';     ii = 7;
end
set(handles.PulseShapePopUp,'Value',ii);
data = [Prot.FSE.Trf; Prot.FSE.Tr; Prot.FSE.Npulse];
set(handles.SeqOptTable,'Data',data);
set(handles.ProtFileName, 'String',Prot.FileName);
setappdata(0,'Prot',Prot);

% ############################## SEQUENCE #################################
% TI
function TiBox_Callback(hObject, eventdata, handles)

function TiBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% TD
function TdBox_Callback(hObject, eventdata, handles)

function TdBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% GENERATE SEQUENCE
function GenSeq_Callback(hObject, eventdata, handles)
Prot = GetProt(handles);
ti = get(handles.TiBox,'String');
td = get(handles.TdBox,'String');
[Prot.ti,Prot.td] = SIRFSE_GetSeq( eval(ti), eval(td) );
SetProt(Prot,handles);

% REMOVE POINT
function PointRem_Callback(hObject, eventdata, handles)
selected = handles.CellSelect;
data = get(handles.SeqTable,'Data');
nRows = size(data,1);
if (numel(selected)==0)
    data = data(1:nRows-1,:);
else
    data (selected(:,1), :) = [];
end
set(handles.SeqTable,'Data',data);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% ADD POINT
function PointAdd_Callback(hObject, eventdata, handles)
selected = handles.CellSelect;
oldDat = get(handles.SeqTable,'Data');
nRows = size(oldDat,1);
data = zeros(nRows+1,2);
if (numel(selected)==0)
    data(1:nRows,:) = oldDat;
else
    data(1:selected(1),:) = oldDat(1:selected(1),:);
    data(selected(1)+2:end,:) = oldDat(selected(1)+1:end,:);
end
set(handles.SeqTable,'Data',data);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% MOVE POINT UP
function PointUp_Callback(hObject, eventdata, handles)
selected = handles.CellSelect;
data = get(handles.SeqTable,'Data');
oldDat = data;
if (numel(selected)==0)
    return;
else
    data(selected(1)-1,:) = oldDat(selected(1),:);
    data(selected(1),:) = oldDat(selected(1)-1,:);
end
set(handles.SeqTable,'Data',data);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% MOVE POINT DOWN
function PointDown_Callback(hObject, eventdata, handles)
selected = handles.CellSelect;
data = get(handles.SeqTable,'Data');
oldDat = data;
if (numel(selected)==0)
    return;
else
    data(selected(1)+1,:) = oldDat(selected(1),:);
    data(selected(1),:) = oldDat(selected(1)+1,:);
end
set(handles.SeqTable,'Data',data);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% CELL SELECT
function SeqTable_CellSelectionCallback(hObject, eventdata, handles)
handles.CellSelect = eventdata.Indices;
guidata(hObject,handles);

% CELL EDIT SeqTable CellEdit
function SeqTable_CellEditCallback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% ######################## SEQUENCE OPTIONS ###############################
function SeqOptTable_CellEditCallback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function PulseShapePopUp_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function PulseShapePopUp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function InvPulseTrf_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function InvPulseTrf_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
