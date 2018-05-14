%% Settings

clc;
Sim  = load('SPGRfun/Parameters/DefaultSim.mat');      % load default parameters
Prot = load('SPGRfun/Parameters/DemoProtocol.mat');     % load default protocol
FitOpt = load('SPGRfun/Parameters/DefaultFitOpt.mat');	% load default fit options
FitOpt.R1 = computeR1obs(Sim.Param);
%% Simulation

% Bloch simulation
tic;
MTdata  = SPGR_sim(Sim, Prot);
MTnoise = addNoise(MTdata, Sim.Opt.SNR, 'mt');
timeSim = toc

%%
% Fitted curve
tic;
Fit = SPGR_fit(MTnoise, Prot, FitOpt );
timeFit = toc

%%
SimCurveResults = SPGR_SimCurve(Fit, Prot, FitOpt )

%%
% Plot results
figure();
SPGR_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults);