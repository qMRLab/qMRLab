function r = ricernd(v, s)
%RICERND Random samples from the Rice/Rician probability distribution.
%   r = ricernd(v, s) returns random sample(s) from the Rice (aka Rician) 
%   distribution with parameters v and s.
%   (either v or s may be arrays, if both are, they must match in size)
%
%   R ~ Rice(v, s) if R = sqrt(X^2 + Y^2), where X ~ N(v*cos(a), s^2) and
%   Y ~ N(v*sin(a), s^2) are independent normal distributions (any real a).
%   Note that v and s are *not* the mean and standard deviation of R!
%
%   The size of Y is the common size of the input arguments.  A scalar
%   input functions as a constant matrix of the same size as the other
%   inputs.
%
%   Note, to add Rician noise to data, with given s and data-dependent v:
%     new = ricernd(old, s);
%
%   Reference: http://en.wikipedia.org/wiki/Rice_distribution (!)
%
%   Example:
%
%     % Compare histogram of random samples with theoretical PDF:
%     v = 4; s = 3; N = 1000;
%     r = ricernd(v*ones(1, N), s);
%     c = linspace(0, ceil(max(r)), 20);
%     w = c(2); % histogram bin-width
%     h = histc(r, c); bar(c, h, 'histc'); hold on
%     xl = xlim; x = linspace(xl(1), xl(2), 100);
%     plot(x, N*w*ricepdf(x, v, s), 'r');
%     
%   See also RICEPDF, RICESTAT, RICEFIT

%   Missing (?) 'See also's RICECDF, RICEINV, RICELIKE

%   Inspired by normpdf from the MATLAB statistics toolbox
%   Copyright 2008 Ged Ridgway (Ged at cantab dot net)

if isscalar(v)
    dim = size(s);
elseif isscalar(s)
    dim = size(v);
elseif all(isequal(size(v), size(s)))
    % (both non-scalar, matching)
    dim = size(v); % == size(s)
else
    error('ricernd:InputSizeMismatch','Sizes of s and v inconsistent.')
end

x = s .* randn(dim) + v;
y = s .* randn(dim);
r = sqrt(x.^2 + y.^2);
