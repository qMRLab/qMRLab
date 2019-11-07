function tool = imtool3D_nii_3planes(filename,varargin)
% NIFTI Viewer with axial, sagittal, coronal views
%
% EXAMPLES
%  imtool3D_nii_3planes fmri.nii.gz              Open fmri.nii.gz in current
%                                                folder
%  imtool3D_nii_3planes **/*fmri*.nii.gz         Open *fmri*.nii.gz files in
%                                                all subfolders
%  imtool3D_nii_3planes({'fmri.nii.gz', 'T1.nii.gz'})    Open fmri and T1
%                                                NIFTI files. fmri is used
%                                                as spatial reference.
%
% Tanguy DUVAL, INSERM, 2019
% SEE ALSO imtool3D, imtool3D_nii


if ~exist('filename','var'), filename=[]; end
tool = imtool3D_nii(filename,[1 2 3],varargin{:});