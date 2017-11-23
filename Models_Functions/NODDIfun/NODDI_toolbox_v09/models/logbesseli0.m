% Computes log(besseli(0,x)) robustly.  Computing it directly causes
% numerical problems at high x, but the function has asymptotic linear
% behaviour, which we approximate here for high x.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%

function lb0 = logbesseli0(x)

% For very large arguments to besseli, we approximate log besseli using a
% linear model of the asymptotic behaviour.
% The linear parameters come from this command:
% app=regress(log(besseli(0,500:700))',[ones(201,1) (500:700)']);
app = [-3.61178295877576 0.99916157999904];

lb0 = zeros(length(x), 1);
exact = find(x<700);
approx = find(x>=700);
lb0(exact) = log(besseli(0, x(exact)));
%lb0(approx) = x(approx)*app(2) + app(1);

% This is a more standard approximation.  For large x, I_0(x) -> exp(x)/sqrt(2 pi x).
lb0(approx) = x(approx) - log(2*pi*x(approx))/2;


