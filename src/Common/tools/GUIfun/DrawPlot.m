function DrawPlot(handles)
set(handles.SourcePop, 'Value',  1);
set(handles.ViewPop,   'Value',  1);
UpdatePopUp(handles);
Current = GetCurrent(handles);
% imagesc(flipdim(Current',1));
if isfield(handles,'tool')
    handles.tool.setImage(Current)
else
    handles.tool = imtool3D(Current,[0.12 0 .88 1],handles.FitResultsPlotPanel);
end
    
H = getHandles(handles.tool);
if isfield(handles.CurrentData,'hdr')
    set(H.Axes,'DataAspectRatio',handles.CurrentData.hdr.hdr.dime.pixdim(2:4))
end

% Change save as NIFTI function
set(H.Tools.Save,'Callback',@(hObject,evnt)saveMask(handles))
guidata(findobj('Name','qMRLab'), handles);

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
        if ext==1 % .nii.gz
            if isfield(handles.CurrentData,'hdr')
                handles.CurrentData.hdr.original.img = unxform_nii(handles.CurrentData.hdr,Mask);
                handles.CurrentData.hdr.shdr.dime.datatype=8;
                handles.CurrentData.hdr.hdr.dime.bitpix=32;
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
