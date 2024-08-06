function varargout = qMRLab(varargin)
%         __  __ ____  _          _     
%    __ _|  \/  |  _ \| |    __ _| |__  
%   / _` | |\/| | |_) | |   / _` | '_ \ 
%  | (_| | |  | |  _ <| |__| (_| | |_) |
%   \__, |_|  |_|_| \_\_____\__,_|_.__/ 
%      |_|

% qmrlab MATLAB code for qMRLab.fig
% GUI to simulate/fit qMRI data

% ----------------------------------------------------------------------------------------------------
% See the list of contributors: https://github.com/qMRLab/qMRLab/graphs/contributors
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :

%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
% ----------------------------------------------------------------------------------------------------

if logical(exist('OCTAVE_VERSION', 'builtin')), warndlg('Graphical user interface not available on octave... use command lines instead'); return; end

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @qMRLab_OpeningFcn, ...
    'gui_OutputFcn',  @qMRLab_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    varargin{end+1}='wait';
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before qMRLab is made visible.
function qMRLab_OpeningFcn(hObject, eventdata, handles, varargin)
if max(strcmp(varargin,'wait')), wait=true; varargin(strcmp(varargin,'wait'))=[]; else wait=false; end
if ~isfield(handles,'opened') % qMRI already opened?
    warning('off','all');
    % Add qMRLab to path
    qMRLabDir = fileparts(which(mfilename()));
    addpath(genpath(qMRLabDir));
    
    % Do not let this break anything if things go wrong.
    try
        GUI_animation;
        cur_ver = qMRLabVer;
    catch
        cur_ver = qMRLabVer;
        fprintf('qMRLab version: v%d.%d.%d \n',cur_ver(1),cur_ver(2),cur_ver(3));
    end
    
    try
        [verStatus] = versionChecker;
    catch
        verStatus = [];
    end
    
    % Display version under qMRLab text
    set(handles.text_version_check, 'String',sprintf('v%d.%d.%d',cur_ver(1),cur_ver(2),cur_ver(3)));
    
    % Handle new version message
    % varstatus is empty unless there is a new release.
    if isempty(verStatus)
        set(handles.upgrade_message, 'Visible','off');
    else
        set(handles.upgrade_message, 'Visible','on');
        set(handles.upgrade_message, 'String',sprintf('Upgrade to v%d.%d.%d',verStatus(1),verStatus(2),verStatus(3)));
    end

    handles.opened = 1;
    % startup;
    qMRLabDir = fileparts(which(mfilename()));
    addpath(genpath(qMRLabDir));
    if isdeployed
        handles.Default = fullfile(qMRLabDir,'DefaultMethod.mat');
    else
        handles.Default = fullfile(qMRLabDir,'src','Common','Parameters','DefaultMethod.mat');
        if isempty(getenv('ISAZURE')) || ~str2double(getenv('ISAZURE')) 
            ISAZURE=false; 
        else
            ISAZURE=true; 
        end
        if ~ISAZURE
          if ~license('test', 'Optimization_Toolbox'), error('Optimization Toolbox is not installed on your system: most qMR models won''t fit. Please consider installing <a href="matlab:matlab.internal.language.introspective.showAddon(''OP'');">Optimization Toolbox</a> if you want to use qMRLab in MATLAB.'); end
          if ~license('test', 'Image_Toolbox'), warning('Image Toolbox is not installed: ROI Analysis tool not available in the GUI. Consider installing <a href="matlab:matlab.internal.language.introspective.showAddon(''IP'');">Image Processing Toolbox</a>'); end
        end    
    end
    handles.CurrentData = [];
    handles.dcm_obj = [];
    MethodList = {}; SetAppData(MethodList);
    guidata(hObject, handles);
        
    
    % SET WINDOW AND PANELS
    movegui(gcf,'center')
    CurrentPos = get(gcf, 'Position');
    NewPos     = CurrentPos;
    NewPos(1)  = CurrentPos(1) - 40;
    set(gcf, 'Position', NewPos);
    if ispc , set(findobj(handles.FitResultsPlotPanel,'Type','uicontrol'),'FontSize',7); end % everything is bigger on windows or linux
    
    % Create viewer
    handles.tool = imtool3D(0,[0.12 0 .88 1],handles.FitResultsPlotPanel);
    H = handles.tool.getHandles;
    set(H.Tools.ViewPlane,'Visible','off')
    set(H.Tools.maskStats,'Visible','off')
    
    % Fill Menu with models
    handles.ModelDir = [qMRLabDir filesep 'src/Models'];
    guidata(hObject, handles);
    addModelMenu(hObject, eventdata, handles);
    
    % Fill FileBrowser with buttons
    MethodList = getappdata(0, 'MethodList');
    MethodList = strrep(MethodList, '.m', '');
    flist = findall(0,'type','figure');
    for iMethod=1:length(MethodList)
        
        Modelfun = str2func(MethodList{iMethod});
        Model = Modelfun();
        close(setdiff(findall(0,'type','figure'),flist)); % close figures that might open when calling models
        % create file browser uicontrol with specific inputs
        FileBrowserList(iMethod) = MethodBrowser(handles.FitDataFileBrowserPanel,Model);
        FileBrowserList(iMethod).Visible('off');
        
    end
    
    
    SetAppData(FileBrowserList);
    if exist(handles.Default,'file')
        load(handles.Default);
    else
        Method = 'inversion_recovery';
    end
else
    Method = class(GetAppData('Model'));
end
% LOAD INPUT
if ~isempty(varargin)
    Model = varargin{1};
    SetAppData(Model);
    Method = class(Model);
    FileBrowserList = GetAppData('FileBrowserList');
    if length(varargin)>1
        data=varargin{2};
        for ff=fieldnames(data)'
            FileBrowserList(strcmp({FileBrowserList.MethodID},Method)).setFileName(ff{1}, data.(ff{1}))
        end
    end
end

% Set Menu to method
MethodList = getappdata(0, 'MethodList');
indice = find(strcmp(Method,MethodList));
set(handles.MethodSelection, 'Value', indice);


MethodMenu(hObject, eventdata, handles, Method);

% Wait if output
if wait
uiwait(hObject)
end



% View first file
if length(varargin)>1
    butobj = FileBrowserList(strcmp({FileBrowserList.MethodID},Method)).ItemsList(1);	
    butobj.ViewBtn_callback(butobj,[],[],handles)
end

set(handles.text_doc_model, 'String',['Visit ' Method ' documentation']);
warning('on','all');
    


% Outputs from this function are returned to the command line.
function varargout = qMRLab_OutputFcn(hObject, eventdata, handles)
if nargout
    varargout{1} = GetAppData('Model');
    AppData = getappdata(0);
    Fields = fieldnames(AppData);
    for k=1:length(Fields)
        rmappdata(0, Fields{k});
    end
end


% Executes when user attempts to close qMRLab.
function qMRLab_CloseRequestFcn(hObject, eventdata, handles)
if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT, us UIRESUME
    uiresume(hObject);
else
    AppData = getappdata(0);
    Fields = fieldnames(AppData);
    for k=1:length(Fields)
        rmappdata(0, Fields{k});
    end
end
% The GUI is no longer waiting, just close it
delete(hObject);
h = findobj('Tag','OptionsGUI');
delete(findobj('Tag','Simu'))
delete(h);
wh=findall(0,'tag','TMWWaitbar');
delete(wh);


% cd(handles.root);

function MethodSelection_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
MethodMenu(hObject,eventdata,handles,Method);
set(handles.text_doc_model, 'String',['Visit ' Method ' documentation']);



function addModelMenu(hObject, eventdata, handles)
% Display all the options in the popupmenu
[MethodList, pathmodels] = sct_tools_ls([handles.ModelDir filesep '*.m'],0,0,2,1);
pathmodels = cellfun(@(x) strrep(x,[handles.ModelDir filesep],''), pathmodels,'UniformOutput',false);
if isdeployed
    [MethodList, pathmodels] = qMRLab_static_Models;
end
SetAppData(MethodList)
maxlength = max(cellfun(@length,MethodList))+4;
maxlengthpath = max(cellfun(@length,pathmodels))+2;
for iM=1:length(MethodList), MethodListfull{iM} = sprintf(['%-' num2str(maxlength) 's%-' num2str(maxlengthpath) 's'],MethodList{iM},['(' strrep(pathmodels{iM},[handles.ModelDir filesep],'') ')']); end
set(handles.MethodSelection,'String',MethodListfull);
set(handles.MethodSelection,'FontName','FixedWidth')
set(handles.MethodSelection,'FontWeight','bold')
set(handles.MethodSelection,'FontUnits','normalized')
set(handles.MethodSelection,'FontSize',.5)


% ###########################################################################################
%                                 COMMON FUNCTIONS
% ###########################################################################################

% METHODSELECTION
function MethodMenu(hObject, eventdata, handles, Method)

SetAppData(Method)

% Start by updating the Model object
if isappdata(0,'Model') && strcmp(class(getappdata(0,'Model')),Method) % if same method, load the current class with parameters
    Model = getappdata(0,'Model');
else % otherwise create a new object of this method
    Modeltobesaved = getappdata(0,'Model');
    savedModel = getappdata(0,'savedModel');
    savedModel.(class(Modeltobesaved)) = Modeltobesaved;
    setappdata(0,'savedModel',savedModel);
    if isfield(savedModel,Method) && ~isempty(savedModel.(Method))
        Model = savedModel.(Method);
    else
        modelfun  = str2func(Method);
        Model = modelfun();
    end
end
SetAppData(Model)
% Create empty Data
Data = GetAppData('Data');
for id=1:length(Model.MRIinputs)
    if isempty(Data) || ~isfield(Data,Method) || ~isfield(Data.(Method),Model.MRIinputs{id})
        Data.(Method).(Model.MRIinputs{id})=[];
    end
end
SetAppData(Data);

% Now create Simulation panel
% find the Simulation functions of the selected Method
Methodfun = methods(Method);
Simfun = Methodfun(~cellfun(@isempty,strfind(Methodfun,'Sim_')));
% Update Options Panel
set(handles.SimPanel,'Visible','off') % hide the simulation panel for qMT methods
if isempty(Simfun)
    set(handles.SimPanel,'Visible','off') % hide the simulation panel
else
    set(handles.SimPanel,'Visible','on') % show the simulation panel
    delete(setdiff(findobj(handles.SimPanel),handles.SimPanel))
    
    N = length(Simfun); %
    Jh = min(0.14,.8/N);
    J=1:max(N,6); J=(J-1)/max(N,6)*0.85; J=1-J-Jh-.01;
    for i = 1:N
        if exist([Simfun{i} '_GUI'],'file')
            uicontrol('Style','pushbutton','String',strrep(strrep(Simfun{i},'Sim_',''),'_',' '),...
                'Parent',handles.SimPanel,'Units','normalized','Position',[.04 J(i) .92 Jh],...
                'HorizontalAlignment','center','FontWeight','bold','Callback',...
                @(x,y) SimfunGUI([Simfun{i} '_GUI']));
        end
    end
    
end


% Update Options Panel
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    delete(h);
end
OpenOptionsPanel_Callback(hObject, eventdata, handles)

% Show FileBrowser
FileBrowserList = GetAppData('FileBrowserList');
MethodNum = find(strcmp({FileBrowserList.MethodID},Method));
for i=1:length(FileBrowserList)
    FileBrowserList(i).Visible('off');
end

FileBrowserList(MethodNum).Visible('on');

scl_str = json2struct('ScalePanels.json');

for ii = 1:length(scl_str)

    if strcmp(Method,scl_str(ii).ModelName)
        
        attachScrollPanelTo(handles.(scl_str(ii).PanelName));
        set(handles.(scl_str(ii).PanelName),'Position',scl_str(ii).Position);

    else
        attachScrollPanelTo(handles.('FitDataFileBrowserPanel'));
        set(handles.FitDataFileBrowserPanel,'Position',[0.0117 0.7391 0.9749 0.2493]);
    end
       
        
end

% Scale the main panel by a super small factor and 
% bring it back to the original to get rid of 
% artificial duplication of the top portion of the data 
% panel that occurs upon switching to another model 
% after selecting mp2rage. 

% Caused by attachScrollToPanel. 

curpos = get(handles.qMRILab,'Position');
set(handles.qMRILab,'Position',curpos.*[1 1 1.0001 1.0001]);
set(handles.qMRILab,'Position',curpos);
        
% enable/disable viewdatafit
if ismethod(Model,'plotModel')
set(handles.ViewDataFit,'Enable','on')
set(handles.ViewROIFit,'Enable','on')
set(handles.ViewDataFit,'TooltipString','View fit in a particular voxel')
set(handles.ViewROIFit,'TooltipString','View fit in currently selected label')
else
set(handles.ViewDataFit,'Enable','off')
set(handles.ViewROIFit,'Enable','off')
set(handles.ViewDataFit,'TooltipString','No voxel-wise fitting for this qMR Method (Volume based method)')
end
guidata(hObject, handles);

function SimfunGUI(functionName)
Model = getappdata(0,'Model');
SimfunGUI = str2func(functionName);
SimfunGUI(Model);


function MethodSelection_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% SET DEFAULT METHODSELECTION
function DefaultMethodBtn_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
setappdata(0, 'Method', Method);
save(handles.Default,'Method');

function PanelOn(panel, handles)
eval(sprintf('set(handles.%sPanel, ''Visible'', ''on'')', panel));

function PanelOff(panel, handles)
eval(sprintf('set(handles.%sPanel, ''Visible'', ''off'')', panel));

% OPEN OPTIONS
function OpenOptionsPanel_Callback(hObject, eventdata, handles)
Method = GetAppData('Method');
Model = getappdata(0,'Model');
Custom_OptionsGUI(Model, gcf);


% UPDATE OPTIONS
function UpdateOptions(Sim,Prot,FitOpt)
h = findobj('Tag','OptionsGUI');
if ~isempty(h)
    OptionsGUIhandles = guidata(h);
    set(OptionsGUIhandles.SimFileName,   'String',  Sim.FileName);
    set(OptionsGUIhandles.ProtFileName,  'String',  Prot.FileName);
    set(OptionsGUIhandles.FitOptFileName,'String',  FitOpt.FileName);
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

% ##############################################################################################
%                                    FIT DATA
% ##############################################################################################

% FITDATA GO
function FitGO_Callback(hObject, eventdata, handles)
Method = GetMethod(handles);
setappdata(0, 'Method', Method);
FitGo_FitData(hObject, eventdata, handles);
% The counterSfMiss variable is assigned by the GetSf.m function
% to keep track of how many times a warning has been printed.
% After fit has been completed, we can remove this from the base 
% workspace to avoid confusion.
if ~evalin('base','exist(''counterSfMiss'')')
    evalin('base','clear(''counterSfMiss'')');
end


% Original FitGo function
function FitGo_FitData(hObject, eventdata, handles)

% Get data
data =  GetAppData('Data');
Method = GetAppData('Method');
Model = getappdata(0,'Model');
if isfield(data,[class(Model) '_hdr']), hdr = data.([class(Model) '_hdr']); end
data = data.(Method);

% check data
ErrMsg = Model.sanityCheck(data);
if ~isempty(ErrMsg), errordlg(ErrMsg,'Input error','modal'); return; end

if ~moxunit_util_platform_is_octave
   
   try
    p = gcp('nocreate');
   catch
    p=[];
   end
   if license('test','Distrib_Computing_Toolbox') && Model.voxelwise && isempty(p)
        cprintf('blue', 'MATLAB detected %d physical cores.',feature('numcores'));
        cprintf('blue', '<< Tip >> You can accelerate fitting by starting a parallel pool by running: \n parpool(%d);',feature('numcores'));
        dlgTitle    = 'Parallel Processing';
        dlgQuestion = sprintf('Would you like to start a parallel pool with %d cores?',feature('numcores'));
        choice = questdlg(dlgQuestion,dlgTitle,'Yes','No', 'Yes');
        if strcmp(choice,'Yes')
            parpool(feature('numcores'));
            p = gcp('nocreate');
        end
   end

   if ~isempty(p) && Model.voxelwise
       FitResults = ParFitData(data,Model);
   else
       FitResults = FitData(data,Model,1);
   end

else
% Do the fitting in Octave
  FitResults = FitData(data,Model,1);
end

% Save info with results
FileBrowserList = GetAppData('FileBrowserList');
MethodList = getappdata(0, 'MethodList');
MethodList = strrep(MethodList, '.m', '');
MethodCount = numel(MethodList);

for i=1:MethodCount
    if FileBrowserList(i).IsMethodID(Method)
        MethodID = i;
    end
end
FitResults.StudyID = FileBrowserList(MethodID).getStudyID;
FitResults.WD = FileBrowserList(MethodID).getWD;
if isempty(FitResults.WD), FitResults.WD = pwd; end
FitResults.Files = FileBrowserList(MethodID).getFileName;
SetAppData(FitResults);

% Kill the waitbar in case of a problem occurred
wh=findall(0,'tag','TMWWaitbar');
delete(wh);

% convert Model to struct
FitResults.Model = objProps2struct(FitResults.Model);

% Save fit results
if(~isempty(FitResults.StudyID))
    filename = strcat('FitResults_',FitResults.StudyID,'.mat');
else
    filename = 'FitResults.mat';
end
outputdir = fullfile(FitResults.WD,['FitResults_', datestr(datetime('now','TimeZone','local'),'yyyy-mm-dd_HH-MM-SS')]); % ISO 8601 format adapted for MATLAB compatibility
if ~exist(outputdir,'dir'), mkdir(outputdir); 
else
    iii=1; outputdirnew = outputdir;
    while exist(outputdirnew,'dir')
        iii=iii+1;
        outputdirnew = [outputdir,'_' num2str(iii)];
    end
    outputdir = outputdirnew;
    mkdir(outputdir);
end
save(fullfile(outputdir,filename),'-struct','FitResults');
set(handles.CurrentFitId,'String','FitResults.mat');

% Save nii maps
for ii = 1:length(FitResults.fields)
    map = FitResults.fields{ii};
    file = strcat(map,'.nii.gz');

    if ~exist('hdr','var')
        save_nii(make_nii(FitResults.(map)),fullfile(outputdir,file));
    else
        % Reset multiplicative and additive scale factors to nifti header
        % in case there were some in the input file's header that was used
        % as a template. If this isn't done, then when a tool loads the
        % qMRI map's nifti file, it will apply an undesired scaling.
        hdr.scl_slope = 1;
        hdr.scl_inter = 0;
	
        nii_save(FitResults.(map),hdr,fullfile(outputdir,file));
    end
end

SetAppData(FileBrowserList);
% Show results
handles.CurrentData = FitResults;
if exist('hdr','var')
    handles.CurrentData.hdr = hdr;
end
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

[FileName,PathName] = uigetfile({'*FitResults*.mat;*.qmrlab.mat;*.mat'},'FitResults.mat');
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
    Method = FitResults.Model.ModelName;
    Model = qMRloadObj(FitResults.Model);
    SetAppData(FitResults,Model);
end

% find model value in the method menu list
methods = sct_tools_ls([handles.ModelDir filesep '*.m'], 0,0,2,1);
val = find(strcmp(methods,Method));
set(handles.MethodSelection,'Value',val)

MethodMenu(hObject, eventdata, handles,Method)
handles = guidata(hObject); % update handle
FileBrowserList = GetAppData('FileBrowserList');
% if isfield(FitResults,'WD'), FileBrowserList.setWD(FitResults.WD); end
% if isfield(FitResults,'StudyID'), FileBrowserList.setStudyID(FitResults.StudyID); end
% if isfield(FitResults,'Files'),
%     for ifile = fieldnames(FitResults.Files)'
%         FileBrowserList.setFileName(ifile{1},FitResults.Files.(ifile{1}))
%     end
% end

SetAppData(FileBrowserList);
handles.CurrentData = FitResults;
guidata(hObject,handles);
DrawPlot(handles);


% #########################################################################
%                            PLOT DATA
% #########################################################################

% SOURCE
function SourcePop_Callback(hObject, eventdata, handles)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

handles.tool.setNvol(get(handles.SourcePop,'Value'));

% VIEW
function ViewPop_Callback(hObject, eventdata, handles)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

UpdateSlice(handles)
View = get(handles.ViewPop,'String');
if ~iscell(View), View = {View}; end
handles.tool.setviewplane(View{get(handles.ViewPop,'Value')})

% STATS Table
function Stats_Callback(hObject, eventdata, handles)
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

I = handles.tool.getImage(1);
Iraw = handles.CurrentData;
fields = setdiff(Iraw.fields,'Mask','stable')';
Maskall = handles.tool.getMask(1);
Color = handles.tool.getMaskColor;
StatsGUI(I,Maskall, fields, Color);


% HISTOGRAM FIG
function Histogram_Callback(hObject, eventdata, handles)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');
% Plot figure
f=figure('Position', [100 100 700 400], 'Resize', 'Off','Name','Histogram');

Map = handles.tool.getImage;
MatlabVer = version;
if str2double(MatlabVer(1))<8 || (str2double(MatlabVer(1))==8 && str2double(MatlabVer(3))<4)
    Maskall = uint8(handles.tool.getMask);
else
    Maskall = handles.tool.getMask(1);
    h_plot = subplot(1,2,2); % Use subplot to give space for GUI elements
    h_plot.OuterPosition = [0.3 0 0.7 1.0];
end

% loop over mask
values = unique(Maskall(Maskall>0))';
if isempty(values), values = 0; end
for ic = 1:length(values)   
    Selected = values(ic);
    Mask = Maskall == Selected;
    
    ii = find(Mask);
    nVox = length(ii);
    data = reshape(Map(ii),1,nVox);
    
    % Matlab < R2014b
    MatlabVer = version;
    if str2double(MatlabVer(1))<8 || (str2double(MatlabVer(1))==8 && str2double(MatlabVer(3))<4)
        defaultNumBins = max(5,round(length(data)/100));
        hist(data, defaultNumBins);
        % Label axes
        SourceFields = cellstr(get(handles.SourcePop,'String'));
        Source = SourceFields{get(handles.SourcePop,'Value')};
        xlabel(Source);
        ylabel('Counts');
        return;
    end
    
    % Matlab >= R2014b
    hold on
    h_hist(ic)=histogram(data);
    BinWidth(ic) = h_hist.BinWidth;

    hold off
    Color = handles.tool.getMaskColor;
    set(h_hist(ic),'FaceColor',Color(Selected+1,:),'FaceAlpha',0.3)
end

% set BinWidth
BinWidth = median(BinWidth);
for ic = 1:length(h_hist)
    h_hist(ic).BinWidth = BinWidth;
end

% Label axes
SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};
xlabel(Source);
h_ylabel = ylabel('Counts');

