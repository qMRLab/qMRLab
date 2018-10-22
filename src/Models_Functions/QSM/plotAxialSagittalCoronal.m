function [  ] = plotAxialSagittalCoronal( vol, scale_fig, title_fig )
%PLOTAXIALSAGITTALCORONAL Summary of this function goes here
%
%   Code refractored from Berkin Bilgic's scripts: "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m" 
%   and "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m"
%   Original source: https://martinos.org/~berkin/software.html
%
%   Original reference:
%   Bilgic et al. (2014), Fast quantitative susceptibility mapping with 
%   L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%   72: 1444-1459. doi:10.1002/mrm.25029
im_size = round(size(vol)/2);

figure(), subplot(1,3,1), imagesc( vol(:,:,im_size(3)), scale_fig  ), axis square off, colormap gray, axis image
figure(get(gcf,'Number')), subplot(1,3,3), imagesc( imrotate(squeeze(vol(:,im_size(2),:)),90), scale_fig  ), axis square off, colormap gray, axis image
figure(get(gcf,'Number')), subplot(1,3,2), imagesc( imrotate(squeeze(vol(im_size(1),:,:)),90), scale_fig  ), axis square off, colormap gray, axis image

if nargin == 3
    title(title_fig)
end

drawnow

end

