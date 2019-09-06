function [orient, orientletter] = nii_get_orient(hdr)
% orient = nii_get_orient_hdr(hdr) GET orientation from the header of a NIFTI file
%
% OUTPUT
%   orient      1x3 vector of integers
%         1		% Left to Right
%         2     % Posterior to Anterior
%         3     % Inferior to Superior
%         4     % Right to Left
%         5     % Anterior to Posterior
%         6     % Superior to Inferior

% nii struct
if isfield(hdr,'img') && isfield(hdr,'hdr'), hdr = hdr.hdr; end

% header struct
if hdr.sform_code > 0
    useForm='s';
elseif hdr.qform_code > 0
    useForm='q';
end

affine_transform = 1;
if isequal(useForm,'s')
    R = [hdr.srow_x(1:3)
        hdr.srow_y(1:3)
        hdr.srow_z(1:3)];
        
    if det(R) == 0 % corrupted matrix
        R = [1 0 0;
             0 1 0;
             0 0 1];
    end
    
elseif isequal(useForm,'q')
    b = hdr.quatern_b;
    c = hdr.quatern_c;
    d = hdr.quatern_d;
    
    if 1.0-(b*b+c*c+d*d) < 0
        if abs(1.0-(b*b+c*c+d*d)) < 1e-5
            a = 0;
        else
            error('Incorrect quaternion values in this NIFTI data.');
        end
    else
        a = sqrt(1.0-(b*b+c*c+d*d));
    end
    
    qfac = hdr.pixdim(1);
    if qfac==0, qfac = 1; end
    i = hdr.pixdim(2);
    j = hdr.pixdim(3);
    k = qfac * hdr.pixdim(4);
    
    R = [a*a+b*b-c*c-d*d     2*b*c-2*a*d        2*b*d+2*a*c
        2*b*c+2*a*d         a*a+c*c-b*b-d*d    2*c*d-2*a*b
        2*b*d-2*a*c         2*c*d+2*a*b        a*a+d*d-c*c-b*b];
    
    
    %  qforms are expected to generate rotation matrices R which are
    %  det(R) = 1; we'll make sure that happens.
    %
    %  now we make the same checks as were done above for sform data
    %  BUT we do it on a transform that is in terms of voxels not mm;
    %  after we figure out the angles and squash them to closest
    %  rectilinear direction. After that, the voxel sizes are then
    %  added.
    %
    %  This part is modified by Jeff Gunter.
    %
    if det(R) == 0 % corrupted matrix
        R = [1 0 0;
            0 1 0;
            0 0 1];
        R = R * diag([i j k]);
    else
        R = R * diag([i j k]);
    end					% 1st det(R)
    
else
    affine_transform = 0;	% no sform or qform transform
end

if affine_transform == 1
    inv_R = inv(R);
    orient = get_orient(inv_R);
else
    orient = [1 2 3]; %
end

orientletter = {'' '' ''; '' '' ''};
for ii = 1:3
    switch orient(ii)
        case 1
            orientletter{1,ii} = 'L';
            orientletter{2,ii} = 'R';
        case 2
            orientletter{1,ii} = 'P';
            orientletter{2,ii} = 'A';
        case 3
            orientletter{1,ii} = 'I';
            orientletter{2,ii} = 'S';
        case 4
            orientletter{1,ii} = 'R';
            orientletter{2,ii} = 'L';
        case 5
            orientletter{1,ii} = 'A';
            orientletter{2,ii} = 'P';
        case 6
            orientletter{1,ii} = 'S';
            orientletter{2,ii} = 'I';
    end
end



function orient = get_orient(Rinv)

orient = [];

for i = 1:3
    [~,I] = max(abs(Rinv(i,:)));
    switch I * sign(Rinv(i,I))
        case 1
            orient = [orient 1];		% Left to Right
        case 2
            orient = [orient 2];		% Posterior to Anterior
        case 3
            orient = [orient 3];		% Inferior to Superior
        case -1
            orient = [orient 4];		% Right to Left
        case -2
            orient = [orient 5];		% Anterior to Posterior
        case -3
            orient = [orient 6];		% Superior to Inferior
    end
end
