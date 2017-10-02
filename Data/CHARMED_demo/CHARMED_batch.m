% Batch to process CHARMED data without qMRLab GUI (graphical user interface)
% Run this script line by line
%**************************************************************************
%% I- LOAD MODEL
%**************************************************************************
%Make sure user is in the correct directory
[pathstr,fname,ext]=fileparts(which('CHARMED_batch.m'));
cd (pathstr);

% Create Model object 
Model = CHARMED;
Model.options.S0normalization = 'Single T2 compartment';
% Load Diffusion Protocol
Model.Prot.DiffusionData.Mat = txt2mat('Protocol.txt');
% Launch Fitting procedure
% save Results in NIFTI

%**************************************************************************
%% II - Perform Simulations
%**************************************************************************

% Generate MR Signal using analytical equation
opt.SNR = 50;
x.fr = .5;
x.Dh = .7; % um2/ms
x.diameter_mean = 6; % um
x.fcsf = 0;
x.lc=0;
x.Dcsf=3;
x.Dintra = 1.4;
Model.Sim_Single_Voxel_Curve(x,opt)

%**************************************************************************
%% III - MRI Data Fitting
%**************************************************************************
% load data
data = struct;
data.DiffusionData = load_nii_data('DiffusionData.nii.gz');

% plot fit in one voxel
voxel = [32 29];
datavox.DiffusionData = squeeze(data.DiffusionData(voxel(1),voxel(2),:,:));
FitResults = Model.fit(datavox)
Model.plotmodel(FitResults,datavox)

% all voxels
data.Mask=load_nii_data('Mask.nii.gz');
FitResults = FitData(data,Model,1);
delete('FitTempResults.mat');

%**************************************************************************
%% V- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults,'DiffusionData.nii.gz');
%save('CHARMEDParameters.mat','Model');

%% Check the results
% Load them in qMRLab
