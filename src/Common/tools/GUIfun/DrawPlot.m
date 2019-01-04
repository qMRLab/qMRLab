function DrawPlot(handles,CurrentName)
if ~exist('CurrentName','var')
    set(handles.SourcePop, 'Value',  1);
else
    set(handles.SourcePop, 'Value',  find(strcmp(handles.CurrentData.fields,CurrentName)));
end
set(handles.ViewPop,   'Value',  1);
set(handles.ViewPop,   'UserData',  1);

UpdatePopUp(handles);

View = get(handles.ViewPop,'String'); if ~iscell(View), View = {View}; end
View = View{get(handles.ViewPop,'Value')};
Data = ApplyView(handles.CurrentData, View);
if isfield(Data,'Mask'), Mask = Data.Mask; Data.fields(strcmp(Data.fields,'Mask'))=[]; else Mask = []; end
for ff = 1:length(Data.fields)
    Current{ff} = Data.(Data.fields{ff});
end
Mask = ApplyView(Mask, View);
handles.tool.setImage(Current,[],[],[],[],Mask);

% Set Volume Number
if exist('CurrentName','var')
    setNvol(handles.tool,find(strcmp(handles.CurrentData.fields,CurrentName)))
end
% Set Slice Number
handles.tool.setCurrentSlice(round(size(Current{1},3)/2))

% Set Pixel size
H = getHandles(handles.tool);
if isfield(handles.CurrentData,'hdr')
    set(H.Axes,'DataAspectRatio',handles.CurrentData.hdr.hdr.dime.pixdim(2:4))
else
    set(H.Axes,'DataAspectRatio',[1 1 1])
end

% Change save as NIFTI function
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
H = tool.getHandles;
S = get(H.Tools.SaveOptions,'String');
switch S{get(H.Tools.SaveOptions,'value')}
    case 'Mask'
        Mask = tool.getMask(1);
        if any(Mask(:))
        % Permute Mask
        View = get(handles.ViewPop,'String'); if ~iscell(View), View = {View}; end
        switch View{get(handles.ViewPop,'Value')}
            case 'Axial';  Mask = permute(Mask,[1 2 3 4 5]);
            case 'Coronal';  Mask = permute(Mask,[1 3 2 4 5]);
            case 'Sagittal';  Mask = permute(Mask,[3 1 2 4 5]);
        end
        
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
            Mask = tool.getMask(1);
            save(fullfile(PathName,FileName),'Mask');
        end

        else
            warndlg('Mask empty... Draw a mask using the brush tools on the right')
        end
    otherwise
        tool.saveImage;
end
