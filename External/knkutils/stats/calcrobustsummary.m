function [md,se] = calcrobustsummary(n,dim)

% function [md,se] = calcrobustsummary(n,dim)
%
% <n> is a matrix
% <dim> is a dimension along which to calculate
%
% return the median and one-half of the central
% 68% range of <n> (which is akin to a standard error).
%
% example:
% x = randn(10,10,10);
% [md,se] = calcrobustsummary(x,2);

% calculate percentiles
temp = prctile(n,[16 50 84],dim);

% compute the median and the quasi-standard error
md = slicematrix(temp,dim,2);
se = diff(slicematrix(temp,dim,[1 3]),1,dim)/2;
