%Place in the right folder to run
cdmfile('CHARMED_batch.m');

%% DESCRIPTION
% Batch to process CHARMED data without qMRLab GUI (graphical user interface)
% Run this script line by line
qMRinfo('CHARMED'); % Display help 
%**************************************************************************
%% I- LOAD MODEL
%**************************************************************************

% Create Model object 
Model = CHARMED;
% Load Diffusion Protocol
% TODO: Explain how Protocol.txt should be created
Model.Prot.DiffusionData.Mat = txt2mat('Protocol.txt');

%**************************************************************************
%% II - Perform Simulations
%**************************************************************************
% See info/usage of Sim_Single_Voxel_Curve
qMRusage(Model,'Sim_Single_Voxel_Curve')

% Let's try Sim_Single_Voxel_Curve
opt.SNR = 50;
x.fr = .5;
x.Dh = .7; % um2/ms
x.diameter_mean = 6; % um
x.fcsf = 0;
x.lc=0;
x.Dcsf=3;
x.Dintra = 1.4;
FitResults = Model.Sim_Single_Voxel_Curve(x,opt);
% compare FitResults and input x
SimResult = table(struct2mat(x,Model.xnames)',struct2mat(FitResults,Model.xnames)','RowNames',Model.xnames,'VariableNames',{'input_x','FitResults'})

% to try other Simulations methods, type:
% qMRusage(Model,'Sim_*')

%**************************************************************************
%% III - MRI Data Fitting
%**************************************************************************
% load data
data = struct;
data.DiffusionData = load_nii_data('DiffusionData.nii.gz');
data.Mask=load_nii_data('Mask.nii.gz');

% plot fit in one voxel
voxel = [32 29];
datavox.DiffusionData = squeeze(data.DiffusionData(voxel(1),voxel(2),:,:));
FitResults = Model.fit(datavox)
Model.plotModel(FitResults,datavox)

% fit all voxels (coffee break)
FitResults = FitData(data,Model,1);
% save maps
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
% FitResultsSave_nii(FitResults,'DiffusionData.nii.gz');
%save('CHARMEDParameters.mat','Model');
FitResultsSave_nii(FitResults,'DiffusionData.nii.gz');

%% Check the results
% Load them in qMRLab
