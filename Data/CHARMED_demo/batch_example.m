% Batch to process CHARMED data without qMRLab GUI (graphical user interface)
% Run this script line by line
%% FIT Experimental MRI data
% Create Model object 
Model = CHARMED;
% Load Diffusion Protocol
Model.Prot.DiffusionData.Mat = txt2mat('Protocol.txt');
% Launch Fitting procedure
% save Results in NIFTI

%% Simulations
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

%% Data Fitting
data.DiffusionData = load_nii_data('DiffusionData.nii.gz');
% one voxel
voxel = [32 29];
datavox.DiffusionData = squeeze(data.DiffusionData(voxel(1),voxel(2),:,:));
FitResults = Model.fit(datavox)
Model.plotmodel(FitResults,datavox)
%all voxels
data.Mask=load_nii_data('Mask.nii.gz');
FitResults = FitData(data,Model)