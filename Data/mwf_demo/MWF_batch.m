% Command Line Interface (CLI) is well-suited for automatization 
% purposes and Octave. 

% Please execute this m-file section by section to get familiar with batch
% processing for mwf on CLI.

% This m-file has been automatically generated. 

% Written by: Agah Karakuzu, 2017
% =========================================================================

%% AUXILIARY SECTION - (OPTIONAL) -----------------------------------------
% -------------------------------------------------------------------------

qMRinfo('mwf'); % Display help 
[pathstr,fname,ext]=fileparts(which('mwf_batch.m'));
cd (pathstr);

%% STEP|CREATE MODEL OBJECT -----------------------------------------------
%  (1) |- This section is a one-liner.
% -------------------------------------------------------------------------

Model = mwf; % Create model object

%% STEP |CHECK DATA AND FITTING - (OPTIONAL) ------------------------------
%  (2)	|- This section will pop-up the options GUI. (MATLAB Only)
%		|- Octave is not GUI compatible. 
% -------------------------------------------------------------------------

if not(moxunit_util_platform_is_octave) % ---> If MATLAB
Custom_OptionsGUI(Model);
Model = getappdata(0,'Model');
end



%% STEP |LOAD PROTOCOL ----------------------------------------------------
%  (3)	|- Respective command lines appear if required by mwf. 
% -------------------------------------------------------------------------

% mwf object needs 1 protocol field(s) to be assigned:
 

% MET2data
% --------------
% EchoTime (ms) is a vector of [32X1]
EchoTime  = [10.0000; 20.0000; 30.0000; 40.0000; 50.0000; 60.0000; 70.0000; 80.0000; 90.0000; 100.0000; 110.0000; 120.0000; 130.0000; 140.0000; 150.0000; 160.0000; 170.0000; 180.0000; 190.0000; 200.0000; 210.0000; 220.0000; 230.0000; 240.0000; 250.0000; 260.0000; 270.0000; 280.0000; 290.0000; 300.0000; 310.0000; 320.0000];
Model.Prot.MET2data.Mat = [ EchoTime ];
% -----------------------------------------



%% STEP |LOAD EXPERIMENTAL DATA -------------------------------------------
%  (4)	|- Respective command lines appear if required by mwf. 
% -------------------------------------------------------------------------
% mwf object needs 2 data input(s) to be assigned:
 

% MET2data
% Mask
% --------------

data = struct();
 
% MET2data.mat contains [64  64   1  32] data.
 load('MET2data.mat');
% Mask.mat contains [64  64] data.
 load('Mask.mat');
 data.MET2data= double(MET2data);
 data.Mask= double(Mask);

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

save -mat7-binary 'mwf_FitResultsOctave.mat' 'FitResults';

else % ---> If MATLAB 

qMRsaveModel(Model,'mwf.qMRLab.mat'); 

end

% You can save outputs in Nifti format using FitResultSave_nii function:
% Plase see qMRinfo('FitResultsSave_nii')




