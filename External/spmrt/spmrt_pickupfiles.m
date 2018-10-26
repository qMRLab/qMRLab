function [image1,image2,masks]=spmrt_pickupfiles

% routine for users to pick up 3 images: img1, img2, and mask img
%
% FORMAT [image1,image2,mask]=spmrt_pickupfiles
%
% OUTPUT image1 is the 1st image file name
%        image2 is the 2nd image file name
%        mask is the mask image file name
%
% Cyril Pernet
% --------------------------------------------------------------------------
% Copyright (C) spmrt 

image1 = [];
image2 = [];
masks  = [];


[image1,sts] = spm_select(1,'image','select 1st image',{},pwd,'.*',1);
if sts == 0
    return
end


[image2,sts] = spm_select(1,'image','select 2nd image',{},pwd,'.*',1);
if sts == 0
    return
end

% note for mask the frame is [1 2 3 4] allowing a 4D file for instance
% brain mask, GM, WM, CSF -- or a series of 3D
[masks,sts] = spm_select(Inf,'image','select mask image(s)',{},pwd,'.*',[1 2 3 4]);
if sts == 0
    return
end