% No. of bins GUI objects
h_text_bin = uicontrol(f,'Style','text',...
                     'String', 'Width of bins:',...
                     'FontSize', 14,...
                     'Position',[5 20+300 140 34]);
h_edit_bin = uicontrol(f,'Style','edit',...
                     'String', BinWidth,...
                     'FontSize', 14,...
                     'Position',[135 25+300 70 34]);
h_slider_bin = uicontrol(f,'Style','slider',...
                       'Min',BinWidth/10,'Max',BinWidth*10,'Value',BinWidth,...
                       'SliderStep',[1/(100-1) 1/(100-1)],...
                       'Position',[205 26+300 10 30],...
                       'Callback',{@sl_call,{h_hist h_edit_bin}});
h_edit_bin.Callback = {@ed_call,{h_hist h_slider_bin}};

% Min-Max GUI objects
h_text_min = uicontrol(f,'Style','text',...
                      'String', 'Min',...
                      'FontSize', 14,...
                      'Position',[0 20+200 140 34]);
BinLimits = cat(1,h_hist.BinLimits);
h_edit_min = uicontrol(f,'Style','edit',...
                     'String', min(BinLimits(:,1)),...
                     'FontSize', 14,...
                     'Position', [35 20+180 70 34]);
h_text_max = uicontrol(f,'Style','text',...
                      'String', 'Max',...
                      'FontSize', 14,...
                      'Position',[130 20+200 40 34]);
