%% DESCRIPTION
% Batch to process CHARMED data without qMRLab GUI (graphical user interface)
% Run this script line by line
qMRinfo('NODDI'); % Display help 
%Make sure user is in the correct directory
[pathstr,fname,ext]=fileparts(which('NODDI_batch.m'));
cd (pathstr);

%**************************************************************************
%% I- Create Model object
%**************************************************************************
% Create Model object 
Model = NODDI;
Custom_OptionsGUI(Model)
%**************************************************************************
%% II- LOAD Diffusion Protocol
%**************************************************************************
% Convert bvec/bvals to schemefile ('Gx'  'Gy'  'Gz'  '|G|'  'Delta'  'delta'  'TE')
% NOTE: Valid for protocols with relatively low bvalue (i.e. bvalue<4000s/mm2)
%        Approximate diffusion pulse duration (delta) and separation (Delta)
Gmax = 80; % mT/m. maximal diffusion gradient capacity
scd_schemefile_FSLconvert('bval.txt', 'bvec.txt', Gmax, 'scheme.txt');
% load protocol
Model.Prot.DiffusionData.Mat = txt2mat('scheme.txt');

%**************************************************************************
%% II - Perform Simulations
%**************************************************************************

% Generate MR Signal using analytical equation
x = struct;
x.ficvf = 0.5;
x.di = 1.7;
x.kappa = 0.5;
x.fiso = 0;
x.diso = 3;
x.b0 = 1;
x.theta = 0.2;
x.phi = 0;
Opt.SNR = 50;
figure
FitResults = Model.Sim_Single_Voxel_Curve(x,Opt);

% compare FitResults and input x
SimResult = table(struct2mat(x,Model.xnames)',struct2mat(FitResults,Model.xnames)','RowNames',Model.xnames,'VariableNames',{'input_x','FitResults'})

%**************************************************************************
%% III - MRI Data Fitting
%**************************************************************************
% load data
data = struct;
data.DiffusionData = load_nii_data('DifffusionData.nii.gz');

% plot fit in one voxel
voxel = [74 45 28];
datavox = extractvoxel(data,voxel);
FitResults = Model.fit(datavox)
Model.plotModel(FitResults,datavox)

% all voxels
data.Mask=load_nii_data('Mask.nii.gz');
FitResults = FitData(data,Model,1);

%**************************************************************************
%% V- SAVE MAPS
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults,'DifffusionData.nii.gz');

%**************************************************************************
%% V- SAVE MODEL (options + protocol) FOR DISTRIBUTION
%**************************************************************************
%save('NODDIParameters.mat','Model');

%% Check the results
% Load them in qMRLab
