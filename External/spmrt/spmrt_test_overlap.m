function [mJ, ,mHD, overlap] = spmrt_test_overlap(source,target,opt)

% routine that calls image_overlap testing multiple levels of the source
% onto the target 
%
% FORMAT
%
% INPUT 
%  - source and target are matrices
%  - source is a probability tissue class mri image and we test for
%        diferent levels of probability (deciles) how it is similar
%        to the target
%  - target is a binary image, this is the reference or ground truth
%        image
%  - opt is a structure of option for image_overlap.m
%
% OUTPUT
%   - mJ: the modified Jaccard index (see Ref here under)
%   - mHd: the mean Hausdorff distance between the 2 surfaces.
%   - overlap is a structure from image_overlap.m
% 
% Cyril Pernet - The university of Edinburgh 23 Sept 2016
% -------------------------------------------------------

parfor d=1:10
    tmp = source.*(source>(d/10)-0.1);
    [mJ(d),mHd(d),overlap(d)] = image_overlap(source,target,opt);
end