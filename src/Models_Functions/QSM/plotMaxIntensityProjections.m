function [] = plotMaxIntensityProjections(volumes, scales)
%PLOTMAXINTENSITYPROJECTIONS Plot the maximum intensity projections of
%3D volumes.
%   volumes: Cell array of volumes to plot
%   scales: Cell array of scales ([min, max]) for the image plots.
%
%   Code refractored from Berkin Bilgic's scripts: "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m" 
%   and "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m"
%   Original source: https://martinos.org/~berkin/software.html
%
%   Original reference:
%   Bilgic et al. (2014), Fast quantitative susceptibility mapping with 
%   L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%   72: 1444-1459. doi:10.1002/mrm.25029

    for volumeIndex = 1:length(volumes)
        figure(), subplot(1,3,1), imagesc(max(volumes{volumeIndex}, [], 3), scales{volumeIndex}), colormap gray, axis image off   
        figure(get(gcf,'Number')), subplot(1,3,2), imagesc(imrotate(squeeze(max(volumes{volumeIndex}, [], 2)), 90), scales{volumeIndex}), colormap gray, axis square off
        figure(get(gcf,'Number')), subplot(1,3,3), imagesc(imrotate(squeeze(max(volumes{volumeIndex}, [], 1)), 90), scales{volumeIndex}), colormap hot, axis square off
    end

end

