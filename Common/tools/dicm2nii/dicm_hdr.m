function [s, info, dict] = dicm_hdr(fname, dict, iFrames)
% Return header of a dicom file in a struct.
% 
% [s, err] = dicm_hdr(dicomFileName, dict, iFrames);
% 
% The mandatory 1st input is the dicom file name. The optional 2nd input can be
% a dicom dict, which may have only part of the full dict. The partial dict can
% be returned by dict = dicm_dict(vendor, fieldNames). The use of partial dict
% may speed up header read considerably. See rename_dicm for example.
% 
% The optional 3rd intput is only needed for multi-frame dicom files. When there
% are many frames, it may be very slow to read all items in
% PerFrameFunctionalGroupsSequence for all frames. The 3rd input can be used to
% specify the frames to read. By default, items for only 1st, 2nd and last
% frames are read.
% 
% The optional 2nd output contains information in case of error, and will be
% empty if there is no error.
% 
% DICM_HDR is like dicominfo from Matlab, but is independent of Image Processing
% Toolbox. The limitation is that it may not work for some special dicom files.
% The advantage is that it decodes most private and shadow tags for Siemens, GE
% and Philips dicom, and runs faster, especially for partial header and
% multi-frame dicom.
% 
% This can also read Philips PAR file, AFNI HEAD file and some BrainVoyager
% files, and return needed fields for dicm2nii to convert into nifti.
% 
% See also DICM_DICT, DICM2NII, DICM_IMG, RENAME_DICM, SORT_DICM

% The method used here:
% Check 4 bytes at 128 to make sure it is 'DICM';
% Find PixelData; Get its location;
% Loop through each item:
%      Read tag: group and element, each 1 uint16;
%        Find name in dictionary by the tag; if not exists,
%        assign it as Private_xxxx_xxxx;
%      Get VR:
%        Read VR (2 char) if explicit VR; 
%        Get VR from dict if implicit;
%      Decode item length type:
%        implicit VR, always uint32;
%        explicit VR: uint16/uint32(skip 2 bytes) based on VR; 
%      Decode data type by VR;
%      if VR == 'SQ', deal in special way;
%      Read the item according to the length and data type;
%        Process the item if needed;
%      Assign to field.

% History (yymmdd):
% 130823 Write it for dicm2nii.m (xiangrui.li@gmail.com).
% 130912 Extend private tags, automatically detect vendor.
% 130923 Call philips_par, so make dicm2nii easier. 
% 131001 Decode SQ, useful for multiframe dicom and Philips Stack. 
% 131008 Load then typecast. Faster than multiple fread.
% 131009 Work for implicit VR.
% 131010 Decode Siemens CSA header (slow), so it is human readable.
% 131019 PAR file: read image col labels, and use it for indexing.
% 131023 Implement afni_hdr.
% 131102 Use last tag for partial hdr, so return if it is non-exist fld.
% 131107 Search tags if only a few fields: faster than regular way.
% 131114 Add 3rd input: only 1,2,last frames hdr read. 0.4 vs 38 seconds!
%        Store needed fields in LastFile for PAR MIXED image type.
% 140123 Support dicom without meta info (thanks Paul).
% 140213 afni_head: IJK_TO_DICOM_REAL replaces IJK_TO_DICOM.
% 140502 philips_par: don't use FOV for PixelSpacing and SpacingBetweenSlices.
% 140506 philips_par: use PAR file name as SeriesDescription.
% 140512 decode GE ProtocolDataBlock (gz compressed).
% 140611 No re-do if there are <16 extra bytes after image data.
% 140724 Ignore PAR/HEAD ext case; fix philips_par: Patient Position.
% 140924 Use dict VR if VR==OB/UN (thx Macro R). Could be bad in theory.
% 141006 philips_par: take care of char(13 10) issue (thx Hye).
% 141021 Store fields in dict, so it can be used for changed vendor.
% 141023 checkManufacturer for fast search approach too.
% 141128 Minor tweaks (len-1 in read_csa) for Octave 3.8.1.
% 150114 Siemens CSA str is not always len=1. Fix it (runs slower).
% 150128 Use memory gunzip for GE ProtocolDataBlock (0.5 vs 43 ms).
% 150222 philips_par: fix slice dir in R using 'image offcentre';
%        Avoid repeatedly reading .REC .BRIK file for hdr. 
% 150227 Avoid error due to empty file (thx Kushal).
% 150316 Avoid error due to empty item dat for search method (thx VG).
% 150324 philips_par/afni_head: make up SeriesInstanceUID for dicm2nii.
% 150405 Implement bv_file to read non-transformed BV fmr/vmr/dmr.
% 150504 bv_file: fix multiple STCdata; bug fix for VMRData.
% 150513 return dict as 3rd output for dicm2nii in case of vendor change.
% 150517 fix manufacturer check problem for Octave: no re-read.
% 150522 PerFrameSQ ind: fix the case if numel(ind)~=nFrame.
% 150526 read_sq: use ItemDelimitationItem instead of empty dat1 as SQ end.
% 150924 philips_par: store SliceNumber if not acsending/decending order.
% 151001 check Manufacturer in advance for 'search' method.
% 160105 Bug fix for b just missing iPixelData (Thx Andrew S).
% 160127 Support big endian dicom; Always return TransferSyntaxUID for dicm_img.

persistent dict_full;
s = []; info = '';
fullHdr = false;
if nargin<2 || isempty(dict)
    if isempty(dict_full), dict_full = dicm_dict; end
    fullHdr = true;
    dict = dict_full; 
end
if nargin<3, iFrames = []; end

fid = fopen(fname);
if fid<0, info = ['File not exists: ' fname]; return; end
cln = onCleanup(@() fclose(fid));
empty = fseek(fid, 128, -1);
if empty
    info = ['Invalid file: ' fname];
    return;
end
sig = fread(fid, 4, '*char')';
isDicm = strcmp(sig, 'DICM');
isTruncated = false;
if ~isDicm
    fseek(fid, 0, -1);
    a = fread(fid, 1, 'uint16');
    if a==2 || a==8 % not safe, but no better way
        fseek(fid, 0, -1);
        isTruncated = true;
    end
end
if ~isDicm && ~isTruncated % may be PAR/HEAD/BV file
    [~, ~, ext] = fileparts(fname);
    try
        if strcmpi(ext, '.PAR') % || strcmpi(ext, '.REC')
            [s, info] = philips_par(fname);
        elseif strcmpi(ext, '.HEAD') % || strcmpi(ext, '.BRIK')
            [s, info] = afni_head(fname);
        elseif any(strcmpi(ext, {'.vmr' '.fmr' '.dmr'})) % BrainVoyager
            [s, info] = bv_file(fname);
        else
            info = ['Unknown file type: ' fname];
            return;
        end
    catch me
        info = me.message;
        return;
    end
    if ~isempty(s), return; end
    if isempty(info), info = ['Not dicom file: ' fname]; end
    return; 
