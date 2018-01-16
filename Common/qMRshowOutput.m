function qMRshowOutput(FitResults,data,Model)
% Show mid-slice fitting maps
% Also show a fit in the center voxel

outputIm = FitResults.(FitResults.fields{1});
hmap = figure();


if length(size(outputIm))>2
    sz = size(outputIm);
    szz = round(sz(3)/2);
    imagesc(imrotate(outputIm(:,:,szz),90)); colormap('jet');  title(FitResults.fields{1});
else
    imagesc(imrotate(outputIm,90)); colormap('jet');  title(FitResults.fields{1});
end
climm = prctile(outputIm(outputIm~=0),10);
climM = prctile(outputIm(outputIm~=0),90);
caxis([climm max(climm*1.01,climM)]); colorbar();

if FitResults.Model.voxelwise 
    
    row = round(size(outputIm,1)/2);
    col = round(size(outputIm,2)/2);
    slice = round(size(outputIm,3)/2);
 
    voxel = [row, col, slice]; % check center voxel
    FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
    dataVox         = extractvoxel(data,voxel);
    
    % plot a cross on the map at the position of the voxel
    hold on
    plot(voxel(1),voxel(2),'kx','MarkerSize',20,'LineWidth',5)
    hold off
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
    
end



end 