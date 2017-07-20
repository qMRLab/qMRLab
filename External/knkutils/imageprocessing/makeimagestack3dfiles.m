function makeimagestack3dfiles(m,outputprefix,skips,rots,cmap,wantnorm,addborder,csize,bordersize)

% function makeimagestack3dfiles(m,outputprefix,skips,rots,cmap,wantnorm,addborder,csize,bordersize)
%
% <m> is a 3D matrix or a NIFTI file
% <outputprefix> is a path to a file prefix
% <skips> (optional) is number of slices to skip in each of the 3 dimensions.
%   Default: [1 1 1].
% <rots> (optional) is a 3-vector with number of CCW rotations to apply for each slicing.
%   Default: [0 0 0].
% <cmap> (optional) is colormap to use. Default: gray(256).
% <wantnorm> (optional) is as in makeimagestack.m
% <addborder> (optional) is as in makeimagestack.m
% <csize> (optional) is as in makeimagestack.m
% <bordersize> (optional) is as in makeimagestack.m
%
% We take <m> and write out three .png files, one for each slicing:
%   <outputprefix>_view1.png
%   <outputprefix>_view2.png
%   <outputprefix>_view3.png
%
% The first slicing is through the third dimension with ordering [1 2 3].
% The second slicing is through the second dimension with ordering [1 3 2].
% The third slicing is through the first dimension with ordering [2 3 1].
% 
% After slicing, rotation (if supplied) is applied within the first 
% two dimensions using rotatematrix.m.
%
% example:
% vol = makegaussian3d([100 100 100],[.7 .3 .5],[.1 .4 .1]);
% makeimagestack3dfiles(vol,'test',[10 10 10],[],[],[0 1])

% input
if ~exist('skips','var') || isempty(skips)
  skips = [1 1 1];
end
if ~exist('rots','var') || isempty(rots)
  rots = [0 0 0];
end
if ~exist('cmap','var') || isempty(cmap)
  cmap = gray(256);
end
if ~exist('wantnorm','var') || isempty(wantnorm)
  wantnorm = 0;
end
if ~exist('addborder','var') || isempty(addborder)
  addborder = 1;
end
if ~exist('csize','var') || isempty(csize)
  csize = [];
end
if ~exist('bordersize','var') || isempty(bordersize)
  bordersize = 1;
end

% load data
if ischar(m)
  m = load_untouch_nii(gunziptemp(m));
  m = double(m.img);
end

% make directory
mkdirquiet(stripfile(outputprefix));

% define
permutes = {[1 2 3] [1 3 2] [2 3 1]};

% do it
for dim=1:3

  % deal with permute (slicing) and rotation
  temp = rotatematrix(permute(m,permutes{dim}),1,2,rots(dim));
  
  % deal with skips
  temp = temp(:,:,1:skips(dim):end);
  
  % make an image stack and write to .png file
  imwrite(uint8(255*makeimagestack(temp,wantnorm,addborder,csize,bordersize)), ...
          cmap,sprintf('%s_view%d.png',outputprefix,dim));

end
