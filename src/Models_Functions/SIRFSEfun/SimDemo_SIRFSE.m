%% Settings
clc;
Sim    =  load('SIRFSEfun/Parameters/DefaultSim.mat');    % load default simulation parameters
Prot   =  load('SIRFSEfun/Parameters/DefaultProt.mat');   % load default protocol
FitOpt =  load('SIRFSEfun/Parameters/DefaultFitOpt.mat'); % load default fit options

%% Simulation
tic
MTdata = SIRFSE_sim(Sim, Prot);
MTnoise = addNoise(MTdata, Sim.Opt.SNR, 'mt');         % add noise
timeSim = toc

tic;
Fit = SIRFSE_fit(MTnoise,Prot,FitOpt)
timeFit = toc

%%
% Fitted curve
SimCurveResults = SIRFSE_SimCurve(Fit, Prot, FitOpt );

% Plot results
figure();
SIRFSE_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults);

