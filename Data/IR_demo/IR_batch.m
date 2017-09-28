% Batch to process Inversion Recovery data without qMRLab GUI (graphical user interface)
% Run this script line by line
%**************************************************************************
%% I- LOAD DATASET
%**************************************************************************

% Create Model object
Model = InversionRecovery;
% Load Inversion Recovery Protocol (list of inversion times, in ms)
Model.Prot.IRData.Mat = txt2mat('TI.txt');

%**************************************************************************
%% II - Perform Simulations
%**************************************************************************

% Generate MR Signal using analytical equation and perform sensitivity
% analysis: Noise
% Call Sensitivity_Analysis addons and click update
%Sim_Sensitivity_Analysis_GUI(Model);

% Alternatively use command line:
help SimVary
runs = 50; % Run simulation with additive noise 50 times
%             'T1'    'rb'    'ra'
OptTable.fx = [false   true   true];  % Vary T1...
OptTable.lb = [100     nan      nan]; % ...between 100..
OptTable.ub = [2000    nan      nan]; % and 2000ms
OptTable.st = [nan    -1000     500]; % Define nominal values for rb and ra

SimVaryResults = SimVary(Model, runs,OptTable);
figure
SimVaryPlot(SimVaryResults,'T1','T1')
% %             'T1'    'rb'    'ra'
% OptTable.fx = [0        1       1]; % Define Parameters that will not be varied
% OptTable.st = [600   -1000    500]; % Define Nominal value
%**************************************************************************
%% III - MRI Data Fitting
%**************************************************************************
% data required:
disp(Model.MRIinputs)
% load data
data = struct;
data.IRData = load_nii_data('IRdata.nii.gz');

% plot fit in one voxel
voxel = [70 60 20];
datavox.IRData = squeeze(data.IRData(voxel(1),voxel(2),voxel(3),:));
FitResults = Model.fit(datavox);
Model.plotmodel(FitResults,datavox)

% all voxels (slice 23 only to go faster)
Mask=load_nii_data('Mask.nii.gz');
data.Mask = false(size(Mask));
data.Mask(:,:,23) = Mask(:,:,23); % fit slice 23 only

FitResults = FitData(data,Model);
delete('FitTempResults.mat');

%**************************************************************************
%% IV- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults,'IRdata.nii.gz'); % use header from 'IRdata.nii.gz'
save('IRParameters.mat','Model');

%% Check the results
% Load them in qMRLab
