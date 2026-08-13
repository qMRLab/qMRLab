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
    nRows = size(outputIm,1);
    nCols = size(outputIm,2);
    row   = round(nRows/1.7);
    col   = round(nCols/1.7);
    slice = round(size(outputIm,3)/2);

    compareMode = nargin > 3;

    if compareMode
        figure();
        difmap = double(FitResults.T2(:,:,slice)) - double(compareFitResults.T2(:,:,slice));
        imshow(imrotate(difmap,90),[]);
        title('Difference Map: (Model 1 Fit - Model 2 Fit)');
        colormap('parula');
        colorbar;
    end

    hplot = figure();

    % ginput needs a human, so batch and CI callers show the centre voxel once.
    interactive = usejava('desktop') && isempty(getenv('ISCITEST'));

    while true
        voxel = [row, col, slice];
        FitResultsVox = extractvoxel(FitResults,voxel,FitResults.fields);
        dataVox       = extractvoxel(data,voxel);

        figure(hmap);
        hold on
        % the map is drawn rotated 90 deg, so data (row,col) is at (row, nCols-col+1)
        cross = plot(row, nCols-col+1,'kx','MarkerSize',20,'LineWidth',5);
        hold off

        figure(hplot);
        clf(hplot);
        Model.plotModel(FitResultsVox,dataVox)
        if compareMode
            Model.plotModel(extractvoxel(compareFitResults,voxel,compareFitResults.fields),dataVox);
        end
        if ~isempty(which('subtitle'))
            subtitle(['Voxel: ' num2str(voxel)],'FontSize',12);
        end

        if ~interactive
            break
        end

        figure(hmap);
        try
            [x, y] = ginput(1);
        catch
            break   % ginput errors rather than returning if the map is closed
        end
        if isempty(x) || ~ishandle(hmap) || ~ishandle(hplot)
            break
        end
        delete(cross);
        row = min(max(round(x),1), nRows);
        col = min(max(nCols-round(y)+1,1), nCols);
    end
end



end 