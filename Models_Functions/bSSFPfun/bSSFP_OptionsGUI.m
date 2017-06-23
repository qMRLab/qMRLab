function varargout = bSSFP_OptionsGUI(varargin)
% BSSFP_OPTIONSGUI MATLAB code for bSSFP_OptionsGUI.fig
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
                   'gui_OpeningFcn', @bSSFP_OptionsGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @bSSFP_OptionsGUI_OutputFcn, ...
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


% --- Executes just before bSSFP_OptionsGUI is made visible.
function bSSFP_OptionsGUI_OpeningFcn(hObject, eventdata, handles, varargin)
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
    PathName = fullfile('bSSFP','Parameters');
    LoadDefaultOptions(PathName);
end

Sim    =  getappdata(0, 'Sim');
Prot   =  getappdata(0, 'Prot');
FitOpt =  getappdata(0, 'FitOpt');

set(handles.SimFileName, 'String', Sim.FileName);
set(handles.ProtFileName,     'String', Prot.FileName);
set(handles.FitOptFileName,   'String', FitOpt.FileName);

SetSim(Sim,handles);
SetProt(Prot,handles);
SetFitOpt(FitOpt,handles);

setappdata(gcf, 'oldSim',  Sim);
setappdata(gcf, 'oldProt',      Prot);
setappdata(gcf, 'oldFitOpt',    FitOpt);


function varargout = bSSFP_OptionsGUI_OutputFcn(hObject, eventdata, handles) 
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

% GetSim Get Sim
function Sim = GetSim(handles)
data = get(handles.ParamTable,'Data');
Param.F = data(1);      Param.kf = data(2);     Param.kr = data(3);    
Param.R1f = data(4);    Param.R1r = data(5);    Param.T2f = data(6);
Param.T2r = data(7);    Param.M0f = data(8);    Param.G = data(9);
Param.T1f = 1/(Param.R1f);      Param.T1r = 1/(Param.R1r);      
Param.R2f = 1/(Param.T2f);      Param.R2r = 1/(Param.T2r);     
Param.M0r = Param.F*Param.M0f;
LineShapes = cellstr(get(handles.LineShapePopUp,'String'));
Param.lineshape = LineShapes{get(handles.LineShapePopUp,'Value')};

Sim.Opt.AddNoise = get(handles.AddNoiseBox,'Value');
Sim.Opt.SNR = str2double(get(handles.SNR,'String'));
Sim.Opt.SScheck = get(handles.SSCheckBox,'Value');
Sim.Opt.SStol = str2double(get(handles.SStolValue,'String'));
Sim.Opt.Reset = get(handles.ResetBox,'Value');

Sim.Param = Param;
Sim.FileName = get(handles.SimFileName, 'String');
setappdata(0,'Sim',Sim);

% SetSim Set Sim
function SetSim(Sim,handles)
Param = Sim.Param;

data = [Param.F;   Param.kf;  Param.kr; Param.R1f; Param.R1r; ...
        Param.T2f; Param.T2r; Param.M0f; Param.G];
set(handles.ParamTable, 'Data', data);
switch Param.lineshape
    case 'Gaussian'
        ii = 1;
    case 'Lorentzian'
        ii = 2;
    case 'SuperLorentzian'
        ii = 3;
end
set(handles.LineShapePopUp, 'Value', ii);

set(handles.AddNoiseBox,'Value', Sim.Opt.AddNoise);
set(handles.SNR,'String', Sim.Opt.SNR);
set(handles.SSCheckBox, 'Value', Sim.Opt.SScheck);
set(handles.SStolValue, 'String', Sim.Opt.SStol);
set(handles.ResetBox, 'Value', Sim.Opt.Reset);

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


% #############################  SIM OPTIONS ##############################
% Sim.OptEditPanel.
function SimOptEditPanel_SelectionChangeFcn(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

% AddNoiseBox
function AddNoiseBox_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

% SNR
function SNR_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function SNR_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% STEADY STATE CHECK
function SSCheckBox_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function SStolValue_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);

function SStolValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% RESET M0
function ResetBox_Callback(hObject, eventdata, handles)
set(handles.SimFileName,'String','unsaved');
GetSim(handles);





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
FitOpt.G = str2double(get(handles.FitGBox,'String'));
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
set(handles.FitGBox, 'String', FitOpt.G);
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

% R1mapBox
function R1mapBox_Callback(hObject, eventdata, handles)
if (get(hObject, 'Value'))
    data = get(handles.FitOptTable,'Data');
    data(3,2) =  num2cell(true);
    set(handles.FitOptTable,'Data', data)
end
set(handles.FitOptFileName,'String','unsaved');
GetFitOpt(handles);

% G(0)
function FitGBox_Callback(hObject, eventdata, handles)
set(handles.FitOptFileName,'String','unsaved');
GetFitOpt(handles);

function FitGBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% #########################################################################
%                           PROTOCOL PANEL
% #########################################################################

