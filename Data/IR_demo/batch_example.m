% Example T1 map processing using Inversion Recovery
% Written by: Ilana Leppert, 2017

%% Generate T1map
%**************************************************************************
% I- Create model instance
%**************************************************************************
Model = InversionRecovery;

%**************************************************************************
% II- LOAD PROTOCOL
%**************************************************************************
% Vector of inversion times
TI = [350,500,650,800,950,1100]';
Prot.IRData.Mat = TI;

%**************************************************************************
% II- LOAD EXPERIMENTAL DATA
%**************************************************************************
% Create a struct "data" that contains all the data
% .MAT file : load('DATA_FILE');
%             data.DATA = double(DATA);
% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));
data.IRData = double(load_nii_data('IRdata-2slices.nii'));
data.Mask  = double(load_nii_data('Mask-2slices.nii'));

%**************************************************************************
% III- FIT DATASET
%**************************************************************************
FitResults       = FitData(data,Model,1); % 3rd argument plots a waitbar
FitResults.Model = Model;

%**************************************************************************
% IV- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults,'Mask-2slices.nii'); % this will save all output files in folder 'FitResults' using the 2nd argument as a template
% A .mat file called 'FitResults.mat' will also be saved in the 'FitResults' folder, which can be loaded for later use

%% Check the results
% Load them in qMRLab