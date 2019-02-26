function [output, output_all] =  polyfit_3D(rawmap, order, mask, bound_factor)
% [output, output_all] =  polyfit_3D(rawmap, order, mask, bound_factor)
% Polynomial fit for 3D volume
% Inputs:
%   rawmap: raw 3D maps for poly fitting (smoothing)
%   order: max order for polynomial fitting, or a list of poly orders (optional, default value 5)
%   mask: mask of the data with sufficient quality. Must be the same size as rawmap (optional, default: whole FOV)
%   bound_factor: used to define the range along X, Y, and Z dimensions, each from -bound_factor to +bound_factor (optional, default value 1)
% Outputs:
%   output: masked fitted map, i.e. output_all .* mask
%   output_all: fitted map with whole FOV range
% Created by Zhe “Tim" Wu, Dec. 15, 2018

N_raw = size(rawmap);

if length(N_raw) ~= 3
    error('Raw Maps should be 3D');
end

if nargin < 4
    bound_factor = 1;
end

if nargin < 3
    mask = ones(N_raw);
end


if nargin < 2      
    order = 5;
end

roi_idx = find(mask);
full_idx = find(ones(size(mask)));

xspace = linspace(-bound_factor, bound_factor, N_raw(2));
yspace = linspace(-bound_factor, bound_factor, N_raw(1));
zspace = linspace(-bound_factor, bound_factor, N_raw(3));

[X,Y,Z] = meshgrid(xspace, yspace, zspace);


x_cord_full = X(:);
y_cord_full = Y(:);
z_cord_full = Z(:);

rimg = rawmap(roi_idx);

% Select the data points for fitting using mask
x_cord = x_cord_full(roi_idx);
y_cord = y_cord_full(roi_idx);
z_cord = z_cord_full(roi_idx);

xAll_idx = x_cord_full;
yAll_idx = y_cord_full;
zAll_idx = z_cord_full;

if(length(order) == 1)
    order_list = [0:order];
else
    order_list = order;
end


Col = 1;
for ii = 1:length(order_list)
    for jj = 1:(length(order_list))
        for kk = 1:(length(order_list))
            Col = Col+1;
        end
    end
end


col = 1;
A = zeros(length(roi_idx), Col);

for ii = 1:length(order_list)
    for jj = 1:(length(order_list))
        for kk = 1:(length(order_list))
            x_order = order_list(ii);
            y_order = order_list(jj);
            z_order = order_list(kk);

            A(:,col) = (x_cord.^(x_order)).*(y_cord.^(y_order)).*(z_cord.^(z_order));
            col = col+1;
        end
    end
end

col = 1;
A_all = zeros(length(full_idx), Col);

for ii = 1:length(order_list)
    for jj = 1:(length(order_list))
        for kk = 1:(length(order_list))
            x_order = order_list(ii);
            y_order = order_list(jj);
            z_order = order_list(kk);

            A_all(:,col) = (xAll_idx.^(x_order)).*(yAll_idx.^(y_order)).*(zAll_idx.^(z_order));
            col = col+1;
        end
    end
end


% Least squares solution
output = zeros(N_raw);
coeffs = pinv(A'*A)*A'*rimg;

fit = A * coeffs;

output(roi_idx) = fit;


output_all = zeros(N_raw);

output_all(full_idx) = A_all * coeffs;

end