function model = MakeModel(modelname)

% function model = MakeModel(modelname)
%
% Set up the model specification for fitting
% 
% model.name: model name
%
% model.numParams: number of parameters
%
% model.paramsStr: parameter strings
%
% model.tissuetype: type of tissue
%
% model.noOfStages: how many stages to run
%
% model.fixGD: fixed variables during gradient descent
% model.fixedvalsGD: values for the fixed variables during gradient descent
%
% model.fixMCMC: fixed variables during MCMC
% model.MCMC.steplengths: MCMC step lengths
% model.MCMC.burnin: MCMC burn-in
% model.MCMC.interval: MCMC interval
% model.MCMC.samples: MCMC samples
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

model.name = modelname;
model.numParams = NumFreeParams(modelname);
model.paramsStr = GetParameterStrings(modelname);
model.tissuetype = 'invivo';
model.GS.fixed = zeros(1, model.numParams);
model.GS.fixedvals = zeros(1, model.numParams);
model.GD.fixed = zeros(1, model.numParams);
model.GD.fixedvals = zeros(1, model.numParams);
model.GD.type = 'single'; % 'multistart'
model.GD.multistart.perturbation = zeros(1, model.numParams);
model.GD.multistart.noOfRuns = 10;
model.MCMC.fixed = ones(1, model.numParams + 1);
model.MCMC.steplengths = 0.05*ones(1, model.numParams+1);
model.MCMC.burnin = 2000;
model.MCMC.interval = 200;
model.MCMC.samples = 40;
model.noOfStages = 2;
model.sigma.perVoxel = 1;
model.sigma.minSNR = 0.02;
model.sigma.scaling = 100;

% use exvivo setting if isotropic restriction is included
irfracIdx = GetParameterIndex(modelname, 'irfrac');
if irfracIdx > 0
    model.tissuetype = 'exvivo';
end

% fix intrinsic diffusivity
diIdx = GetParameterIndex(modelname, 'di');
model.GS.fixed(diIdx) = 1;
model.GD.fixed(diIdx) = 1;
if strcmp(model.tissuetype, 'invivo')
    model.GS.fixedvals(diIdx) = 1.7E-9;
    model.GD.fixedvals(diIdx) = 1.7E-9;
else
    model.GS.fixedvals(diIdx) = 0.6E-9;
    model.GD.fixedvals(diIdx) = 0.6E-9;
end

% fix isotropic diffusivity
disoIdx = GetParameterIndex(modelname, 'diso');
if disoIdx > 0
    model.GS.fixed(disoIdx) = 1;
    model.GD.fixed(disoIdx) = 1;
	 if strcmp(model.tissuetype, 'invivo')
        model.GS.fixedvals(disoIdx) = 3.0E-9;
        model.GD.fixedvals(disoIdx) = 3.0E-9;
    else
        model.GS.fixedvals(disoIdx) = 2.0E-9;
        model.GD.fixedvals(disoIdx) = 2.0E-9;
    end
end

% fix B0
% fixed value is estimated from the b0 images voxel-wise
b0Idx = GetParameterIndex(modelname, 'b0');
if b0Idx > 0
    model.GS.fixed(b0Idx) = 1;
    model.GD.fixed(b0Idx) = 1;
end

