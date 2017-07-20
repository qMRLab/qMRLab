function [dist,mnix] = surfaceslice2(vol,XYZ,chunksz,delta)

% function [dist,mnix] = surfaceslice2(vol,XYZ,chunksz,delta)
% 
% <vol> is a 3D binary volume
% <XYZ> is 4 x coordinates where the coordinates are in the
%   matrix space of <vol>
% <chunksz> is the number of slices of <vol> (in the third dimension)
%   to process at one time
% <delta> is the distance along the slice dimension within which we
%   will consider vertices.  for example, if <chunksz> is 3 and
%   <delta> is 4, then we might process slices 50-52 and consider
%   vertices within 46-56 in the slice dimension.
%
% for the voxels marked in <vol>, compute 3D matrices:
%   <dist> indicates distance to the closest vertex
%   <mnix> indicates the index of the closest vertex
% voxels not marked in <vol> have NaNs in <dist> and <mnix>.
%
% the point of <chunksz> is to reduce memory usage.
% the point of <delta> is to speed up computation; we do a sanity check
%   to make sure that the speed up is valid (if not, we relax the
%   speed up until it works).

% figure out coordinates of the selected voxels
sel = vflatten(find(vol));
[ii,jj,kk] = ind2sub(size(vol),sel);

% loop over subvolumes in the third dimension of vol
chunks = chunking(1:size(vol,3),chunksz);
dist = NaN*zeros(size(vol));
mnix = NaN*zeros(size(vol));
for p=1:length(chunks)
  statusdots(p,length(chunks));
  
  % calc
  firstix = chunks{p}(1);
  lastix = chunks{p}(end);

  % loop until it works
  deltaUSE = delta;
  while 1
  
    % throw away vertices that are more than deltaUSE away from the edges of the subvolume
    goodv = find(XYZ(3,:) >= firstix-deltaUSE & XYZ(3,:) <= lastix+deltaUSE);
    
    %%% MAYBE: if goodv empty, increase delta and go?
  
    % extract the mask voxels to do now
    ok = find(kk>=firstix & kk<=lastix);

    % loop
    [dist(sel(ok)),temp] = min(sqrt(bsxfun(@minus,XYZ(1,goodv),ii(ok)).^2 + ...
                                   bsxfun(@minus,XYZ(2,goodv),jj(ok)).^2 + ...
                                   bsxfun(@minus,XYZ(3,goodv),kk(ok)).^2),[],2);
    mnix(sel(ok)) = goodv(temp);
  
    % sanity check that our speed-up was valid
    if all(dist(sel(ok))<deltaUSE)
      break;
    else
      fprintf('surfaceslice2: incrementing deltaUSE.\n');
      deltaUSE = deltaUSE + 1;
    end

  end

end
