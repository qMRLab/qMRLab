clear all
clc
close all
%%

dim = 128;
x=linspace(1,dim,dim);

signal = 1000;

PulseOpt.slope = dim/100;

b1_func = signal*fermi_pulse(x, dim, PulseOpt);

%% Add comb

factor = 1.25;
seperation = 8;
delta_b1 = b1_func;

for ii=1:16
    delta_b1(4+(ii-1)*seperation)=delta_b1(4+(ii-1)*seperation)*factor;
end
%%

filtered_obj = filter_map();
filtered_obj.options.Smoothingfilter_Dimension = '2D';

fwhm_vox = 5;
filtered_obj.options.Smoothingfilter_sizex = fwhm_vox;
filtered_obj.options.Smoothingfilter_sizey = fwhm_vox;
filtered_obj.options.Smoothingfilter_sizez = fwhm_vox;

smoothingfilter_order = 6;

vox_range = 1:10;

gauss_b1_1d = zeros(length(vox_range), dim);
median_b1_1d = zeros(length(vox_range), dim);
spline_b1_1d = zeros(length(vox_range), dim);

for ii=1:length(vox_range)

    % Gaussian
    w = gausswin(2*vox_range(ii)+1, 2);
    w = w/sum(w);
    
    tmp_data = [zeros(1, vox_range(ii)) delta_b1 zeros(1, vox_range(ii))];
    
    tmp = filter(w, 1, tmp_data);
    shifted_tmp_data = [tmp(vox_range(ii)+1:end) zeros(1,vox_range(ii))];
    shifted_tmp_data(1:vox_range(ii)) = [];
    shifted_tmp_data(end-vox_range(ii)+1:end) = [];
    gauss_b1_1d(ii,:) = shifted_tmp_data;
    
    % Median
    median_b1_1d(ii,:) = medfilt1(delta_b1,vox_range(ii));
    
    % Spline    
    spline_b1_1d(ii,:) = smoothn(delta_b1, vox_range(ii));
end

save("b1filt_fig5.mat", "b1_func", "delta_b1", "gauss_b1_1d", "median_b1_1d", "spline_b1_1d", "vox_range")
