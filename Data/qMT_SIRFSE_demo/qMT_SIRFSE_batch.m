% Command Line Interface (CLI) is well-suited for automatization 
% purposes and Octave. 

% Please execute this m-file section by section to get familiar with batch
% processing for qmt_sirfse on CLI.

% This m-file has been automatically generated. 

% Written by: Agah Karakuzu, 2017
% =========================================================================

%% AUXILIARY SECTION - (OPTIONAL) -----------------------------------------
% -------------------------------------------------------------------------

qMRinfo('qmt_sirfse'); % Display help 
[pathstr,fname,ext]=fileparts(which('qmt_sirfse_batch.m'));
cd (pathstr);

%% STEP|CREATE MODEL OBJECT -----------------------------------------------
%  (1) |- This section is a one-liner.
% -------------------------------------------------------------------------

Model = qmt_sirfse; % Create model object

%% STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------
%  (2)	|- This section will pop-up the options GUI. (MATLAB Only)
%		|- Octave is not GUI compatible. 
% -------------------------------------------------------------------------

if not(moxunit_util_platform_is_octave) % ---> If MATLAB
Custom_OptionsGUI(Model);
Model = getappdata(0,'Model');
end



%% STEP |LOAD PROTOCOL ----------------------------------------------------
%  (3)	|- Respective command lines appear if required by qmt_sirfse. 
% -------------------------------------------------------------------------

% qmt_sirfse object needs 2 protocol field(s) to be assigned:
 

% MTdata
% FSEsequence
% --------------
% Ti is a vector of [25X1]
Ti = [0.0030; 0.0037; 0.0047; 0.0058; 0.0072; 0.0090; 0.0112; 0.0139; 0.0173; 0.0216; 0.0269; 0.0335; 0.0417; 0.0519; 0.0646; 0.0805; 0.1002; 0.1248; 0.1554; 0.1935; 0.2409; 0.3000; 1.0000; 2.0000; 10.0000];
% Td is a vector of [25X1]
Td = [3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000; 3.5000];
Model.Prot.MTdata.Mat = [ Ti Td];
% -----------------------------------------
Trf  = 0.001;
Tr  = 0.01;
Npulse = 16;
Model.Prot.FSEsequence.Mat = [ Trf  Tr  Npulse];
% -----------------------------------------



%% STEP |LOAD EXPERIMENTAL DATA -------------------------------------------
%  (4)	|- Respective command lines appear if required by qmt_sirfse. 
% -------------------------------------------------------------------------
% qmt_sirfse object needs 3 data input(s) to be assigned:
 

% MTdata
% R1map
% Mask
% --------------

data = struct();
% MTdata.nii.gz contains [128  128    1   25] data.
data.MTdata=double(load_nii_data('MTdata.nii.gz'));
% Mask.nii.gz contains [128  128] data.
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

save -mat7-binary 'qmt_sirfse_FitResultsOctave.mat' 'FitResults';

else % ---> If MATLAB 

qMRsaveModel(Model,'qmt_sirfse.qMRLab.mat'); 

end

% You can save outputs in Nifti format using FitResultSave_nii function:
% Plase see qMRinfo('FitResultsSave_nii')




