function FitResultsSave_nii(FitResults,fname_copyheader,folder)
% Save FitResutls with headers copied from nifti file
% FitResultsSave_nii(FitResults,fname_copyheader)
% FitResultsSave_nii(FitResults,fname_copyheader,folder)
%
% Example:
%   FitResultsSave_nii(FitResults,'merged_crop_eddy_moco.nii')
if ~exist('folder','var'), folder = 'FitResults'; end
mkdir(folder)
for i = 1:length(FitResults.fields)
    map = FitResults.fields{i};
    file = strcat(map,'.nii');
    save_nii_v2(FitResults.(map),fullfile(folder,file),fname_copyheader,64);
end
save(fullfile(folder,'FitResults.mat'),FitResults)