end

expl = false; explVR = false; % default for truncated dicom
be = false; % little endian by default

% Get TransferSyntaxUID first
b8 = fread(fid, 130000, '*uint8')';
i = strfind(char(b8), char([2 0 16 0 'UI'])); % TransferSyntaxUID, explicit LE
if ~isempty(i) % empty for truncated
    i = (i(1)+1) / 2;
    len = min(i+50, round(numel(b8)/2)); % 50*2: enough for data+length
    b = typecast(b8(1:len*2), 'uint16');
    dat = read_item(i);
    if ischar(dat)
        expl = ~strcmp(dat, '1.2.840.10008.1.2');
        be = strcmp(dat, '1.2.840.10008.1.2.2');
        syntaxUID = dat;
    end
end

% This is the trick to make partial hdr faster.
tag_img = char([224 127 16 0]); % PixelData, VR uncertain even expl
if be, tag_img = tag_img([2 1 4 3]); end
for nb = [2e6 20e6 Inf] % if not enough, read more
    allRead = feof(fid);
    i = strfind(char(b8), tag_img);
    if ~isempty(i)
        break;
    elseif allRead
        info = ['No PixelData in ' fname]; 
        return; 
    end
    b8 = [b8 fread(fid, nb, '*uint8')']; %#ok
end
s.Filename = fopen(fid);

% iPixelData could be in header or data. Using full hdr can correct this
iPixelData = i(end); % start of PixelData tag with 132 offset
b = typecast(b8, 'uint16'); % hope this makes the code faster

i = 1; len = numel(b)-6; % 6 less avoid missing next tag
toSearch = numel(dict.tag) < 10;

if toSearch % search each tag if only a few fields
    b8 = char(b8);
    if exist('syntaxUID', 'var'), s.TransferSyntaxUID = syntaxUID; end
    if ~isempty(dict.vendor)
        tg = char([8 0 112 0]); % Manufacturer
        if be, tg = tg([2 1 4 3]); end
        if expl, tg = [tg 'LO']; end
        i = (strfind(b8, tg)+1) / 2;
        if ~isempty(i) % empty for truncated 
            dat = read_item(i(1));
            if ischar(dat) && ~strncmpi(dat, dict.vendor, 2)
                updateManufacturer(dat); 
            end
        end
    end
    for k = 1:numel(dict.tag)
        tg = typecast(dict.tag(k), 'uint8');
        tg = tg([3 4 1 2]);
        if be && ~isequal(tg(1:2), [2 0]), tg = tg([2 1 4 3]); end
        tg = char(tg);
        i = (strfind(b8, tg)+1) / 2;
        if isempty(i), continue;
        elseif numel(i)>1 % +1 tags found
            if expl, tg = [tg dict.vr{k}]; end %#ok add vr
            i = (strfind(b8, tg)+1) / 2;
            if isempty(i), continue;
            elseif numel(i)>1 % +1 tags found. use non-search method
                i = 1;
                toSearch = false;
                break; % re-do in regular way
            end
        end
        [dat, name, info] = read_item(i);
        if isnumeric(name) || isempty(dat), continue; end
        s.(name) = dat;
    end
end

while ~toSearch
    if i>=len
        if strcmp(name, 'PixelData') % if PixelData in SQ/data was caught
            iPixelData = iPre*2-1; % start of PixelData tag in bytes
            break; % done
        end
        if allRead
            info = ['End of file reached: likely error: ' s.Filename];  
            break; % give up
        else % in case PixelData in SQ was caught
            b = [b fread(fid, inf, '*uint16')']; %#ok read all
            len = numel(b)-6; % update length
            i = iPre; % re-do the previous item
            allRead = true;
        end
    end
    iPre = i; % backup it, also useful for PixelData
    
    [dat, name, info, i, tg] = read_item(i);
    if ~fullHdr && tg>dict.tag(end), break; end % done for partial hdr
    if strncmp(info, 'Given up', 8), break; end
    if isnumeric(name) || isempty(dat), continue; end
    s.(name) = dat;
    if strcmp(name, 'Manufacturer') 
        if ~isempty(dict.vendor) && ~strncmpi(dat, dict.vendor, 2)
            updateManufacturer(dat);
        end
    elseif strcmp(name, 'TransferSyntaxUID')
        expl = ~strcmp(dat, '1.2.840.10008.1.2'); % may be wrong for some
        be = strcmp(dat, '1.2.840.10008.1.2.2');
    end
end

i = (iPixelData+1) / 2; % start of PixelData tag in b (uint16)
if isTruncated
    iPixelData = iPixelData +   7; i=i+2;
elseif explVR
    % s.PixelData.VR = char(typecast(b(i+2), 'uint8'));
    iPixelData = iPixelData + 143; i=i+4; % extra vr(2) + pad(2) than implicitVR
else
    iPixelData = iPixelData + 139; i=i+2;
end
s.PixelData.Start = uint32(iPixelData);
if numel(b)<i+1, b = [b fread(fid, i+1-numel(b), '*uint16')']; end
bytes = typecast(b(i+(0:1)), 'uint32');
if be, bytes = swapbytes(bytes); end
s.PixelData.Bytes = bytes;

% if iPixelData is not right, re-do with full header
if ~fullHdr
    fseek(fid, 0, 1); % end of file
    if ftell(fid)-s.PixelData.Start-s.PixelData.Bytes > 15 % ==0 is too strict
        [s, info] = dicm_hdr(fname, [], iFrames); % full hdr
        return;
    end
end

if isfield(s, 'CSAImageHeaderInfo') % Siemens CSA image header (slow)
    s.CSAImageHeaderInfo = read_csa(s.CSAImageHeaderInfo);
end
if isfield(s, 'CSASeriesHeaderInfo') % series header
    s.CSASeriesHeaderInfo = read_csa(s.CSASeriesHeaderInfo);
end
if isfield(s, 'ProtocolDataBlock') % GE
    s.ProtocolDataBlock = read_ProtocolDataBlock(s.ProtocolDataBlock);
end
return;

% Nested function: read dicom item. Called by dicm_hdr and read_sq
function [dat, name, info, i, tag] = read_item(i)
persistent len16 chDat;
if isempty(len16)
    len16 = 'AE AS AT CS DA DS DT FD FL IS LO LT PN SH SL SS ST TM UI UL US';
    chDat = 'AE AS CS DA DS DT IS LO LT PN SH ST TM UI UT';
end
dat = []; name = nan; info = ''; 
vr = 'CS'; % CS for Manufacturer and TransferSyntaxUID

group = b(i); i=i+1;
elmnt = b(i); i=i+1;
if be && group>2
    group = swapbytes(group);
    elmnt = swapbytes(elmnt);
end

tag = uint32(group)*65536 + uint32(elmnt);
if tag == 4294893581 %|| tag == 4294893789 % FFFE E00D ItemDelimitationItem
    i = i+2; % skip length, in case there is another SQ Item
    name = '';
    return;
end

explVR = expl || group==2;
if explVR, vr = char(typecast(b(i), 'uint8')); i=i+1; end % 2-byte VR

if ~explVR % implicit, length irrevalent to VR
    n = typecast(b(i+(0:1)), 'uint32'); i = i+2;
elseif ~isempty(strfind(len16, vr)) % data length in uint16
    n = b(i); i=i+1;
else % length in uint32: skip 2 bytes
    n = typecast(b(i+(1:2)), 'uint32'); i = i+3;
end
if be && group>2, n = swapbytes(n); end
if n<1, return; end % empty val

% Look up item name in dictionary
if n==13, n = 10; end % ugly bug fix for some old dicom file
n = double(n)/2;
ind = find(dict.tag == tag, 1);
if ~isempty(ind)
    name = dict.name{ind};
    if strcmp(vr, 'UN') || strcmp(vr, 'OB') || ~explVR, vr = dict.vr{ind}; end
elseif tag==524400 % in case not in dict
    name = 'Manufacturer';
elseif tag==131088 % can't skip TransferSyntaxUID even if not in dict
    name = 'TransferSyntaxUID';
elseif fullHdr
    if elmnt==0, i=i+n; return; end % skip GroupLength
    if mod(group, 2), name = sprintf('Private_%04x_%04x', group, elmnt);
    else              name = sprintf('Unknown_%04x_%04x', group, elmnt);
    end
    if ~explVR, vr = 'UN'; end
elseif n<2147483647.5 % no skip for SQ with length 0xffffffff
    i=i+n; return;
end
% compressed PixelData, n can be 0xffffffff
if ~explVR && n==2147483647.5, vr = 'SQ'; end % best guess
if (n+i>len) && (~strcmp(vr, 'SQ')), i = i+n; return; end % re-do
% fprintf('(%04x %04x) %s %g %s\n', group, elmnt, vr, n*2, name);

% Decode data length and type of an item by VR
if ~isempty(strfind(chDat, vr)) % char data
    dat = deblank(char(typecast(b(i+(0:n-1)), 'uint8'))); i=i+n;
    if strcmp(vr, 'DS') || strcmp(vr, 'IS')
        dat = sscanf(dat, '%f%*c'); % like 1\2\3
    end
elseif strcmp(vr, 'SQ')
    isPerFrameSQ = strcmp(name, 'PerFrameFunctionalGroupsSequence');
    [dat, info, i] = read_sq(i, min(i+n,len), isPerFrameSQ);
else % numeric data, or UN
    switch vr 
        case 'OB', fmt = 'uint8';
        case 'UN', fmt = 'uint8';
        case 'AT', fmt = 'uint16';
        case 'OW', fmt = 'uint16';
        case 'US', fmt = 'uint16';
        case 'SS', fmt = 'int16'; 
        case 'UL', fmt = 'uint32';
        case 'SL', fmt = 'int32';
        case 'FL', fmt = 'single'; 
        case 'FD', fmt = 'double';
        otherwise, fmt = '';
    end
    if isempty(fmt)
        info = sprintf('Given up: Invalid VR (%d %d) for %s', vr, name);
    else
        dat = typecast(b(i+(0:n-1)), fmt)'; i=i+n;
        if be, dat = swapbytes(dat); end
    end
end
end % nested func

% Nested function: decode SQ, called by read_item (recursively)
function [rst, info, i] = read_sq(i, nEnd, isPerFrameSQ)
rst = []; info = ''; j = 0; % j is frame index

while i<nEnd
    tag = b(i+(0:1)); i=i+2;
    if be, tag = swapbytes(tag); end
    tag = typecast(tag, 'uint32');
    n = typecast(b(i+(0:1)), 'uint32'); i=i+2; % n may be 0xffff ffff
    if be, n = swapbytes(n); end
    if tag ~= 3758161918, return; end % only do FFFE E000, Item
    if isPerFrameSQ && ~ischar(iFrames)
        if j==0, i0 = i; j = 1; % always read 1st frame
        elseif j==1 % always read 2nd frame, and find ind for all frames
            if ~exist('tag1', 'var') % in case 1st frame has no asked tag
                iFrames = 'all'; rst = []; j = 0; i = i0-4; % re-do the SQ
                continue;
            end
            j = 2; iItem = 2;
            tag1 = char(typecast(tag1, 'uint8'));
            tag1 = tag1([3 4 1 2]);
            if be, tag1 = tag1([2 1 4 3]); end
            ind = strfind(char(typecast(b(i0:(iPixelData+1)/2), 'uint8')), tag1);
            ind = (ind-1)/2 + i0;
            nInd = numel(ind);
            if isfield(s, 'NumberOfFrames') && nInd~=s.NumberOfFrames
                tag1PerF = nInd / s.NumberOfFrames;
                if mod(tag1PerF, 1)>0 % not integer, read all frames
                    iFrames = 'all'; rst = []; j = 0; i = i0-4; % re-do the SQ
                    fprintf(2, ['Failed to determine indice for frames. ' ...
                        'Will read all frames.\nFile: %s\n'], s.Filename);
                    continue;
                elseif tag1PerF>1 % more than one ind for each frame
                    ind = ind(1:tag1PerF:nInd);
                    nInd = s.NumberOfFrames;
                end
            end
            iFrames = unique([1 2 round(iFrames) nInd]);
        else
            iItem = iItem + 1;
            j = iFrames(iItem);
            i = ind(j); % start of tag1 for a frame
        end
    else
        j = j + 1;
    end
    
    Item_n = sprintf('Item_%g', j);
    n = min(i+double(n)/2, nEnd);
    
    while i<n
        [dat1, name1, info, i, tag] = read_item(i);
        if isnumeric(name1), continue; end % 0-length or skipped item
        if tag == 4294893581, break; end % FFFE E00D ItemDelimitationItem
        if isempty(dat1), continue; end
        if isempty(rst), tag1 = tag; end % first wanted tag in PerFrame SQ
        rst.(Item_n).(name1) = dat1;
    end
end
end % nested func

function updateManufacturer(vendor)
    dict_full = dicm_dict(vendor); % update vendor
    if ~fullHdr && isfield(dict, 'fields')
        dict = dicm_dict(vendor, dict.fields);
    else
        dict = dict_full;
    end
end

end % main func

% subfunction: decode Siemens CSA image and series header
function csa = read_csa(csa)
b = csa';
if numel(b)<4 || ~strcmp(char(b(1:4)), 'SV10'), return; end % no op if not SV10
chDat = 'AE AS CS DA DT LO LT PN SH ST TM UI UN UT';
i = 8; % 'SV10' 4 3 2 1
try %#ok in case of error, we return the original uint8
    nField = typecast(b(i+(1:4)), 'uint32'); i=i+8;
    for j = 1:nField
        i=i+68; % name(64) and vm(4)
        vr = char(b(i+(1:2))); i=i+8; % vr(4), syngodt(4)
        n = typecast(b(i+(1:4)), 'int32'); i=i+8;
        if n<1, continue; end % skip name decoding, faster
        name = strtok(char(b(i-84+(1:64))), char(0));
        % fprintf('%s %3g %s\n', vr, n, name);

        dat = [];
        for k = 1:n % n is often 6, but often only the first contains value
            len = typecast(b(i+(1:4)), 'int32'); i=i+16;
            if len<1, i = i+double(n-k)*16; break; end % rest are empty too
            foo = char(b(i+(1:len-1))); % exclude nul, need for Octave
            i = i + ceil(double(len)/4)*4; % multiple 4-byte
            if isempty(strfind(chDat, vr))
                tmp = str2double(foo);
                if isnan(tmp), continue; end
                dat(end+1, 1) = tmp; %#ok numeric to double
            else
                dat{end+1, 1} = deblank(foo); %#ok
            end
        end
        if iscellstr(dat) && numel(dat)<2, dat = dat{1}; end
        if ~isempty(dat), rst.(name) = dat; end
    end
    csa = rst;
end
end

% subfunction: decode GE ProtocolDataBlock
function ch = read_ProtocolDataBlock(ch)
n = typecast(ch(1:4), 'int32') + 4; % nBytes, zeros may be padded to make 4x
if ~all(ch(5:6) == [31 139]') || n>numel(ch), return; end % gz signature

b = gunzip_mem(ch(5:n));
if isempty(b), return; end % guzip faild, we give up
b = char(b');

try %#ok
    i = 1; n = numel(b);
    while i<n
        nam = strtok(b(i:n), ' "'); i = i + numel(nam) + 2; % VIEWORDER "1"
        val = strtok(b(i:n),  '"'); i = i + numel(val) + 2;
        if strcmp(val(end), ';'), val(end) = []; end
        foo = str2double(val);
        if ~isnan(foo), val = foo; end % convert into num if possible
        rst.(nam) = val;
    end
    ch = rst;
end
end

%% subfunction: read PAR file, return struct like that from dicm_hdr.
function [s, err] = philips_par(fname)
err = '';
if numel(fname)>4 && strcmpi(fname(end+(-3:0)), '.REC')
    fname(end+(-3:0)) = '.PAR';
    if ~exist(fname, 'file'), fname(end+(-3:0)) = '.par'; end
end
fid = fopen(fname);
if fid<0, s = []; err = ['File not exist: ' fname]; return; end
str = fread(fid, inf, '*char')'; % read all as char
fname = fopen(fid); % name with full path
fclose(fid);

str = strrep(str, char(13), char(10)); % make carriage return single char(10)
while true
    ind = strfind(str, char([10 10]));
    if isempty(ind), break; end
    str(ind) = []; 
end

% In V4, offcentre and Angulation labeled as y z x, but actually x y z. We
% try not to use these info
key = 'image export tool';
i = strfind(lower(str), key) + numel(key);
if isempty(i), err = 'Not PAR file'; s = []; return; end
C = textscan(str(i:end), '%s', 1);
s.SoftwareVersion = [C{1}{1} '\PAR'];
if strncmpi(s.SoftwareVersion, 'V3', 2)
    err = 'V3 PAR file is not supported';
    fprintf(2, ' %s.\n', err);
    s = []; return;
end

s.PatientName = par_key('Patient name', '%c');
s.StudyDescription = par_key('Examination name', '%c');
[pth, nam] = fileparts(fname);
s.SeriesDescription = nam;
s.ProtocolName = par_key('Protocol name', '%c');
foo = par_key('Examination date/time', '%s');
foo = foo(isstrprop(foo, 'digit'));
s.AcquisitionDateTime = foo;
% s.SeriesType = strkey(str, 'Series Type', '%c');
s.SeriesNumber = par_key('Acquisition nr');
s.SeriesInstanceUID = sprintf('%g.%s.%09.0f', s.SeriesNumber, ...
    datestr(now, 'yymmdd.HHMMSS.fff'), rand*1e9);
% s.SamplesPerPixel = 1; % make dicm2nii.m happy
% s.ReconstructionNumberMR = strkey(str, 'Reconstruction nr', '%g');
% s.MRSeriesScanDuration = strkey(str, 'Scan Duration', '%g');
s.NumberOfEchoes = par_key('Max. number of echoes');
nSL = par_key('Max. number of slices/locations');
s.LocationsInAcquisition = nSL;
foo = par_key('Patient position', '%c');
if isempty(foo), foo = par_key('Patient Position', '%c'); end
if ~isempty(foo)
    if numel(foo)>4, s.PatientPosition = foo(regexp(foo, '\<.')); 
    else s.PatientPosition = foo; 
    end
end
s.MRAcquisitionType = par_key('Scan mode', '%s');
s.ScanningSequence = par_key('Technique', '%s'); % ScanningTechnique
s.ImageType = ['PhilipsPAR\' s.ScanningSequence];
% foo = strkey(str, 'Scan resolution', '%g'); % before reconstruction
% s.AcquisitionMatrix = [foo(1) 0 0 foo(2)]'; % depend on slice ori
s.RepetitionTime = par_key('Repetition time');
% FOV = par_key('FOV'); % (ap,fh,rl) [mm] 
% FOV = FOV([3 1 2]); % x y z
s.WaterFatShift = par_key('Water Fat shift');
rotAngle = par_key('Angulation midslice'); % (ap,fh,rl) deg
rotAngle = rotAngle([3 1 2]);
posMid = par_key('Off Centre midslice'); % (ap,fh,rl) [mm]
s.Stack.Item_1.MRStackOffcentreAP = posMid(1);
s.Stack.Item_1.MRStackOffcentreFH = posMid(2);
s.Stack.Item_1.MRStackOffcentreRL = posMid(3);
posMid = posMid([3 1 2]); % better precision than those in the table
s.EPIFactor = par_key('EPI factor');
% s.DynamicSeries = strkey(str, 'Dynamic scan', '%g'); % 0 or 1
isDTI = par_key('Diffusion')>0;
if isDTI
    s.ImageType = [s.ImageType '\DIFFUSION\'];
    s.DiffusionEchoTime = par_key('Diffusion echo time'); % ms
end

foo = par_key('Preparation direction', '%s'); % Anterior-Posterior
if ~isempty(foo)
    foo = foo(regexp(foo, '\<.')); % 'AP'
    s.Stack.Item_1.MRStackPreparationDirection = foo;
    iPhase = strfind('LRAPFH', foo(1));
    iPhase = ceil(iPhase/2); % 1/2/3
end

% Get list of para meaning for the table, and col index of each para
i1 = strfind(str, '= IMAGE INFORMATION DEFINITION ='); i1 = i1(end);
ind = strfind(str(i1:end), [char(10) '#']) + i1;
for i = 1:9 % find the empty line before column descrip
    [~, foo] = strtok(str(ind(i):ind(i+1)-2)); % remove # and char(10)
    if isempty(foo), break; end 
end
j = 1; 
for i = i+1:numel(ind)
    [~, foo] = strtok(str(ind(i):ind(i+1)-2));
    if isempty(foo), break; end % the end of the col label
    foo = strtrim(foo);
    i3 = strfind(foo, '<');
    i2 = strfind(foo, '(');
    if isempty(i3), i3 = i2(1); end
    colLabel{j} = strtrim(foo(1:i3(1)-1)); %#ok para name
    nCol = sscanf(foo(i2(end)+1:end), '%g');
    if isempty(nCol), nCol = 1; end
    iColumn(j) = nCol; %#ok number of columns in the table for this para
    j = j + 1;
end
iColumn = cumsum([1 iColumn]); % col start ind for corresponding colLabel
keyInLabel = @(key)strcmp(colLabel, key);
colIndex = @(key)iColumn(keyInLabel(key));

i1 = strfind(str, '= IMAGE INFORMATION ='); i1 = i1(end);
ind = strfind(str(i1:end), char(10)) + i1 + 1; % start of a line
for i = 1:9
    foo = sscanf(str(ind(i):end), '%g', 1);
    if ~isempty(foo), break; end % get the first number
end
while str(ind(i))==10, i = i+1; end % skip empty lines (only one)
str = str(ind(i):end); % now start of the table
i1 = strfind(str, char(10));
para = sscanf(str(1:i1(1)), '%g'); % 1st row
n = numel(para); % number of items each row, 41 for V4
para = sscanf(str, '%g'); % read all numbers
nImg = floor(numel(para) / n); 
para = reshape(para(1:n*nImg), n, nImg)'; % whole table now
s.NumberOfFrames = nImg;
nVol = nImg/nSL;
s.NumberOfTemporalPositions = nVol;

s.Dim3IsVolume = (diff(para(1:2, colIndex('slice number'))) == 0);
if s.Dim3IsVolume
    iVol = 1:nVol;
    iSL = 1:nVol:nImg;
else
    iVol = 1:nSL:nImg;
    iSL = 1:nSL;
end

% PAR/REC file may not start with SliceNumber of 1, WHY?
sl = para(iSL, colIndex('slice number'));
dSL = diff(sl);
if ~(all(dSL==1) || all(dSL==-1))
    s.SliceNumber = sl; % slice order in REC file
end

imgType = para(iVol, colIndex('image_type_mr')); % 0 mag; 3, phase?
if any(diff(imgType) ~= 0) % more than 1 type of image
    s.ComplexImageComponent = 'MIXED';
    s.VolumeIsPhase = (imgType==3); % one for each vol
    s.LastFile.RescaleIntercept = para(end, colIndex('rescale intercept'));
    s.LastFile.RescaleSlope = para(end, colIndex('rescale slope'));
elseif imgType(1)==0, s.ComplexImageComponent = 'MAGNITUDE';
elseif imgType(1)==3, s.ComplexImageComponent = 'PHASE';
end

% These columns should be the same for all images: 
cols = {'image pixel size' 'recon resolution' 'image angulation' ...
        'slice thickness' 'slice gap' 'slice orientation' 'pixel spacing'};
if ~strcmp(s.ComplexImageComponent, 'MIXED')
    cols = [cols {'rescale intercept' 'rescale slope'}];
end
ind = [];
for i = 1:numel(cols)
    j = find(keyInLabel(cols{i}));
    if isempty(j), continue; end
    ind = [ind iColumn(j):iColumn(j+1)-1]; %#ok
end
foo = para(:, ind);
foo = abs(diff(foo));
if any(foo(:) > 1e-5)
    err = sprintf('Inconsistent image size, bits etc: %s', fname);
    fprintf(2, ' %s. \n', err);
    s = []; return;
end

% getTableVal('echo number', 'EchoNumber', 1:nImg);
% getTableVal('dynamic scan number', 'TemporalPositionIdentifier', 1:nImg);
getTableVal('image pixel size', 'BitsAllocated');
getTableVal('recon resolution', 'Columns');
s.Rows = s.Columns(2); s.Columns = s.Columns(1);
getTableVal('rescale intercept', 'RescaleIntercept');
getTableVal('rescale slope', 'RescaleSlope');
getTableVal('window center', 'WindowCenter', 1:nImg);
getTableVal('window width', 'WindowWidth', 1:nImg);
mx = max(s.WindowCenter + s.WindowWidth/2);
mn = min(s.WindowCenter - s.WindowWidth/2);
s.WindowCenter = round((mx+mn)/2);
s.WindowWidth = ceil(mx-mn);
getTableVal('slice thickness', 'SliceThickness');
getTableVal('echo_time', 'EchoTime');
% getTableVal('dyn_scan_begin_time', 'TimeOfAcquisition', 1:nImg);
if isDTI
    getTableVal('diffusion_b_factor', 'B_value', iVol);
    fld = 'bvec_original';
    getTableVal('diffusion', fld, iVol);
    if isfield(s, fld), s.(fld) = s.(fld)(:, [3 1 2]); end
end
getTableVal('TURBO factor', 'TurboFactor');

% Rotation order and signs are figured out by try and err, not 100% sure
ca = cosd(rotAngle); sa = sind(rotAngle);
rx = [1 0 0; 0 ca(1) -sa(1); 0 sa(1) ca(1)]; % 3D rotation
ry = [ca(2) 0 sa(2); 0 1 0; -sa(2) 0 ca(2)];
rz = [ca(3) -sa(3) 0; sa(3) ca(3) 0; 0 0 1];
R = rx * ry * rz; % seems right for Philips

getTableVal('slice orientation', 'SliceOrientation'); % 1/2/3 for TRA/SAG/COR
iOri = mod(s.SliceOrientation+1, 3) + 1; % [1 2 3] to [3 1 2]
if iOri == 1 % Sag
    s.SliceOrientation = 'SAGITTAL';
    ixyz = [2 3 1];
    R(:,[1 3]) = -R(:,[1 3]); % change col sign according to iOri
elseif iOri == 2 % Cor
    s.SliceOrientation = 'CORONAL';
    ixyz = [1 3 2];
    R(:,3) = -R(:,3);
else % Tra
    s.SliceOrientation = 'TRANSVERSAL';
    ixyz = [1 2 3];
end
% bad precision for some PAR, 'pixel spacing' and 'slice gap', but it is wrong
% to use FOV, maybe due to partial Fourier?
getTableVal('pixel spacing', 'PixelSpacing');
s.PixelSpacing = s.PixelSpacing(:);
getTableVal('slice gap', 'SpacingBetweenSlices');

s.SpacingBetweenSlices = s.SpacingBetweenSlices + s.SliceThickness;
% s.PixelSpacing = FOV(ixyz(1:2)) ./ [s.Columns s.Rows]';
% s.SpacingBetweenSlices = FOV(ixyz(3)) ./ nSL;

if exist('iPhase', 'var')
    foo = 'COL';
    if iPhase == ixyz(1), foo = 'ROW'; end
    s.InPlanePhaseEncodingDirection = foo;
end

R = R(:, ixyz); % dicom rotation matrix
s.ImageOrientationPatient = R(1:6)';
R = R * diag([s.PixelSpacing; s.SpacingBetweenSlices]);
R = [R posMid; 0 0 0 1]; % 4th col is mid slice center position
% x = ([s.Columns s.Rows nSL] -1) / 2; % some V4.2 seem to use this
x = [s.Columns s.Rows nSL-1] / 2; % ijk of mid slice center 

c0 = R(iOri,3:4) * [-x(3) 1]'; % 1st slice center loc based on current slice dir
if sign(R(iOri,3)) ~= sign(posMid(iOri)-c0)
    R(:,3) = -R(:,3);
end

R(:,4) = R * [-x 1]'; % dicom xform matrix
y = R * [0 0 nSL-1 1]'; % last slice position
s.ImagePositionPatient = R(1:3,4);
s.LastFile.ImagePositionPatient = y(1:3);
s.Manufacturer = 'Philips';
s.Filename = fullfile(pth, [nam '.REC']); % for dicm_img
s.PixelData.Start = 0; % for dicm_img.m
s.PixelData.Bytes = s.Rows * s.Columns * nImg * s.BitsAllocated / 8;

    % nested function: set field if the key is in colTable
    function getTableVal(key, fldname, iRow)
        if nargin<3, iRow = 1; end
        iCol = find(keyInLabel(key));
        if isempty(iCol), return; end
        s.(fldname) = para(iRow, iColumn(iCol):iColumn(iCol+1)-1);
    end

    % nested subfunction: return value specified by key in PAR file
    function val = par_key(key, fmt)
        if nargin<2 || isempty(fmt), fmt = '%g';  end
        i1 = regexp(str, ['\n.\s{1,}' key '\s{0,}[(<\[:]']);
        if isempty(i1)
            if strcmp(fmt, '%g'), val = [];
            else val = '';
            end
            return; 
        end
        i1 = i1(1) + 1; % skip '\n'
        i2 = find(str(i1:end)==char(10), 1, 'first') + i1 - 2;
        ln = str(i1:i2); % the line
        i1 = strfind(ln, ':') + 1;
        val = sscanf(ln(i1(1):end), fmt); % convert based on fmt, re-use fmt
        if isnumeric(val), val = double(val);
        else val = strtrim(val);
        end
    end
end

%% subfunction: read AFNI HEAD file, return struct like that from dicm_hdr.
function [s, err] = afni_head(fname)
persistent SN;
if isempty(SN), SN = 1; end
err = '';
if numel(fname)>5 && strcmp(fname(end+(-4:0)), '.BRIK')
    fname(end+(-4:0)) = '.HEAD';
end
fid = fopen(fname);
if fid<0, s = []; err = ['File not exist: ' fname]; return; end
str = fread(fid, inf, '*char')';
fname = fopen(fid);
fclose(fid);

i = strfind(str, 'DATASET_DIMENSIONS');
if isempty(i), s = []; err = 'Not brik header file'; return; end

% these make dicm_nii.m happy
[~, foo] = fileparts(fname);
% s.IsAFNIHEAD = true;
s.ProtocolName = foo;
s.SeriesNumber = SN; SN = SN+1; % make it unique for multilple files
s.SeriesInstanceUID = sprintf('%g.%s.%09.0f', s.SeriesNumber, ...
    datestr(now, 'yymmdd.HHMMSS.fff'), rand*1e9);
s.ImageType = ['AFNIHEAD\' afni_key('TYPESTRING')];

foo = afni_key('BYTEORDER_STRING');
if strcmp(foo(1), 'M'), err = 'BYTEORDER_STRING not supported'; s = []; return; end

foo = afni_key('BRICK_FLOAT_FACS');
if any(diff(foo)~=0), err = 'Inconsistent BRICK_FLOAT_FACS'; 
    s = []; return; 
end
if foo(1)==0, foo = 1; end
s.RescaleSlope = foo(1);
s.RescaleIntercept = 0;

foo = afni_key('BRICK_TYPES');
if any(diff(foo)~=0), err = 'Inconsistent DataType'; s = []; return; end
foo = foo(1);
if foo == 0
    s.BitsAllocated =  8; s.PixelData.Format = '*uint8';
elseif foo == 1
    s.BitsAllocated = 16; s.PixelData.Format = '*int16';
elseif foo == 3
    s.BitsAllocated = 32; s.PixelData.Format = '*single';
else
    error('Unsupported BRICK_TYPES: %g', foo);
end

hist = afni_key('HISTORY_NOTE');
i = strfind(hist, 'Time:') + 6;
if ~isempty(i)
    dat = sscanf(hist(i:end), '%11c', 1); % Mar  1 2010
    dat = datenum(dat, 'mmm dd yyyy');
    s.AcquisitionDateTime = datestr(dat, 'yyyymmdd');
end
i = strfind(hist, 'Sequence:') + 9;
if ~isempty(i), s.ScanningSequence = strtok(hist(i:end), ' '); end
i = strfind(hist, 'Studyid:') + 8;
if ~isempty(i), s.StudyID = strtok(hist(i:end), ' '); end
% i = strfind(hist, 'Dimensions:') + 11;
% if ~isempty(i)
%     dimStr = strtok(hist(i:end), ' ') % 64x64x35x92
% end
% i = strfind(hist, 'Orientation:') + 12;
% if ~isempty(i)
%     oriStr = strtok(hist(i:end), ' ') % LAI
% end
i = strfind(hist, 'TE:') + 3;
if ~isempty(i), s.EchoTime = sscanf(hist(i:end), '%g', 1) * 1000; end

% foo = afni_key('TEMPLATE_SPACE'); % ORIG/TLRC
% INT_CMAP
foo = afni_key('SCENE_DATA');
s.TemplateSpace = foo(1)+1; %[0] 0=+orig, 1=+acpc, 2=+tlrc
if foo(2)==9, s.ImageType = [s.ImageType '\DIFFUSION\']; end
% ori = afni_key('ORIENT_SPECIFIC')+1;
% orients = [1 -1 -2 2 3 -3]; % RL LR PA AP IS SI
% ori = orients(ori) % in dicom/afni LPS, 
% seems always [1 2 3], meaning AFNI re-oriented the volome

% no read/phase/slice dim info, so following 3D info are meaningless
dim = afni_key('DATASET_DIMENSIONS');
s.Columns = dim(1); s.Rows = dim(2); s.LocationsInAcquisition = dim(3);
R = afni_key('IJK_TO_DICOM_REAL'); % IJK_TO_DICOM is always straight?
if isempty(R), R = afni_key('IJK_TO_DICOM'); end
R = reshape(R, [4 3])';
s.ImagePositionPatient = R(:,4); % afni_key('ORIGIN') can be wrong
y = [R; 0 0 0 1] * [0 0 dim(3)-1 1]';
s.LastFile.ImagePositionPatient = y(1:3);
R = R(1:3, 1:3);
R = R ./ (ones(3,1) * sqrt(sum(R.^2)));
s.ImageOrientationPatient = R(1:6)';
foo = afni_key('DELTA');
s.PixelSpacing = foo(1:2);
% s.SpacingBetweenSlices = foo(3);
s.SliceThickness = foo(3);
foo = afni_key('BRICK_STATS');
foo = reshape(foo, [2 numel(foo)/2]);
mn = min(foo(1,:)); mx = max(foo(2,:));
s.WindowCenter = (mx+mn)/2;
s.WindowWidth = mx-mn;
foo = afni_key('TAXIS_FLOATS'); %[0]:0; 
if ~isempty(foo), s.RepetitionTime = foo(2)*1000; end

foo = afni_key('TAXIS_NUMS'); % [0]:nvals; [1]: 0 or nSL normally
if ~isempty(foo)
    inMS = foo(3)==77001;
    foo = afni_key('TAXIS_OFFSETS');
    if inMS, foo = foo/1000; end
    if ~isempty(foo), s.MosaicRefAcqTimes = foo; end
end

foo = afni_key('DATASET_RANK'); % [3 nvals]
dim(4) = foo(2);
s.NumberOfTemporalPositions = dim(4);
% s.NumberOfFrames = dim(4)*dim(3);
 
s.Manufacturer = '';
s.Filename = strrep(fname, '.HEAD', '.BRIK');
s.PixelData.Start = 0; % make it work for dicm_img.m
s.PixelData.Bytes = prod(dim(1:4)) * s.BitsAllocated / 8;

    % subfunction: return value specified by key in afni header str
    function val = afni_key(key)
    i1 = regexp(str, ['\nname\s{0,}=\s{0,}' key '\n']); % line 'name = key'
    if isempty(i1), val = []; return; end
    i1 = i1(1) + 1;
    i2 = regexp(str(1:i1), 'type\s{0,}=\s{0,}\w*-attribute\n');
    keyType = sscanf(str(i2(end):i1), 'type%*c=%*c%s', 1); %'string-attribute'
    i1 = find(str(i1:end)==char(10), 1, 'first') + i1;
    count = sscanf(str(i1:end), 'count%*c=%*c%g', 1);
    if strcmp(keyType, 'string-attribute')
        i1 = find(str(i1:end)=='''', 1, 'first') + i1;
        val = str(i1+(0:count-2));
    else
        i1 = find(str(i1:end)==char(10), 1, 'first') + i1;
        val = sscanf(str(i1:end), '%g', count);
    end
    end
end

%% gunzip data in memory if possible.
% For a GE ProtocolDataBlock, memory / file approaches take 0.5 / 43 ms.
% When gz_bytes is large, pigz will be faster. The reversing point is about 8M.
function bytes = gunzip_mem(gz_bytes)
bytes = [];
try
    import com.mathworks.mlwidgets.io.*
    streamCopier = InterruptibleStreamCopier.getInterruptibleStreamCopier;
    baos = java.io.ByteArrayOutputStream;
    b = typecast(gz_bytes, 'int8');
    bais = java.io.ByteArrayInputStream(b);
    gzis = java.util.zip.GZIPInputStream(bais);
    streamCopier.copyStream(gzis, baos);
    bytes = typecast(baos.toByteArray, 'uint8'); % int8 to uint8
catch
    try %#ok
        tmp = tempname; % temp gz file
        fid = fopen([tmp '.gz'], 'w');
        if fid<0, return; end
        cln = onCleanup(@() delete([tmp '*'])); % delete gz and unziped files
        fwrite(fid, gz_bytes, 'uint8');
        fclose(fid);
        
        gunzipOS = nii_tool('func_handle', 'gunzipOS');
        gunzipOS([tmp '.gz']);
        
        fid = fopen(tmp);
        bytes = fread(fid, '*uint8');
        fclose(fid);
    end
end
end

%% Subfunction: read BrainVoyager vmr/fmr/dmr. Call BVQXfile
function [s, err] = bv_file(fname)
s = []; err = '';
try 
    bv = BVQXfile(fname);
catch me
    err = me.message;
    if strfind(me.identifier, 'UndefinedFunction')
        fprintf(2, 'Please download BVQXtools at \n%s\n', ...
        'http://support.brainvoyager.com/available-tools/52-matlab-tools-bvxqtools.html');
    end
    return;
end

if ~isempty(bv.Trf)
    for i = 1:numel(bv.Trf)
        if ~isequal(diag(bv.Trf(i).TransformationValues), [1 1 1 1]')
            err = 'Data has been transformed: skipped.';
            return;
        end
    end
end

persistent SN subj folder % folder is used to update subj
if isempty(SN), SN = 1; subj = ''; folder = ''; end
s.Filename = bv.FilenameOnDisk;
fType = bv.filetype;
s.ImageType = ['BrainVoyagerFile\' fType];

% Find a fmr/dmr, and get subj based on dicom file name in BV format.
% Suppose BV files in the folder are for the same subj
[pth, nam] = fileparts(s.Filename);
s.SeriesDescription = nam;
if isempty(folder) || ~strcmp(folder, pth)
    folder = pth;
    subj = '';
    if strcmp(fType, 'fmr') || strcmp(fType, 'dmr')
        [~, nam] = fileparts(bv.FirstDataSourceFile);
        nam = strtok(nam, '-');
        if ~isempty(nam), subj = nam; end
    else
        fnames = dir([pth '/*.fmr']);
        if isempty(fnames), fnames = dir([pth '/*.dmr']); end
        if ~isempty(fnames)
            bv1 = BVQXfile(fullfile(pth, fnames(1).name));
            [~, nam] = fileparts(bv1.FirstDataSourceFile);
            bv1.ClearObject;
            nam = strtok(nam, '-');
            if ~isempty(nam), subj = nam; end
        end
    end
end
if ~isempty(subj), s.PatientName = subj; end

s.SoftwareVersion = sprintf('%g/BV_FileVersion', bv.FileVersion);
s.Columns = bv.NCols;
s.Rows = bv.NRows;
s.SliceThickness = bv.SliceThickness;
R = [bv.RowDirX bv.RowDirY bv.RowDirZ; bv.ColDirX bv.ColDirY bv.ColDirZ]';
s.ImageOrientationPatient = R(:);
R(:,3) = cross(R(:,1), R(:,2));
[~, ixyz] = max(abs(R)); iSL =ixyz(3);

try 
    s.TemplateSpace = bv.ReferenceSpace; % 0/2/3: Scanner/ACPC/TAL
    if s.TemplateSpace==0, s.TemplateSpace = 1; end
catch
    s.TemplateSpace = 1;
end
pos = [bv.Slice1CenterX bv.Slice1CenterY bv.Slice1CenterZ
       bv.SliceNCenterX bv.SliceNCenterY bv.SliceNCenterZ]'; % for real slices

if strcmpi(fType, 'vmr')
    s.SpacingBetweenSlices = s.SliceThickness + bv.GapThickness;
    s.PixelSpacing = [bv.VoxResX bv.VoxResY]';
    if ~isempty(bv.VMRData16)
        nSL = bv.DimZ;
        s.PixelData = bv.VMRData16; % no padded zeros
    else
        v16 = [s.Filename(1:end-3) 'v16'];
        if exist(v16, 'file')
            bv16 = BVQXfile(v16);
            nSL = bv16.DimZ;
            s.PixelData = bv16.VMRData; % no padded zeros
            bv16.ClearObject;
        else % fall back the 8-bit data, and deal with padded zeros
            ix = floor((bv.DimX - s.Columns)/2);
            iy = floor((bv.DimY - s.Rows)/2);
            R3 = abs(R(iSL,3)) * s.SpacingBetweenSlices;
            nSL = round(abs(diff(pos(iSL,:))) / R3) + 1;
            iz = floor((bv.DimZ - nSL)/2);
            s.PixelData = bv.VMRData(ix+(1:s.Columns), iy+(1:s.Rows), iz+(1:nSL), :);
        end
    end
    s.LocationsInAcquisition = nSL;
    s.MRAcquisitionType = '3D'; % for dicm2nii to re-orient
elseif strcmpi(fType, 'fmr') || strcmpi(fType, 'dmr')
    s.SpacingBetweenSlices = s.SliceThickness + bv.SliceGap;
    s.PixelSpacing = [bv.InplaneResolutionX bv.InplaneResolutionY]';
    nSL = bv.NrOfSlices;
    s.LocationsInAcquisition = nSL;
    s.NumberOfTemporalPositions = bv.NrOfVolumes;
    s.RepetitionTime = bv.TR;
    s.EchoTime = bv.TE;
    if bv.TimeResolutionVerified
        switch bv.SliceAcquisitionOrder % the same as NIfTI?
            case 1, ind = 1:nSL;
            case 2, ind = nSL:-1:1;
            case 3, ind = [1:2:nSL 2:2:nSL];
            case 4, ind = [nSL:-2:1 nSL-1:-2:1];
            case 5, ind = [2:2:nSL 1:2:nSL];
            case 6, ind = [nSL-1:-2:1 nSL:-2:1];
            otherwise, ind = []; err = 'Unknown SliceAcquisitionOrder';
        end
        if ~isempty(ind)
            t = (0:s.LocationsInAcquisition-1)' * bv.InterSliceTime; % ms
            t(ind) = t;
            s.SliceTiming = t;
        end
    end
    if strcmpi(fType, 'fmr')
        bv.LoadSTC;
        s.PixelData = permute(bv.Slice(1).STCData , [1 2 4 3]);
        for i = 2:numel(bv.Slice)
            s.PixelData(:,:,i,:) = permute(bv.Slice(i).STCData , [1 2 4 3]);
        end
    else % dmr
        s.ImageType = [s.ImageType '\DIFFUSION\'];
        bv.LoadDWI;
        s.PixelData = bv.DWIData;
        if strncmpi(bv.GradientInformationAvailable, 'Y', 1)
            a = bv.GradientInformation; % nDir by 4
            s.B_value = a(:,4);
            a = a(:,1:3); % bvec
            % Following should be right in theory, but I would trust the grd
            % table which should be in dicom coodinate system, rather than the
            % confusing Gradient?DirInterpretation 
%             % 1:6 for LR RL AP PA IS SI. Default [2 3 5] by dicom LPS
%             i1_6 = [bv.GradientXDirInterpretation ...
%                     bv.GradientYDirInterpretation ...
%                     bv.GradientZDirInterpretation];
%             [xyz, ind] = sort(i1_6);
%             if isequal(ceil(xyz/2), 1:3) % perm of 1/2/3
%                 a = a(:,ind);
%                 flip = xyz == [1 4 6]; % negative by dicom 
%                 a(:,flip) = -a(:,flip);
%             else
%                 str = sprintf(['Wrong Interpretation of gradient found: %s\n' ... 
%                        'Please check bvec and its sign.\n'], fname);
%                 fprintf(2, str);
%                 err = [err str];
%             end
            s.bvec_original = a;
        end
    end
    
    % fmr/dmr are normally converted from uint16 to single
    if isfloat(s.PixelData) && isequal(floor(s.PixelData), s.PixelData) ...
            && max(s.PixelData(:))<32768 && min(s.PixelData(:))>=-32768
        s.PixelData = int16(s.PixelData);
    end
else
    err = ['Unknown BV file type: ' fType];
    s = [];
    return;
end

pos = pos - R(:,1:2) * diag(s.PixelSpacing) * [s.Columns s.Rows]'/2 * [1 1];
s.ImagePositionPatient = pos(:,1);
s.LastFile.ImagePositionPatient = pos(:,2);

% Following make dicm2nii happy
try %#ok
    [~, nam] = fileparts(bv.FirstDataSourceFile);
    [~, nam] = strtok(nam, '-');
    serN = str2double(strtok(nam, '-'));
    if ~isempty(serN), SN = serN; end
end
s.SeriesNumber = SN; SN = SN+1; % make it unique for multilple files
s.SeriesInstanceUID = sprintf('%g.%s.%09.0f', s.SeriesNumber, ...
    datestr(now, 'yymmdd.HHMMSS.fff'), rand*1e9);
c = class(s.PixelData);
if strcmp(c, 'double') %#ok
    s.BitsAllocated = 64;
elseif strcmp(c, 'single') %#ok
    s.BitsAllocated = 32;
else
    ind = find(isstrprop(c, 'digit'), 1);
    s.BitsAllocated = sscanf(c(ind:end), '%g');
end
end
