function nii = nii_set_orient(nii)
% nii = nii_set_orient(nii)   Rotate nii.img into LPI orientation 
%
% Add the following fields:
%   nii.hdr.rot_orient      permute dimensions
%   nii.hdr.flip_orient     flip    dimensions

% get orient
orient = nii_get_orient(nii);

if ~isequal(orient, [1 2 3])
    nii.hdr.dim(nii.hdr.dim==0)=1;
    old_dim = nii.hdr.dim([2:4]);
    
    %  More than 1 time frame
    %
    if ndims(nii.img) > 3
        pattern = 1:prod(old_dim);
    else
        pattern = [];
    end
    
    if ~isempty(pattern)
        pattern = reshape(pattern, old_dim);
    end
    
    %  calculate for rotation after flip
    %
    rot_orient = mod(orient + 2, 3) + 1;
    
    %  do flip:
    %
    flip_orient = orient - rot_orient;
    
    for ii = 1:3
        if flip_orient(ii)
            if ~isempty(pattern)
                pattern = flipdim(pattern, ii);
            else
                nii.img = flipdim(nii.img, ii);
            end
        end
    end
    
    %  get index of orient (rotate inversely)
    %
    [~, rot_orient] = sort(rot_orient);
    
    new_dim = old_dim;
    new_dim = new_dim(rot_orient);
    nii.hdr.dim([2:4]) = new_dim;
    
    new_pixdim = nii.hdr.pixdim([2:4]);
    new_pixdim = new_pixdim(rot_orient);
    nii.hdr.pixdim([2:4]) = new_pixdim;
    
    %  re-calculate originator

    flip_orient = flip_orient(rot_orient);
    nii.hdr.rot_orient = rot_orient;
    nii.hdr.flip_orient = flip_orient;
    
    %  do rotation:
    %
    if ~isempty(pattern)
        pattern = permute(pattern, rot_orient);
        pattern = pattern(:);
        
        if nii.hdr.datatype == 32 | nii.hdr.datatype  == 1792 | ...
                nii.hdr.datatype  == 128 | nii.hdr.datatype  == 511
            
            tmp = reshape(nii.img(:,:,:,1), [prod(new_dim) nii.hdr.dim(5:8)]);
            tmp = tmp(pattern, :);
            nii.img(:,:,:,1) = reshape(tmp, [new_dim       nii.hdr.dim(5:8)]);
            
            tmp = reshape(nii.img(:,:,:,2), [prod(new_dim) nii.hdr.dim(5:8)]);
            tmp = tmp(pattern, :);
            nii.img(:,:,:,2) = reshape(tmp, [new_dim       nii.hdr.dim(5:8)]);
            
            if nii.hdr.datatype == 128 | nii.hdr.datatype == 511
                tmp = reshape(nii.img(:,:,:,3), [prod(new_dim) nii.hdr.dim(5:8)]);
                tmp = tmp(pattern, :);
                nii.img(:,:,:,3) = reshape(tmp, [new_dim       nii.hdr.dim(5:8)]);
            end
            
        else
            nii.img = reshape(nii.img, [prod(new_dim) nii.hdr.dim(5:8)]);
            nii.img = nii.img(pattern, :);
            nii.img = reshape(nii.img, [new_dim       nii.hdr.dim(5:8)]);
        end
    else
        if nii.hdr.datatype == 32 | nii.hdr.datatype == 1792 | ...
                nii.hdr.datatype == 128 | nii.hdr.datatype == 511
            
            nii.img(:,:,:,1) = permute(nii.img(:,:,:,1), rot_orient);
            nii.img(:,:,:,2) = permute(nii.img(:,:,:,2), rot_orient);
            
            if nii.hdr.datatype == 128 | nii.hdr.datatype == 511
                nii.img(:,:,:,3) = permute(nii.img(:,:,:,3), rot_orient);
            end
        else
            nii.img = permute(nii.img, rot_orient);
        end
    end
else
    nii.hdr.rot_orient = [];
    nii.hdr.flip_orient = [];
end
