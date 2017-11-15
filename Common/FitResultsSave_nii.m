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
    file = strcat(map,'.nii.gz');
    if ~exist('fname_copyheader','var') || isempty(fname_copyheader)
        save_nii_v2(make_nii(FitResults.(map)),fullfile(folder,file),[],64);
    else
    save_nii_v2(FitResults.(map),fullfile(folder,file),fname_copyheader,64);
    end
end
if moxunit_util_platform_is_octave % octave cannot save models
    FitResults = rmfield(FitResults,'Model');
end
save(fullfile(folder,'FitResults.mat'),'-struct','FitResults')