h_edit_max = uicontrol(f,'Style','edit',...
                     'String', max(BinLimits(:,2)),...
                     'FontSize', 14,...
                     'Position', [116 20+180 70 34]);
h_button_minmax = uicontrol(f,'Style','pushbutton',...
                              'String', 'Recalculate',...
                              'FontSize', 14,...
                              'Position', [65 20+140 100 34],...
                              'Callback',{@minmax_call,{h_hist h_edit_min h_edit_max data}});

% Normalization GUI objects
h_text_min = uicontrol(f,'Style','text',...
                      'String', 'Normalization mode',...
                      'FontSize', 14,...
                      'Position',[30 20+40 180 34]);
h_popup_norm = uicontrol(f,'Style','popupmenu',...
                           'String', {'Count',...
                                      'Cumulative count',...
                                      'Probability',...
                                      'PDF',...
                                      'CDF'},...
                           'FontSize', 14,...
                           'Position', [30 20+20 180 34],...
                           'Callback',{@norm_call,{h_hist h_ylabel}});


% Histogram GUI callbacks
function [] = sl_call(varargin)
    % Callback for the histogram slider.
    [h_slider_bin,h_cell] = varargin{[1,3]};
    h_hist = h_cell{1};
    h_edit_bin = h_cell{2};
    for ic = 1:length(h_hist)
        h_hist(ic).BinWidth = h_slider_bin.Value;
    end
    h_edit_bin.String = h_slider_bin.Value;

