% Batch to generate B0map with Dual Echo Method (DEM) without qMRLab GUI (graphical user interface)
% Run this script line by line
% Written by: Ian Gagnon, 2017

%% Load dataset

% Load your parameters to create your Model
% load('MODELPamameters.mat');
load('B0_DEMParameters.mat');

%% Check data and fitting (Optional)

%**************************************************************************
% I- GENERATE FILE STRUCT
%**************************************************************************
% Create a struct "file" that contains the NAME of all data's FILES
% file.DATA = 'DATA_FILE';
file.Phase = 'Phase.nii';
file.Magn = 'Magn.nii';

%**************************************************************************
% II- CHECK DATA AND FITTING
%**************************************************************************
qMRLab(Model,file);


%% Create Quantitative Maps

%**************************************************************************
% I- LOAD PROTOCOL
%**************************************************************************

% Echo (time in millisec)
TE2 = 1.92e-3;
Model.Prot.Time.Mat = TE2;

% Update the model
Model = Model.UpdateFields;

%**************************************************************************
% II- LOAD EXPERIMENTAL DATA
%**************************************************************************
% Create a struct "data" that contains all the data
% .MAT file : load('DATA_FILE');
%             data.DATA = double(DATA);
% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));
data.Phase = double(load_nii_data('Phase.nii'));
data.Magn  = double(load_nii_data('Magn.nii'));

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
FitResultsSave_nii(FitResults,'Phase.nii');
save('Parameters.mat','Model');

%% Check the results
% Load them in qMRLab
