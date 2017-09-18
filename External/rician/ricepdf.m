function y = ricepdf(x, v, s)
%RICEPDF Rice/Rician probability density function (pdf).
%   y = ricepdf(x, v, s) returns the pdf of the Rice (aka Rician) 
%   distribution with parameters v and s, evaluated at the values in x.
%
%   R ~ Rice(v, s) if R = sqrt(X^2 + Y^2), where X ~ N(v*cos(a), s^2) and
%   Y ~ N(v*sin(a), s^2) are independent normal distributions (any real a).
%   Note that v and s are *not* the mean and standard deviation of R -- use
%   ricestat to get these statistics for specified v and s.
%
%   The size of Y is the common size of the input arguments.  A scalar
%   input functions as a constant matrix of the same size as the other
%   inputs.
%
%   Reference: http://en.wikipedia.org/wiki/Rice_distribution (!)
%
%   Example:
%
%     x = linspace(0, 8, 100);
%     figure; subplot(2, 1, 1)
%     plot(x, ricepdf(x, 0, 1), x, ricepdf(x, 1, 1),...
%          x, ricepdf(x, 2, 1), x, ricepdf(x, 4, 1))
%     title('Rice PDF with s=1')
%     legend('v=0', 'v=1', 'v=2', 'v=4')
%     subplot(2,1,2)
%     plot(x, ricepdf(x, 1, 0.25), x, ricepdf(x, 1, 0.50),...
%          x, ricepdf(x, 1, 1.00), x, ricepdf(x, 1, 2.00))
%     title('Rice PDF with v=1')
%     legend('s=0.25', 's=0.50', 's=1.00', 's=2.00')
%
%   See also RICERND, RICESTAT.

%   Missing (?) 'See also's RICECDF, RICEFIT, RICEINV, RICELIKE

%   Inspired by normpdf from the MATLAB statistics toolbox
%   Copyright 2008 Ged Ridgway (Ged at cantab dot net)

s2 = s.^2; % (neater below)

try
    y = (x ./ s2) .*...
        exp(-0.5 * (x.^2 + v.^2) ./ s2) .*...
        besseli(0, x .* v ./ s2);
        % besseli(0, ...) is the zeroth order modified Bessel function of
        % the first kind. (see help bessel)
    y(x <= 0) = 0;
catch
    error('ricepdf:InputSizeMismatch',...
        'Non-scalar arguments must match in size.');
end