function [] = ed_call(varargin)
    % Callback for the histogram edit box.
    [h_edit_bin,h_cell] = varargin{[1,3]};
    h_hist = h_cell{1};
    h_slider_bin = h_cell{2};

    for ic=1:length(h_hist)
    h_hist(ic).BinWidth = max(eps,str2double(h_edit_bin.String));
    end
    h_slider_bin.Value = round(str2double(h_edit_bin.String));

function [] = minmax_call(varargin)
    % Callback for the histogram bin bounds recalculate box.
    h_cell = varargin{3};
    h_hist = h_cell{1};
    h_min = h_cell{2};
    h_max = h_cell{3};

    % Mask data out of range of min-max
    minVal = str2double(h_min.String);
    maxVal = max(minVal,str2double(h_max.String));

    for ic = 1:length(h_hist)
        h_hist(ic).BinLimits = [minVal maxVal];
    end
    
function [] = norm_call(varargin)
    % Callback for the histogram edit box.
    [h_popup_norm,h_cell] = varargin{[1,3]};
    h_hist = h_cell{1};
    h_ylabel = h_cell{2};

    menu_status = h_popup_norm.String{h_popup_norm.Value};

    for ic=1:length(h_hist)
        switch menu_status
            case 'Count'
                h_hist(ic).Normalization = 'count';
            case 'Cumulative count'
                h_hist(ic).Normalization = 'cumcount';
            case 'Probability'
                h_hist(ic).Normalization = 'probability';
            case 'PDF'
                h_hist(ic).Normalization = 'pdf';
            case 'CDF'
                h_hist(ic).Normalization = 'cdf';
        end
    end
    h_ylabel.String = menu_status;

