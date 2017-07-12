% Batch to process CHARMED data without qMRLab graphical interface
% Run this script line by line
%% FIT Experimental MRI data
% Create Model object 
Model = CHARMED;
% Load Diffusion Protocol
Model.Prot.DiffusionData = txt2mat()
% Launch Fitting procedure
% save Results in NIFTI

%% Simulations
% Generate MR Signal using analytical equation
opt.SNR = 50;
Model.Sim_Single_Voxel_Curve()
% 