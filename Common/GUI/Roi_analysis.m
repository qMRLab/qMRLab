function varargout = Roi_analysis(varargin)
% qmrlab MATLAB code for Roi_analysis.fig
% GUI for ROI analysis of simulated/fitted qMRI maps

% ----------------------------------------------------------------------------------------------------
% Written by: Tommy Boshkovski, 2018
%
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :

% Cabana, JF. et al (2016).
% Quantitative magnetization transfer imaging made easy with qMRLab
% Software for x simulation, analysis and visualization.
% Concepts in Magnetic Resonance Part A
% ----------------------------------------------------------------------------------------------------
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Roi_analysis_OpeningFcn, ...
    'gui_OutputFcn',  @Roi_analysis_OutputFcn, ...
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

% --- Executes just before Roi_analysis is made visible.
function Roi_analysis_OpeningFcn(hObject, eventdata, handles, varargin)

%if max(strcmp(varargin,'wait')), wait=true; varargin(strcmp(varargin,'wait'))=[]; else wait=false; end
if ~isfield(handles,'opened') % qMRI already opened?
    handles.opened = 1;
    clc;
    % startup;
    qMRLabDir = fileparts(which(mfilename()));
    addpath(genpath(qMRLabDir));
    handles.root = qMRLabDir;
    handles.methodfiles = '';
    handles.CurrentData = [];
    handles.FitDataDim = [];
    handles.FitDataSize = [];
    handles.FitDataSlice = [];
    handles.NewMap = {};
    handles.ROI = {};
    handles.dcm_obj = [];
    MethodList = {};
    handles.mainHandles = varargin{1}; %Get passed-in handles structure and add them to secondary GUI's handles structure;
    %guidata(hObject, handles);
    maps = get(handles.ColorMapStyle, 'String');
    tmp = maps{2};
    maps{2} = maps{5};
    maps{5} = tmp;
    set(handles.ColorMapStyle, 'String', maps);
    
    % SET WINDOW AND PANELS
    movegui(gcf,'center')
    CurrentPos = get(gcf, 'Position');
    NewPos     = CurrentPos;
    NewPos(1)  = CurrentPos(1) - 40;
    set(gcf, 'Position', NewPos);
    set(handles.drawROI, 'enable', 'off');
    set(handles.AddROI, 'enable', 'on');
    set(handles.ROIList, 'enable', 'on');
    handles.CurrentData = getappdata(0,'roidata');
    guidata(hObject, handles);
    str = char(handles.CurrentData.fields{:});
    set(handles.data,'String',str);
    DrawMaps(handles);
    
end
% UIWAIT makes Roi_analysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);




handles.output = hObject;
handles.Data = varargin;
% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);


% UIWAIT makes Roi_analysis wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Roi_analysis_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user x (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)

if isfield(handles, 'metricdata') && ~isreset
    return;
end



% --- Executes on selection change in drawROI.
function drawROI_Callback(hObject, eventdata, handles)

set(gcf,'Pointer','Cross');
contents = cellstr(get(hObject,'String'));
model = contents{get(hObject,'Value')};
set(handles.FitDataAxe);
imagesc(rot90(GetCurrents(handles)));
axis equal off;
RefreshColorMaps(handles);
switch model
    case 'Ellipse'
        draw = imellipse();
    case 'Polygone'
        draw = impoly();
    case 'Rectangle'
        draw = imrect();
    case 'FreeHand'
        draw = imfreehand();
    otherwise
        warning('Choose a Drawing Method');
end

if(isfield(handles,'ROI'))
    roi = double(draw.createMask());
    SourceFields = cellstr(get(handles.data,'String'));
    Source = SourceFields{get(handles.data,'Value')};
    View = get(handles.ViewPop,'Value');
    Slice = str2double(get(handles.SliceValue,'String'));
    Time = str2double(get(handles.TimeValue,'String'));
    
    Data = handles.CurrentData;
    data = Data.(Source);
    
    
    switch View
        case 1
            handles.ROI{size(handles.ROI,2)+1}.vol=zeros(size(data));
            handles.ROI{size(handles.ROI,2)}.vol(:,:,Slice,Time) = rot90(roi,-1);
            handles.ROI{size(handles.ROI,2)}.color = rand(3);
        case 2
            handles.ROI{size(handles.ROI,2)+1}.vol=zeros(size(data));
            handles.ROI{size(handles.ROI,2)}.vol(:,Slice,:,Time)=rot90(roi,-1);
            handles.ROI{size(handles.ROI,2)}.color = rand(3);
        case 3
            handles.ROI{size(handles.ROI,2)+1}.vol=zeros(size(data));
            handles.ROI{size(handles.ROI,2)}.vol(Slice,:,:,Time)=rot90(roi,-1);
            handles.ROI{size(handles.ROI,2)}.color = rand(3);
    end