% PLOT DATA FIT
function ViewDataFit_Callback(hObject, eventdata, handles)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

if isempty(handles.dcm_obj) || isempty(getCursorInfo(handles.dcm_obj))
    helpdlg('Select a voxel in the image using cursor')
    return;
end

info_dcm_all = getCursorInfo(handles.dcm_obj);
for ipix = 1:length(info_dcm_all)
    info_dcm = info_dcm_all(ipix);
    x = info_dcm.Position(1);
    y = info_dcm.Position(2);
    z = handles.tool.getCurrentSlice;
    S = handles.tool.getImageSize;
    vox{ipix} = sub2ind(S,y,x,z);
end
hh = plotfit(handles,vox);
if ~isempty(hh)
    set(hh,'Name',['Fitting results of voxel [' num2str([info_dcm.Position(1) info_dcm.Position(2) z]) ']'],'NumberTitle','off');
    set(hh,'Color',[.94 .94 .94])
end

function ViewROIFit_Callback(hObject, eventdata, handles)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

Mask = handles.tool.getMask();
if isempty(Mask) || ~any(Mask(:))
    helpdlg('Draw a mask for current label using the brush tools')
    return;
end

vox{1} = find(Mask);
hh = plotfit(handles,vox);
if ~isempty(hh)
    set(hh,'Name',['Fitting results in current label #' num2str(handles.tool.getmaskSelected())],'NumberTitle','off');
    C = handles.tool.getMaskColor();
    set(hh,'Color',[1 1 1]*.8+.2*C(handles.tool.getmaskSelected()+1,:))
