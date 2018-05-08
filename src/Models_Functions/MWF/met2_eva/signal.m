function s = signal(params, times)
% signal equation for simple T2 decay
%
% t2 = params(1)
% s0 = params(2)

s = params(2)*exp(-times/params(1));

