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

disp(' ');
disp('Correlation toolbox, Copyright (C) 2012. C. Pernet & G. Rousselet')
disp('This program comes with ABSOLUTELY NO WARRANTY')
disp('This is free software, and you are welcome to redistribute it')
disp('under certain conditions; see http://www.gnu.org/licenses/ for details.')
disp(' ');

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
corr_normplot(X,Y);

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

%% 6 - Pearson correlation
[r,t,pval,hboot,CI] = Pearson(X,Y);
results.Pearson.r = r;
results.Pearson.t = t;
results.Pearson.p = pval;
results.Pearson.CI = CI;

disp(' ')
if hboot == 1
    fprintf('Pearson correlation is significant \n')
    fprintf('r=%g p=%g CI=[%g %g] \n',r,pval,CI)
    results.Pearson.result = 'Pearson correlation is significant';
else
    fprintf('Pearson correlation is not significant \n')
    fprintf('r=%g CI=[%g %g] \n',r,CI)
    results.Pearson.result = 'Pearson correlation is not significant';
end

clear r t pval hboot CI
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
%% 7 - performs Spearman

[r,t,pval,hboot,CI] = Spearman(X,Y);
results.Spearman.r = r;
results.Spearman.t = t;
results.Spearman.p = pval;
results.Spearman.CI = CI;

disp(' ')
if hboot == 1
    fprintf('Spearman correlation is significant \n')
    fprintf('r=%g p=%g CI=[%g %g] \n',r,pval,CI)
    results.Spearman.result = 'Spearman correlation is significant ';
else
    fprintf('Spearman correlation is not significant \n')
    fprintf('r=%g CI=[%g %g] \n',r,CI)
    results.Spearman.result = 'Spearman correlation is not significant ';
end
clear r t pval hboot CI

%% 8 - skip correlation to remove effect of bivariate outliers

[r,t,h,outliers,hboot,CI]=skipped_correlation(X,Y);
results.Skipped_correlation.Pearson.r = r.Pearson;
results.Skipped_correlation.Spearman.r = r.Spearman;
results.Skipped_correlation.Pearson.t = t.Pearson;
results.Skipped_correlation.Spearman.t = t.Spearman;
results.Skipped_correlation.Pearson.CI = CI.Pearson;
results.Skipped_correlation.Spearman.CI = CI.Spearman;
results.Skipped_correlation.Pearson.h = h.Pearson;
results.Skipped_correlation.Spearman.h = h.Spearman;

disp(' ')
if hboot.Pearson == 1
    fprintf('Pearson Skipped correlation is significant \n')
    fprintf('r=%g CI=[%g %g] \n',r.Pearson,CI.Pearson)
    results.Skipped_correlation.Pearson.result = 'Skipped correlation is significant ';
else
    fprintf('Skipped correlation is not significant \n')
    fprintf('r=%g CI=[%g %g]\n',r.Pearson,CI.Pearson)
    results.Skipped_correlation.Pearson.result = 'Skipped correlation is not significant ';
end

if hboot.Spearman == 1
    fprintf('Spearman Skipped correlation is significant \n')
    fprintf('r=%g CI=[%g %g] \n',r.Spearman,CI.Spearman)
    results.Skipped_correlation.Spearman.result = 'Skipped correlation is significant ';
else
    fprintf('Spearman Skipped correlation is not significant \n')
    fprintf('r=%g CI=[%g %g] \n',r.Spearman,CI.Spearman)
    results.Skipped_correlation.Spearman.result = 'Skipped correlation is not significant ';
end

clear h r t outliers CI

