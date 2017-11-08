% Batch to process SIRFSE data without qMRLab GUI (graphical user interface)
% Run this script line by line
% Written by: Ian Gagnon, 2017

%% Load dataset

% Load your parameters to create your Model
% load('MODELPamameters.mat');
load('SIRFSEParameters.mat');

%% Check data and fitting (Optinal)

%**************************************************************************
% I- GENERATE FILE STRUCT
%**************************************************************************
% Create a struct "file" that contains the NAME of all data's FILES
% file.DATA = 'DATA_FILE';file.MTdata = 'MTdata.nii';
file.MTdata = 'MTdata.nii.gz';
file.Mask   = 'Mask.nii.gz';

%**************************************************************************
% II- CHECK DATA AND FITTING
%**************************************************************************
qMRLab(Model,file);

%% Create Quantitative Maps

%**************************************************************************
% I- LOAD PROTOCOL
%**************************************************************************

% MTdata
Ti = [  0.0030 ; 0.0037 ; 0.0047 ; 0.0058 ; 0.0072
        0.0090 ; 0.0112 ; 0.0139 ; 0.0173 ; 0.0216
        0.0269 ; 0.0335 ; 0.0417 ; 0.0519 ; 0.0646
        0.0805 ; 0.1002 ; 0.1248 ; 0.1554 ; 0.1935
        0.2409 ; 0.3000 ; 1.0000 ; 2.0000 ; 10.0000 ];
Td = 3.5 * ones(length(Ti),1);
Model.Prot.MTdata.Mat = [Ti,Td];

% FSE sequence (time in sec)
Trf    = 0.001;
Tr     = 0.01;
Npulse = 16;
Model.Prot.FSEsequence.Mat = [ Trf ; Tr ; Npulse ];

% *** To change other option, go directly in qMRLab ***

% Update the model
Model = Model.UpdateFields;

%**************************************************************************
% II- LOAD EXPERIMENTAL DATA
%**************************************************************************
% Create a struct "data" that contains all the data
% .MAT file : load('DATA_FILE');
%             data.DATA = double(DATA);
% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));
data = struct;
data.MTdata = double(load_nii_data('MTdata.nii.gz'));
data.Mask   = double(load_nii_data('Mask.nii.gz'));

%**************************************************************************
% III- FIT DATASET
%**************************************************************************
FitResults       = FitData(data,Model,1); % 3rd argument plots a waitbar
FitResults.Model = Model;
delete('FitTempResults.mat');

%**************************************************************************
% IV- CHECK FITTING RESULT IN A VOXEL
%**************************************************************************
figure
voxel           = [50, 60, 1];
FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
dataVox         = extractvoxel(data,voxel);
Model.plotModel(FitResultsVox,dataVox)

%**************************************************************************
% V- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults,'MTdata.nii.gz');
save('SIRFSEParameters.mat','Model');

%% Check the results
% Load them in qMRLab

