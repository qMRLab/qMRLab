clear all
clc
close all
%%

dim = 128;
x=linspace(1,dim,dim);

signal = 1000;

PulseOpt.slope = dim/100;

b1_func = signal*fermi_pulse(x, dim, PulseOpt);

%%

vox_range = 1:10;

gauss_b1_1d = zeros(length(vox_range), dim);
median_b1_1d = zeros(length(vox_range), dim);
spline_b1_1d = zeros(length(vox_range), dim);

for ii=1:length(vox_range)

    % Gaussian
    w = gausswin(2*vox_range(ii)+1, 2);
    w = w/sum(w);
    
    tmp_data = [zeros(1, vox_range(ii)) b1_func zeros(1, vox_range(ii))];
    
    tmp = filter(w, 1, tmp_data);
    shifted_tmp_data = [tmp(vox_range(ii)+1:end) zeros(1,vox_range(ii))];
    shifted_tmp_data(1:vox_range(ii)) = [];
    shifted_tmp_data(end-vox_range(ii)+1:end) = [];
    gauss_b1_1d(ii,:) = shifted_tmp_data;
    
    % Median
    median_b1_1d(ii,:) = medfilt1(b1_func,vox_range(ii));
    
    % Spline    
    spline_b1_1d(ii,:) = smoothn(b1_func, vox_range(ii));
end

save("b1filt_fig1.mat", "b1_func", "gauss_b1_1d", "median_b1_1d", "spline_b1_1d", "vox_range")