end

function hh = plotfit(handles,vox)
Model = GetAppData('Model');
% Get data
data =  getappdata(0,'Data'); data=data.(class(getappdata(0,'Model')));
S = [size(data.(Model.MRIinputs{1}),1) size(data.(Model.MRIinputs{1}),2) size(data.(Model.MRIinputs{1}),3)];
Data = handles.tool.getImage(0);
Scurrent = [size(Data,1) size(Data,2) size(Data,3)];
datafields = get(handles.SourcePop,'String');

if sum(S)==0
    helpdlg(['Specify a ' Model.MRIinputs{1} ' file in the filebrowser'])
elseif ~isequal(Scurrent(1:3), S(1:3))
    Sstr = sprintf('%ix',S);
    Scurstr = sprintf('%ix',Scurrent);
    helpdlg([Model.MRIinputs{1} ' file (' Sstr(1:end-1) ') in the filebrowser is inconsistent with ' datafields{get(handles.SourcePop,'Value')} ' in the viewer (' Scurstr(1:end-1) '). Load corresponding ' Model.MRIinputs{1} '.'])
    return;
end

Model.sanityCheck(data);

for ipix = 1:length(vox)    
    
    for ii=1:length(Model.MRIinputs)
        if isfield(data,(Model.MRIinputs{ii})) && ~isempty(data.(Model.MRIinputs{ii}))
            voltmp = reshape2D(data.(Model.MRIinputs{ii}),4);
            datasqueeze.(Model.MRIinputs{ii}) = nanmean(voltmp(:,vox{ipix}),2);
        end
    end
    if isfield(datasqueeze,'Mask'), datasqueeze.Mask = 1; end
    
    
    % Create axe
    hh = 68;
    figure(hh)
    h = findobj(hh,'Style','checkbox','String','hold plot in order to compare voxels');
    if ipix==1 && (isempty(h) || ~get(h,'Value'))  % If a data fit check has already been run OR do not hold plot,
        clf(hh)        % clear the previous data from the figure plot
        uicontrol('Style','checkbox','String','hold plot in order to compare voxels','Value',0,'Position',[0 0 210 20]);
    end
    
    haxes = get(hh,'children'); haxes = haxes(strcmp(get(haxes,'Type'),'axes'));
    
    if ~isempty(haxes)
        % turn gray old plots
        for h=1:length(haxes) %might have subplots
            haxe = get(haxes(h),'children');
            set(haxe,'Color',[0.8 0.8 0.8]);
            hAnnotation = get(haxe,'Annotation');
            % remove their legends
            for ih=1:length(hAnnotation)
                if iscell(hAnnotation), hAnnot = hAnnotation{ih}; else hAnnot = hAnnotation; end
                hLegendEntry = get(hAnnot,'LegendInformation');
                set(hLegendEntry,'IconDisplayStyle','off');
            end
        end
    end
    hold on;
    
    % Do the fitting
    if ~ismethod(Model,'plotModel'), warndlg('No plotting methods in this model'); return; end
    Fit = Model.fit(datasqueeze) % Display fitting results in command window
    Model.plotModel(Fit,datasqueeze);
    
    % update legend
    if ~moxunit_util_platform_is_octave
        legend('Location','best')
    end

