%% DESCRIPTION
help B0_DEM
% Batch to generate B0map with Dual Echo Method (DEM) without qMRLab GUI (graphical user interface)
% Run this script line by line
% Written by: Ian Gagnon, 2017
% Move the the dataset folder
[pathstr,fname,ext]=fileparts(which('B0_DEM_batch.m'));
cd (pathstr);

%**************************************************************************
%% I- LOAD MODEL and DATA
%**************************************************************************

% create your Model
%  Model = B0_DEM;
% Alternatively, load your parameters
   Model = qMRloadModel('qMRLab_B0_DEMObj.mat');
%% Check data and fitting (Optional)

%**************************************************************************
% A- GENERATE FILE STRUCT
%**************************************************************************
% Create a struct "file" that contains the NAME of all data's FILES
% file.DATA = 'DATA_FILE';
file = struct;
file.Phase = 'Phase.nii.gz';
file.Magn = 'Magn.nii.gz';

%**************************************************************************
% B- CHECK DATA 
%**************************************************************************
%qMRLab(Model,file);

%**************************************************************************
%% II- Create Quantitative Maps
%**************************************************************************
% 1. LOAD PROTOCOL
%**************************************************************************
% Echo (time in millisec)
TE2 = 1.92e-3;
Model.Prot.TimingTable.Mat = TE2;

% Update the model
Model = Model.UpdateFields;

%**************************************************************************
% 2. LOAD EXPERIMENTAL DATA
%**************************************************************************
% Create a struct "data" that contains all the data
% .MAT file : load('DATA_FILE');
%             data.DATA = double(DATA);
% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));
data.Phase = double(load_nii_data('Phase.nii.gz'));
data.Magn  = double(load_nii_data('Magn.nii.gz'));

%**************************************************************************
% 3.- FIT DATASET
%**************************************************************************
FitResults       = FitData(data,Model,1); % 3rd argument plots a waitbar
FitResults.Model = Model;

%**************************************************************************
%% IV- Check the Results
%**************************************************************************
imagesc3D(FitResults.B0map,[-100 100]); colormap jet; axis off; colorbar

%**************************************************************************
%% V- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults,'Phase.nii.gz');
% qMRsaveModel(Model, 'B0_DEM.qMRLab.mat'); % save the model object 
