% Command Line Interface (CLI) is well-suited for automatization 
% purposes and Octave. 

% Please execute this m-file section by section to get familiar with batch
% processing for b1_dam on CLI.

% This m-file has been automatically generated. 

% Written by: Agah Karakuzu, 2017
% =========================================================================

%% AUXILIARY SECTION - (OPTIONAL) -----------------------------------------
% -------------------------------------------------------------------------

qMRinfo('b1_dam'); % Display help 
[pathstr,fname,ext]=fileparts(which('b1_dam_batch.m'));
cd (pathstr);

%% STEP|CREATE MODEL OBJECT -----------------------------------------------
%  (1) |- This section is a one-liner.
% -------------------------------------------------------------------------

Model = b1_dam; % Create model object

%% STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------
%  (2)	|- This section will pop-up the options GUI. (MATLAB Only)
%		|- Octave is not GUI compatible. 
% -------------------------------------------------------------------------

if not(moxunit_util_platform_is_octave) % ---> If MATLAB
Custom_OptionsGUI(Model);
Model = getappdata(0,'Model');
end



%% STEP |LOAD PROTOCOL ----------------------------------------------------
%  (3)	|- Respective command lines appear if required by b1_dam. 
% -------------------------------------------------------------------------

% This object does not have protocol attributes.
 



%% STEP |LOAD EXPERIMENTAL DATA -------------------------------------------
%  (4)	|- Respective command lines appear if required by b1_dam. 
% -------------------------------------------------------------------------
% b1_dam object needs 2 data input(s) to be assigned:
 

% SF60
% SF120
% --------------

data = struct();
% SF120.nii.gz contains [64  64] data.
data.SF120=double(load_nii_data('SF120.nii.gz'));
% SF60.nii.gz contains [64  64] data.
data.SF60=double(load_nii_data('SF60.nii.gz'));
 

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

save -mat7-binary 'b1_dam_FitResultsOctave.mat' 'FitResults';

else % ---> If MATLAB 

qMRsaveModel(Model,'b1_dam.qMRLab.mat'); 

end

% You can save outputs in Nifti format using FitResultSave_nii function:
% Plase see qMRinfo('FitResultsSave_nii')