end

% OPEN VIEWER
function Viewer_Callback(hObject, eventdata, handles)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

I.img = handles.tool.getImage(1);
I.label = cellstr(get(handles.SourcePop,'String'));
Mask = handles.tool.getMask(1);
if isfield(handles.CurrentData,'hdr')
    I.hdr = handles.CurrentData.hdr;

    tool = imtool3D_nii_3planes(I,Mask);
else

    tool = imtool3D_3planes(I.img,Mask);

    for ii=1:3, tool(ii).setlabel(I.label); end
end
clims = handles.tool.getClimits;
for ii=1:3
    tool(ii).setNvol(handles.tool.getNvol);
    tool(ii).setClimits(clims);
end


% CURSOR
function CursorBtn_Callback(hObject, eventdata, handles)
% unselect button to prevent activation with spacebar
set(hObject, 'Enable', 'off');
drawnow;
set(hObject, 'Enable', 'on');

datacursormode;
H = handles.tool.getHandles;
fig = H.fig;
handles.dcm_obj = datacursormode(fig);
guidata(gcbf,handles);

set(handles.dcm_obj,'UpdateFcn',{@dataCursorUpdateFcn,handles})

function txt = dataCursorUpdateFcn(h_PointDataTip,event_obj,handles)
% Customizes text of data tips
pos = get(event_obj,'Position');
data = handles.tool.getCurrentImageSlice;

