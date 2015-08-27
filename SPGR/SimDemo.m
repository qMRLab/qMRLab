%% Settings

clear; clc;
Sim  = load('SPGR/Parameters/DefaultSim.mat');      % load default parameters
Prot = load('SPGR/Parameters/DefaultProt.mat');     % load default protocol
FitOpt = load('SPGR/Parameters/DefaultFitOpt.mat');	% load default fit options
FitOpt.R1 = computeR1obs(Sim.Param);
%% Simulation

% Bloch simulation
tic;
MTdata  = SPGR_sim(Sim, Prot);
MTnoise = noise(MTdata, Sim.Opt.SNR);
timeSim = toc

%%
% Fitted curve Yarnykh
FitOpt.model = 'Ramani';
tic;
Fit = SPGR_fit(MTnoise, Prot, FitOpt );
timeFit = toc

%%
SimCurveResults = SPGR_SimCurve(Fit, Prot, FitOpt )

% Plot results
figure();
SPGR_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults);