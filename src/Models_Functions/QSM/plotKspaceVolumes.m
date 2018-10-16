function [] = plotKspaceVolumes(kspaceVolumes, scales)
%PLOTKSPACEVOLUMES Plot the kspace 3D volumes.
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

    for volumeIndex = 1:length(kspaceVolumes)
        figure(), subplot(1,3,1), imagesc( kspaceVolumes{volumeIndex}(:,:,1+end/2), scales{volumeIndex} ), axis square off, colormap gray
        figure(get(gcf,'Number')), subplot(1,3,2), imagesc( squeeze(kspaceVolumes{volumeIndex}(:,1+end/2,:)), scales{volumeIndex} ), axis square off, colormap gray
        figure(get(gcf,'Number')), subplot(1,3,3), imagesc( squeeze(kspaceVolumes{volumeIndex}(1+end/2,:,:)), scales{volumeIndex} ), axis square off, colormap gray
    end

end
