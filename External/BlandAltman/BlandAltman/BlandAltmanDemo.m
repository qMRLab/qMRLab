% BlandAltmanDemo - demonstrate calling BlandAltman.m
%
% By Ran Klein
% 2016-08-10  RK  Major overhull of Bland-Altman.m and new functionality is
%                 demonstrated.


%% Generate paramteres for data generation
clear;
noise = 10/100; % percent
npatients = 30; % number of patients
bias = 1; % slope bias

% Heart muscle territories per patient
territories = {'LAD','LCx','RCA'};
nterritories = length(territories);

% Patient states during measurement
states = {'Rest','Stress'};
nstates = length(states);

% Real flow values
restFlow = 0.7*(1+0.2*randn(npatients,nterritories));
stressFlow = 2*(1+0.2*randn(npatients,nterritories));

% Test support for nan values in the data
if 0
	restFlow(3,1) = nan;
end

%% Example 1
% Baseline data with noise
data1 = cat(3,  restFlow.*(1+noise*randn(npatients,nterritories)), stressFlow.*(1+noise*randn(npatients,nterritories)));
% Follow-up data with noise and a bias
data2 = bias * cat(3,  restFlow.*(1+noise*randn(npatients,nterritories)), stressFlow.*(1+noise*randn(npatients,nterritories)));

% BA plot paramters
tit = 'Flow Repeatability'; % figure title
gnames = {territories, states}; % names of groups in data {dimension 1 and 2}
label = {'Baseline Flow','Follow-up Flow','mL/min'}; % Names of data sets
corrinfo = {'n','SSE','r2','eq'}; % stats to display of correlation scatter plot
BAinfo = {'RPC(%)','ks'}; % stats to display on Bland-ALtman plot
limits = 'auto'; % how to set the axes limits
if 1 % colors for the data sets may be set as:
	colors = 'br';      % character codes
else
	colors = [0 0 1;... % or RGB triplets
		      1 0 0];
end

% Generate figure with symbols
[cr, fig, statsStruct] = BlandAltman(data1, data2,label,tit,gnames,'corrInfo',corrinfo,'baInfo',BAinfo,'axesLimits',limits,'colors',colors, 'showFitCI',' on');

% Generate figure with numbers of the data points (patients) and fixed
% Bland-Altman difference data axes limits
BlandAltman(data1, data2,label,[tit ' (numbers, forced 0 intercept, and fixed BA y-axis limits)'],gnames,'corrInfo',corrinfo,'baInfo',BAinfo,'axesLimits',limits,'colors',colors,'symbols','Num','baYLimMode','square','forceZeroIntercept','on')


% Generate figure with numbers of the data points (patients) and fixed
% Bland-Altman difference data axes limits
BAinfo = {'RPC(%)'};
BlandAltman(data1, data2,label,[tit ' (show fit confidence intervals and differences as percentages)'],gnames,'diffValueMode','percent', 'showFitCI','on')


% Display statistical results that were returned from analyses
disp('Statistical results:');
disp(statsStruct);


%% Example 2 - using non-Gaussian data
BAinfo = {'RPC(%)','ks'};
% Baseline data with non-Gaussian noise
data1 = cat(3,  restFlow.*(1+noise*rand(npatients,nterritories)), stressFlow.*(1+noise*rand(npatients,nterritories)));
% Follow-up data with non-Gaussian noise and a bias
data2 = bias * cat(3,  restFlow.*(1+noise*rand(npatients,nterritories)), stressFlow.*(1+noise*rand(npatients,nterritories)));

[cr, fig, statsStruct] = BlandAltman(data1, data2,label,[tit ' (inappropriate Gauassian stats)'],gnames,'corrInfo',corrinfo,'baInfo',BAinfo,'axesLimits',limits,'colors',colors);

% A warning should appear indicating detection of non-Gaussian
% distribution.
% Repeat analysis using non-parametric analysis, no warning should appear.
BAinfo = {'RPCnp','ks'};
[cr, fig, statsStruct] = BlandAltman(data1, data2,label,[tit ' (using non-parametric stats)'],gnames,'corrInfo',corrinfo,'baInfo',BAinfo,'axesLimits',limits,'colors',colors,'baStatsMode','non-parametric');
% Keep in mind that alpha is set to 0.05 so there is a 1/20 chace of false
% warnings.
