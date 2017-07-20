function [vols,brainmask,polymodel] = homogenizevolumes(vols,knobs,wantsingle,brainmask,xyz)

% function [vols,brainmask] = homogenizevolumes(vols,knobs,wantsingle,brainmask,xyz)
%
% <vols> is a 4D volume (X x Y x Z x T) or a cell vector of 4D volumes.
%   these volumes should be suitable for interpretation as double
%   (though they do not need to be passed in as double).  the 
%   first three dimensions must be consistent across cases.
%   alternatively, <vols> can be specified as V x T (or a cell vector of those).
%   each column is a set of values defined for V points.  this case is 
%   detected if ndims is less than 3, and in this case, <xyz> must be supplied. 
% <knobs> (optional) is [A B C D] with various constants used in
%   the analysis.  see below for details.  default: [99 1/4 5 10].
% <wantsingle> (optional) is whether you want to apply exactly the same 
%   correction to all volumes.  default: 0.
% <brainmask> (optional) is a direct specification of the "brain" voxels to use.
%   should be X x Y x Z (or V x 1) with 0/1 indicating the "brain" voxels.
%   default is to use a intensity-based scheme (see below).
% <xyz> (optional) should be supplied when <vols> is of the V x T case.
%   <xyz> should be V x 3 with the x-, y-, and z-coordinates of the V points.
%
% first, we determine the "brain" voxels by selecting voxels in the 
% mean volume (mean across all volumes) that are at least B of
% the Ath percentile of all values in the mean volume.  then,
% we homogenize each volume by fitting a 3D polynomial of degree up 
% to C to the "brain" voxels and then dividing the whole volume by 
% the fitted polynomial.  if <wantsingle>, then we fit a single 
% 3D polynomial to the mean volume; if not <wantsingle>, we fit 
% individual 3D polynomials to each volume.  to ensure reasonable 
% results, before the division the fitted polynomial is massaged 
% such that any negative values are set to Inf (so that they 
% result in 0 after division) and values are truncated at 1/D of 
% the maximum value in the fitted polynomial in the "brain" voxels
% (so that the maximum scaling to be applied is D).
%
% note that the behavior of the polynomials depends on the reference frame
% and ranges with respect to which the polynomials are evaluated. when <vols>
% are 4D volumes, the reference frame is given by the natural indexing scheme
% of the matrices (e.g. x ranges from 1:64, y ranges from 1:64, z ranges from 1:20).
% when <vols> is specified as V x T, the reference frame is given by the empirical min 
% and max along each dimension of <xyz>. if any of these reference frames is changed,
% the behavior of this function may change completely.
%
% return the homogenized volumes in double format in <vols>.
% the dimensions will be exactly the same as what was passed in for <vols>.
% the general range of values will be 0 to 1, although values greater than
% 1 are possible.  also, return <brainmask> as X x Y x Z (or V x 1) with 0/1
% indicating the "brain" voxels.
%
% history:
% 2016/04/10 - add point-wise case (<vols> as V x T and use of <xyz>)
% 2011/03/28 - use inv method for the polynomial fitting to save memory
% 2011/03/26 - fix bug --- we now consider only the brain voxels when 
%              determining the max value of the polynomial.  this does 
%              change results with respect to previous behavior.
% 2011/03/26 - change default to [99 1/4 5 10]
%
% example:
% vol = getsamplebrain(4);
% vol = vol(:,:,:,1);
% volB = homogenizevolumes(vol);
% figure; imagesc(makeimagestack(vol)); colorbar;
% figure; imagesc(makeimagestack(volB)); colorbar;

% input
if ~exist('knobs','var') || isempty(knobs)
  knobs = [99 1/4 5 10];
end
if ~exist('wantsingle','var') || isempty(wantsingle)
  wantsingle = 0;
end
if ~exist('brainmask','var') || isempty(brainmask)
  brainmask = [];
end
if ~exist('xyz','var') || isempty(xyz)
  xyz = [];
end
isbare = ~iscell(vols);
if isbare
  vols = {vols};
