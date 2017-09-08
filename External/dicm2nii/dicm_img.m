function img = dicm_img(s, xpose)
% Read image of a dicom file.
% 
% img = dicm_img(metaStructOrFilename, xpose);
% 
% The mandatory first input is the dicom file name, or the struct returned by
% dicm_hdr. The output keeps the data type in dicom file.
% 
% The second input is for special purpose. When it is provided and is false, the
% returned img won't be transposed. This is likely only useful for dicm2nii.m,
% where the Columns and Rows parameters become counter-intuitive.
% 
% DICM_IMG is like dicomread from Matlab, but is independent of Image Processing
% Toolbox.
%
% See also DICM_HDR, DICM_DICT, DICM2NII

% TO DO: take care of BitsAllocated, BitsStored and HighBit related issue.
% Now we assume
%   HighBit is BitsStored-1;
%   extra bits beyond BitsStored are zeros.

% History (yymmdd):
% 130823 Write it for dicm2nii.m (xiangrui.li@gmail.com)
% 130914 Use PixelData.Bytes rather than nPixels;
%        Use PixelRepresentation to determine signed data.
% 130923 Use BitsAllocated for bits. Make it work for multiframe.
% 131018 Add jpeg de-compression part.
% 141023 Use memmapfile for temp file: ~25% speedup.
% 150109 Transpose img by default. dicm2nii needs xpose=0 to avoid transpose.
% 150115 SamplesPerPixel>1 works: put it as dim3, and push rest to dim4.
% 150211 dim3 reserved for RGB, even if SamplesPerPixel=1 (like dicomread). 
% 150404 Add 'if' block for numeric s.PixelData (BVfile). 
% 160114 cast s.PixelData.Bytes to double (thx DavidR). 
% 160127 support big endian files. 

persistent flds dict;
if isempty(flds)
    flds = {'Columns' 'Rows' 'BitsAllocated'};
    dict = dicm_dict('', [flds 'SamplesPerPixel' 'PixelRepresentation' ...
                     'PlanarConfiguration' 'BitsStored' 'HighBit']);
end
if isstruct(s) && ~all(isfield(s, flds)), s = s.Filename; end
if ischar(s), [s, err] = dicm_hdr(s, dict); end % input is file name
if isempty(s), error(err); end
if isfield(s, 'SamplesPerPixel'), spp = double(s.SamplesPerPixel);
else spp = 1;
end

if isnumeric(s.PixelData) % data already in hdr
    img = s.PixelData;
    return;
end

if all(isfield(s, {'BitsStored' 'HighBit'})) && s.BitsStored ~= s.HighBit+1
    error('Please report to author: HighBit+1 ~= BitsStored, %s', s.Filename);
end

fid = fopen(s.Filename);
if fid<0
    if exist([s.Filename '.gz'], 'file')
        gunzip([s.Filename '.gz']);
        fid = fopen(s.Filename);
    end
    if fid<0, error(['File not exists: ' s.Filename]); end
end
closeFile = onCleanup(@() fclose(fid));
fseek(fid, s.PixelData.Start, -1);
if ~isfield(s.PixelData, 'Format')
    fmt = sprintf('*uint%g', s.BitsAllocated);
else
    fmt =  s.PixelData.Format;
end

if nargin<2 || isempty(xpose), xpose = true; end % same as dicomread by default

if ~isfield(s, 'TransferSyntaxUID') || ... % files other than dicom
        strcmp(s.TransferSyntaxUID, '1.2.840.10008.1.2.1') || ...
        strcmp(s.TransferSyntaxUID, '1.2.840.10008.1.2.2') || ...
        strcmp(s.TransferSyntaxUID, '1.2.840.10008.1.2')
    n = double(s.PixelData.Bytes) / (double(s.BitsAllocated) / 8);
    img = fread(fid, n, fmt);
    dim = double([s.Columns s.Rows]);
    if ~isfield(s, 'PlanarConfiguration') || s.PlanarConfiguration==0
        img = reshape(img, [spp dim n/spp/dim(1)/dim(2)]);
        img = permute(img, [2 3 1 4]);
    else
        img = reshape(img, [dim spp n/spp/dim(1)/dim(2)]);
    end
    if xpose, img = permute(img, [2 1 3 4]); end
    if isfield(s, 'TransferSyntaxUID') && ...
            strcmp(s.TransferSyntaxUID, '1.2.840.10008.1.2.2');
        img = swapbytes(img);
    end
else % rely on imread for decompression
    b = fread(fid, inf, '*uint8'); % read all as bytes
    nEnd = numel(b) - 8; % terminator 0xFFFE E0DD and its zero length
    n = typecast(b(5:8), 'uint32'); i = 8+n; % length of offset table
    if n>0
        nFrame = n/4; % # of elements in offset table 
    else % empty offset table
        ind = strfind(b', uint8([254 255 0 224])); % 0xFFFE E000
        nFrame = numel(ind) - 1; % one more for offset table, even if empty
    end
    img = zeros(s.Rows, s.Columns, spp, nFrame, fmt(2:end)); % pre-allocate
    
    useMemmapfile = ~isempty(which('memmapfile'));
    fname = tempname;
    if useMemmapfile
        fid = fopen(fname, 'w');
        n = double(s.Columns) * double(s.Rows) * double(s.BitsAllocated) / 8 * spp;
        fwrite(fid, zeros(n, 1, 'uint8')); % large enough: 1 frame w/o compression
        fclose(fid); 
        m = memmapfile(fname, 'Writable', true);
    end
    deleteTemp = onCleanup(@() delete(fname)); % after memmapfile
    
    for j = 1:nFrame
        i = i+4; % delimiter: FFFE E000
        n = typecast(b(i+uint32(1:4)), 'uint32'); i = i+4;
        if useMemmapfile
            m.Data(1:n) = b(i+(1:n)); i = i + n;
        else
            fid = fopen(fname, 'w');
            fwrite(fid, b(i+(1:n)), 'uint8'); i = i + n;
            fclose(fid); 
        end
        img(:,:,:,j) = imread(fname); % take care of decompression
        if i>nEnd % in case false delimiter in data was counted
            img(:,:,:,j+1:end) = [];
            break;
        end
    end
    if ~xpose, img = permute(img, [2 1 3 4]); end
end

if isfield(s, 'PixelRepresentation') && s.PixelRepresentation>0
    img = reshape(typecast(img(:), fmt(3:end)), size(img)); % signed
end
