close all
clear all
clc 

filter_size = {'low','medium','high'}

da_data.Raw = load_nii_data('data/b1_clt_tse.nii.gz');
afi_data.Raw = load_nii_data('data/b1_clt_afi.nii.gz');
bs_data.Raw = load_nii_data('data/b1_clt_gre_bs_cr_fermi.nii.gz');

mask = load_nii_data('data/brain_mask_es_2x2x5.nii.gz');

% Median
MedianFilter = filter_map;

MedianFilter.options.Smoothingfilter_Type = 'median';
MedianFilter.options.Smoothingfilter_Dimension = '2D';

median_smoothing_factors = [3,5,9];

% Gaussian

GaussianFilter = filter_map;
GaussianFilter.options.Smoothingfilter_Type = 'gaussian';
GaussianFilter.options.Smoothingfilter_Dimension = '2D';

gaussian_smoothing_factors = [2,4,6];

% Spline

SplineSmoothing = filter_map;
SplineSmoothing.options.Smoothingfilter_Type = 'spline';
SplineSmoothing.options.Smoothingfilter_Dimension = '2D';

spline_smoothing_factors = [0.1,1,10];


for ii=1:3
    
    % Median
    
    MedianFilter.options.Smoothingfilter_sizex = median_smoothing_factors(ii);
    MedianFilter.options.Smoothingfilter_sizey = median_smoothing_factors(ii);
    MedianFilter.options.Smoothingfilter_sizez = median_smoothing_factors(ii);
    
    FitResults = FitData(da_data, MedianFilter);
    da_data.('median_' + string(filter_size(ii))) = FitResults.Filtered;
    
    FitResults = FitData(afi_data, MedianFilter);
    afi_data.('median_' + string(filter_size(ii))) = FitResults.Filtered;
    
    FitResults = FitData(bs_data, MedianFilter);
    bs_data.('median_' + string(filter_size(ii))) = FitResults.Filtered;
        
    % Gaussian
    GaussianFilter.options.Smoothingfilter_sizex = gaussian_smoothing_factors(ii);
    GaussianFilter.options.Smoothingfilter_sizey = gaussian_smoothing_factors(ii);
    GaussianFilter.options.Smoothingfilter_sizez = gaussian_smoothing_factors(ii);
    
    FitResults = FitData(da_data, GaussianFilter);
    da_data.('gaussian_' + string(filter_size(ii))) = FitResults.Filtered;

    FitResults = FitData(afi_data, GaussianFilter);
    afi_data.('gaussian_' + string(filter_size(ii))) = FitResults.Filtered;
    
    FitResults = FitData(bs_data, GaussianFilter);
    bs_data.('gaussian_' + string(filter_size(ii))) = FitResults.Filtered;
        
    % Spline    
    SplineSmoothing.options.Smoothingfilter_order = spline_smoothing_factors(ii);
    
    FitResults = FitData(da_data, SplineSmoothing);
    da_data.('spline_' + string(filter_size(ii))) = FitResults.Filtered;
    
    FitResults = FitData(afi_data, SplineSmoothing);
    afi_data.('spline_' + string(filter_size(ii))) = FitResults.Filtered;
    
    FitResults = FitData(bs_data, SplineSmoothing);
    bs_data.('spline_' + string(filter_size(ii))) = FitResults.Filtered;
        
end

save("b1filt_fig6.mat", "da_data", "afi_data", "bs_data", "mask", "median_smoothing_factors", "gaussian_smoothing_factors", "spline_smoothing_factors")

