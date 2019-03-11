function DrawPlot(handles,CurrentName)
if ~exist('CurrentName','var') || strcmp(CurrentName,'Mask')
    set(handles.SourcePop, 'Value',  1);
else
    set(handles.SourcePop, 'Value',  find(strcmp(handles.CurrentData.fields,CurrentName)));
end
set(handles.ViewPop,   'Value',  1);
set(handles.ViewPop,   'UserData',  1);

UpdatePopUp(handles);

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
set(H.Tools.Save,'Callback',@(hObject,evnt)saveMask(handles))
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

function saveMask(handles)
tool = handles.tool;
Mask = tool.getMask(1);
if any(Mask(:))    
    [FileName,PathName, ext] = uiputfile({'*.nii.gz';'*.mat'},'Save Mask','Mask');
    FileName = strrep(FileName,'.gz','.nii.gz');
    FileName = strrep(FileName,'.nii.nii','.nii');
    if ext==1 % .nii.gz
        if isfield(handles.CurrentData,'hdr')
            handles.CurrentData.hdr.original.img = unxform_nii(handles.CurrentData.hdr,Mask);
            handles.CurrentData.hdr.shdr.dime.datatype=8;
            handles.CurrentData.hdr.hdr.dime.bitpix=32;
            handles.CurrentData.hdr.original.hdr.dime.dim(1)=3;
            handles.CurrentData.hdr.original.hdr.dime.dim(5:end)=1;
            save_nii(handles.CurrentData.hdr.original,fullfile(PathName,FileName))
        else
            save_nii(make_nii(uint8(Mask)),fullfile(PathName,FileName))
        end
    elseif ext==2 % .mat
        save(fullfile(PathName,FileName),'Mask');
    end
    
else
    warndlg('Mask empty... Draw a mask using the brush tools on the right')
end
