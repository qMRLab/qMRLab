function save_nii_datas(img,hdr,FileName)
% save_nii_datas(img,hdr,FileName) save the matrix img in nifti

nii.img = unxform_nii(hdr,img);
nii.hdr = hdr.original;
nii_tool('save',nii,FileName)


function outblock = unxform_nii(hdr, inblock)

if isempty(hdr.rot_orient)
    outblock=inblock;
else
    [~, unrotate_orient] = sort(hdr.rot_orient);
    outblock = permute(inblock, [unrotate_orient 4 5 6 7]);
end

if ~isempty(hdr.flip_orient)
    flip_orient = hdr.flip_orient(unrotate_orient);
    
    for i = 1:3
        if flip_orient(i)
            outblock = flip(outblock, i);
        end
    end
end
