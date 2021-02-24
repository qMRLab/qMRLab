function Stats = roi_stats(FitResults, roi_mask)

% -------------------------------------------------------------------------
% Stats = roi_stats(FitResults, roi_mask)
% Returns mean, median and standard deviation of fitted parameters
% in FitResults over a region of interest defined by roi_mask
% -------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% -------------------------------------------------------------------------

fields = FitResults.fields;
ind = find(roi_mask);

for ii = 1:length(fields)
    Stats.median.(fields{ii}) = median(FitResults.(fields{ii})(ind));   
    Stats.mean.(fields{ii}) = mean(FitResults.(fields{ii})(ind));
    Stats.std.(fields{ii}) = std(FitResults.(fields{ii})(ind));
end
