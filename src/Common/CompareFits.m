function Diff = CompareFits(FitResults1, FitResults2, Fields)

% -------------------------------------------------------------------------
% Diff = CompareFits(FitResults1, FitResults2)
% 
% Compute the difference between fitted parameter maps of two FitResults
% files and plot the results in a new figure.
% 'Fields' is a cell specifying which parameters to plot.
% If not given or empty, plot all
% -------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% -------------------------------------------------------------------------

if (~exist('Fields','var') || isempty(Fields))
    Fields = FitResults1.fields;
end

n = length(Fields);
figure();
p = 1;

for ii = 1:n
    
    map = Fields{ii};
    Diff.(map) = FitResults1.(map) - FitResults2.(map);
    MaxLim = max([max(FitResults1.(map)) max(FitResults2.(map))]);
    clim = [0 MaxLim];
    
    subplot(n,3,p);
    imagesc(FitResults1.(map));
    caxis(clim);
    title(sprintf('%s 1',map));
    axis off image;
    
    subplot(n,3,p+1);
    imagesc(FitResults2.(map));
    caxis(clim);
    title(sprintf('%s 2',map));
    axis off image;
    
    subplot(n,3,p+2);
    imagesc(abs(Diff.(map)));
    caxis(clim);
    title('|difference|');
    axis off image;
    colorbar;
    
    p = p + 3;
end
