function [xmin, xmax] = range_outlier(x,qt)
if nargin<2, qt=5; end
% detect outliers based on 5 times the Interquartile Range
x=x(unique(round(linspace(1,numel(x),min(5000,numel(x)))))); x(isinf(x))=[]; x(isnan(x))=[]; 
x = unique(x);
if isempty(x)
    xmin=nan; xmax=nan;
    if nargout<2
        xmin = [xmin xmax];
    end
    return;
end
% compute 25th percentile (first quartile)
Q1L = x<median(x);
if ~any(Q1L)
  Q(1)=min(x);
  else
  Q(1) = median(x(Q1L)); 
end

% compute 50th percentile (second quartile)
Q(2) = median(x);

% compute 75th percentile (third quartile)
Q3L = x>median(x);
if ~any(Q3L)
  Q(3)=max(x);
  else
  Q(3) = median(x(Q3L));

end

% compute Interquartile Range (IQR)
IQR = Q(3)-Q(1);

% determine extreme Q1 outliers (e.g., x < Q1 - 3*IQR)
xmin = max(min(x),Q(1)-qt*IQR);
xmax = min(max(x),Q(3)+qt*IQR);

if nargout<2
    xmin = [xmin xmax];
end
