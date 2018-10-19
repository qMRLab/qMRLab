function [x,y] = pairwise_cleanup(X,Y)

% This function receives two column vectors and removes the missing values
% pairwise
%
% M C Valdes Hernandez <mvhernan@staffmail.ed.ac.uk>
% 29.10.2013

LX = length(X);
LY = length(Y);

if ~isequal(LX,LY)
    errdlg('Both vectors need to have the same length');
    exit;
end

p = isnan(X)|isnan(Y);

x = X(~any(p,2),:);
y = Y(~any(p,2),:);

end
