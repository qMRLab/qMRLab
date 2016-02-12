function varargout = nii_xform(src, target, rst, intrp, missVal)
% Transform a NIfTI into different resolution, or into a space of a template.
% 
%  NII_XFORM('sourceNiiName', 'templateNiiName', 'resultNiiName')
%  NII_XFORM('sourceNiiName', [1 1 1], 'resultNiiName')
%  nii = NII_XFORM('sourceNiiName', 'templateNiiName');
%  NII_XFORM('src', {'tempNiiName' 'xformMatFile'}, 'rstNiiName')
%  NII_XFORM('src', 'temp', 'rst', 'nearest', 0)
% 
% NII_XFORM transforms the source NIfTI file, so it has the requested resolution
% or has the same dimension and resolution as the provided template NIfTI file.
% 
% Input (first two mandatory):
%  1. source file name to be transformed (nii, hdr or compressed versions).
%  2. The second input determines how to transform the source file:
%    (1) If it is a vector of length 3, [2 2 2] for example, it will be treated
%         as requested resolution in millimeter. The result will be in the same
%         coordinate system as the source file.
%    (2) If it is a nii file name, it will be treated as the template name
%        (only hdr will be used). The result will have the same dimension and
%        resolution as the template. The source file and the template must have
%        at least one common coordinate system, otherwise the transformation
%        doesn't make sense, and it will error out. With different coordinate
%        systems, a transformation matrix to align the two dataset is needed,
%        which is the next case.
%    (3) If the input is a cellstr containing two file names, it will be
%        interpreted as a template nii file and a matrix file. The matrix file
%        must be a text file with 4x4 transformation matrix which aligns the
%        source data to the template (like those from FSL, and only FSL mat
%        files are tested for now). It may look like:
%          0.9983  -0.0432  -0.0385  -17.75  
%          0.0476   0.9914   0.1216  -14.84  
%          0.0329  -0.1232   0.9918  111.12  
%          0        0        0       1  
%  3. result file name. If not provided or empty, nii struct will be returned.
%     This allows one to use the returned nii in script without saving to file.
%  4. interpolation method, default 'linear'. It can also be one of 'nearest',
%     'cubic' and 'spline'.
%  5. value for missing data, default NaN. This is the value assigned to the
%     location in template where no data is available in the source file.
% 
% Output (optional): nii struct.
%  NII_XFORM will return the struct if the output is requested or result file
%  name is not provided.
% 
% Please note that, once the transformation is applied to functional data, it is
% normally invalid to perform slice timing correction. Also the data type is
% changed to single unless the interpolation is 'nearest'.
% 
% See also NII_VIEWER, NII_TOOL, DICM2NII

% By Xiangrui Li (xiangrui.li@gmail.com)
% History(yymmdd):
% 151024 Write it.

narginchk(2, 5);
if nargin<3, rst = []; end
if nargin<4 || isempty(intrp), intrp = 'linear'; end
if nargin<5 || isempty(missVal), missVal = nan; end
intrp = lower(intrp);
    
