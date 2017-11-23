function [L, D] = legendreGaussianIntegral(x, n)
% function [L, D] = legendreGaussianIntegral(x, n)
% Computes legendre gaussian integrals up to the order specified and the
% derivatives if requested
%
% The integral takes the following form, in Mathematica syntax,
%
% L[x, n] = Integrate[Exp[-x \mu^2] Legendre[2*n, \mu], {\mu, -1, 1}]
% D[x, n] = Integrate[Exp[-x \mu^2] (-\mu^2) Legendre[2*n, \mu], {\mu, -1, 1}]
%
% INPUTS:
%
% x should be a column vector of positive numbers, specifying the
% parameters of the gaussian
%
% n should be a non-negative integer, such that 2n specifies the maximum order
% of legendre polynomial
%
% The maximum value for n is 6.
%
% OUTPUTS:
%
% L will be a two-dimensional array with each row containing the
% legendre gaussian integrals of the orders 0, 2, 4, ..., to 2n for the
% parameter value at the corresponding row in x
%
% Note that the legendre gaussian integrals of the odd orders are zero.
%
% D will be the 1st order derivative of L
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

% Make sure n is not larger than 6
if n > 6
	error('The maximum value for n is 6, which correspondes to the 12th order Legendre polynomial');
end

%
% Computing the related exponent gaussian integrals
% I[x, n] = Integrate[Exp[-x \mu^2] \mu^(2*n), {\mu, -1, 1}]
% with the following recursion:
% 1) I[x, 0] = Sqrt[\pi]Erf[x]/Sqrt[x]
% 2) I[x, n+1] = -Exp[-x]/x + (2n+1)/(2x) I[x, n]
%
% This does not work well when x is small

exact = find(x>0.05);
approx = find(x<=0.05);
% Necessary to make matlab happy when x is a single value
exact = exact(:);
approx = approx(:);

if nargout > 1
	mn = n + 2;
else
	mn = n + 1;
end
I = zeros(length(x),mn);
sqrtx = sqrt(x(exact));
I(exact,1) = sqrt(pi)*erf(sqrtx)./sqrtx;
dx = 1.0./x(exact);
emx = -exp(-x(exact));
for i = 2:mn
    I(exact,i) = emx + (i-1.5)*I(exact,i-1);
    I(exact,i) = I(exact,i).*dx;
end

% Computing the legendre gaussian integrals for large enough x
L = zeros(length(x),n+1);
for i = 1:n+1
	if i == 1
		L(exact,1) = I(exact,1);
	elseif i == 2
		L(exact,2) = -0.5*I(exact,1) + 1.5*I(exact,2);
	elseif i == 3
		L(exact,3) = 0.375*I(exact,1) - 3.75*I(exact,2) + 4.375*I(exact,3);
	elseif i == 4
		L(exact,4) = -0.3125*I(exact,1) + 6.5625*I(exact,2) - 19.6875*I(exact,3) + 14.4375*I(exact,4);
	elseif i == 5
		L(exact,5) = 0.2734375*I(exact,1) - 9.84375*I(exact,2) + 54.140625*I(exact,3) - 93.84375*I(exact,4) + 50.2734375*I(exact,5);
    elseif i == 6
        L(exact,6) = -(63/256)*I(exact,1) + (3465/256)*I(exact,2) - (30030/256)*I(exact,3) + (90090/256)*I(exact,4) - (109395/256)*I(exact,5) + (46189/256)*I(exact,6);
    elseif i == 7
        L(exact,7) = (231/1024)*I(exact,1) - (18018/1024)*I(exact,2) + (225225/1024)*I(exact,3) - (1021020/1024)*I(exact,4) + (2078505/1024)*I(exact,5) - (1939938/1024)*I(exact,6) + (676039/1024)*I(exact,7);
	end
end

% Computing the legendre gaussian integrals for small x
x2=x(approx,1).^2;
x3=x2.*x(approx,1);
x4=x3.*x(approx,1);
x5=x4.*x(approx,1);
x6=x5.*x(approx,1);
for i = 1:n+1
	if i == 1
		L(approx,1) = 2 - 2*x(approx,1)/3 + x2/5 - x3/21 + x4/108;
	elseif i == 2
		L(approx,2) = -4*x(approx,1)/15 + 4*x2/35 - 2*x3/63 + 2*x4/297;
	elseif i == 3
		L(approx,3) = 8*x2/315 - 8*x3/693 + 4*x4/1287;
	elseif i == 4
		L(approx,4) = -16*x3/9009 + 16*x4/19305;
	elseif i == 5
		L(approx,5) = 32*x4/328185;
    elseif i == 6
		L(approx,6) = -64*x5/14549535;
    elseif i == 7
		L(approx,7) = 128*x6/760543875;
	end
end

if nargout == 1
	return;
end

% Computing the derivatives for large enough x
D = zeros(length(x),n+1);
for i = 1:n+1
	if i == 1
		D(exact,1) = -I(exact,2);
	elseif i == 2
		D(exact,2) = 0.5*I(exact,2) - 1.5*I(exact,3);
	elseif i == 3
		D(exact,3) = -0.375*I(exact,2) + 3.75*I(exact,3) - 4.375*I(exact,4);
	elseif i == 4
		D(exact,4) = 0.3125*I(exact,2) - 6.5625*I(exact,3) + 19.6875*I(exact,4) - 14.4375*I(exact,5);
	elseif i == 5
		D(exact,5) = -0.2734375*I(exact,2) + 9.84375*I(exact,3) - 54.140625*I(exact,4) + 93.84375*I(exact,5) - 50.2734375*I(exact,6);
    elseif i == 6
        D(exact,6) = (63/256)*I(exact,2) - (3465/256)*I(exact,3) + (30030/256)*I(exact,4) - (90090/256)*I(exact,5) + (109395/256)*I(exact,6) - (46189/256)*I(exact,7);
    elseif i == 7
        D(exact,7) = -(231/1024)*I(exact,2) + (18018/1024)*I(exact,3) - (225225/1024)*I(exact,4) + (1021020/1024)*I(exact,5) - (2078505/1024)*I(exact,6) + (1939938/1024)*I(exact,7) - (676039/1024)*I(exact,8);
	end
end

% Computing the derivatives for small x
for i = 1:n+1
	if i == 1
		D(approx,1) = -2/3 + 2*x(approx,1)/5 - x2/7 + x3/27 - x4/132;
	elseif i == 2
		D(approx,2) = -4/15 + 8*x(approx,1)/35 - 2*x2/21 + 8*x3/297 - 5*x4/858;
	elseif i == 3
		D(approx,3) = 16*x(approx,1)/315 - 8*x2/231 + 16*x3/1287 - 4*x4/1287;
	elseif i == 4
		D(approx,4) = -16*x2/3003 + 64*x3/19305 - 8*x4/7293;
	elseif i == 5
		D(approx,5) = 128*x3/328185 - 32*x4/138567;
    elseif i == 6
        D(approx,6) = -64*x4/2909907 + 128*x5/10140585;
    elseif i == 7
        D(approx,7) = 256*x5/253514625;
	end
end

