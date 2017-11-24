<<<<<<< HEAD:Data/InversionRecovery_demo/InversionRecovery_batch.m
%Place in the right folder to run
cdmfile('InversionRecovery_batch.m');

warning('off','all');
%% DESCRIPTION
help InversionRecovery
% Batch to process Inversion Recovery data without qMRLab GUI (graphical user interface)
% Run this script line by line

%**************************************************************************
%% I- LOAD DATASET
%**************************************************************************
% Create Model object
Model = InversionRecovery;
% Load Inversion Recovery Protocol (list of inversion times, in ms)
Model.Prot.IRData.Mat = txt2mat('TI.txt');
%**************************************************************************
%% II - Perform Simulations
%**************************************************************************

% Generate MR Signal using analytical equation and perform sensitivity
% analysis
%
% Call Sensitivity_Analysis addons and click update
% Sim_Sensitivity_Analysis_GUI(Model);
%
% Alternatively use command line:
Opt=struct;
Opt.Nofrun = 50; % Run simulation with additive noise 50 times
Opt. SNR   = 50;

%             'T1'    'rb'    'ra'
OptTable.fx = [false   true   true];  % Vary T1...
OptTable.lb = [100     nan      nan]; % ...between 100..
OptTable.ub = [2000    nan      nan]; % and 2000ms
OptTable.st = [nan    -1000     500]; % Define nominal values for rb and ra

% SimVaryGUI
SimVaryResults = Sim_Sensitivity_Analysis(Model, OptTable, Opt);
figure
SimVaryPlot(SimVaryResults,'T1','T1')

%**************************************************************************
%% III - MRI Data Fitting
%**************************************************************************
% data required:
disp(Model.MRIinputs)
% load data
data = struct;
data.IRData = load_nii_data('IRData.nii.gz');

% plot fit in one voxel
voxel = [70 60 20];
datavox.IRData = squeeze(data.IRData(voxel(1),voxel(2),voxel(3),:));
FitResults = Model.fit(datavox);
Model.plotModel(FitResults,datavox)

% all voxels (slice 23 only to go faster)
Mask=load_nii_data('Mask.nii.gz');
data.Mask = false(size(Mask));
data.Mask(:,:,23) = Mask(:,:,23); % fit slice 23 only

FitResults = FitData(data,Model);
delete('FitTempResults.mat');

%**************************************************************************
%% IV- SAVE
%**************************************************************************
% .MAT file : FitResultsSave_mat(FitResults,folder);
% .NII file : FitResultsSave_nii(FitResults,fname_copyheader,folder);
FitResultsSave_nii(FitResults,'IRData.nii.gz'); % use header from 'IRData.nii.gz'
save('IRParameters.mat','Model');

%% Check the results
% Load them in qMRLab
=======
% Command Line Interface (CLI) is well-suited for automatization 
% purposes and Octave. 

% Please execute this m-file section by section to get familiar with batch
% processing for inversion_recovery on CLI.

% This m-file has been automatically generated. 

% Written by: Agah Karakuzu, 2017
% =========================================================================

%% AUXILIARY SECTION - (OPTIONAL) -----------------------------------------
% -------------------------------------------------------------------------

qMRinfo('inversion_recovery'); % Display help 
[pathstr,fname,ext]=fileparts(which('inversion_recovery_batch.m'));
cd (pathstr);

%% STEP|CREATE MODEL OBJECT -----------------------------------------------
%  (1) |- This section is a one-liner.
% -------------------------------------------------------------------------

Model = inversion_recovery; % Create model object

%% STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------
%  (2)	|- This section will pop-up the options GUI. (MATLAB Only)
%		|- Octave is not GUI compatible. 
% -------------------------------------------------------------------------

if not(moxunit_util_platform_is_octave) % ---> If MATLAB
Custom_OptionsGUI(Model);
Model = getappdata(0,'Model');
end



%% STEP |LOAD PROTOCOL ----------------------------------------------------
%  (3)	|- Respective command lines appear if required by inversion_recovery. 
% -------------------------------------------------------------------------

% inversion_recovery object needs 1 protocol field(s) to be assigned:
 

% IRData
% --------------
% TI(ms) is a vector of [9X1]
TI = [350.0000; 500.0000; 650.0000; 800.0000; 950.0000; 1100.0000; 1250.0000; 1400.0000; 1700.0000];
Model.Prot.IRData.Mat = [ TI];
% -----------------------------------------



%% STEP |LOAD EXPERIMENTAL DATA -------------------------------------------
%  (4)	|- Respective command lines appear if required by inversion_recovery. 
% -------------------------------------------------------------------------
% inversion_recovery object needs 2 data input(s) to be assigned:
 

% IRData
% Mask
% --------------

data = struct();
% IRData.nii.gz contains [128  128   45    9] data.
data.IRData=double(load_nii_data('IRData.nii.gz'));
% Mask.nii.gz contains [128  128   45] data.
data.Mask=double(load_nii_data('Mask.nii.gz'));
 

%% STEP |FIT DATASET ------------------------------------------------------
%  (5)  |- This section will fit data. 
% -------------------------------------------------------------------------

FitResults = FitData(data,Model,0);

FitResults.Model = Model; % qMRLab output.

%% STEP |CHECK FITTING RESULT IN A VOXEL - (OPTIONAL) ---------------------
%   (6)	|- To observe outputs, please execute this section.
% -------------------------------------------------------------------------

% Read output  ---> 
%{
outputIm = FitResults.(FitResults.fields{1});
row = round(size(outputIm,1)/2);
col = round(size(outputIm,2)/2);
voxel           = [row, col, 1]; % Please adapt 3rd index if 3D. 
%}

% Show plot  ---> 
% Warning: This part may not be available for all models.
%{
figure();
FitResultsVox   = extractvoxel(FitResults,voxel,FitResults.fields);
dataVox         = extractvoxel(data,voxel);
Model.plotModel(FitResultsVox,dataVox)
%}

% Show output map ---> 
%{ 
figure();
imagesc(outputIm); colorbar(); title(FitResults.fields{1});
%}


%% STEP |SAVE -------------------------------------------------------------
%  	(7) |- Save your outputs. 
% -------------------------------------------------------------------------

if moxunit_util_platform_is_octave % ---> If Octave 

save -mat7-binary 'inversion_recovery_FitResultsOctave.mat' 'FitResults';

else % ---> If MATLAB 

qMRsaveModel(Model,'inversion_recovery.qMRLab.mat'); 

end

% You can save outputs in Nifti format using FitResultSave_nii function:
% Plase see qMRinfo('FitResultsSave_nii')




>>>>>>> 4429dc669997c933346a530414c9a07122ecca8e:Data/inversion_recovery_demo/inversion_recovery_batch.m
