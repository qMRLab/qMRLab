function y = demean(x)

% simple routine to removes the mean value from the vector X
% or the mean value from each column, if X is a matrix.
%
% Cyril Pernet
% ---------------------------------
%  Copyright (C) Corr_toolbox 2014

n = size(x,1);
if n == 1,
  x = x(:);	% If a single row, turn into column vector
end
N = size(x,1);
y = x - ones(N,1)*nanmean(x);