function [] = plot_max_intensity_projections(volumes, scales)
%PLOT_MAX_INTENSITY_PROJECTIONS Plot the maximum intensity projections of
%3D volumes.
%   volumes: Cell array of volumes to plot
%   scales: Cell array of scales ([min, max]) for the image plots.
%

    for volumeIndex = 1:length(volumes)
        figure(), subplot(1,3,1), imagesc(max(volumes{volumesIndex}, [], 3), scales{volumesIndex}), colormap gray, axis image off   
        figure(get(gcf,'Number')), subplot(1,3,2), imagesc(imrotate(squeeze(max(volumes{volumesIndex}, [], 2)), 90), scales{volumesIndex}), colormap gray, axis square off
        figure(get(gcf,'Number')), subplot(1,3,3), imagesc(imrotate(squeeze(max(volumes{volumesIndex}, [], 1)), 90), scales{volumesIndex}), colormap hot, axis square off
    end

end

