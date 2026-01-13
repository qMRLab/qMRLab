clear all
clc
close all
%%

dim = 128;
x=linspace(1,dim,dim);

signal = 1000;

PulseOpt.slope = dim/100;

b1_func = signal*fermi_pulse(x, dim, PulseOpt);

%% Add noise

SNR_range = 1:100;
noisy_b1_1d = zeros(length(SNR_range), dim);

%%

filtered_obj = filter_map();
filtered_obj.options.Smoothingfilter_Dimension = '2D';

fwhm_vox = 5;
filtered_obj.options.Smoothingfilter_sizex = fwhm_vox;
filtered_obj.options.Smoothingfilter_sizey = fwhm_vox;
filtered_obj.options.Smoothingfilter_sizez = fwhm_vox;

filtered_obj.options.Smoothingfilter_order = 6;
    
noisy_b1 = zeros(length(SNR_range), dim);
gauss_b1_1d = zeros(length(SNR_range), dim);
median_b1_1d = zeros(length(SNR_range), dim);
spline_b1_1d = zeros(length(SNR_range), dim);
poly_b1_1d = zeros(length(SNR_range), dim);

for ii=1:length(SNR_range)
    noisy_b1(ii,:) = addNoise(b1_func, SNR_range(ii));
    data.Raw = repmat(noisy_b1(ii,:), dim, 1);


    filtered_obj.options.Smoothingfilter_Type = 'gaussian';
    fit_results = filtered_obj.fit(data);
    gauss_b1_1d(ii,:) = fit_results.Filtered(1,:);


    filtered_obj.options.Smoothingfilter_Type = 'median';
    fit_results = filtered_obj.fit(data);
    median_b1_1d(ii,:) = fit_results.Filtered(1,:);
    
        
    filtered_obj.options.Smoothingfilter_Type = 'spline';
    fit_results = filtered_obj.fit(data);
    spline_b1_1d(ii,:) = fit_results.Filtered(1,:);


    filtered_obj.options.Smoothingfilter_Type = 'polynomial';
    fit_results = filtered_obj.fit(data);
    poly_b1_1d(ii,:) = fit_results.Filtered(1,:);
end

save("b1filt_fig2.mat", "b1_func", "noisy_b1", "gauss_b1_1d", "median_b1_1d", "spline_b1_1d", "poly_b1_1d", "SNR_range")
