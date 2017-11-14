warning('off','all');

%% DESCRIPTION
help MWF

% Batch to process MWF data without qMRLab GUI (graphical user interface)
% Run this script line by line
% Written by: Ian Gagnon, 2017

%% Load dataset
[pathstr,fname,ext]=fileparts(which('MWF_batch.m'));
cd (pathstr);

% Load your parameters to create your Model
% load('MWFPamameters.mat');
Model = MWF;

%% Check data and fitting (Optional)

%**************************************************************************
% I- GENERATE FILE STRUCT
%**************************************************************************
% Create a struct "file" that contains the NAME of all data's FILES
% file.DATA = 'DATA_FILE';
file = struct;
file.MET2data = 'MET2data.mat';
file.Mask = 'Mask.mat';

%**************************************************************************
% II- CHECK DATA AND FITTING
%**************************************************************************
qMRLab(Model,file);


%% Create Quantitative Maps

%**************************************************************************
% I- LOAD PROTOCOL
%**************************************************************************

% Echo (time in millisec)
EchoTimes = [10; 20; 30; 40; 50; 60; 70; 80; 90; 100; 110; 120; 130; 140; 150; 160; 170;
            180; 190; 200; 210; 220; 230; 240; 250; 260; 270; 280; 290; 300; 310; 320];
Model.Prot.MET2data.Mat = EchoTimes;

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
load('MET2data.mat');
data.MET2data = double(MET2data);
load('Mask.mat');
data.Mask     = double(Mask);

%**************************************************************************
% III- FIT DATASET
%**************************************************************************
% All voxels
FitResults       = FitData(data,Model,1); % 3rd argument plots a waitbar
delete('FitTempResults.mat');

%**************************************************************************
% IV- CHECK FITTING RESULT IN A VOXEL
%**************************************************************************
figure
voxel           = [37, 40, 1];
FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
dataVox         = extractvoxel(data,voxel);
Model.plotModel(FitResultsVox,dataVox)

%**************************************************************************
% V- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_mat(FitResults);
save('MWFPamameters.mat','Model');

%% Check the results
% Load them in qMRLab
