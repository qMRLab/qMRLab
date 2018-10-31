function [p,S,mu] = polyfitZero(x,y,degree)
% POLYFITZERO Fit polynomial to data, forcing y-intercept to zero.
%   P = POLYFITZERO(X,Y,N) is similar POLYFIT(X,Y,N) except that the
%   y-intercept is forced to zero, i.e. P(N) = 0. In the same way as
%   POLYFIT, the coefficients, P(1:N-1), fit the data Y best in the least-
%   squares sense. You can also use Y = POLYVAL(PZERO,X) to evaluate the
%   polynomial because the output is the same as POLYFIT.
%
%   [P,S,MU] = POLYFITZERO() Return structure, S, similar to POLYFIT for use
%   with POLYVAL to calculate error estimates of predictions with P.
%
%   [P,S,MU] = POLYFITZERO() Scale X by std(X), returns MU = [0,std(X)].
%
%   See also POLYVAL, POLYFIT
%
%   Also see <a href="http://www.mathworks.com/matlabcentral/fileexchange/34765-polyfitn">POLYFITN by John D'Errico</a>
%

% Copyright (c) 2013 Mark Mikofski
% Version 1-1, 2013-10-15
%   add delta output
%   center and scale
% Version 1-0, 2011-06-29

%% check args
% X & Y should be numbers
assert(isnumeric(x) && isnumeric(y),'polyfitZero:notNumeric', ...
    'X and Y must be numeric.')
dim = numel(x); % number of elements in X
% DEGREE should be scalar positive number between 1 & 10 inclusive
assert(isnumeric(degree) && isscalar(degree) && degree>0 && degree<=10, ...
    'polyfitZero:degreeOutOfRange', ...
    'DEGREE must be an integer between 1 and 10.')
% DEGREE must be less than number of elements in X & Y
assert(degree<dim && degree==round(degree), ...
    'polyfitZero:DegreeGreaterThanDim', 'DEGREE must be less than numel(X)')
% X & Y should be same size vectors
assert(isvector(x) && isvector(y) && dim==numel(y), ...
    'polyfitZero:vectorMismatch', 'X and Y must be vectors of the same length.')
%% solve
% convert X & Y to column vectors
x = x(:); y = y(:);
% Scale X.
% attribution: this is based on code from POLYFIT by The MathWorks Inc.
if nargout > 2
   mu = [0; std(x)];
   x = (x - mu(1))/mu(2);
end
% using pow() is actually as fast or faster than looping, same # of flops!
z = zeros(dim,degree);
for n = 1:degree
    z(:,n) = x.^(degree-n+1);
end
p = z\y; % solve
p = [p;0]; % set y-intercept to zero
%% error estimates
% attribution: this is based on code from POLYFIT by The MathWorks Inc.
if nargout > 1
    V = [z,ones(dim,1)]; % append constant term for Vandermonde matrix
    % Return upper-triangular factor of QR-decomposition for error estimates
    R = triu(qr(V,0));
    r = y - V*p;
    S.R = R(1:size(R,2),:);
    S.df = max(0,length(y) - (degree+1));
    S.normr = norm(r);
end
p = p'; % polynomial output is row vector by convention
end
