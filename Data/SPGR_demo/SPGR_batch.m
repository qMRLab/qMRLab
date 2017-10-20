% Batch to process SPGR data without qMRLab GUI (graphical user interface)
% Run this script line by line
% Written by: Ian Gagnon, 2017

%% DESCRIPTION
help SPGR

%% Load dataset
%warning('off')
[pathstr,fname,ext]=fileparts(which('SPGR_batch.m'));
cd (pathstr);

% Load your parameters to create your Model
% load('MODELPamameters.mat');
load('SPGRParameters.mat');
%Model = SPGR;

%% Check data and fitting (Optional)

%**************************************************************************
% I- GENERATE FILE STRUCT
%**************************************************************************
% Create a struct "file" that contains the NAME of all data's FILES
% file.DATA = 'DATA_FILE';
file.MTdata = 'MTdata.mat';
file.R1map = 'R1map.mat';
file.B1map = 'B1map.mat';
file.B0map = 'B0map.mat';
file.Mask = 'Mask.mat';

%**************************************************************************
% II- CHECK DATA AND FITTING
%**************************************************************************
qMRLab(Model,file);


%% Create Quantitative Maps

%**************************************************************************
% I- LOAD PROTOCOL
%**************************************************************************

% MTdata
Angles  = [ 142 ; 426 ; 142  ; 426  ; 142  ; 426  ; 142  ; 426  ; 142  ; 426   ];
Offsets = [ 443 ; 443 ; 1088 ; 1088 ; 2732 ; 2732 ; 6862 ; 6862 ; 17235; 17235 ];
Model.Prot.MTdata.Mat = [Angles,Offsets];

% Timing Table (time in sec)
Tmt = 0.0102;
Ts  = 0.0030;
Tp  = 0.0018;
Tr  = 0.0100;
TR  = Tmt + Ts + Tp + Tr;
Model.Prot.TimingTable.Mat = [ Tmt ; Ts ; Tp ; Tr ; TR ];

% *** To change other option, go directly in qMRLab ***

% Update the model and 
Model = Model.UpdateFields;

% Compute SfTable if necessary
Prot = Model.GetProt;
Model.ProtSfTable = CacheSf(Prot);

%**************************************************************************
% II- LOAD EXPERIMENTAL DATA
%**************************************************************************
% Create a struct "data" that contains all the data
% .MAT file : load('DATA_FILE');
%             data.DATA = double(DATA);
% .NII file : data.DATA = double(load_nii_data('DATA_FILE'));
data = struct;
load('MTdata.mat');
data.MTdata	= double(MTdata);
load('R1map.mat');
data.R1map  = double(R1map);
load('B1map.mat');
data.B1map  = double(B1map);
load('B0map.mat');
data.B0map  = double(B0map);
load('Mask.mat');
data.Mask   = double(Mask);

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
voxel           = [34, 46, 1];
FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
dataVox         = extractvoxel(data,voxel);
Model.plotmodel(FitResultsVox,dataVox)

%**************************************************************************
% V- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults);
save('SPGRParameters.mat','Model');

%% Check the results
% Load them in qMRLab
