function sct_merge_nii(flist,output)
% sct_merge_nii(flist,output)
% merge niftis in the 4th dimenstion.
% sct_merge_nii(sct_tools_ls('*dwi.nii'),'DWI.nii.gz') --> always .nii.gz

sct_unix(['fslmerge -t ' output ' ' strjoin(flist)])
    