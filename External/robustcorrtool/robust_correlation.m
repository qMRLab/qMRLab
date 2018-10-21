function results = robust_correlation(X,Y)

% General function that performs multiple tests on X and Y.
%
% FORMAT:  results = robust_correlation(X,Y)
% 
% INPUTS:  X and Y are two vectors of the same length.
%
% OUTPUTS: 
%          result is a structure with one field for each output from the
%          different tests performed. 
%          In particular the function: 
%
%   1 - plots the data and generates univariate and bivariate histograms;
%   2 - performs the Henze-Zirkler test for normality (results.normality);
%   3 - computes conditional data and variances (results.conditional);
%   4 - tests for heteroscedasticity based on conditional variances
%     (results.heteroscedasticity);
%   5 - checks for outliers (results.outliers);
%   6 - performs Pearson, Spearman, Bend and Skipped correlations.
%
% See also HZMVNTEST, CONDITIONAL, PEARSON, SPEARMAN, DETECT_OUTLIERS, BENDCORR, SKIPPED_CORRELATION. 
%
% Cyril Pernet v1
% ---------------------------------
%  Copyright (C) Corr_toolbox 2012



%% data check
if size(X)~=size(Y)
    error('X and Y must have the same size')
end

[r c] = size(X);
if r == 1 && c > 1
    X = X'; 
    Y = Y';
elseif r > 1 && c > 1
    error('X and Y must be 2 vectors, more than 1 column/row detected')
end

level = 5/100;

    
%% 1 - plot the data and generate univariate and bivariate histograms

% figure 1 - histograms and scatter plot
h1 = corr_normplot(X,Y);

% figure 2 - Joint density 
joint_density(X,Y,1)


%% 2 - performs the Henze- Zirkler test for normality
[results.normality.test_value,results.normality.p_value] = HZmvntest(X,Y,level);

%% 3 - get conditional data
[results.conditional.values,results.conditional.variances]=conditional(X,Y);

%% 4 - test for heteroscedasticity based on conditional variances
[h,results.heteroscedasticity.CI] = variance_homogeneity(X,Y,1);
if h == 0
    results.heteroscedasticity.result = 'variance are equals';
else
    results.heteroscedasticity.result = 'variances are inequals';
end

disp(' ')
fprintf('heteroscedasticity testing indicates that %s\n',results.heteroscedasticity.result)
fprintf('conditional variances = %g %g \n', results.conditional.variances)

%% 5 - check for outliers based on the MAD median rule & the IQR rule
results.outliers = detect_outliers(X,Y);


%% 6 - Bend correlation (remove effect of univariate outliers)

[r_bend,t_bend,p_bend,h,CI] = bendcorr(X,Y); % use the default 20% triming
results.bend_correlation.r = r_bend;
results.bend_correlation.t = t_bend;
results.bend_correlation.p = p_bend;
results.bend_correlation.CI = CI;
results.bend_correlation.h  = h;

disp(' ')
if h == 1
    fprintf('Bend correlation is significant \n')
    fprintf('r=%g p=%g CI=[%g %g] \n',r_bend,p_bend,CI)
    results.bend_correlation.result = 'Bend correlation is significant ';
else
    fprintf('Bend correlation is not significant \n')
    fprintf('r=%g CI=[%g %g] \n',r_bend,CI)
    results.bend_correlation.result = 'Bend correlation is not significant ';
end

clear r_bend t_bend p_bend CI h
\