function imagesc3D(im,cmap,standardscore)

% function fig = viewimages(im)
%
% <im> is a set of 2D images (res x res x images)
%
% make a figure window and show all of the images.
% return the figure number.

%setfigurepos([50 50 500 500]);
if exist('standardscore','var') && standardscore
    im = reshape2D_undo(zscore(reshape2D(im,3)')',3,size(im));
end
if nargin<2 || isempty(cmap)
    imagesc(makeimagestack(squeeze(im))); axis equal tight;
elseif length(cmap)==1
    imagesc(makeimagestack(squeeze(im),cmap)); axis equal tight;
else
    imagesc(makeimagestack(squeeze(im)),cmap); axis equal tight;
end

drawnow;
