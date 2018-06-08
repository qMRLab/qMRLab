%% Settings
clc;
Sim    = load('bSSFPfun/Parameters/DefaultSim.mat');    % load default parameters
Prot   = load('bSSFPfun/Parameters/DefaultProt.mat');   % load default protocol
FitOpt = load('bSSFPfun/Parameters/DefaultFitOpt.mat'); % load default fit options
FitOpt.R1 = Sim.Param.R1f;                           % simulate R1 map value

%% Simulation
% Bloch simulation
tic;
MTdata  = bSSFP_sim(Sim, Prot);	
MTnoise = addNoise(MTdata, Sim.Opt.SNR, 'magnitude');
timeSim = toc

% Fitting
tic;
Fit = bSSFP_fit(MTnoise, Prot, FitOpt)
timeFit = toc

%%
% Fitted curve
SimCurveResults = bSSFP_SimCurve(Fit, Prot, FitOpt );

% Plot results
figure();
subplot(2,1,1);
axe(1) = gca;
subplot(2,1,2);
axe(2) = gca;
bSSFP_PlotSimCurve(MTdata, MTnoise, Prot, Sim, SimCurveResults, axe);