SourceFields = cellstr(get(handles.SourcePop,'String'));
Source = SourceFields{get(handles.SourcePop,'Value')};

sliceNum = handles.tool.getCurrentSlice;

txt = {['Source: ', Source],...
       ['[X,Y]: ', '[', num2str(pos(1)), ',', num2str(pos(2)), ']'],...
       ['Slice: ', num2str(sliceNum)],...
	   ['Value: ', num2str(data(pos(2), pos(1)))]};

function RefreshPlot(handles)
if isempty(handles.CurrentData), return; end
% Apply View
View = get(handles.ViewPop,'String'); if ~iscell(View), View = {View}; end
View = View{get(handles.ViewPop,'Value')};
Data = ApplyView(handles.CurrentData, View);
% Display
if isfield(Data,'Mask'), Mask = Data.Mask; else Mask = []; end
for ff = 1:length(Data.fields)
    Current{ff} = Data.(Data.fields{ff});
end
handles.tool.setImage(Current,[],[],[],[],Mask);



% ######################## CREATE FUNCTIONS ##############################
function SourcePop_CreateFcn(hObject, eventdata, handles)
function ViewPop_CreateFcn(hObject, eventdata, handles)
function FitDataAxe_CreateFcn(hObject, eventdata, handles)
function Method_Selection_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function ChooseMethod_Callback(hObject, eventdata, handles)
% ----------------------------------------- END ------------------------------------------%


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over text_doc_model.
function text_doc_model_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to text_doc_model (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'Enable', 'Inactive');
Method = class(GetAppData('Model'));
web(['https://qmrlab.readthedocs.io/en/latest/' Method '_batch.html']);



% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over upgrade_message.
function upgrade_message_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to upgrade_message (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject, 'Enable', 'Inactive');
web('https://github.com/qMRLab/qMRLab/releases/latest');
