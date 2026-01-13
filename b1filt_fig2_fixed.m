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

smoothingfilter_order = 6;
    
noisy_b1 = zeros(length(SNR_range), dim);
gauss_b1_1d = zeros(length(SNR_range), dim);
median_b1_1d = zeros(length(SNR_range), dim);
spline_b1_1d = zeros(length(SNR_range), dim);
poly_b1_1d = zeros(length(SNR_range), dim);

for ii=1:length(SNR_range)

    noisy_b1(ii,:) = addNoise(b1_func, SNR_range(ii));
    data.Raw = repmat(noisy_b1(ii,:), dim, 1);

    % Gaussian
    w = gausswin(2*fwhm_vox+1, 2);
    w = w/sum(w);
    
    tmp_data = [zeros(1, fwhm_vox) noisy_b1(ii,:) zeros(1, fwhm_vox)];
    
    tmp = filter(w, 1, tmp_data);
    shifted_tmp_data = [tmp(fwhm_vox+1:end) zeros(1,fwhm_vox)];
    shifted_tmp_data(1:fwhm_vox) = [];
    shifted_tmp_data(end-fwhm_vox+1:end) = [];
    gauss_b1_1d(ii,:) = shifted_tmp_data;
    
    % Median
    median_b1_1d(ii,:) = medfilt1(noisy_b1(ii,:),fwhm_vox);
    
    % Spline    
    spline_b1_1d(ii,:) = smoothn(noisy_b1(ii,:), smoothingfilter_order);
end

save("b1filt_fig2.mat", "b1_func", "noisy_b1", "gauss_b1_1d", "median_b1_1d", "spline_b1_1d", "SNR_range")
