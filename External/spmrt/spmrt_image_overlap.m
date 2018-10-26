function [mJ,mHd,overlap] = spmrt_image_overlap(img1,img2,opt)

% This function computes the matching between 2 3D images, based on
% different measures:
% - the modified Jaccard index
% - the percentages of overlap between the two binary images.
%
% FORMAT:
%   [mJ,mHd] = image_overlap(img1,img2,opt);
%   [mJ,mHd,overlap] = image_overlap(img1,img2,opt);
%
% INPUT:
%   - img1 and img2 are two image names or matrices, by default assuming
%     these are binary images (but see opt below)
%     img1 can be seen as a source image and img2 as the reference
%     (ground truth) image to computes overlap of source to the reference
%     in that case only, is the overlap output a useful measure
%   - opt is a structure with a few processing options
%       .thr is the threshold applied to both images to binarize them,
%            otherwise any non-zero value is considered as 1.
%            By default, thr=0, i.e. no thresholding is performed.
%       .mask is a binary image indicating which pixels/voxels
%        have to be taken into account (name or matrix)
%        By default, no masking, i.e. [].
%       .v2r voxel-to-realworld coordinates transformation, for the case
%            where 3D arrays are passed directly.
%            By default, anisotropic of size 1mm3, i.e. eye(4).
%
% OUTPUT:
%   - mJ: the modified Jaccard index (see Ref here under)
%   - mHd: the mean Hausdorff distance between the 2 surfaces.
%   - overlap is a structure with the followign measures
%       .voxel   overlap computed over all positive/negative voxels
%       .cluster overlap computed over all positive clusters
%                this is reported only if more than one cluster is
%                found in the ground truth image (img2)
%
%       .voxel.tp:   percentage of img1 roi inside img2 roi this is the
%                        true positive rate (sensitivity)
%       .voxel.fp:   percentage of img1 roi inside img2 0 this is the
%                        false positive rate
%       .voxel.tn:   percentage of img1 0 inside img2 0 this is the
%                        true negative rate
%       .voxel.fn:   percentage of img1 0 inside img2 roi this is the
%                        false negative rate (specificity)
%       .voxel.cm:   confusion matrix [ TP FN ; FP TN ] counts
%       .voxel.mcc:  Matthews correlation coefficient  (see Ref here under)
%       .voxel.CK:   Cohen's Kappa
%
%       .cluster.tp: percentage of clusters in img1 roi matching img2
%       .cluster.fp: percentage of clusters in img1 not matching any in img2
%
% REFERENCES:
% The Jaccard index (1910) is defined as
%   J(A,B) = N(intersect(A,B)) / N(union(A,B))
%   <https://en.wikipedia.org/wiki/Jaccard_index>
%
% The modified Jaccard index follows Maitra (2010)
%   W(A,B) = N(intersect(A,B) / N(A)+N(B)-N(intersect(A,B))
%   <http://www.ncbi.nlm.nih.gov/pubmed/19963068>
%
% Haussdorf distance:
%   <https://en.wikipedia.org/wiki/Hausdorff_measure>
% Here use a modified form where the mean distance between the surfaces is
% calculated, instead of taking the maximum, i.e. the "average symmetric
% surface distance" as in the MS lesion segmentation challenge
%
% The confusion matrix follows the same convention as in
% <https://en.wikipedia.org/wiki/Confusion_matrix>
% that is [ TP FN ; FP TN ]
%
% The Matthews correlation coefficient is described here
%   <https://en.wikipedia.org/wiki/Matthews_correlation_coefficient>
%
% Cohen's Kappa is described here:
%   <https://en.wikipedia.org/wiki/Cohen's_kappa>
%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% NOTES:
% To execute this function using MRI images, the software SPM needs to be
% in your matlab path - see SPM <http://www.fil.ion.ucl.ac.uk/spm/>
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% Cyril R Pernet, wrote the basic of the code (mJ,tp,fp,fn,tn,mcc)
% The University of Edinburgh, NeuroImaging Sciences, UK.
%
% Christophe Phillips, speed-up confusion matrix, Cohen's K, Hausdorff dist
% University of Liege, GIGA - Research, Belgium

%%
% *Check input data*
opt_def = struct('thr',0,'mask',[],'v2r',eye(4)); % default options

if nargin == 0
    display_help_and_example % Simple example with synthetic images
    return
    
elseif nargin == 2
    opt = []; % Go with the defaults
    
elseif nargin < 2 || nargin > 3
    error('Two or three inputs are expected - FORMAT: [mJ,overlap] = percent_overlap(img1,img2,option)')
end
% Fill the opt structure with defaults
opt = crc_check_flag(opt_def,opt);
mJ = []; mHd = []; overlap = [];

%%
% * Check fisrt images in*
% they need to be of the same size and to have 0s
% vox-to-real world mapping is extracted from the 1st image, or set to the
% value in 'opt', possibly the default value eye(4)

% check format
if ischar(img1)
    if exist(img1,'file')
        V1 = spm_vol(img1);
        img1 =spm_read_vols(V1);
        v2r = V1.mat;
    else
        error('the file %s doesn''t exist',spm_file(img1,'filename'))
    end
else
    v2r = opt.v2r; % Use passed v2r or default one
end

if ischar(img2)
    if exist(img2,'file')
        V2 = spm_vol(img2);
        img2 =spm_read_vols(V2);
    else
        error('the file %s doesn''t exist',spm_file(img2,'filename'))
    end
end

% check dimensions
if any(size(img1)~=size(img2))
    error('img1 and img2 are not of the same size')
end

%%
% *Check the mask*

mask = opt.mask;  % a mask field will be there, empty or not.
if ~isempty(mask) % load if not empty
    if ischar(mask)
        if exist(mask,'file')
            V3 = spm_vol(mask);
            mask = spm_read_vols(V3);
        else
            error('the file %s doesn''t exist',fileparts(mask))
        end
    end
    
    if any(size(img1)~=size(mask))
        error('the mask is not of the same size as input images')
    end
    
    % invert the mask as logical
    if isnan(sum(mask(:)))
        mask(~isnan(mask)) = 0;
        mask(isnan(mask)) = 1;
    else
        mask = (mask==0);
    end
end

%%
% *Consider images as binary images & vectors and apply the mask*

% binarize
img1 = img1 > opt.thr;
img2 = img2 > opt.thr;

% vectorize
vimg1 = img1(:);
vimg2 = img2(:);
if ~isempty(mask)
    vimg1(mask(:)) = [];
    vimg2(mask(:)) = [];
end

%% Similarity measures
% ---------------------

%%
% *Compute Jaccard coefficient
I = sum((vimg1+vimg2)==2);
mJ = I / (sum(vimg1)+sum(vimg2)-I);

%%
% *Extract the mean Hausdorff distance*

% Get border coordinates in vx, not considering the mask!
if nargout >=2
    [iBx1,iBy1,iBz1] = crc_borderVx(img1);
    [iBx2,iBy2,iBz2] = crc_borderVx(img2);
    
    % Get coordinates in mm
    Bxyz1_mm = v2r(1:3,1:3)* [iBx1' ; iBy1' ; iBz1'];
    Bxyz2_mm = v2r(1:3,1:3)* [iBx2' ; iBy2' ; iBz2'];
    
    [mD,D12,D21] = crc_meanHausdorffDist(Bxyz1_mm,Bxyz2_mm);
    mHd = mean(mD);
end

%% Overlap measures to ground truth
% ----------------------------------

if nargout == 3
    
    %%
    % *Compute percentage of overalp at the cluster level*
    
    [L2,num2] = spm_bwlabel(double(img2),26);
    if num2 >1
        [L1,num1] = spm_bwlabel(double(img1),26);
        
        % for each cluster in img2 check if img1 has one too
        for n=1:num2
            NP(n) = length(intersect(find(img1),find(L2==n)));
            % divide by length(find(L2==n)) to get percentage per cluster;
        end
        overlap.cluster.tp = length(find(NP)) / num2;
        
        % for each cluster in img1 check if img2 has one too
        for n=1:num1
            NN(n) = length(intersect(find(L1==n),find(img2)));
        end
        overlap.cluster.fp = sum(NN==0) / num1;
    else
        overlap.cluster.tp = [];
        overlap.cluster.fp = [];
    end
    
    
    %%
    % *Compute percentage of overalp at the voxel level*
    TP = sum((vimg1+vimg2)==2);
    FN = sum((~vimg1+vimg2)==2);
    FP = sum((vimg1+~vimg2)==2);
    TN = sum((~vimg1+~vimg2)==2);
    overlap.voxel.cm = [ TP FN ; FP TN ];
    
    % percentage of vimg1 roi inside vimg2 roi
    tp = TP / sum(vimg2);
    overlap.voxel.tp = tp*100;
    
    % percentage of vimg1 0 inside vimg2 0
    tn = TN / sum(vimg2==0);
    overlap.voxel.tn = tn*100;
    
    % percentage of vimg1 roi inside vimg2 0
    fp = FP / sum(vimg2==0);
    overlap.voxel.fp = fp*100;
    
    % percentage of vimg1 0 inside vimg2 roi
    fn = FN / sum(vimg2);
    overlap.voxel.fn = fn *100;
    
    % Matthews correlation coefficient
    overlap.voxel.mcc = ((TP*TN)-(FP*FN))/sqrt((TP+FP)*(TP+FN)*(TN+FP)*(TN+FN));
    
    % Cohen's Kappa
    Po = (TP+TN)/sum(overlap.voxel.cm(:));
    Pr = (TP+TN)*(TP+FP)/sum(overlap.voxel.cm(:))^2;
    overlap.voxel.CK = (Po - Pr)/(1 - Pr);
    
end
end
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% SUBFUNCTIONS
%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function display_help_and_example
% Simple function to display the help and an example of its use.
help image_overlap
disp(' '); disp('a 2D exemple is displayed in the figure')

% this is a simple code check
index1 = 1:6; index2 = 7:12;
figure;
for move = 1:4
    img1 = zeros(12,12); img2 = img1;
    img1(index1,index1) = 1;
    img2(index2,index2) = 1;
    subplot(2,2,move); imagesc(img1+img2); drawnow
    A = image_overlap(img1,img2);
    TP = (sum((img1(:)+img2(:))==2)) / sum(img2(:));
    title(['overlap ' num2str(TP*100) '% mJ=' num2str(A)])
    index1 = index1+1; index2 = index2 -1;
end
end