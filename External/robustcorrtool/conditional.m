function [values,variance]=conditional(X,Y)

% Returns the conditional values and variances of X given Y and Y given X.
% The calculation is based on Pearson correlation values because 
% if the X & Y are jointly normal and r = 0, then X & Y are independent.
%
% FORMAT:  [values,variance]=conditional(X,Y)
%
% INPUTS:  X and Y are two vectors of the same length
%
% OUTPUTS: values are the conditioned variables X and Y
%          variances are the conditional variances
%

% Cyril Pernet v1 21/05/2012
% ---------------------------------
%  Copyright (C) Corr_toolbox 2012

if size(X)~=size(Y)
    error('X and Y must have the same size')
end

r = corr(X,Y);
Xhat = r*std(X)*Y / std(Y);
Yhat = r*std(Y)*X / std(X);
Cond_stdX = (1-r^2)*std(X);
Cond_stdY = (1-r^2)*std(Y);

values = [Xhat Yhat];
variance = [Cond_stdX^2 Cond_stdY^2];
