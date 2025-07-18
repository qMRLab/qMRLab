function qMRshowOutput(FitResults,data,Model, compareFitResults)
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
compIm = compareFitResults.(FitResults.fields{1});
hmap = figure();


if length(size(outputIm))>2
    sz = size(outputIm);
    szz = round(sz(3)/2);
    imagesc(imrotate(outputIm(:,:,szz),90));
else
    imagesc(imrotate(outputIm,90));
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
 
    if nargin>3
        hdifmap = figure();
        difmap = double(FitResults.T2(:,:,slice)) - double(compareFitResults.T2(:,:,slice));
        imshow(imrotate(difmap,90),[]);
        title('Difference Map: (Model 1 Fit - Model 2 Fit)');
        colormap('parula');
        colorbar;
        hcompmap = figure();
        if length(size(compIm))>2
            sz = size(compIm);
            szz = round(sz(3)/2);
            imagesc(imrotate(compIm(:,:,szz),90));
        else
            imagesc(imrotate(compIm,90));
        end
    end
    
    hplot = figure();

    while 1
    voxel = [round(row), round(col), slice]; % check center voxel
    try
        FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
        if nargin >= 4
            compareFitResultVox = extractvoxel(compareFitResults,voxel,compareFitResults.fields);
        end
        dataVox         = extractvoxel(data,voxel);
    catch exception
        disp("Error: Voxel out of bounds");
    end
    % plot a cross on the map at the position of the voxel
    hold on
    cross = plot(voxel(1),voxel(2),'kx','MarkerSize',20,'LineWidth',5);
    hold off
    % move windows
    figure(hplot);
    %{
    this code messes with windows for some reason? plan to remove it
    CurrentPos = get(hplot, 'Position');
    MapPos = get(hmap, 'Position');
    MapPos(1) = max(1,MapPos(1)-round(MapPos(3)/2));
    set(hmap, 'Position', MapPos);
    NewPos = [MapPos(1)+MapPos(3), MapPos(2)+MapPos(4)-CurrentPos(4), CurrentPos(3), CurrentPos(4)];
    set(hplot, 'Position', NewPos);
    %}
    
    % plot voxel curve
    clf(hplot);
    Model.plotModel(FitResultsVox,dataVox)
    if nargin >= 4
        Model.plotModel(compareFitResultVox,dataVox);
    end
    try
        strvox = num2str(voxel);
        subtitle("Voxel: "+strvox,'FontSize',12);
    catch exception
        disp("Error: Cannot add subtitle use a newer matlab");
    end
    figure(hmap);
    [row, col] = ginput(1);
    delete(cross);
    end
end



end 