function DrawPlot(handles,CurrentName)
if ~exist('CurrentName','var') || strcmp(CurrentName,'Mask')
    set(handles.SourcePop, 'Value',  1);
else
    set(handles.SourcePop, 'Value',  find(strcmp(handles.CurrentData.fields,CurrentName)));
end


Data = handles.CurrentData;
if isfield(Data,'Mask'), Mask = Data.Mask; Data.fields(strcmp(Data.fields,'Mask'))=[]; else Mask = []; end
if ~isempty(Data.fields)
    for ff = 1:length(Data.fields)
        Current{ff} = Data.(Data.fields{ff});
    end
else
    Current{1} = Mask;
end
handles.tool.setImage(Current,[],[],[],[],Mask);
UpdatePopUp(handles);

% Set Volume Number
if exist('CurrentName','var')
    if strcmp(CurrentName,'Mask')
        setNvol(handles.tool,1)
    else
        setNvol(handles.tool,find(strcmp(handles.CurrentData.fields,CurrentName)))
    end
end
% Set Slice Number
handles.tool.setCurrentSlice(round(size(Current{1},3)/2))

% Set Pixel size
if isfield(handles.CurrentData,'hdr')
    handles.tool.setAspectRatio(handles.CurrentData.hdr.pixdim(2:4))
else
    handles.tool.setAspectRatio([1 1 1])
end

% Change save as NIFTI function
H = handles.tool.getHandles;
if isfield(handles.CurrentData,'hdr'), hdr = {handles.CurrentData.hdr}; else, hdr = {}; end
set(H.Tools.maskSave,'Callback',@(hObject,evnt)saveMask(handles.tool,hObject,hdr{:}))
set(H.Tools.maskLoad,'Callback',@(hObject,evnt)loadMask(handles.tool,hObject,hdr{:}))

% Use Shortcut to Source button
set(findobj('Name','qMRLab'),'Windowkeypressfcn', @(hobject, event) shortcutCallback(hobject, event,handles))

guidata(findobj('Name','qMRLab'), handles);

function shortcutCallback(hobject, event,handles)
switch event.Key
    case 'uparrow'
        setNvol(handles.tool,handles.tool.getNvol-1)
        set(handles.SourcePop, 'Value',  handles.tool.getNvol);
    case 'downarrow'
        setNvol(handles.tool,handles.tool.getNvol+1)   
        set(handles.SourcePop, 'Value',  handles.tool.getNvol);
    otherwise
        handles.tool.shortcutCallback(event)
end