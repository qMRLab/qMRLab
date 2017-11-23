function [gsps, fobj_gs, mlps, fobj_ml, error_code, ps] = ThreeStageFittingVoxel(Epn, protocol, model, verbose)
% Performs the three stage fitting routine used for the human data in
% Alexander et al NeuroImage 2000.  The three stages are grid search,
% maximum likelihood gradient descent and MCMC with a Rician noise model.
%
% function [gsps, fobj_gs, mlps, fobj_ml, error_code, ps] = ThreeStageFittingVoxel(Epn, protocol, model, verbose)
%
% protocol is the measurement protocol.
%
% model is the model structure created with MakeModel
%
% verbose: optional, 1 for printing verbose messages, 0 for quiet (default)
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

if nargin < 4
	verbose = 0;
end

%% Initialization

warning off all

% Get the required variables
modelname = model.name;
noOfStages = model.noOfStages;
tissuetype = model.tissuetype;
GS = model.GS;
GD = model.GD;
MCMC = model.MCMC;

% Initialize the output
error_code = 0;
gsps = zeros(1, model.numParams);
mlps = gsps;
fobj_gs = 0;
fobj_ml = 0;

% Constants used during grid search and gradient descent
constantsGD.roots_cyl = BesselJ_RootsCyl(30);

%% First remove non-positive measurements
try
    [Epn, protocol] = RemoveNegMeas(Epn, protocol);
catch err
    error_code = 1;
    disp(err);
    return;
end

%% Determine the sigma
sig = EstimateSigma(Epn, protocol, model);

%% Grid Search stage

if verbose
    fprintf('Grid Search fitting with %s\n', modelname);
end

% Set up the search grid
grid = GetSearchGrid(modelname, tissuetype, GS.fixed, GS.fixedvals);

% Run the grid search
[x0 liks] = GridSearchRician(Epn, modelname, grid, protocol, constantsGD, sig);
gsps = x0(1:(end-1));
fobj_gs = max(liks);
if verbose
    if (strcmp(modelname, 'StickIsoV_B0'))
        fprintf('gsps: %5.4f %2.1f %2.1f %5.4f %2.1f %5.1f %5.4f %5.4f : %e\n', gsps, fobj_gs)
    elseif (strcmp(modelname, 'StickTortIsoV_B0'))
        fprintf('gsps: %5.4f %2.1f %5.4f %2.1f %5.1f %5.4f %5.4f : %e\n', gsps, fobj_gs)
    elseif (strcmp(modelname, 'WatsonSHStickTortIsoV_B0'))
        fprintf('gsps: %5.4f %2.1f %5.4f %5.4f %2.1f %5.1f %5.4f %5.4f : %e\n', gsps, fobj_gs)
    elseif (strcmp(modelname, 'WatsonSHStickTortIsoVIsoDot_B0'))
        fprintf('gsps: %5.4f %2.1f %5.4f %5.4f %2.1f %5.4f %5.1f %5.4f %5.4f : %e\n', gsps, fobj_gs)
    elseif (strcmp(modelname, 'BinghamStickTortIsoV_B0'))
        fprintf('gsps: %5.4f %2.1f %5.4f %5.4f %5.4f %5.4f %2.1f %5.1f %5.4f %5.4f : %e\n', gsps, fobj_gs)
    else
        disp(fobj_gs);
        disp(gsps);
    end
end

if noOfStages == 1
    return;
end

%% Gradient Descent stage

if verbose
    fprintf('Gradient Descent fitting with %s\n', modelname);
end

h=optimset('Algorithm', 'active-set', 'Display', 'iter', 'MaxIter',100,...
           'MaxFunEvals',20000,'TolX',1e-6,...
           'TolFun',1e-6,'GradObj','off', 'Hessian', 'off', 'FunValCheck',...
           'on', 'Display', 'off');%,'DerivativeCheck','on');

% Convert from actual parameters to optimized quantities that enforce
% constraints.
startx = GradDescEncode(modelname, gsps);
fobj_ml = fobj_gs;
mlps = gsps;
if (strcmp(GD.type, 'multistart'))
    noOfIterations = GD.multistart.noOfRuns;
    perturbation = GD.multistart.perturbation;
    if isempty(find(perturbation~=0, 1))
        error('multistart mode: at least one perturbation should be nonzero');
    else
        perturbation(GD.fixed==1) = 0;
    end
    if verbose
        fprintf('Multistart fitting with %i trials\n', noOfIterations);
        fprintf('Parameter perturbation adjusted for fixed variables');
    end
