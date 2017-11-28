% Command Line Interface (CLI) is well-suited for automatization 
% purposes and Octave. 

% Please execute this m-file section by section to get familiar with batch
% processing for mt_sat on CLI.

% This m-file has been automatically generated. 

% Written by: Agah Karakuzu, 2017
% =========================================================================

%% AUXILIARY SECTION - (OPTIONAL) -----------------------------------------
% -------------------------------------------------------------------------

qMRinfo('mt_sat'); % Display help 
[pathstr,fname,ext]=fileparts(which('mt_sat_batch.m'));
cd (pathstr);

%% STEP|CREATE MODEL OBJECT -----------------------------------------------
%  (1) |- This section is a one-liner.
% -------------------------------------------------------------------------

Model = mt_sat; % Create model object

%% STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------
%  (2)	|- This section will pop-up the options GUI. (MATLAB Only)
%		|- Octave is not GUI compatible. 
% -------------------------------------------------------------------------

if not(moxunit_util_platform_is_octave) % ---> If MATLAB
Custom_OptionsGUI(Model);
Model = getappdata(0,'Model');
end



%% STEP |LOAD PROTOCOL ----------------------------------------------------
%  (3)	|- Respective command lines appear if required by mt_sat. 
% -------------------------------------------------------------------------

% mt_sat object needs 3 protocol field(s) to be assigned:
 

% MT
% T1
% PD
% --------------
FlipAngle = 6;
TR  = 0.028;
Offset  = 1000;
Model.Prot.MT.Mat = [ FlipAngle TR  Offset ];
% -----------------------------------------
FlipAngle = 20;
TR = 0.018;
Model.Prot.T1.Mat = [ FlipAngle TR];
% -----------------------------------------
FlipAngle = 6;
TR = 0.028;
Model.Prot.PD.Mat = [ FlipAngle TR];
% -----------------------------------------



%% STEP |LOAD EXPERIMENTAL DATA -------------------------------------------
%  (4)	|- Respective command lines appear if required by mt_sat. 
% -------------------------------------------------------------------------
% mt_sat object needs 4 data input(s) to be assigned:
 

% MTw
% T1w
% PDw
% Mask
% --------------

data = struct();
% MTw.nii.gz contains [128  128   96] data.
data.MTw=double(load_nii_data('MTw.nii.gz'));
% PDw.nii.gz contains [128  128   96] data.
data.PDw=double(load_nii_data('PDw.nii.gz'));
% T1w.nii.gz contains [128  128   96] data.
data.T1w=double(load_nii_data('T1w.nii.gz'));
 

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

save -mat7-binary 'mt_sat_FitResultsOctave.mat' 'FitResults';

else % ---> If MATLAB 

qMRsaveModel(Model,'mt_sat.qMRLab.mat'); 

end

% You can save outputs in Nifti format using FitResultSave_nii function:
% Plase see qMRinfo('FitResultsSave_nii')




