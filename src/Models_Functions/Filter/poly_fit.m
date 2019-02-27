function [out] =  poly_fit(data, order, mask)
%% Fit polynomials to a surface
%
% data = 2D data
% oder = maximum order or list of orders to fit to
% mask = ROI in which the fit makes sense (don't want to fit noise)
%%%%%%%%%%%%%%%%%%
% Adapted from poly_sensitivty_fit.m

N = size(data);
if nargin < 3
    mask = ones(N);
end

[x,y] = meshgrid( linspace(-1,1,N(2)), linspace(-1,1,N(1)) );

v_idx = find(mask);

img = data(v_idx);

x_all_idx = x(1:end)';
y_all_idx = y(1:end)';
x_idx = x_all_idx(v_idx);
y_idx = y_all_idx(v_idx);

% List of all the orders
if(max(size(order))==1)
    order_list = [0:order];
else
    order_list = order;
end


% Combination of all orders
Col = 1;
for ii = 1:length(order_list)
    for jj = 1:length(order_list)
        Col = Col+1;
    end
end

% Regressors
col = 1;
A = zeros(length(v_idx), Col);

for ii = 1:length(order_list)
    for jj = 1:length(order_list)
        x_order = order_list(ii);
        y_order = order_list(jj);

        A(:,col) = (x_idx.^(x_order)).*(y_idx.^(y_order));
        col = col+1;
    end
end

% least squares solution
out = zeros(N);
coeffs = (pinv(A'*A)*A'*img);

fit = A * coeffs;
out(v_idx) = fit;