end

%add new ROI to the list of ROIs in the listbox
boxMsg = get(handles.ROIList,'String');
if(size(boxMsg,2)==0)
    boxMsg{1,1} = 'ROI1';
else
    boxMsg{size(boxMsg,1)+1,1} = ['ROI' num2str(size(boxMsg,1)+1)];
end
set(handles.ROIList,'String',boxMsg);
set(handles.drawROI, 'enable', 'off');
set(handles.AddROI, 'enable', 'on');
set(handles.ROIList, 'enable', 'on');
set(handles.DeleteRoi, 'enable', 'on');
set(gcf,'Pointer','Arrow')
guidata(gcbo,handles);


% --- Executes on button press in load_rois.
function load_rois_Callback(hObject, eventdata, handles)

[FileName,PathName] = uigetfile({'*.mat;*.nii'});
if isequal(FileName,0), return; end
FullPathName = fullfile(PathName, FileName);
extension = strsplit(FileName,'.');
boxMsg = get(handles.ROIList,'String');
if(strcmp(extension{size(extension,2)},'mat'))
    Tmp = load(FullPathName);
    for i=1:size(Tmp.Mask,2)
        if(size(boxMsg,2)==0)
            boxMsg{size(boxMsg,1),1} = ['ROI' num2str(size(boxMsg,1))];
            handles.ROI{size(handles.ROI,2)+1}.vol = Tmp.Mask{i}.vol;
            handles.ROI{size(handles.ROI,2)}.color = Tmp.Mask{i}.color;
        else
            boxMsg{size(boxMsg,1)+1,1} = ['ROI' num2str(size(boxMsg,1)+1)];
            handles.ROI{size(handles.ROI,2)+1}.vol = Tmp.Mask{i}.vol;
            handles.ROI{size(handles.ROI,2)}.color = Tmp.Mask{i}.color;
        end
    end
else
    niftiFile = load_nii(FullPathName);
    boxMsg = get(handles.ROIList,'String');
    if(size(boxMsg,2)==0)
        boxMsg{size(boxMsg,1),1} = ['ROI' num2str(size(boxMsg,1))];
        handles.ROI{size(handles.ROI,2)+1}.vol = niftiFile.img;
        handles.ROI{size(handles.ROI,2)}.color = rand(3);
    else
        boxMsg{size(boxMsg,1)+1,1} = ['ROI' num2str(size(boxMsg,1)+1)];
        handles.ROI{size(handles.ROI,2)+1}.vol = niftiFile.img;
        handles.ROI{size(handles.ROI,2)}.color = rand(3);
    end
end
set(handles.ROIList,'String',boxMsg);
guidata(gcbo,handles);




% --- Executes on button press in save_rois.
function save_rois_Callback(hObject, eventdata, handles)

Mask = handles.ROI;
[FileName, PathName] = uiputfile({'*.mat'},'Save as');
FullPathName = fullfile(PathName, FileName);
if FileName ~= 0
    save(FullPathName,'Mask');
end

