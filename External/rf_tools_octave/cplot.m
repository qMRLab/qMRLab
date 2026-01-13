%
% cplot(x) - plot complex function;
%

%  written by John Pauly, 1989
%  (c) Board of Trustees, Leland Stanford Junior University

function  cplot(x)

l = length(x);
t = [1:l]/(l+1);
plot(t,real(x),t,imag(x));




