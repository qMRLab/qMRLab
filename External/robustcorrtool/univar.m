function [nu,x,h,xp,yp]=univar(data)

% Computes the univariate pdf of data and the histogram values.
% Returns the frequency of data per bin (nu), the position of the bins (x) 
% and their size (h). The pdf is returned in yp for the xp values

% Cyril Pernet v1
% ---------------------------------
%  Copyright (C) Corr_toolbox 2012


mu = mean(data);
v = var(data);

% get the normal pdf for this distribution
xp = linspace(min(data),max(data));
if v <= 0
   error('Variance must be greater than zero')
   return
end
arg = ((xp-mu).^2)/(2*v);
cons = sqrt(2*pi)*sqrt(v);
yp = (1/cons)*exp(-arg);

% get histogram info using Surges' rule: 
k = round(1 + log2(length(data)));
[nu,x]=hist(data,k);
h = x(2) - x(1);
end