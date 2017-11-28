% Command Line Interface (CLI) is well-suited for automatization 
% purposes and Octave. 

% Please execute this m-file section by section to get familiar with batch
% processing for vfa_t1 on CLI.

% This m-file has been automatically generated. 

% Written by: Agah Karakuzu, 2017
% =========================================================================

%% AUXILIARY SECTION - (OPTIONAL) -----------------------------------------
% -------------------------------------------------------------------------

qMRinfo('vfa_t1'); % Display help 
[pathstr,fname,ext]=fileparts(which('vfa_t1_batch.m'));
cd (pathstr);

%% STEP|CREATE MODEL OBJECT -----------------------------------------------
%  (1) |- This section is a one-liner.
% -------------------------------------------------------------------------

Model = vfa_t1; % Create model object

%% STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------
%  (2)	|- This section will pop-up the options GUI. (MATLAB Only)
%		|- Octave is not GUI compatible. 
% -------------------------------------------------------------------------

if not(moxunit_util_platform_is_octave) % ---> If MATLAB
Custom_OptionsGUI(Model);
Model = getappdata(0,'Model');
end



%% STEP |LOAD PROTOCOL ----------------------------------------------------
%  (3)	|- Respective command lines appear if required by vfa_t1. 
% -------------------------------------------------------------------------

% vfa_t1 object needs 1 protocol field(s) to be assigned:
 

% SPGR
% --------------
% FlipAngle is a vector of [2X1]
FlipAngle = [3.0000; 20.0000];
% TR is a vector of [2X1]
TR = [0.0150; 0.0150];
Model.Prot.SPGR.Mat = [ FlipAngle TR];
% -----------------------------------------



%% STEP |LOAD EXPERIMENTAL DATA -------------------------------------------
%  (4)	|- Respective command lines appear if required by vfa_t1. 
% -------------------------------------------------------------------------
% vfa_t1 object needs 2 data input(s) to be assigned:
 

% VFAData
% B1map
% --------------

data = struct();
% B1map.nii.gz contains [128  128] data.
data.B1map=double(load_nii_data('B1map.nii.gz'));
% VFAData.nii.gz contains [128  128    1    2] data.
data.VFAData=double(load_nii_data('VFAData.nii.gz'));
 

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

save -mat7-binary 'vfa_t1_FitResultsOctave.mat' 'FitResults';

else % ---> If MATLAB 

qMRsaveModel(Model,'vfa_t1.qMRLab.mat'); 

end

% You can save outputs in Nifti format using FitResultSave_nii function:
% Plase see qMRinfo('FitResultsSave_nii')




