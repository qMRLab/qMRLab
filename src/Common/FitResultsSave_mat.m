function FitResultsSave_mat(FitResults,folder)
% Save FitResutls with headers copied from nifti file
% FitResultsSave_nii(FitResults,fname_copyheader)
% FitResultsSave_nii(FitResults,fname_copyheader,folder)
%
% Example:
%   FitResultsSave_nii(FitResults,'merged_crop_eddy_moco.nii')
if ~exist('folder','var'), folder = 'FitResults'; end

if length(strfind(folder,filesep)) <= 1 && length(strfind(folder,['.' filesep]))~=1
% Normally users should pass folder variable in the ./myDir format to create folder
% myDir at their current directory. This condition guards against users who pass
% folder without './' expression preceding the folder name (e.g. myDir or /myDir).
% The conditional statement checks for the existence of this case, if present, 
% it prepends absolute path of the pwd to the folder name to ensure that 
% the folder is created without possibly conflicting with another folder that may 
% be saved in the MATLAB/Octave's search path (e.g. Test).

    folder = [pwd filesep folder];
    mkdir(folder);
end

if ~exist(folder,'dir')
% Avoids warnings to amazing users who would like to save somehting to an 
% existing directory using absolute path.   
    mkdir(folder)
end

for i = 1:length(FitResults.fields)
    map = FitResults.fields{i};
    file = strcat(map,'.mat');
    save(fullfile(folder,file),'-struct','FitResults',map);
end
if isfield(FitResults,'Model')
    FitResults.Model = objProps2struct(FitResults.Model);
end
save(fullfile(folder,'FitResults.mat'),'-struct','FitResults')