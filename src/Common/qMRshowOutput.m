function qMRshowOutput(FitResults,data,Model)
% qMRshowOutput   Show mid-slice fitting maps
%                 Also show a fit in an off-center voxel to avoid central sulcus in brain
%                 images
%
% Example:
%   Model = noddi;
%   %% LOAD DATA
%   data.DiffusionData = load_nii_data('DiffusionData.nii.gz');
%   data.Mask = load_nii_data('Mask.nii.gz');
%   %% FIT
%   FitResults = FitData(data,Model);
%   %% DISPLAY
%   qMRshowOutput(FitResults,data,Model)

if nargin<3, help('qMRshowOutput'); return; end

outputIm = FitResults.(FitResults.fields{1});
hmap = figure();
hmap_axis = gca;

if length(size(outputIm))>2
    sz = size(outputIm);
    szz = round(sz(3)/2);
    himg = imagesc(hmap_axis,imrotate(outputIm(:,:,szz),90));
else
    himg = imagesc(hmap_axis, imrotate(outputIm,90));
end
title(FitResults.fields{1});
if moxunit_util_platform_is_octave
    colormap('viridis')
else
    colormap('parula')
end
axis image
[climm, climM] = range_outlier(outputIm(outputIm~=0),.5);
caxis([climm max(climm*1.01,climM)]); colorbar();

if FitResults.Model.voxelwise
    row = round(size(outputIm,1)/1.7);
    col = round(size(outputIm,2)/1.7);
    slice = round(size(outputIm,3)/2);
 
    voxel = [row, col, slice]; % check center voxel
    FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
    dataVox         = extractvoxel(data,voxel);
    
    % plot a cross on the map at the position of the voxel
    hold(hmap_axis, 'on')
    cross_plot = plot(voxel(1),voxel(2),'kx','MarkerSize',20,'LineWidth',5)
    hold(hmap_axis, 'off')
    % move windows
    hplot = figure();
    CurrentPos = get(hplot, 'Position');
    MapPos = get(hmap, 'Position');
    MapPos(1) = max(1,MapPos(1)-round(MapPos(3)/2));
    set(hmap, 'Position', MapPos);
    NewPos = [MapPos(1)+MapPos(3), MapPos(2)+MapPos(4)-CurrentPos(4), CurrentPos(3), CurrentPos(4)];
    set(hplot, 'Position', NewPos);
    
    % plot voxel curve
    Model.plotModel(FitResultsVox,dataVox)
    set(himg, 'ButtonDownFcn', @voxelClickCallback);
    disp("Finished!");
end

function voxelClickCallback(src, event)
    disp("click callback called");
    coords = round(get(hmap_axis, 'CurrentPoint'));
    
    % NOTE: The mapping from clicked (X,Y) to matrix (row,col) depends on
    % the imrotate(..., 90). The new X is the old row, new Y is old (max_col - col).
    % The line below swaps X/Y which is often correct for image display.
    % You may need to adjust this based on your specific image orientation.
    clickedVoxel = [coords(1,2), coords(1,1), slice];

    % Ensure the voxel is within the image bounds
    if all(clickedVoxel > 0) && clickedVoxel(1) <= size(outputIm, 1) && clickedVoxel(2) <= size(outputIm, 2)
        FitResultsVox = extractvoxel(FitResults, clickedVoxel, FitResults.fields);
        dataVox = extractvoxel(data, clickedVoxel);
        
        % Plot the new voxel curve in the plot figure
        % Use the plot figure's handle 'hplot' and clear it first
        figure(hplot);
        cla;
        Model.plotModel(FitResultsVox, dataVox);
        
        % --- Update the cross position on the map ---
        % This is better than replotting, as it just moves the existing object
        set(cross_plot, 'XData', clickedVoxel(2), 'YData', clickedVoxel(1));

        drawnow; % Ensure plots update immedia
    end
end

end
