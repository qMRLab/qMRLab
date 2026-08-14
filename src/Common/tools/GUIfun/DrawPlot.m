function DrawPlot(handles,CurrentName)
% Resolve WHICH volume should end up selected, but do not assign it yet.
% UpdatePopUp below rewrites SourcePop's list, and a selection assigned against
% the OLD list is exactly what makes that rewrite throw -- see setPopUp. Loading
% a second, smaller dataset was the case that died.
if ~exist('CurrentName','var') || strcmp(CurrentName,'Mask')
    wantVol = 1;
else
    wantVol = find(strcmp(handles.CurrentData.fields,CurrentName));
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

% Safe now: the list is current.
setPopUp(handles.SourcePop, get(handles.SourcePop,'String'), wantVol);

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
if isfield(handles.CurrentData, 'hdr')
    hdr = handles.CurrentData.hdr;
    if isfield(hdr, 'pixdim') && numel(hdr.pixdim) >= 4
        % For NIfTI files
        handles.tool.setAspectRatio(hdr.pixdim(2:4));
    elseif isfield(hdr,'details') && isfield(hdr.details,'variables') ...
            && numel(hdr.details.variables) >= 3
        % For MINC files: voxel size is the 'step' attribute of each of the
        % first three dimension variables. Steps are signed (they encode
        % direction), but DataAspectRatio only accepts positive values.
        steps = ones(1, 3);  % Default aspect ratio

        for i = 1:3
            vari = hdr.details.variables(i);
            step_idx = find(strcmp(vari.attributes, 'step'));
            if ~isempty(step_idx)
                steps(i) = abs(vari.values{step_idx});
            end
        end
        steps(steps == 0) = 1;

        handles.tool.setAspectRatio(steps);
    else
        handles.tool.setAspectRatio([1 1 1]);
    end
else
    % Fallback in case no header exists
    handles.tool.setAspectRatio([1 1 1]);
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
        setPopUp(handles.SourcePop, get(handles.SourcePop,'String'), handles.tool.getNvol);
    case 'downarrow'
        setNvol(handles.tool,handles.tool.getNvol+1)   
        setPopUp(handles.SourcePop, get(handles.SourcePop,'String'), handles.tool.getNvol);
    otherwise
        handles.tool.shortcutCallback(event)
end