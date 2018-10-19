function [ql,qu]=idealf(x)
% Compute the ideal fourths for data in x
% The estimate of the interquartile range is:
% IQR=qu-ql;
% Adapted from Rand Wilcox's idealf R function, described in
% Rand Wilcox, Introduction to Robust Estimation & Hypothesis Testing, 3rd
% edition, Academic Press, Elsevier, 2012

% Cyril Pernet & Guillaume Rousselet, v1 - September 2012
% ---------------------------------------------------
%  Copyright (C) Corr_toolbox 2012

j=floor(length(x)/4 + 5/12);
y=sort(x);
g=(length(x)/4)-j+(5/12);
ql=(1-g).*y(j)+g.*y(j+1);
k=length(x)-j+1;
qu=(1-g).*y(k)+g.*y(k-1);