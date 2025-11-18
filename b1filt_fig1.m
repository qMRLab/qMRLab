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

filtered_obj = filter_map();
filtered_obj.options.Smoothingfilter_Dimension = '2D';
data.Raw = repmat(b1_func, dim, 1);

vox_range = 1:25;

gauss_b1_1d = zeros(length(vox_range), dim);
median_b1_1d = zeros(length(vox_range), dim);

for ii=1:length(vox_range)
    fwhm_vox = vox_range(ii);

    filtered_obj.options.Smoothingfilter_sizex = fwhm_vox;
    filtered_obj.options.Smoothingfilter_sizey = fwhm_vox;
    filtered_obj.options.Smoothingfilter_sizez = fwhm_vox;
    
    filtered_obj.options.Smoothingfilter_Type = 'gaussian';
    fit_results = filtered_obj.fit(data);
    gauss_b1_1d(ii,:) = fit_results.Filtered(1,:);


    filtered_obj.options.Smoothingfilter_Type = 'median';
    fit_results = filtered_obj.fit(data);
    median_b1_1d(ii,:) = fit_results.Filtered(1,:);
end


order_range = 1:25;

spline_b1_1d = zeros(length(order_range), dim);
poly_b1_1d = zeros(length(order_range), dim);


for ii=1:length(order_range)
    filtered_obj.options.Smoothingfilter_order = order_range(ii);
    
    filtered_obj.options.Smoothingfilter_Type = 'spline';
    fit_results = filtered_obj.fit(data);
    spline_b1_1d(ii,:) = fit_results.Filtered(1,:);


    filtered_obj.options.Smoothingfilter_Type = 'polynomial';
    fit_results = filtered_obj.fit(data);
    poly_b1_1d(ii,:) = fit_results.Filtered(1,:);
end

save("b1filt_fig1.mat", "b1_func", "gauss_b1_1d", "median_b1_1d", "spline_b1_1d", "poly_b1_1d", "vox_range", "order_range")
