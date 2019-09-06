function nii = nii_reset_orient(hdr, img)
% nii_reset_orient(hdr, img)
% Put back orientation in original orientation

if isfield(hdr,'rot_orient') && ~isempty(hdr.rot_orient)
    [~, unrotate_orient] = sort(hdr.rot_orient);
    if nargin>1
        img = permute(img, [unrotate_orient 4 5 6 7]);
    end
    hdr.pixdim(2:4) = hdr.pixdim(unrotate_orient+1);
    hdr.dim(2:4) = hdr.dim(unrotate_orient+1);
end

if nargin>1
    if isfield(hdr,'flip_orient') && ~isempty(hdr.flip_orient)
        flip_orient = hdr.flip_orient(unrotate_orient);
        
        for ii = 1:3
            if flip_orient(ii)
                img = flip(img, ii);
            end
        end
    end
    nii.img = img;
    nii.hdr = hdr;
else
    nii = hdr;
end

