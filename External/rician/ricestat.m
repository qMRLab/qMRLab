function [mu vr] = ricestat(v, s)
%RICESTAT Mean and variance of Rice/Rician probability distribution.
%   [mu vr] = ricestat(v, s) returns the mean and variance of the Rice 
%   distribution with parameters v and s.
%
%   R ~ Rice(v, s) if R = sqrt(X^2 + Y^2), where X ~ N(v*cos(a), s^2) and
%   Y ~ N(v*sin(a), s^2) are independent normal distributions (any real a).
%   Note that v and s are *not* the mean and standard deviation of R!
%
%   Reference: http://en.wikipedia.org/wiki/Rice_distribution (!)
%
%   Example:
%
%     % Compare expected and sample stats:
%     v = 5; s = 4; N = 1000;
%     r = ricernd(v*ones(1, N), s);
%     mu = mean(r), vr = var(r)
%     [Mu Vr] = ricestat(v, s)
%     % Plot histogram and mark expected mean +/- 1 stdev:
%     c = linspace(0, ceil(max(r)), 20);
%     w = c(2); % histogram bin-width
%     h = histc(r, c); bar(c, h, 'histc'); hold on
%     pk = N*w*ricepdf(Mu, v, s);
%     plot([Mu-sqrt(Vr) Mu+sqrt(Vr)], [pk pk]/2, 'ro-')
%     plot(Mu, pk/2, 'rx')
%
%   See also RICEPDF, RICERND, RICEFIT

%   Missing (?) 'See also's RICECDF, RICEINV, RICELIKE

%   Inspired by normstat from the MATLAB statistics toolbox
%   Copyright 2008 Ged Ridgway (Ged at cantab dot net)

L = Lhalf(-0.5 * v^2 / s^2);
mu = s * sqrt(pi/2) * L;
vr = 2*s^2 + v^2 - (pi * s^2 / 2) * L^2;


function l = Lhalf(x)
% Laguerre polynomial L_{1/2}(x)
% see Moments section of http://en.wikipedia.org/wiki/Rice_distribution
l = exp(x/2) * ( (1-x) * besseli(0, -x/2) - x*besseli(1, -x/2) );
