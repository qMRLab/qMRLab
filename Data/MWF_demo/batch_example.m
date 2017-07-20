% Batch to process MWF data without qMRLab GUI (graphical user interface)
% Run this script line by line
% Written by: Ian Gagnon, 2017

%% Load dataset

% Load your parameters to create your Model
% load('MODELPamameters.mat');
load('MWFParameters.mat');

%% Check data and fitting (Optional)

%**************************************************************************
% I- GENERATE FILE STRUCT
%**************************************************************************
% Create a struct "file" that contains the NAME of all data's FILES
% file.DATA = 'DATA_FILE';
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
First = 10;
Spacing  = 10;
Cutoff  = 50;
Model.Prot.Echo.Mat = [ First ; Spacing ; Cutoff ];

% Update the model
Model = Model.UpdateFields;

%**************************************************************************
% II- LOAD EXPERIMENTAL DATA
%**************************************************************************
% Create a struct "data" that contains all the data
% .MAT file : load('DATA_FILE');
%             data.DATA = double(DATA);
% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));
load('MET2data.mat');
data.MET2data = double(MET2data);
load('Mask.mat');
data.Mask     = double(Mask);

%**************************************************************************
% III- FIT DATASET
%**************************************************************************
FitResults       = FitDataCustom(data,Model,1); % 3rd argument plots a waitbar
FitResults.Model = Model;
delete('logfile_multi_comp_fit');

%**************************************************************************
% IV- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_mat(FitResults);
save('Parameters.mat','Model');

%% Check the results
% Load them in qMRLab
