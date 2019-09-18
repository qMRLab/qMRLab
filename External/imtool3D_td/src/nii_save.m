function nii_save(img,hdr,FileName)
% nii_save(img,hdr,FileName) save the matrix img in nifti
% img and hdr must have been loaded with nii_load

nii = nii_reset_orient(hdr,img);
nii_tool('save',nii,FileName)