% --- Executes on button press in saveImage.
function saveImage_Callback(hObject, eventdata, handles)
% hObject    handle to saveImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[FileName, PathName] = uiputfile({'*.fig'},'Save as');
FullPathName = fullfile(PathName, FileName);
if FileName ~= 0
fignew = figure('Visible','off'); % Invisible figure
newAxes = copyobj(handles.FitDataAxe,fignew); % Copy the appropriate axes
set(newAxes,'Position',get(groot,'DefaultAxesPosition')); % The original position is copied too, so adjust it.
set(fignew,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
savefig(fignew,FullPathName);
delete(fignew);
end


% --- Executes on selection change in x dropdown list.
function data_Callback(hObject, eventdata, handles)

GetPlotRanges(handles);
RefreshPlot(handles);


% --- Executes on selection change in ROIs listbox.
function ROIList_Callback(hObject, eventdata, handles)

%get selected ROI
RefreshPlot(handles);



% --- Executes on button press in AddROI.
function AddROI_Callback(hObject, eventdata, handles)
set(handles.drawROI, 'enable', 'on');


% --- Executes on button press in DeleteRoi.
function DeleteRoi_Callback(hObject, eventdata, handles)

index_selected = get(handles.ROIList,'Value');
if(size(handles.ROI,2) == 0)
    return;
end
rois = get(handles.ROIList,'String');
rois = removerows(rois,index_selected);
list = handles.ROI';
list = removerows(list,index_selected);
if(size(list,1) == 0) 
    list = {};
    rois = char.empty(1,0);
    index_selected=1;
end
handles.ROI = list';
set(handles.ROIList,'String',rois);
set(handles.ROIList,'Value',index_selected);
guidata(gcbo,handles);
RefreshPlot(handles);


% --- Executes on button press in zoomIn.
function zoomIn_Callback(hObject, eventdata, handles)
% hObject    handle to zoomIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of zoomIn
h = zoom;
h.Direction = 'in';
if(strcmp(get(handles.zoomOut,'TooltipString'),'on'))
    set(handles.zoomOut,'Value',0)
end
if(strcmp(get(handles.zoomIn,'TooltipString'),'off'))
h.Enable = 'on';
set(handles.zoomIn,'TooltipString','on')
else
    set(handles.zoomIn,'TooltipString','off')
    h.Enable = 'off';
end


% --- Executes on button press in zoomOut.
function zoomOut_Callback(hObject, eventdata, handles)
% hObject    handle to zoomOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = zoom;
h.Direction = 'out';
if(strcmp(get(handles.zoomIn,'TooltipString'),'on'))
    set(handles.zoomIn,'Value',0)
end
if(strcmp(get(handles.zoomOut,'TooltipString'),'off'))
h.Enable = 'on';
set(handles.zoomOut,'TooltipString','on')
else
    set(handles.zoomOut,'TooltipString','off')
    h.Enable = 'off';
end
% Hint: get(hObject,'Value') returns toggle state of zoomOut
% --- Executes on slider movement.

function roi_transparency_Callback(hObject, eventdata, handles)
RefreshPlot(handles);

% --- Executes on button press in saveResults.
function saveResults_Callback(hObject, eventdata, handles)
results = handles.RoiResults.Data;
[FileName, PathName] = uiputfile({'*.mat'},'Save as');
FullPathName = fullfile(PathName, FileName);
if FileName ~= 0
    save(FullPathName,'results');
end



function ColorMapStyle_Callback(hObject, eventdata, handles)
val  =  get(handles.ColorMapStyle, 'Value');
maps =  get(handles.ColorMapStyle, 'String');
colormap(maps{val});

function Auto_Callback(hObject, eventdata, handles)
GetPlotRanges(handles);
RefreshPlot(handles);

% SOURCE
function SourcePop_Callback(hObject, eventdata, handles)
GetPlotRanges(handles);
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
UpdatePopUps(handles);
RefreshPlot(handles);
xlim('auto');
ylim('auto');

% SLICE
function SliceValue_Callback(hObject, eventdata, handles)
Slice = str2double(get(hObject,'String'));
Slice = min(get(handles.SliceSlider,'Max'),Slice);
Slice = max(1,Slice);
set(hObject,'String',num2str(Slice));
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

function TimeValue_Callback(hObject, eventdata, handles)
Time = str2double(get(hObject,'String'));
Time = min(get(handles.TimeSlider,'Max'),Time);
Time = max(1,Time);
set(hObject,'String',num2str(Time));
set(handles.TimeSlider,'Value',Time);
RefreshPlot(handles);

function TimeSlider_Callback(hObject, eventdata, handles)
Time = get(hObject,'Value');
Time = max(1,round(Time));
set(handles.TimeSlider, 'Value', Time);
set(handles.TimeValue, 'String', Time);
RefreshPlot(handles);


function RefreshPlot(handles)
if isempty(handles.CurrentData), return; end
xl = xlim;
yl = ylim;
% 

index_selected = get(handles.ROIList,'Value');

    SourceFields = cellstr(get(handles.data,'String'));
    Source = SourceFields{get(handles.data,'Value')};
    View = get(handles.ViewPop,'Value');
    Slice = str2double(get(handles.SliceValue,'String'));
    Time = str2double(get(handles.TimeValue,'String'));
    transparency = get(handles.roi_transparency,'Value');
    Data = handles.CurrentData;
    data = Data.(Source);
    if (size(handles.ROI,2) ~= 0)
    switch View
        case 1
            Map = rot90(squeeze(data(:,:,Slice,Time)));
            NewMap = rot90(squeeze(handles.ROI{index_selected}.vol(:,:,Slice,Time)))*transparency;
        case 2
            Map = rot90(squeeze(data(:,Slice,:,Time)));
            NewMap = rot90(squeeze(handles.ROI{index_selected}.vol(:,Slice,:,Time)))*transparency;
        case 3
            Map = rot90(squeeze(data(Slice,:,:,Time)));
            NewMap = rot90(squeeze(handles.ROI{index_selected}.vol(Slice,:,:,Time)))*transparency;
    end
    
    %guidata(gcbo, handles);
    set(handles.FitDataAxe);
    %overaly the image with a colored ROI
    green = cat(3, ones(size(Map)).* handles.ROI{index_selected}.color(1), ones(size(Map)).* handles.ROI{index_selected}.color(2), ...
        ones(size(Map)).* handles.ROI{index_selected}.color(3)); % randomly select a color
    
    imagesc(Map);
    hold on
    b = imshow(green);
    set(b, 'AlphaData', NewMap)
    hold off
    table(2:1+size(get(handles.data,'String'),1),1) = get(handles.data,'String');
    table(1,1:4) = {'map','mean','std','median'};
    length = max(size(handles.CurrentData.fields,2),size(handles.CurrentData.fields,1));
    for i = 1:length
        data = Data.(handles.CurrentData.fields{i});
        data = data(handles.ROI{index_selected}.vol > 0);
        table(1+i,2) = {mean(data(~isnan(data) & ~isinf(data)))};
        table(1+i,3) = {std(data(~isnan(data) & ~isinf(data)))};
        table(1+i,4) = {median(data(~isnan(data) & ~isinf(data)))};
    end
    set(handles.RoiResults,'Data',table)
    else
    switch View
        case 1
            Map = rot90(squeeze(data(:,:,Slice,Time)));
        case 2
            Map = rot90(squeeze(data(:,Slice,:,Time)));
        case 3
            Map = rot90(squeeze(data(Slice,:,:,Time)));
    end
    imagesc(Map);
    end
    axis equal off;
    RefreshColorMaps(handles)
    xlim(xl);
    ylim(yl);



function DrawMaps(handles)
set(handles.data, 'Value',  1);
set(handles.ViewPop,   'Value',  1);
UpdatePopUps(handles);
GetPlotRanges(handles);
Current = GetCurrents(handles);
% imagesc(flipdim(Current',1));
imagesc(rot90(Current));
axis equal off;
RefreshColorMaps(handles)


function RefreshColorMaps(handles)
val  = get(handles.ColorMapStyle, 'Value');
maps = get(handles.ColorMapStyle, 'String');
colormap(maps{val});
View = get(handles.ViewPop,'Value');
switch View
    case 1
        colorbar('location', 'East', 'Color', 'white', 'FontSize',12,'FontWeight','bold');
    case 2
        colorbar('location', 'South', 'Color', 'white', 'FontSize',12,'FontWeight','bold');
    case 3
        colorbar('location', 'South', 'Color', 'white', 'FontSize',12,'FontWeight','bold');
end
min = str2double(get(handles.MinValue, 'String'));
max = str2double(get(handles.MaxValue, 'String'));
caxis([min max]);




function UpdateSlices(handles)
% UpdateSlice: set slice slider maximal value

% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran�is Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for x simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------

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
if (dim(3)>1)
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

% Set Time (Vol #) slider max value
if length(dim)<4, dim(4)=1; end
set(handles.TimeSlider,  'Max',dim(4));
set(handles.TimeSlider,  'SliderStep',[1, 1] / dim(4));
% if new x has fewer volumes,set to maximal volume #
TimeBounded = min(dim(4),str2double(get(handles.TimeValue,'String')));
set(handles.TimeValue,'String',TimeBounded)
set(handles.TimeSlider,'Value',TimeBounded)

function UpdatePopUps(handles)
axes(handles.FitDataAxe);
Data   =  handles.CurrentData;
fields =  Data.fields;
set(handles.data, 'String', fields);
handles.FitDataSize = size(Data.(fields{1}));
handles.FitDataDim = size(Data.(fields{1})); if length(handles.FitDataDim)<3, handles.FitDataDim(3)=1; end
dim = handles.FitDataDim;
if dim(3)>1
    set(handles.ViewPop,'String',{'Axial','Coronal','Sagittal'});
    handles.FitDataSlice = floor(handles.FitDataSize/2);
else
    set(handles.ViewPop,'String','Axial');
    handles.FitDataSlice = 1;
end
UpdateSlices(handles)
guidata(findobj('Name','qMRLab'), handles);


function Current = GetCurrents(handles)
SourceFields = cellstr(get(handles.data,'String'));
Source = SourceFields{get(handles.data,'Value')};
View = get(handles.ViewPop,'Value');
Slice = str2double(get(handles.SliceValue,'String'));
Time = str2double(get(handles.TimeValue,'String'));

Data = handles.CurrentData;
data = Data.(Source);
switch View
    case 1;  Current = squeeze(data(:,:,Slice,Time));
    case 2;  Current = squeeze(data(:,Slice,:,Time));
    case 3;  Current = squeeze(data(Slice,:,:,Time));
end


function GetPlotRanges(handles)
if isempty(handles.CurrentData), return; end
Current = GetCurrents(handles);
values=Current(:); values(isinf(values))=[]; values(isnan(values))=[];

if length(unique(values))>20 % it is a mask?
    values(~values)=[];
    Min = prctile(values,1); % 5 percentile of the data to prevent extreme values
    Max = prctile(values,99);% 95 percentile of the data to prevent extreme values
else
    Min=min(values);
    Max=max(values);
end

if (abs(Min - Max)<1e-3)
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
guidata(findobj('Name','qMRLab'), handles);

function figure1_CloseRequestFcn(hObject, eventdata, handles)
%guidata(handles,handles.mainHandles);
delete(hObject);

%%UI Create functions

function roiList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function x_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function popupmenu3_Callback(hObject, eventdata, handles)
function popupmenu3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function ROIList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pushbutton5_Callback(hObject, eventdata, handles)
function pushbutton6_Callback(hObject, eventdata, handles)
function MinValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function MaxValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function MinSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function MaxSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function ColorMapStyle_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function SliceValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function SliceSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function ViewPop_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function TimeValue_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function TimeSlider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function drawROI_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function data_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function edit7_Callback(hObject, eventdata, handles)
function edit7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit8_Callback(hObject, eventdata, handles)
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function slider6_Callback(hObject, eventdata, handles)
function slider6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function slider7_Callback(hObject, eventdata, handles)
function slider7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function popupmenu8_Callback(hObject, eventdata, handles)
function popupmenu8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function edit9_Callback(hObject, eventdata, handles)
function edit9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function slider8_Callback(hObject, eventdata, handles)
function slider8_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function popupmenu9_Callback(hObject, eventdata, handles)
function popupmenu9_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pushbutton10_Callback(hObject, eventdata, handles)
function edit10_Callback(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function slider9_Callback(hObject, eventdata, handles)
function slider9_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function popupmenu10_Callback(hObject, eventdata, handles)
function popupmenu10_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function roi_transparency_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in roiDilation.
function roiDilation_Callback(hObject, eventdata, handles)
index_selected = get(handles.ROIList,'Value');
se = strel('line',3,0);
se1 = strel('line',3,90);
handles.ROI{index_selected}.vol = imdilate(handles.ROI{index_selected}.vol,[se se1]);
guidata(hObject,handles);
RefreshPlot(handles);


% --- Executes on button press in roiErosion.
function roiErosion_Callback(hObject, eventdata, handles)
index_selected = get(handles.ROIList,'Value');
se = strel('line',3,0);
se1 = strel('line',3,90);
handles.ROI{index_selected}.vol = imerode(handles.ROI{index_selected}.vol,[se se1]);
guidata(hObject,handles);
RefreshPlot(handles);


% --- Executes on button press in roiEdit.
function roiEdit_Callback(hObject, eventdata, handles)
index_selected = get(handles.ROIList,'Value');
% fignew = figure('Visible','off'); % Invisible figure
% set(newAxes,'Position',get(groot,'DefaultAxesPosition')); % The original position is copied too, so adjust it.
% imagesc(rot90(GetCurrents(handles)));
% axis equal off;
draw = imfreehand(gca);
if(isfield(handles,'ROI'))
    roi = double(createMask());
    SourceFields = cellstr(get(handles.data,'String'));
    Source = SourceFields{get(handles.data,'Value')};
    View = get(handles.ViewPop,'Value');
    Slice = str2double(get(handles.SliceValue,'String'));
    Time = str2double(get(handles.TimeValue,'String'));
    
    Data = handles.CurrentData;
    data = Data.(Source);
    
    
    switch View
        case 1
            tmp=zeros(size(data));
            tmp(:,:,Slice,Time) = rot90(roi,-1);
            handles.ROI{index_selected}.vol = double(handles.ROI{index_selected}.vol|tmp);
        case 2
            tmp=zeros(size(data));
            tmp(:,Slice,:,Time)=rot90(roi,-1);
            handles.ROI{index_selected}.vol = double(handles.ROI{index_selected}.vol|tmp);
        case 3
            tmp=zeros(size(data));
            tmp(Slice,:,:,Time)=rot90(roi,-1);
            handles.ROI{index_selected}.vol = double(handles.ROI{index_selected}.vol|tmp);
    end
end
guidata(hObject,handles);
RefreshPlot(handles);
