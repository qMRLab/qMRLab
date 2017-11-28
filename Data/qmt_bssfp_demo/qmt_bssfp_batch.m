% Command Line Interface (CLI) is well-suited for automatization 
% purposes and Octave. 

% Please execute this m-file section by section to get familiar with batch
% processing for qmt_bssfp on CLI.

% This m-file has been automatically generated. 

% Written by: Agah Karakuzu, 2017
% =========================================================================

%% AUXILIARY SECTION - (OPTIONAL) -----------------------------------------
% -------------------------------------------------------------------------

qMRinfo('qmt_bssfp'); % Display help 
[pathstr,fname,ext]=fileparts(which('qmt_bssfp_batch.m'));
cd (pathstr);

%% STEP|CREATE MODEL OBJECT -----------------------------------------------
%  (1) |- This section is a one-liner.
% -------------------------------------------------------------------------

Model = qmt_bssfp; % Create model object

%% STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------
%  (2)	|- This section will pop-up the options GUI. (MATLAB Only)
%		|- Octave is not GUI compatible. 
% -------------------------------------------------------------------------

if not(moxunit_util_platform_is_octave) % ---> If MATLAB
Custom_OptionsGUI(Model);
Model = getappdata(0,'Model');
end



%% STEP |LOAD PROTOCOL ----------------------------------------------------
%  (3)	|- Respective command lines appear if required by qmt_bssfp. 
% -------------------------------------------------------------------------

% qmt_bssfp object needs 1 protocol field(s) to be assigned:
 

% MTdata
% --------------
% Alpha is a vector of [16X1]
Alpha = [5.0000; 10.0000; 15.0000; 20.0000; 25.0000; 30.0000; 35.0000; 40.0000; 35.0000; 35.0000; 35.0000; 35.0000; 35.0000; 35.0000; 35.0000; 35.0000];
% Trf is a vector of [16X1]
Trf = [0.0003; 0.0003; 0.0003; 0.0003; 0.0003; 0.0003; 0.0003; 0.0003; 0.0002; 0.0003; 0.0004; 0.0006; 0.0008; 0.0012; 0.0016; 0.0021];
Model.Prot.MTdata.Mat = [ Alpha Trf];
% -----------------------------------------



%% STEP |LOAD EXPERIMENTAL DATA -------------------------------------------
%  (4)	|- Respective command lines appear if required by qmt_bssfp. 
% -------------------------------------------------------------------------
% qmt_bssfp object needs 3 data input(s) to be assigned:
 

% MTdata
% R1map
% Mask
% --------------

data = struct();
% MTdata.nii.gz contains [128  128    1   16] data.
data.MTdata=double(load_nii_data('MTdata.nii.gz'));
% Mask.nii.gz contains [128  128] data.
data.Mask=double(load_nii_data('Mask.nii.gz'));
% R1map.nii.gz contains [128  128] data.
data.R1map=double(load_nii_data('R1map.nii.gz'));
 

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

save -mat7-binary 'qmt_bssfp_FitResultsOctave.mat' 'FitResults';

else % ---> If MATLAB 

qMRsaveModel(Model,'qmt_bssfp.qMRLab.mat'); 

end

% You can save outputs in Nifti format using FitResultSave_nii function:
% Plase see qMRinfo('FitResultsSave_nii')




