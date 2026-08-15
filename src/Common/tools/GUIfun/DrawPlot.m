function DrawPlot(app,CurrentName)
% DrawPlot  Push CurrentData into the viewer and refresh the Volume list.
%
%   Stage F1: takes the app rather than a `handles` struct.
%
%   The old last line was
%       guidata(findobj('Name','qMRLab'), handles);
%   which is what made this function the COMMIT POINT for anything an outside
%   caller had written into its copy -- BrowserSet in particular. That is gone:
%   BrowserSet now writes app.CurrentData directly, before calling in, so the
%   data is live from the moment it is set rather than from whenever this
%   function happens to reach its last line.
%
%   Worth being clear that this is a fix, not a regression. tool.setImage below
%   runs BEFORE the two places this function can throw, so on failure the viewer
%   already showed the NEW data while guidata still held the OLD CurrentData.
%   The late commit manufactured that divergence rather than preventing it.
% Resolve WHICH volume should end up selected, but do not assign it yet.
% UpdatePopUp below rewrites SourcePop's list, and a selection assigned against
% the OLD list is exactly what makes that rewrite throw -- see setPopUp. Loading
% a second, smaller dataset was the case that died.
if ~exist('CurrentName','var') || strcmp(CurrentName,'Mask')
    wantVol = 1;
else
    wantVol = find(strcmp(app.CurrentData.fields,CurrentName));
end


Data = app.CurrentData;
if isfield(Data,'Mask'), Mask = Data.Mask; Data.fields(strcmp(Data.fields,'Mask'))=[]; else Mask = []; end
if ~isempty(Data.fields)
    for ff = 1:length(Data.fields)
        Current{ff} = Data.(Data.fields{ff});
    end
else
    Current{1} = Mask;
end
app.Tool.setImage(Current,[],[],[],[],Mask);
UpdatePopUp(app);

% Safe now: the list is current.
setPopUp(app.SourcePop, app.SourcePop.Items, wantVol);

% Set Volume Number
if exist('CurrentName','var')
    if strcmp(CurrentName,'Mask')
        setNvol(app.Tool,1)
    else
        setNvol(app.Tool,find(strcmp(app.CurrentData.fields,CurrentName)))
    end
end
% Set Slice Number
app.Tool.setCurrentSlice(round(size(Current{1},3)/2))

% Set Pixel size
if isfield(app.CurrentData, 'hdr')
    hdr = app.CurrentData.hdr;
    if isfield(hdr, 'pixdim') && numel(hdr.pixdim) >= 4
        % For NIfTI files
        app.Tool.setAspectRatio(hdr.pixdim(2:4));
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

        app.Tool.setAspectRatio(steps);
    else
        app.Tool.setAspectRatio([1 1 1]);
    end
else
    % Fallback in case no header exists
    app.Tool.setAspectRatio([1 1 1]);
end

% Change save as NIFTI function
H = app.Tool.getHandles;
if isfield(app.CurrentData,'hdr'), hdr = {app.CurrentData.hdr}; else, hdr = {}; end
set(H.Tools.maskSave,'Callback',@(hObject,evnt)saveMask(app.Tool,hObject,hdr{:}))
set(H.Tools.maskLoad,'Callback',@(hObject,evnt)loadMask(app.Tool,hObject,hdr{:}))

% Use Shortcut to Source button.
% Closes over the app, not over a snapshot struct, and addresses the window
% directly instead of searching the root for one called 'qMRLab'.
app.qMRILab.WindowKeyPressFcn = @(hobject, event) shortcutCallback(hobject, event, app);

function shortcutCallback(hobject, event, app)
switch event.Key
    case 'uparrow'
        setNvol(app.Tool,app.Tool.getNvol-1)
        setPopUp(app.SourcePop, app.SourcePop.Items, app.Tool.getNvol);
    case 'downarrow'
        setNvol(app.Tool,app.Tool.getNvol+1)
        setPopUp(app.SourcePop, app.SourcePop.Items, app.Tool.getNvol);
    otherwise
        app.Tool.shortcutCallback(event)
end