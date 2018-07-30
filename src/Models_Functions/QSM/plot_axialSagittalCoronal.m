function [  ] = plot_axialSagittalCoronal( vol, scale_fig, title_fig )
%PLOT_AXIALSAGITTALCORONAL Summary of this function goes here
%   Detailed explanation goes here

im_size = round(size(vol)/2);

figure(), subplot(1,3,1), imagesc( vol(:,:,im_size(3)), scale_fig  ), axis square off, colormap gray, axis image
figure(get(gcf,'Number')), subplot(1,3,3), imagesc( imrotate(squeeze(vol(:,im_size(2),:)),90), scale_fig  ), axis square off, colormap gray, axis image
figure(get(gcf,'Number')), subplot(1,3,2), imagesc( imrotate(squeeze(vol(im_size(1),:,:)),90), scale_fig  ), axis square off, colormap gray, axis image

if nargin == 3
    title(title_fig)
end

drawnow

end