end
vcase = ndims(vols{1}) < 3;  % whether vertex case
nn = choose(vcase,1,3);  % how many dimensions to squish together

% calc
if vcase
  xyzsize = [size(vols{1},1) 1];            % [V 1]
  xyzsizeB = [xyzsize(1)];                  % [V]
else
  xyzsize = sizefull(vols{1},3);            % [X Y Z]
  xyzsizeB = xyzsize;                       % [X Y Z]
end
numvoxels = prod(xyzsize);                % total number of voxels
polydeg = knobs(3);                       % max poly degree to use
polyfactor = knobs(4);                    % what is the maximum scaling factor to apply?

% calc brainmask
if isempty(brainmask)
  meanvol = mean(catcell(nn+1,vols),nn+1);  % mean volume.  could have NaNs.
  highval = prctile(meanvol(:),knobs(1));   % what is a high signal intensity value?
  lowval = highval*knobs(2);                % what is a low value?
  brainmask = meanvol >= lowval;            % where are brain voxels?
else
  brainmask = logical(brainmask);
end

% prepare volumes by dividing by a fitted polynomial
if vcase
  rngs = [min(xyz,[],1); max(xyz,[],1)];                                    % [min; max] as 2 x 3 (to ensure a fixed reference frame)
  pmatrix = constructpolynomialmatrix3d(rngs,xyz,polydeg);                  % locs x basis (all voxels)
  pmatrixB = constructpolynomialmatrix3d(rngs,xyz(brainmask,:),polydeg);    % locs x basis (voxels in brain mask)
else
  pmatrix = constructpolynomialmatrix3d(xyzsize,1:numvoxels,polydeg);       % locs x basis (all voxels)
  pmatrixB = constructpolynomialmatrix3d(xyzsize,find(brainmask),polydeg);  % locs x basis (voxels in brain mask)
end
omatrix = olsmatrix(pmatrixB,1);  % basis x maskvoxels

% single case, calc global polymodel (X x Y x Z)
if wantsingle

  % determine weighting parameters
  params = omatrix*mean(catcell(2,cellfun(@(x) double(subscript(squish(x,nn),{find(brainmask) ':'})),vols,'UniformOutput',0)),2);  % basisparameters x 1

  % calculate full polynomial model
  polymodel = reshape(pmatrix*params,[xyzsize]);  % same X Y Z (or V 1) as the vols{p}

  % massage the model
  isneg = polymodel < 0;
  minpoly = max(polymodel(brainmask))/polyfactor;  % this should be the minimum (positive) value
  istoolow = polymodel >= 0 & polymodel < minpoly;
  polymodel(isneg) = Inf;  % if poly is negative, just set that voxel to 0
  polymodel(istoolow) = minpoly;  % do not allow the poly to result in more than polyfactor scaling

end

% do it
for p=1:length(vols)

  % calculate individualized polymodel (X x Y x Z x T)
  if ~wantsingle

    % determine weighting parameters
    params = omatrix*double(subscript(squish(vols{p},nn),{find(brainmask) ':'}));  % basisparameters x timepoints
    
    % calculate full polynomial model
    polymodel = reshape(pmatrix*params,[xyzsizeB size(params,2)]);  % same X Y Z T (or V T) as the vols{p}
    
    % massage the model
    isneg = polymodel < 0;
    minpoly = repmat(reshape(max(subscript(squish(polymodel,nn),{find(brainmask) ':'}),[],1)/polyfactor, ...
                             [ones(1,nn) size(polymodel,nn+1)]),xyzsize);  % this should be the minimum (positive) value
    istoolow = polymodel >= 0 & polymodel < minpoly;
    polymodel(isneg) = Inf;  % if poly is negative, just set that voxel to 0
    polymodel(istoolow) = minpoly(istoolow);  % do not allow the poly to result in more than polyfactor scaling
    
  end

  % do it
  vols{p} = bsxfun(@rdivide,double(vols{p}),polymodel);
  
end

% prepare output
if isbare
  vols = vols{1};
end