else
    noOfIterations = 1;
end

% Get limits and constraints for gradient descent
[MinValGD MaxValGD] = GradDescLimits(modelname);

% Get orientation dispersion index, if applicable
kappaIdx = GetParameterIndex(modelname, 'kappa');

for i=1:noOfIterations
    if i==1
        parameter_input = startx;
    else
        parameter_input = startx.*(1 + perturbation.*randn(1,length(perturbation)));
    end
    
    try
        % optimize with orientation fixed
        fixedGD = GD.fixed;
        fixedGD(end-1:end) = 1;
        % if kappa is a parameter, fix it first as well
        if (kappaIdx ~= -1)
            fixedGD(kappaIdx) = 1;
        end
        % Account for any fixed parameters
        fittedMinValGD = MinValGD(fixedGD==0);
        fittedMaxValGD = MaxValGD(fixedGD==0);
        [parameter_hat,RESNORM,EXITFLAG,OUTPUT]=fmincon_fix(fixedGD, 'fobj_rician_fix',...
            parameter_input,[],[],[],[],fittedMinValGD,fittedMaxValGD,[],h,Epn,protocol, modelname, sig, constantsGD);
        parameter_input = parameter_hat;
        
        % now optimize all free variables
        % Account for any fixed parameters
        fittedMinValGD = MinValGD(GD.fixed==0);
        fittedMaxValGD = MaxValGD(GD.fixed==0);
        [parameter_hat,RESNORM,EXITFLAG,OUTPUT]=fmincon_fix(GD.fixed, 'fobj_rician_fix',...
            parameter_input,[],[],[],[],fittedMinValGD,fittedMaxValGD,[],h,Epn,protocol, modelname, sig, constantsGD);
        
        if (-RESNORM > fobj_ml)
            fobj_ml = -RESNORM;
            mlps = GradDescDecode(modelname, parameter_hat);
        end
        if (verbose)
            disp(fobj_ml);
        end
    catch err
        error_code = 2;
        disp(err);
        return;
    end
    
end

if verbose
    if (strcmp(modelname, 'StickIsoV_B0'))
        fprintf('mlps: %5.4f %2.1f %2.1f %5.4f %2.1f %5.1f %5.4f %5.4f : %e\n', mlps, fobj_ml)
    elseif (strcmp(modelname, 'StickTortIsoV_B0'))
        fprintf('mlps: %5.4f %2.1f %5.4f %2.1f %5.1f %5.4f %5.4f : %e\n', mlps, fobj_ml)
    elseif (strcmp(modelname, 'WatsonSHStickTortIsoV_B0'))
        fprintf('mlps: %5.4f %2.1f %5.4f %5.4f %2.1f %5.1f %5.4f %5.4f : %e\n', mlps, fobj_ml)
    elseif (strcmp(modelname, 'WatsonSHStickTortIsoVIsoDot_B0'))
        fprintf('mlps: %5.4f %2.1f %5.4f %5.4f %2.1f %5.4f %5.1f %5.4f %5.4f : %e\n', mlps, fobj_ml)
    elseif (strcmp(modelname, 'BinghamStickTortIsoV_B0'))
        fprintf('mlps: %5.4f %2.1f %5.4f %5.4f %5.4f %5.4f %2.1f %5.1f %5.4f %5.4f : %e\n', mlps, fobj_ml)
    else
        disp(fobj_ml);
        disp(mlps);
    end
end

if noOfStages == 2
    return;
end

%% MCMC stage

if verbose
    fprintf('MCMC fitting with %s\n', modelname);
end

% Get limits and constraints for MCMC
[MinValMCMC MaxValMCMC] = MCMC_Limits(modelname);

% MCMC parameters
steplengths = MCMC.steplengths;
burnin = MCMC.burnin;
interval = MCMC.interval;
samples = MCMC.samples;

% Constants used during MCMC
constantsMCMC.roots_cyl = BesselJ_RootsCyl(20);

% Run the MCMC procedure
x0t = [mlps sig];

ps(:,:) = RicianMCMC(Epn, x0t, modelname, protocol, MinValMCMC, MaxValMCMC, constantsMCMC, MCMC.fixed, steplengths, burnin, samples, interval);
mcmcps = squeeze(mean(ps,1));

if verbose
    disp(mcmcps);
end
