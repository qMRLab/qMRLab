warning('off','all');
%% DESCRIPTION
help VFA_T1
% Batch to process Variable Flip Angle data without qMRLab GUI (graphical user interface)
% Run this script line by line

%**************************************************************************
%% I- LOAD DATASET
%**************************************************************************
[pathstr,fname,ext]=fileparts(which('VFA_T1_batch.m'));
cd (pathstr);

% Create Model object
Model = VFA_T1;
% Load VFA Protocol  
%   Array [nbFA x 2]: [FA1 TR1; FA2 TR2;...]      flip angle [degrees] TR [s]
Model.Prot.SPGR.Mat=[3 0.015; 20 0.015]; %Protocol: 2 different FAs

%**************************************************************************
%% II - MRI Data Fitting
%**************************************************************************
% data required:
disp(Model.MRIinputs)
% load data
data = struct;
data.SPGR = load_nii_data('VFA_2FA.nii.gz');
data.B1map = load_nii_data('B1.nii.gz');

FitResults = FitData(data,Model); %fit data
%   FitResultsSave_mat(FitResults);

%**************************************************************************
%% IV- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults,'VFA_2FA.nii.gz'); % use header from SPGR.nii.gz

%% Check the results
% Load them in qMRLab
