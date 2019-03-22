function [dat,hdr,list] = load_nii_datas(filename,untouch)
% [dat,hdr,list] = load_nii_datas(filename,untouch) loads nifti files
% if multiple files, the first image is used as reference
% INPUT
%   filename        char (handles wildcards **/ and *) or cell array of char
%   untouch         if false or empty, matrix is rotated to be in LPI
%                    orientation
%
% OUTPUT
%   dat             cell array of 4D matrix
%   hdr             header of the reference image (first image)
%   list            cell array of char listing filenames (useful if wildcards were used)
%
% EXAMPLE
%   [dat,hdr,list] = load_nii_datas('**\*.nii.gz')
%   img = cat(5,dat{:});
%   img = mean(img,5);
%   save_nii_datas(img,hdr,'Tmean.nii.gz')

if ~isdeployed
    A = which('nii_tool');
    if isempty(A)
        warning('Dependency to Xiangrui Li NIFTI tools is missing. http://www.mathworks.com/matlabcentral/fileexchange/42997');
        return
    end
end

if ~iscell(filename)
    if strcmp(filename(1:min(3,end)),'**/') || strcmp(filename(1:min(3,end)),'**\')
        list = tools_ls(filename(4:end),1,1,2,1);
    else
        list = tools_ls(filename,1,1,2,0);
    end
else
    list = filename;
end
list(cellfun(@ischar,list)) = cellfun(@(X) X{1},cellfun(@(X) strsplit(X,','),list(cellfun(@ischar,list)),'uni',0),'uni',0);

if isempty(list)
    error(['no files match ' filename])
end

%reslice images
if isstruct(list{1})
    hdr0 = list{1};
else
    hdr0 = nii_tool('hdr', list{1});
end
quat2R = nii_viewer('func_handle', 'quat2R');
if hdr0.sform_code>0
    R0 = [hdr0.srow_x; hdr0.srow_y; hdr0.srow_z; 0 0 0 1];
elseif hdr0.qform_code>0
    R0 = quat2R(hdr0);
end

del = [];
for ff=2:length(list)
    % same space???
    hdr = nii_tool('hdr', list{ff});
    if hdr.sform_code>0
        R1 = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
    elseif hdr.qform_code>0
        R1 = quat2R(hdr);
    else
        R1 = diag([1 1 1 1]);
    end
    % reslice
    if max(max(abs(R0-R1)))>1e-5
        originalfilename = list{ff};
        list{ff} = [tempname '.nii'];
        nii_xform(originalfilename,list{1},list{ff})
        del = [del ff];
    end
end

dat = {};
for iii=1:length(list)
    if isstruct(list{iii}) && isfield(list{iii},'img')
        nii = list{iii};
    elseif ischar(list{iii})
        nii = nii_tool('load',list{iii});
    else
        continue
    end
    if nargin==1 || (~isempty(untouch) && ~untouch)
        [nii.hdr, orient] = change_hdr(nii.hdr);
        nii = rotateimage(nii,orient);
    end
    if iii==1
        hdr = nii.hdr;
    end
    nii = nii.img;
    dat(end+1:end+size(nii(:,:,:,:,:),5)) = mat2cell(nii(:,:,:,:,:),size(nii,1),size(nii,2),size(nii,3),size(nii,4),ones(1,size(nii(:,:,:,:,:),5)));
end

% delete resliced images
for ff=del
    delete(list{ff})
end

function [list, path]=tools_ls(fname, keeppath, keepext, folders,arborescence,select)
% [list, path]=tools_ls(fname, keeppath?, keepext?, folders?,recursive?)
% Example: tools_ls('ep2d*')
% example 2: tools_ls('*',[],[],1) --> folders only
% example 3: tools_ls('*',[],[],2) --> files only

if nargin < 2, keeppath=0; end
if nargin < 3, keepext=1; end
if nargin < 4 || isempty(folders), folders=0; end
if nargin < 6 || isempty(select), select=0; end
if nargin < 5, arborescence=0; end

% [list, path]=tools_ls('*T.txt);
list=dir(fname);
[path,name,ext]= fileparts(fname); 
path=[path filesep]; name = [name ext];
if strcmp(path,filesep)
    path=['.' filesep];
end

if folders==1
    list=list(cat(1,list.isdir));
elseif folders==2
    list=list(~cat(1,list.isdir));
end

% sort by name
list=sort_nat({list.name})';


% remove files starting with .
list(cellfun(@(x) strcmp(x(1),'.'), list))=[];
if keeppath
    for iL=1:length(list)
        list{iL}=[path list{iL}];
    end
end
pathcur = path;
path = repmat({path},[length(list),1]);

if ~keepext
    list=cellfun(@(x) sct_tool_remove_extension(x,keeppath),list,'UniformOutput',false);
end

if arborescence
    listdir = tools_ls(pathcur,1,1,1);
    for idir = 1:length(listdir)
        [listidir, pathidir]=tools_ls([listdir{idir} filesep name], keeppath, keepext, folders,arborescence,0);
        list = [list; listidir];
        path = cat(1,path, pathidir{:});
    end
end

if select, list=list{select}; end

function [hdr, orient] = change_hdr(hdr)
hdr.original = hdr;
tolerance = 1;
preferredForm = 's';
orient = [1 2 3];
affine_transform = 1;

%  NIFTI can have both sform and qform transform. This program
%  will check sform_code prior to qform_code by default.
%
%  If user specifys "preferredForm", user can then choose the
%  priority.					- Jeff
%
useForm=[];					% Jeff

if isequal(preferredForm,'S')
    if isequal(hdr.sform_code,0)
        error('User requires sform, sform not set in header');
    else
        useForm='s';
    end
end						% Jeff

if isequal(preferredForm,'Q')
    if isequal(hdr.qform_code,0)
        error('User requires qform, qform not set in header');
    else
        useForm='q';
    end
end						% Jeff

if isequal(preferredForm,'s')
    if hdr.sform_code > 0
        useForm='s';
    elseif hdr.qform_code > 0
        useForm='q';
    end
end						% Jeff

if isequal(preferredForm,'q')
    if hdr.qform_code > 0
        useForm='q';
    elseif hdr.sform_code > 0
        useForm='s';
    end
end						% Jeff

if isequal(useForm,'s')
    R = [hdr.srow_x(1:3)
        hdr.srow_y(1:3)
        hdr.srow_z(1:3)];
    
    T = [hdr.srow_x(4)
        hdr.srow_y(4)
        hdr.srow_z(4)];
    
    if det(R) == 0 || ~isequal(R(find(R)), sum(R)')
        R_sort = sort(abs(R(:)));
        if tolerance ==1
            R(2:3,1) = 0; R([1,3],2) = 0; R(1:2,3) = 0;
        else
            R( find( abs(R) < tolerance*min(R_sort(end-2:end)) ) ) = 0;
        end
        hdr.new_affine = [ [R;[0 0 0]] [T;1] ];
        
        if det(R) == 0 || ~isequal(R(find(R)), sum(R)')
            msg = [char(10) char(10) '   Non-orthogonal rotation or shearing '];
            msg = [msg 'found inside the affine matrix' char(10)];
            msg = [msg '   in this NIfTI file. You have 3 options:' char(10) char(10)];
            msg = [msg '   1. Using included ''reslice_nii.m'' program to reslice the NIfTI' char(10)];
            msg = [msg '      file. I strongly recommand this, because it will not cause' char(10)];
            msg = [msg '      negative effect, as long as you remember not to do slice' char(10)];
            msg = [msg '      time correction after using ''reslice_nii.m''.' char(10) char(10)];
            msg = [msg '   2. Using included ''load_untouch_nii.m'' program to load image' char(10)];
            msg = [msg '      without applying any affine geometric transformation or' char(10)];
            msg = [msg '      voxel intensity scaling. This is only for people who want' char(10)];
            msg = [msg '      to do some image processing regardless of image orientation' char(10)];
            msg = [msg '      and to save data back with the same NIfTI header.' char(10) char(10)];
            msg = [msg '   3. Increasing the tolerance to allow more distortion in loaded' char(10)];
            msg = [msg '      image, but I don''t suggest this.' char(10) char(10)];
            msg = [msg '   To get help, please type:' char(10) char(10) '   help reslice_nii.m' char(10)];
            msg = [msg '   help load_untouch_nii.m' char(10) '   help load_nii.m'];
            error(msg);
        end
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
    
    T = [hdr.qoffset_x
        hdr.qoffset_y
        hdr.qoffset_z];
    
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
    if det(R) == 0 | ~isequal(R(find(R)), sum(R)')
        
        %  det(R) == 0 is not a common trigger for this ---
        %  R(find(R)) is a list of non-zero elements in R; if that
        %  is straight (not oblique) then it should be the same as
        %  columnwise summation. Could just as well have checked the
        %  lengths of R(find(R)) and sum(R)' (which should be 3)
        %
        R_sort = sort(abs(R(:)));
        if tolerance ==1
            R(2:3,1) = 0; R([1,3],2) = 0; R(1:2,3) = 0;
        else
            R( find( abs(R) < tolerance*min(R_sort(end-2:end)) ) ) = 0;
        end
        R = R * diag([i j k]);
        hdr.new_affine = [ [R;[0 0 0]] [T;1] ];
        
        if det(R) == 0 | ~isequal(R(find(R)), sum(R)')
            msg = [char(10) char(10) '   Non-orthogonal rotation or shearing '];
            msg = [msg 'found inside the affine matrix' char(10)];
            msg = [msg '   in this NIfTI file. You have 3 options:' char(10) char(10)];
            msg = [msg '   1. Using included ''reslice_nii.m'' program to reslice the NIfTI' char(10)];
            msg = [msg '      file. I strongly recommand this, because it will not cause' char(10)];
            msg = [msg '      negative effect, as long as you remember not to do slice' char(10)];
            msg = [msg '      time correction after using ''reslice_nii.m''.' char(10) char(10)];
            msg = [msg '   2. Using included ''load_untouch_nii.m'' program to load image' char(10)];
            msg = [msg '      without applying any affine geometric transformation or' char(10)];
            msg = [msg '      voxel intensity scaling. This is only for people who want' char(10)];
            msg = [msg '      to do some image processing regardless of image orientation' char(10)];
            msg = [msg '      and to save data back with the same NIfTI header.' char(10) char(10)];
            msg = [msg '   3. Increasing the tolerance to allow more distortion in loaded' char(10)];
            msg = [msg '      image, but I don''t suggest this.' char(10) char(10)];
            msg = [msg '   To get help, please type:' char(10) char(10) '   help reslice_nii.m' char(10)];
            msg = [msg '   help load_untouch_nii.m' char(10) '   help load_nii.m'];
            error(msg);
        end
        
    else
        R = R * diag([i j k]);
    end					% 1st det(R)
    
else
    affine_transform = 0;	% no sform or qform transform
end

if affine_transform == 1
    voxel_size = abs(sum(R,1));
    inv_R = inv(R);
    originator = inv_R*(-T)+1;
    orient = get_orient(inv_R);
    
    %  modify pixdim and originator
    %
    %hdr.dime.pixdim(2:4) = voxel_size;
    hdr.originator(1:3) = originator;
    
    %  set sform or qform to non-use, because they have been
    %  applied in xform_nii
    %
    hdr.qform_code = 0;
    hdr.sform_code = 0;
end

%  apply space_unit to pixdim if not 1 (mm)
%
space_unit = get_units(hdr);

if space_unit ~= 1
    hdr.pixdim(2:4) = hdr.pixdim(2:4) * space_unit;
    
    %  set space_unit of xyzt_units to millimeter, because
    %  voxel_size has been re-scaled
    %
    hdr.xyzt_units = char(bitset(hdr.xyzt_units,1,0));
    hdr.xyzt_units = char(bitset(hdr.xyzt_units,2,1));
    hdr.xyzt_units = char(bitset(hdr.xyzt_units,3,0));
end

hdr.pixdim = abs(hdr.pixdim);

function orient = get_orient(R)

orient = [];

for i = 1:3
    switch find(R(i,:)) * sign(sum(R(i,:)))
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

function [space_unit, time_unit] = get_units(hdr)

switch bitand(hdr.xyzt_units, 7)	% mask with 0x07
    case 1
        space_unit = 1e+3;		% meter, m
    case 3
        space_unit = 1e-3;		% micrometer, um
    otherwise
        space_unit = 1;			% millimeter, mm
end

switch bitand(hdr.xyzt_units, 56)	% mask with 0x38
    case 16
        time_unit = 1e-3;			% millisecond, ms
    case 24
        time_unit = 1e-6;			% microsecond, us
    otherwise
        time_unit = 1;			% second, s
end

function nii = rotateimage(nii,orient)
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
    
    for i = 1:3
        if flip_orient(i)
            if ~isempty(pattern)
                pattern = flipdim(pattern, i);
            else
                nii.img = flipdim(nii.img, i);
            end
        end
    end
    
    %  get index of orient (rotate inversely)
    %
    [tmp rot_orient] = sort(rot_orient);
    
    new_dim = old_dim;
    new_dim = new_dim(rot_orient);
    nii.hdr.dim([2:4]) = new_dim;
    
    new_pixdim = nii.hdr.pixdim([2:4]);
    new_pixdim = new_pixdim(rot_orient);
    nii.hdr.pixdim([2:4]) = new_pixdim;
    
    %  re-calculate originator
    %
    tmp = nii.hdr.originator([1:3]);
    tmp = tmp(rot_orient);
    flip_orient = flip_orient(rot_orient);
    
    for i = 1:3
        if flip_orient(i) && ~isequal(tmp(i), 0)
            tmp(i) = new_dim(i) - tmp(i) + 1;
        end
    end
    
    nii.hdr.originator([1:3]) = tmp;
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
