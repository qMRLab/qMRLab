function [v s] = ricefit(mudat, vr)
%RICEFIT Estimate parameters for Rice/Rician distribution from data.
%   Uses simple moment-matching approach, with numerical optimisation.
%   [v s] = ricefit(dat) estimates v and s from samples in dat
%   [v s] = ricefit(mu, vr) estimates v and s from given mean and variance
%
%   R ~ Rice(v, s) if R = sqrt(X^2 + Y^2), where X ~ N(v*cos(a), s^2) and
%   Y ~ N(v*sin(a), s^2) are independent normal distributions (any real a).
%   Note that v and s are *not* the mean and standard deviation of R!
%
%   Reference: http://en.wikipedia.org/wiki/Rice_distribution (!)
%
%   Example:
%     % Sample data, fit model, compare expected, fitted & observed moments
%     V = 5; S = 4; N = 1000;
%     [MN VR] = ricestat(V, S)      % expected mean and variance
%     r = ricernd(V*ones(1, N), S);
%     [v s] = ricefit(dat)          % fitted Rician distribution parameters
%     [mn vr] = ricestat(v, s)      % fitted mean and variance
%     mean(dat), var(dat)           % observed mean and variance
%
%   See also RICEPDF, RICERND, RICESTAT

%   Missing (?) 'See also's RICECDF, RICEINV, RICELIKE

%   Inspired by normfit from the MATLAB statistics toolbox
%   Copyright 2008 Ged Ridgway (Ged at cantab dot net)

if nargin == 1
    dat = mudat;
    mu = mean(dat(:));
    vr = var(dat(:));
else
    mu = mudat;
end

% Optimise cost based on difference of mu and vr from ricestat(v, s) as a 
% function of v and s, using mu and sqrt(vr) as initial values for v and s
cost = @(x) moment_cost(x(1), x(2), mu, vr);
x = fminsearch(cost, [mu sqrt(vr)]);
if nargout == 1
    v = x;
else
    v = x(1);
    s = x(2);
end

function cost = moment_cost(v, s, MU, VR)
% Very naive approach...
% Not clear how to wait relative errors in mean and variance...
[mu vr] = ricestat(v, s);
cost = norm([mu - MU; vr - VR;]);
