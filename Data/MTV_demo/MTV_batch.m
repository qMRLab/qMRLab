% Batch to process MTV data without qMRLab GUI (graphical user interface)
% Run this script line by line
% Written by: Ian Gagnon, 2017

%% Load dataset

% Load your parameters to create your Model
% load('MODELPamameters.mat');
load('MTVParameters.mat');

%% Check data and fitting (Optional)

%**************************************************************************
% I- GENERATE FILE STRUCT
%**************************************************************************
% Create a struct "file" that contains the NAME of all data's FILES
% file.DATA = 'DATA_FILE';
file = struct;
file.SPGR = 'SPGR.mat';
file.B1map = 'B1map.mat';
file.CSFMask = 'CSFMask.mat';

%**************************************************************************
% II- CHECK DATA AND FITTING
%**************************************************************************
qMRLab(Model,file);


%% Create Quantitative Maps

%**************************************************************************
% I- LOAD PROTOCOL
%**************************************************************************

% Echo (time in millisec)
FlipAngle = [ 4 ; 10 ; 20];
TR        = 0.025 * ones(length(FlipAngle),1);
Model.Prot.MTV.Mat = [ FlipAngle , TR ];

% Update the model
Model = Model.UpdateFields;

%**************************************************************************
% II- LOAD EXPERIMENTAL DATA
%**************************************************************************
% Create a struct "data" that contains all the data
% .MAT file : load('DATA_FILE');
%             data.DATA = double(DATA);
% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));
load('SPGR.mat');
data.SPGR    = double(SPGR);
load('B1map.mat');
data.B1map   = double(B1map);
load('CSFMask.mat');
data.CSFMask = double(CSFMask);


%**************************************************************************
% III- FIT DATASET
%**************************************************************************
FitResults       = FitData(data,Model);
FitResults.Model = Model;

%**************************************************************************
% IV- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_mat(FitResults);
save('Parameters.mat','Model');

%% Check the results
% Load them in qMRLab
