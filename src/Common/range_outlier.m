function [xmin, xmax] = range_outlier(x,qt)
if nargin<2, qt=5; end
% detect outliers based on 5 times the Interquartile Range
x=x(:); x(isinf(x))=[]; x(isnan(x))=[]; 

% STEP 1 - rank the data
y = sort(x);

% compute 25th percentile (first quartile)
Q1L = y<median(y);
if ~any(Q1L)
  Q(1)=min(y);
  else
  Q(1) = median(y(Q1L)); 
end

% compute 50th percentile (second quartile)
Q(2) = median(y);

% compute 75th percentile (third quartile)
Q3L = y>median(y);
if ~any(Q3L)
  Q(3)=max(y);
  else
  Q(3) = median(y(Q3L));

end

% compute Interquartile Range (IQR)
IQR = Q(3)-Q(1);

% determine extreme Q1 outliers (e.g., x < Q1 - 3*IQR)
xmin = max(min(y),Q(1)-qt*IQR);
xmax = min(max(y),Q(3)+qt*IQR);

if nargout<2
    xmin = [xmin xmax];
end
