% Batch to process MT_SAT
% Run this script line by line

%% I- LOAD DATASET
%**************************************************************************

% Create Model object 
Model = MTSAT;
% Define Protocol
disp(Model.Prot.PD.Format)
Model.Prot.PD.Mat = [6  28e-3]; % FA, TR
Model.Prot.MT.Mat = [6  28e-3 1000]; % FA, TR, Offset
Model.Prot.T1.Mat = [20 18e-3]; % FA, TR

%**************************************************************************
%% II - MRI Data Fitting
%**************************************************************************
% list required inputs
disp(Model.MRIinputs)
% load data
data = struct;
data.MTw = load_nii_data('MTw.nii.gz');
data.T1w = load_nii_data('T1w.nii.gz');
data.PDw = load_nii_data('PDw.nii.gz');

% plot fit in one voxel
FitResults = FitData(data,Model);
delete('FitTempResults.mat');

%**************************************************************************
%% III- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults,'MTw.nii.gz');
save('CHARMEDParameters.mat','Model');

%% Check the results
% Load them in qMRLab
