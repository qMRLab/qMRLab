function opengz(gz)
% Open imtool3D by double click on a .nii.gz file in Matlab file browser
if strcmp(gz(max(end-6,1):end),'.nii.gz')
    imtool3D_nii_3planes(gz);
else
    gunzip(gz);
end