% SAVE
function ProtSave_Callback(hObject, eventdata, handles)
Prot = GetProt(handles);
[FileName,PathName] = uiputfile(fullfile(handles.root,'Parameters','NewProtocol.mat'));
if PathName == 0, return; end
Prot.FileType = 'Protocol';
Prot.Method = 'bSSFP';
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
Prot.VaryAlpha = eval(get(handles.VaryAlphaBox,'String'));
Prot.VaryTrf = eval(get(handles.VaryTrfBox,'String'));
Prot.FixAlpha = str2double(get(handles.FixAlphaBox,'String'));
Prot.FixTrf = str2double(get(handles.FixTrfBox,'String'));
data = get(handles.SeqTable, 'Data');
Prot.alpha = data(:,1);
Prot.Trf = data(:,2);

Prot.FixTR = get(handles.FixTRRadio,'Value');
Prot.Td = str2double(get(handles.FixTdValue,'String'));
Prot.TR = str2double(get(handles.FixTRValue,'String'));
if (isnan(Prot.TR))
    Prot.TR = [];
end
if (isnan(Prot.Td))
    Prot.Td = [];
end
Prot.prepulse = get(handles.PrepulseBox,'Value');
Prot.Npulse = str2double(get(handles.NpulseValue,'String'));
content = cellstr(get(handles.PulseShapePopUp,'String'));
Prot.Pulse.shape = content{get(handles.PulseShapePopUp,'Value')};

Prot.FileName = get(handles.ProtFileName, 'String');
setappdata(0,'Prot',Prot);

% SETPROT Set Protocol
function SetProt(Prot,handles)
set(handles.VaryAlphaBox, 'String', mat2str(Prot.VaryAlpha'));
set(handles.VaryTrfBox, 'String', mat2str(Prot.VaryTrf'));
set(handles.FixAlphaBox, 'String', Prot.FixAlpha);
set(handles.FixTrfBox, 'String', Prot.FixTrf);
set(handles.SeqTable, 'Data', [Prot.alpha, Prot.Trf]);

set(handles.FixTRRadio, 'Value',  Prot.FixTR);
set(handles.FixTdRadio, 'Value', ~Prot.FixTR);
set(handles.FixTRValue, 'String', Prot.TR);
set(handles.FixTdValue, 'String', Prot.Td);
set(handles.PrepulseBox,'Value',  Prot.prepulse);
set(handles.NpulseValue,'String', Prot.Npulse);
switch Prot.Pulse.shape
    case 'hard';      ii = 1;
    case 'gaussian';  ii = 2;
    case 'gausshann'; ii = 3;
    case 'sinc';      ii = 4;
    case 'sinchann';  ii = 5;
    case 'sincgauss'; ii = 6;
    case 'fermi';     ii = 7;
end
set(handles.PulseShapePopUp,'Value',ii);

set(handles.ProtFileName, 'String', Prot.FileName);
setappdata(0,'Prot',Prot);


% ############################# SEQUENCE ##################################
% VARY ALPHA
function VaryAlphaBox_Callback(hObject, eventdata, handles)

function VaryAlphaBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function FixTrfBox_Callback(hObject, eventdata, handles)

function FixTrfBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% VARY TRF
function VaryTrfBox_Callback(hObject, eventdata, handles)

function VaryTrfBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function FixAlphaBox_Callback(hObject, eventdata, handles)

function FixAlphaBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% GENERATE SEQUENCE
function GenSeq_Callback(hObject, eventdata, handles)
Prot = GetProt(handles);
VaryAlpha = get(handles.VaryAlphaBox,'String');
VaryTrf = get(handles.VaryTrfBox,'String');
FixAlpha = get(handles.FixAlphaBox,'String');
FixTrf = get(handles.FixTrfBox,'String');
[Prot.alpha,Prot.Trf] = bSSFP_GetSeq( eval(VaryAlpha), eval(FixTrf), eval(VaryTrf), eval(FixAlpha) );
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
dat = get(handles.SeqTable,'Data');
oldDat = dat;
if (numel(selected)==0)
    return;
else
    dat(selected(1)-1,:) = oldDat(selected(1),:);
    dat(selected(1),:) = oldDat(selected(1)-1,:);
end
set(handles.SeqTable,'Data',dat);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% MOVE POINT DOWN
function PointDown_Callback(hObject, eventdata, handles)
selected = handles.CellSelect;
dat = get(handles.SeqTable,'Data');
oldDat = dat;
if (numel(selected)==0)
    return;
else
    dat(selected(1)+1,:) = oldDat(selected(1),:);
    dat(selected(1),:) = oldDat(selected(1)+1,:);
end
set(handles.SeqTable,'Data',dat);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

% CELL SELECT
function SeqTable_CellSelectionCallback(hObject, eventdata, handles)
handles.CellSelect = eventdata.Indices;
guidata(hObject,handles);

% CELL EDIT
function SeqTable_CellEditCallback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);



% ######################## SEQUENCE OPTIONS ###############################
% FIX TR
function FixTRRadio_Callback(hObject, eventdata, handles)
set(handles.FixTdRadio,'Value',0);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function FixTRValue_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function FixTRValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% FIX TD
function FixTdRadio_Callback(hObject, eventdata, handles)
set(handles.FixTRRadio,'Value',0);
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function FixTdValue_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function FixTdValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% NPULSE
function NpulseValue_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function NpulseValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% PULSESHAPE
function PulseShapePopUp_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);

function PulseShapePopUp_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% PREPULSE
function PrepulseBox_Callback(hObject, eventdata, handles)
set(handles.ProtFileName,'String','unsaved');
GetProt(handles);
