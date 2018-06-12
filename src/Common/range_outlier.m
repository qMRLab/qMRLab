function [xmin, xmax] = range_outlier(x)
% detect outliers based on 5 times the Interquartile Range
x=x(:); x(isinf(x))=[]; x(isnan(x))=[]; 

% STEP 1 - rank the data
y = sort(x);

% compute 25th percentile (first quartile)
Q(1) = median(y(y<median(y)));

% compute 50th percentile (second quartile)
Q(2) = median(y);

% compute 75th percentile (third quartile)
Q(3) = median(y(y>median(y)));

% compute Interquartile Range (IQR)
IQR = Q(3)-Q(1);

% determine extreme Q1 outliers (e.g., x < Q1 - 3*IQR)
xmin = max(min(y),Q(1)-5*IQR);
xmax = min(max(y),Q(3)+5*IQR);
