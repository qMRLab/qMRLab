%% Settings
clear; clc;
Sim    =  load('SIRFSE/Parameters/DefaultSim.mat');    % load default simulation parameters
Prot   =  load('SIRFSE/Parameters/DefaultProt.mat');   % load default protocol
FitOpt =  load('SIRFSE/Parameters/DefaultFitOpt.mat'); % load default fit options

%% Simulation
tic
MTdata = SIRFSE_sim(Sim, Prot);
MTnoise = noise( MTdata, Sim.Opt.SNR );         % add noise
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