nii = nii_tool('load', src);
if iscell(target) % transformation and template file names
    fid = fopen(target{2});
    if fid<0, error('Transformation file not found.'); end
    R = str2num(fread(fid, '*char')'); %#ok
    fclose(fid);
    
    hdr = nii_tool('hdr', target{1});
    if hdr.sform_code>0, R0 = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
    elseif hdr.qform_code>0, R0 = quat2R(hdr);
    end
    
    if nii.hdr.sform_code>0
        R1 = [nii.hdr.srow_x; nii.hdr.srow_y; nii.hdr.srow_z; 0 0 0 1];
    elseif nii.hdr.qform_code>0
        R1 = quat2R(nii.hdr);
    end
    
    % I thought it is something like R = R0 \ R * R1; but it is way off. It
    % seems the location info in src nii is irrevelant, but direction must be
    % used: Left-handed storage and Right-handed storage give exactly the same
    % alignment R with the same target nii (left-handed). Alignment R may not be
    % diag-major, and can be negative for major axes (e.g. cor/sag slices).
    
    % Following works for tested FSL .mat files: Any better way?
    R = R0 / diag([hdr.pixdim(2:4) 1]) * R * diag([nii.hdr.pixdim(2:4) 1]);
    [~, i1] = max(abs(R1(1:3,1:3)));
    [~, i0] = max(abs(R(1:3,1:3)));
    flp = sign(R(i0+[0 4 8])) ~= sign(R1(i1+[0 4 8]));
    if any(flp)
        rotM = diag([1-flp*2 1]);
        rotM(1:3,4) = (nii.hdr.dim(2:4)-1).* flp;
        R = R / rotM;
    end
elseif ischar(target) % template file name
    hdr = nii_tool('hdr', target);
elseif isnumeric(target) && numel(target)==3 % new resolution in mm
    hdr = nii.hdr;
    ratio = target(:)' ./ hdr.pixdim(2:4);
    hdr.pixdim(2:4) = target;
    hdr.dim(2:4) = round(hdr.dim(2:4) ./ ratio);
    if hdr.sform_code>0
        hdr.srow_x(1:3) = hdr.srow_x(1:3) .* ratio;
        hdr.srow_y(1:3) = hdr.srow_y(1:3) .* ratio;
        hdr.srow_z(1:3) = hdr.srow_z(1:3) .* ratio;
    end
else
    error('Invalid template or resolution input.');
end

if ~iscell(target) 
    s = hdr.sform_code;
    q = hdr.sform_code;
    if s>0 && any(s == [nii.hdr.sform_code nii.hdr.qform_code])
        R0 = [hdr.srow_x; hdr.srow_y; hdr.srow_z; 0 0 0 1];
        frm = s;
    elseif any(q == [nii.hdr.sform_code nii.hdr.qform_code])
        R0 = quat2R(hdr);
        frm = q;
    else
        error('No matching transformation between source and template.');
    end

    if nii.hdr.sform_code == frm
        R = [nii.hdr.srow_x; nii.hdr.srow_y; nii.hdr.srow_z; 0 0 0 1];
    else
        R = quat2R(nii.hdr);
    end
end

dim = single(hdr.dim(2:4));
[Y, X, Z] = meshgrid(1:dim(2), 1:dim(1), 1:dim(3));
I = [X(:) Y(:) Z(:)]'-1; I(4,:) = 1; % template ijk
I = R \ (R0 * I) + 1; % ijk+1 (fraction) in source
clear X Y Z;
I = reshape(I(1:3,:)', [dim 3]);

d47 = nii.hdr.dim(5:8);
d47(d47<1 | d47>32767) = 1;
if strcmp(intrp, 'nearest'), 
    img = nii.img;
    nii.img = zeros([dim d47], class(img)); %#ok
else
    img = single(nii.img);
    nii.img = zeros([dim d47], 'single');
end
d8 = size(img, 8); % in case of RGB
for i8=1:d8; for i7=1:d47(4); for i6=1:d47(3); for i5=1:d47(2); for i4=1:d47(1) %#ok
    nii.img(:,:,:,i4,i5,i6,i7,i8) = interp3(img(:,:,:,i4,i5,i6,i7,i8), ...
        I(:,:,:,2), I(:,:,:,1), I(:,:,:,3), intrp, missVal);
end; end; end; end; end

% copy xform info from template to rst nii
nii.hdr.pixdim(1:4) = hdr.pixdim(1:4);
flds = {'qform_code' 'sform_code' 'srow_x' 'srow_y' 'srow_z' ...
    'quatern_b' 'quatern_c' 'quatern_d' 'qoffset_x' 'qoffset_y' 'qoffset_z'};
for i=1:numel(flds), nii.hdr.(flds{i}) = hdr.(flds{i}); end

if ~isempty(rst), nii_tool('save', nii, rst); end
if nargout || isempty(rst), varargout{1} = nii_tool('update', nii); end

%% quatenion to xform_mat
function R = quat2R(hdr)
b = hdr.quatern_b;
c = hdr.quatern_c;
d = hdr.quatern_d;
a = sqrt(1-b^2-c^2-d^2);
R = [1-2*(c^2+d^2)  2*(b*c-d*a)     2*(b*d+c*a);
     2*(b*c+d*a)    1-2*(b^2+d^2)   2*(c*d-b*a);
     2*(b*d-c*a )   2*(c*d+b*a)     1-2*(b^2+c^2)];
R = R * diag(hdr.pixdim(2:4));
if hdr.pixdim(1)<0, R(:,3)= -R(:,3); end
R = [R [hdr.qoffset_x hdr.qoffset_y hdr.qoffset_z]'; 0 0 0 1];
