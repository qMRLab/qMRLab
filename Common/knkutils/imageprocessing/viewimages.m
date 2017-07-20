function fig = viewimages(im)

% function fig = viewimages(im)
% 
% <im> is a set of 2D images (res x res x images)
%
% make a figure window and show all of the images.
% return the figure number.

fig = figure; setfigurepos([50 50 500 500]);
imagesc(makeimagestack(im)); axis equal tight;
drawnow;
