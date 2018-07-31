function [] = plot_kspace_volumes(kspaceVolumes, scales)
%PLOT_KSPACE_VOLUMES Plot the kspace 3D volumes.
%   volumes: Cell array of volumes to plot
%   scales: Cell array of scales ([min, max]) for the image plots.
%

    for volumeIndex = 1:length(kspaceVolumes)
        figure(), subplot(1,3,1), imagesc( kspaceVolumes{volumesIndex}(:,:,1+end/2), scales{volumesIndex} ), axis square off, colormap gray
        figure(get(gcf,'Number')), subplot(1,3,2), imagesc( squeeze(kspaceVolumes{volumesIndex}(:,1+end/2,:)), scales{volumesIndex} ), axis square off, colormap gray
        figure(get(gcf,'Number')), subplot(1,3,3), imagesc( squeeze(kspaceVolumes{volumesIndex}(1+end/2,:,:)), scales{volumesIndex} ), axis square off, colormap gray
    end

end
