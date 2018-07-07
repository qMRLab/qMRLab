function [s, info, dict] = dicm_hdr(fname, dict, iFrames)
% Return header of a dicom file in a struct.
% 
% [s, err] = DICM_HDR(dicomFileName, dict, iFrames);
% 
% The mandatory 1st input is the dicom file name. 
% 
% The optional 2nd input is a dicom dictionary returned by dicm_dict. It may
% have only part of the full dictionary, which can speed up header read
% considerably. See rename_dicm for example.
% 
% The optional 3rd intput is useful for multi-frame dicom. When there are many
% frames, it may be slow to read all frames in PerFrameFunctionalGroupsSequence.
% The 3rd input specifies the frames to read. By default, items for only 1st,
% 2nd and last frames are read.
% 
% The optional 2nd output contains information in case of error, and will be
% empty if there is no error.
% 
% The optional 3rd output is rarely needed. It returns the dicom dictionary
% which may be updated from the input dict if the dicom vendor is different from
% that in the input dict.
% 
% DICM_HDR is like Matlab dicominfo, but is independent of Image Processing
% Toolbox. The advantage is that it decodes most private and shadow tags for
% Siemens, GE and Philips dicom, and runs faster, especially for partial header
% and multi-frame dicom.
% 
% DICM_HDR can also read Philips PAR file, AFNI HEAD file, Freesurfer MGH file
% and some BrainVoyager files, and return needed fields for dicm2nii to convert
% into nifti.
% 
% See also DICM_DICT, DICM2NII, DICM_IMG, RENAME_DICM, SORT_DICM, ANONYMIZE_DICM

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
% 150222 Avoid repeatedly reading .REC .BRIK file for hdr. 
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
% 160310 Fix problem of failing to update allRead with Inf bytes read.
% 160410 philips_par: check IndexInREC, and minor improvement.
% 160412 add read_val() for search method, but speed benefit is minor.
% 160414 Skip GEIIS SQ: not dicom compliant.
% 160418 Add search_MF_val(); need FrameStart in PerFrameSQ.
% 160422 Performance: avoid nestedFunc (big), use uint8, avoid typecast (minor).
% 160527 philips_par: center of slice 1 for slice dir; (dim-1)/2 for vol center.
% 160608 read_sq: n=nEnd (j>2) with PerFrameSQ (needed if length is not inf).
% 160825 can read dcm without PixelData, by faking p.iPixelData=fSize+1.
% 160829 no make-up SeriesNumber/InstanceUID in afni_head/philips_par/bv_file.
% 160928 philips_par: fix para table ind; treat type 17 as phase img. Thx SS.
% 161130 check i+n-1<=p.iPixelData in search method to avoid error. Thx xLei.
% 170127 Implement mgh_file: read FreeSurfer mgh or mgz.
% 170618 philips_par(): use regexp (less error prone); ignore keyname case.
% 170618 afni_head(): make MSB_FIRST (BE) BRIK work; fix negative PixelSpacing.
% 170625 read_ProtocolDataBlock(): decompress only to avoid datatype guess.
% 170803 par_key(): bug fix introduced on 170618.
% 170910 regexp tweak to work for Octave.
% 170921 read_ProtocolDataBlock: decode into struct with better performance.
% 171228 philips_par: bug fix for possible slice flip. thx ShereifH.
% 170309 philips_par: take care of incomplete volume if not XYTZ. thx YiL.
% 180507 read_val: keep bytes if typecast fails. thx JillM.

persistent dict_full;
s = []; info = '';
p.fullHdr = false; % parameters: only updated in main func
if nargin<2 || isempty(dict)
    if isempty(dict_full), dict_full = dicm_dict; end
    p.fullHdr = true;
    p.dict = dict_full; 
else
    p.dict = dict;
end

if nargin==3 && isstruct(fname) % wrapper
    s = search_MF_val(fname, dict, iFrames); % s, s1, iFrames
    return;
end

if nargin<3, iFrames = []; end
p.iFrames = iFrames;
fid = fopen(fname, 'r', 'l');
if fid<0, info = ['File not exists: ' fname]; return; end
closeFile = onCleanup(@() fclose(fid)); % auto close when done or error
fseek(fid, 0, 1); fSize = ftell(fid); fseek(fid, 0, -1);
if fSize<140 % 132 + one empty tag, ignore truncated
    info = ['Invalid file: ' fname];
    return;
end
b8 = fread(fid, 130000, 'uint8=>uint8')'; % enough for most dicom

iTagStart = 132; % start of first tag
isDicm = isequal(b8(129:132), 'DICM');
if ~isDicm % truncated dicom: is first group 2 or 8? not safe
    group = ch2int16(b8(1:2), 0);
    isDicm = group==2 || group==8; % truncated dicm always LE
    iTagStart = 0;
end
if ~isDicm % may be PAR/HEAD/BV file
    [~, ~, ext] = fileparts(fname);
    try
        if strcmpi(ext, '.PAR') % || strcmpi(ext, '.REC')
            [s, info] = philips_par(fname);
        elseif strcmpi(ext, '.HEAD') % || strcmpi(ext, '.BRIK')
            [s, info] = afni_head(fname);
        elseif any(strcmpi(ext, {'.mgh' '.mgz'}))
            [s, info] = mgh_file(fname);
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

p.expl = false; % default for truncated dicom
p.be = false; % little endian by default

% Get TransferSyntaxUID first, so find PixelData
i = strfind(char(b8), [char([2 0 16 0]) 'UI']); % always explicit LE
tsUID = '';
if ~isempty(i) % empty for truncated
    i = i(1) + 6;
    n = ch2int16(b8(i+(0:1)), 0);
    tsUID = deblank(char(b8(i+1+(1:n))));
    p.expl = ~strcmp(tsUID, '1.2.840.10008.1.2'); % may be wrong for some
    p.be =    strcmp(tsUID, '1.2.840.10008.1.2.2');
end

% find s.PixelData.Start so avoid search in img
% We verify iPixelData+bytes=fSize. If bytes=2^32-1, read all and use last tag
tg = char([224 127 16 0]); % PixelData, VR can be OW/OB even if expl
if p.be, tg = tg([2 1 4 3]); end
found = false;
for nb = [0 2e6 20e6 fSize] % if not enough, read more till all read
    b8 = [b8 fread(fid, nb, 'uint8=>uint8')']; %#ok
    i = strfind(char(b8), tg);
    i = i(mod(i,2)==1); % must be odd number
    for k = i(end:-1:1) % last is likely real PixelData
        p.iPixelData = k + p.expl*4 + 7; % s.PixelData.Start: 0-based
        if numel(b8)<p.iPixelData, b8 = [b8 fread(fid, 8, '*uint8')']; end %#ok
        p.bytes = ch2int32(b8(p.iPixelData+(-3:0)), p.be);
        if p.bytes==4294967295 && feof(fid), break; end % 2^32-1 compressed
        d = fSize - p.iPixelData - p.bytes; % d=0 most of time
        if d>=0 && d<16, found = true; break; end % real PixelData
    end
    if found, break; end
    if feof(fid)
        if isempty(i), p.iPixelData = fSize+1; end % fake it: no PixelData
        break;
    end
end

s.Filename = fopen(fid);
s.FileSize = fSize;

nTag = numel(p.dict.tag); % always search if only one tag: can find it in any SQ
toSearch = nTag<2 || (nTag<30 && ~any(strcmp(p.dict.vr, 'SQ')) && p.iPixelData<1e6);
if toSearch % search each tag if header is short and not many tags asked
    if ~isempty(tsUID), s.TransferSyntaxUID = tsUID; end % hope it is 1st tag
    ib = p.iPixelData-1; % will be updated each loop
    if ~isempty(p.dict.vendor) && any(mod(p.dict.group, 2)) % private group
        tg = char([8 0 112 0]); % Manufacturer
        if p.be, tg = tg([2 1 4 3]); end
        if p.expl, tg = [tg 'LO']; end
        i = strfind(char(b8(1:ib)), tg);
        i = i(mod(i,2)==1);
        if ~isempty(i)
            i = i(1) + 4 + p.expl*2; % Manufacturer should be the earliest one
            n = ch2int16(b8(i+(0:1)), p.be);
            dat = deblank(char(b8(i+1+(1:n))));
            [p, dict] = updateVendor(p, dat);
        end
    end
    
    s1 = [];
    for k = numel(p.dict.tag):-1:1 % reverse order so reduce range each loop
        group = p.dict.group(k);
        swap = p.be && group~=2;
        hasVR = p.expl || group==2;
        tg = char(typecast([group p.dict.element(k)], 'uint8'));
        if swap, tg = tg([2 1 4 3]); end
        i = strfind(char(b8(1:ib)), tg);
        i = i(mod(i,2)==1);
        if isempty(i), continue; % no this tag, next
        elseif numel(i)>1 % +1 tags found, add vr to try again if expl
            if hasVR
                tg = [tg p.dict.vr{k}]; %#ok
                i = strfind(char(b8(1:ib)), tg);
                i = i(mod(i,2)==1);
                if numel(i)~=1, toSearch = false; break; end
            else
                toSearch = false; break; % switch to regular way
            end
        end
        ib = i-1; % make next tag search faster
        i = i + 4; % tag
        if hasVR
            vr = char(b8(i+(0:1))); i = i+2;
            if strcmp(vr, 'UN') || strcmp(vr, 'OB'), vr = p.dict.vr{k}; end
        else
            vr = p.dict.vr{k};
        end
        [n, nvr] = val_len(vr, b8(i+(0:5)), hasVR, swap); i = i+nvr;
        if n==0, continue; end % dont assign empty tag

        if i+n-1>p.iPixelData, break; end
        [dat, info] = read_val(b8(i+(0:n-1)), vr, swap);
        if ~isempty(info), toSearch = false; break; end % re-do in regular way
        if ~isempty(dat), s1.(p.dict.name{k}) = dat; end
    end
    if ~isempty(s1) % reverse the order: just make it look normal
        nam = fieldnames(s1);
        for k = numel(nam):-1:1, s.(nam{k}) = s1.(nam{k}); end
    end
end

i = iTagStart + 1;
while ~toSearch
    if i >= p.iPixelData
        if strcmp(name, 'PixelData') % iPixelData might be in img
            p.iPixelData = iPre + p.expl*4 + 7; % overwrite previous
            p.bytes = ch2int32(b8(p.iPixelData+(-3:0)), p.be);
        elseif p.iPixelData < fSize % has PixelData
            info = ['End of file reached: likely error: ' s.Filename];  
        end
        break; % done or give up
    end
    iPre = i; % back it up for PixelData
    [dat, name, info, i, tg] = read_item(b8, i, p);
    if ~isempty(info), break; end
    if ~p.fullHdr && tg>p.dict.tag(end), break; end % done for partial hdr
    if isempty(dat) || isnumeric(name), continue; end
    s.(name) = dat;
    if strcmp(name, 'Manufacturer')
        [p, dict] = updateVendor(p, dat);
    elseif tg>=2621697 && ~isfield(p, 'nFrames') % BitsAllocated
        p = get_nFrames(s, p); % only make code here cleaner
    end
end

if p.iPixelData < fSize+1
    s.PixelData.Start = p.iPixelData;
    s.PixelData.Bytes = p.bytes;
end

if isfield(s, 'CSAImageHeaderInfo') % Siemens CSA image header
    s.CSAImageHeaderInfo = read_csa(s.CSAImageHeaderInfo);
end
if isfield(s, 'CSASeriesHeaderInfo') % series header
    s.CSASeriesHeaderInfo = read_csa(s.CSASeriesHeaderInfo);
end
if isfield(s, 'ProtocolDataBlock') % GE
    s.ProtocolDataBlock = read_ProtocolDataBlock(s.ProtocolDataBlock);
end

    %% nested function: update Manufacturer
    function [p, dict] = updateVendor(p, vendor)
        if ~isempty(p.dict.vendor) && strncmpi(vendor, p.dict.vendor, 2)
            dict = p.dict; % in case dicm_hdr asks 3rd output
            return;
        end
        dict_full = dicm_dict(vendor);
        if ~p.fullHdr && isfield(p.dict, 'fields')
            dict = dicm_dict(vendor, p.dict.fields);
        else
            dict = dict_full;
        end
        p.dict = dict;
    end
end % main func

%% subfunction: read dicom item. Called by dicm_hdr and read_sq
function [dat, name, info, i, tag] = read_item(b8, i, p)
dat = []; name = nan; info = ''; vr = 'CS'; % vr may be used if implicit

group = b8(i+(0:1)); i=i+2;
swap = p.be && ~isequal(group, [2 0]); % good news: no 0x0200 group
group = ch2int16(group, swap);
elmnt = ch2int16(b8(i+(0:1)), swap); i=i+2;
tag = group*65536 + elmnt;
if tag == 4294893581 % || tag == 4294893789 % FFFEE00D or FFFEE0DD
    i = i+4; % skip length
    return; % return in case n is not 0
end

swap = p.be && group~=2;
hasVR = p.expl || group==2;
if hasVR, vr = char(b8(i+(0:1))); i = i+2; end % 2-byte VR

[n, nvr] = val_len(vr, b8(i+(0:5)), hasVR, swap); i = i + nvr;
if n==0, return; end % empty val

% Look up item name in dictionary
ind = find(p.dict.tag == tag, 1);
if ~isempty(ind)
    name = p.dict.name{ind};
    if strcmp(vr, 'UN') || strcmp(vr, 'OB') || ~hasVR, vr = p.dict.vr{ind}; end
elseif tag==524400 % in case not in dict
    name = 'Manufacturer';
elseif tag==131088 % need TransferSyntaxUID even if not in dict
    name = 'TransferSyntaxUID';
elseif tag==593936 % 0x0009 0010 GEIIS not dicom compliant
    i = i+n; return; % seems n is not 0xffffffff
elseif p.fullHdr
    if elmnt==0, i = i+n; return; end % skip GroupLength
    if mod(group,2), name = sprintf('Private_%04x_%04x', group, elmnt);
    else,            name = sprintf('Unknown_%04x_%04x', group, elmnt);
    end
    if ~hasVR, vr = 'UN'; end % not in dict, will leave as uint8
elseif n<4294967295 % no skip for SQ with length 0xffffffff
    i = i+n; return;
end
% compressed PixelData, n can be 0xffffffff
if ~hasVR && n==4294967295, vr = 'SQ'; end % best guess
if n+i>p.iPixelData && ~strcmp(vr, 'SQ'), i = i+n; return; end % PixelData or err
% fprintf('(%04x %04x) %s %6.0f %s\n', group, elmnt, vr, n, name);

if strcmp(vr, 'SQ')
    nEnd = min(i+n, p.iPixelData); % n is likely 0xffff ffff
    [dat, info, i] = read_sq(b8, i, nEnd, p, tag==1375769136); % isPerFrameSQ?
else
    [dat, info] = read_val(b8(i+(0:n-1)), vr, swap); i=i+n;
end
% if group==33
%     fprintf('\t''%04X'' ''%04X'' ''%s'' ''%s'' ', group, elmnt, vr, name);
%     if numel(dat)>99, fprintf('''Long''');
%     elseif ischar(dat), fprintf('''%s''', dat);
%     elseif isnumeric(dat), fprintf(''''); fprintf('%g ', dat); fprintf('''');
%     else, fprintf('''SQ''');
%     end
%     fprintf('\n');
% end
end

%% Subfunction: decode SQ, called by read_item (recursively)
% SQ structure:
%  while isItem (FFFE E000, Item) % Item_1, Item_2, ... 
%   loop tags under the Item till FFFE E00D, ItemDelimitationItem
%   return if FFFE E0DD SequenceDelimitationItem (not checked)
function [rst, info, i] = read_sq(b8, i, nEnd, p, isPerFrameSQ)
rst = []; info = ''; tag1 = []; j = 0; % j is SQ Item index

while i<nEnd % loop through multi Item under the SQ
    tag = b8(i+([2 3 0 1])); i = i+4;
    if p.be, tag = tag([2 1 3 4]); end
    tag = ch2int32(tag, 0);
    if tag ~= 4294893568, i = i+4; return; end % only do FFFE E000, Item
    n = ch2int32(b8(i+(0:3)), p.be); i = i+4; % n may be 0xffff ffff
    n = min(i+n, nEnd);
    j = j + 1;
    
    % This 'if' block deals with partial PerFrameSQ: j and i jump to a frame. 
    % The 1/2/nf frame scheme will have problem in case that tag1 in 1st frame
    % is not the first tag in other frames. Then the tags before tag1 in other
    % frames will be treated as for previous.
    if isPerFrameSQ
        if ischar(p.iFrames) % 'all' frames
            if j==1 && ~isnan(p.nFrames), rst.FrameStart = nan(1, p.nFrames); end
            rst.FrameStart(j) = i-9;
        elseif j==1, i0 = i-8; % always read 1st frame, save i0 in case of re-do
        elseif j==2 % always read 2nd frame, and find start ind for all frames
            if isnan(p.nFrames) || isempty(tag1) % 1st frame has no asked tag
                p.iFrames = 'all'; rst = []; j = 0; i = i0; % re-do the SQ
                continue; % re-do
            end
            tag1 = char(typecast(uint32(tag1), 'uint8'));
            tag1 = tag1([3 4 1 2]);
            if p.be && ~isequal(tag1(1:2),[2 0]), tag1 = tag1([2 1 4 3]); end
            ind = strfind(char(b8(i0:p.iPixelData)), tag1) + i0 - 1;
            ind = ind(mod(ind,2)==1);
            nInd = numel(ind);
            if nInd ~= p.nFrames
                tag1PerF = nInd / p.nFrames;
                if mod(tag1PerF, 1) > 0 % not integer, read all frames
                    p.iFrames = 'all'; rst = []; j = 0; i = i0; % re-do SQ
                    fprintf(2, ['Failed to determine indice for frames. ' ...
                        'Reading all frames. Maybe slow ...\n']);
                    continue;
                elseif tag1PerF>1 % more than one ind for each frame
                    ind = ind(1:tag1PerF:nInd);
                    nInd = p.nFrames;
                end
            end
            rst.FrameStart = ind-9; % 0-based

            iItem = 2; % initialize here. Increase when j>2
            iFrame = unique([1 2 round(p.iFrames) nInd]);
        else % overwrite j with asked iFrame, overwrite i with start ind
            iItem = iItem + 1;
            j = iFrame(iItem);
            i = ind(j); % start of tag1 for asked frame
            n = nEnd; % use very end of the sq
        end
    end
    
    Item_n = sprintf('Item_%g', j);
    while i<n % loop through multi tags under one Item
        [dat, name, info, i, tag] = read_item(b8, i, p);
        if tag == 4294893581, break; end % FFFE E00D ItemDelimitationItem
        if isempty(tag1), tag1 = tag; end % first detected tag for PerFrameSQ
        if isempty(dat) || isnumeric(name), continue; end % 0-length or skipped
        rst.(Item_n).(name) = dat;
    end
end
end

%% subfunction: cast uint8/char to double. Better performance than typecast
function d = ch2int32(u8, swap)
    if swap, u8 = u8([4 3 2 1]); end
    d = double(u8);
    d = d(1) + d(2)*256 + d(3)*65536 + d(4)*16777216; % d = d * 256.^(0:3)';
end

function d = ch2int16(u8, swap)
    if swap, u8 = u8([2 1]); end
    d = double(u8);
    d = d(1) + d(2)*256;
end

%% subfunction: return value length, numel(b)=6
function [n, nvr] = val_len(vr, b, expl, swap)
len16 = 'AE AS AT CS DA DS DT FD FL IS LO LT PN SH SL SS ST TM UI UL US';
if ~expl % implicit, length irrevalent to vr (faked as CS)
    n = ch2int32(b(1:4), swap);
    nvr = 4; % bytes of VR
elseif ~isempty(strfind(len16, vr)) %#ok<*STREMP> % length in uint16
    n = ch2int16(b(1:2), swap);
    nvr = 2;
else % length in uint32 and skip 2 bytes
    n = ch2int32(b(3:6), swap);
    nvr = 6;
end
if n==13, n = 10; end % ugly bug fix for some old dicom file
end

%% subfunction: read value, called by search method and read_item
function [dat, info] = read_val(b, vr, swap)
if strcmp(vr, 'DS') || strcmp(vr, 'IS')
    dat = sscanf(char(b), '%f\\'); % like 1\2\3
elseif ~isempty(strfind('AE AS CS DA DT LO LT PN SH ST TM UI UT', vr)) % char
    dat = deblank(char(b));
else % numeric data, UN. SQ taken care of
    fmt = vr2fmt(vr);
    if isempty(fmt)
        dat = [];
        info = sprintf('Given up: Invalid VR (%d %d)', vr);
        return;
    end
    dat = b'; % keep as bytes in case typecast fails
    try dat = typecast(dat, fmt); end
    if swap, dat = swapbytes(dat); end
end
info = '';
end

%% subfunction: numeric format str from VR
function fmt = vr2fmt(vr)
    switch vr
        case 'US', fmt = 'uint16';
        case 'OB', fmt = 'uint8';
        case 'FD', fmt = 'double';
        case 'SS', fmt = 'int16';
        case 'UL', fmt = 'uint32';
        case 'SL', fmt = 'int32';
        case 'FL', fmt = 'single';
        case 'AT', fmt = 'uint16';
        case 'OW', fmt = 'uint16';
        case 'UN', fmt = 'uint8';
        otherwise, fmt = '';
    end
end

%% subfunction: get nFrames into p.nFrames
function p = get_nFrames(s, p)
if isfield(s, 'NumberOfFrames')
    p.nFrames = s.NumberOfFrames; % useful for PerFrameSQ
elseif all(isfield(s, {'Columns' 'Rows' 'BitsAllocated'})) && p.bytes<4294967295
    if isfield(s, 'SamplesPerPixel'), spp = double(s.SamplesPerPixel);
    else, spp = 1;
    end
    n = p.bytes * 8 / double(s.BitsAllocated);
    p.nFrames = n / (spp * double(s.Columns) * double(s.Rows));
else
    p.nFrames = nan;
end
end
        
%% subfunction: decode Siemens CSA image and series header
function csa = read_csa(csa)
b = csa';
if numel(b)<4 || ~strcmp(char(b(1:4)), 'SV10'), return; end % no op if not SV10
chDat = 'AE AS CS DA DT LO LT PN SH ST TM UI UN UT';
i = 8; % 'SV10' 4 3 2 1
try % in case of error, we return the original csa
    nField = ch2int32(b(i+(1:4)), 0); i=i+8;
    for j = 1:nField
        i=i+68; % name(64) and vm(4)
        vr = char(b(i+(1:2))); i=i+8; % vr(4), syngodt(4)
        n = ch2int32(b(i+(1:4)), 0); i=i+8;
        if n<1, continue; end % skip name decoding, faster
        nam = regexp(char(b(i-84+(1:64))), '\w+', 'match', 'once');
        isNum = isempty(strfind(chDat, vr));
        % fprintf('%s %3g %s\n', vr, n, nam);

        dat = [];
        for k = 1:n % n is often 6, but often only the first contains value
            len = ch2int32(b(i+(1:4)), 0); i=i+16;
            if len<1, i = i+(n-k)*16; break; end % rest are empty too
            foo = char(b(i+(1:len-1))); % exclude nul, need for Octave
            i = i + ceil(len/4)*4; % multiple 4-byte
            if isNum
                tmp = sscanf(foo, '%f', 1); % numeric to double
                if ~isempty(tmp), dat(k,1) = tmp; end %#ok
            else
                dat{k} = deblank(foo); %#ok
            end
        end
        if ~isNum
            dat(cellfun(@isempty, dat)) = []; %#ok
            if isempty(dat), continue; end
            if numel(dat)==1, dat = dat{1}; end
        end
        rst.(nam) = dat;
    end
    csa = rst;
end
end

%% subfunction: decode GE ProtocolDataBlock
function ch = read_ProtocolDataBlock(ch)
n = typecast(ch(1:4), 'int32') + 4; % nBytes, zeros may be padded to make 4x
if ~all(ch(5:6) == [31 139]') || n>numel(ch), return; end % gz signature
ch = nii_tool('LocalFunc', 'gunzip_mem', ch(5:n))';
ch = regexp(char(ch), '(\w*)\s+"(.*?)"\n', 'tokens');
ch = [ch{:}];
ch = struct(ch{:});
end

%% subfunction: get fields for multiframe dicom
function s1 = search_MF_val(s, s1, iFrame)
% s1 = search_MF_val(s, s1, iFrame);
%  Arg 1: the struct returned by dicm_hdr for a multiframe dicom
%  Arg 2: a struct with fields to search, and with initial value, such as
%    zeros or nans. The number of rows indicates the number of values for the
%    tag, and columns for frames indicated by iFrame, Arg 3.
%  Arg 3: frame indice, length consistent with columns of s1 field values.
% Example: 
%  s = dicm_hdr('multiFrameFile.dcm'); % read only 1,2 and last frame by default
%  s1 = struct('ImagePositionPatient', nan(3, s.NumberOfFrames)); % define size
%  s1 = search_MF_val(s, s1, 1:s.NumberOfFrames); % get values
% This is MUCH faster than asking all frames by dicm_hdr, and avoid to get into
% annoying SQ levels under PerFrameFuntionalGroupSequence. In case a tag is not
% found in PerFrameSQ, the code will search SharedSQ and common tags, and will
% ignore the 3th arg and duplicate the same value for all frames.

if ~isfield(s, 'PerFrameFunctionalGroupsSequence'), return; end
expl = false;
be = false;
if isfield(s, 'TransferSyntaxUID')
    expl = ~strcmp(s.TransferSyntaxUID, '1.2.840.10008.1.2');
    be =    strcmp(s.TransferSyntaxUID, '1.2.840.10008.1.2.2');
end

fStart = s.PerFrameFunctionalGroupsSequence.FrameStart; % error if no FrameStart
fid = fopen(s.Filename);
b0 = fread(fid, fStart(1), 'uint8=>char')'; % before 1st frame in PerFrameSQ
b = fread(fid, s.PixelData.Start-fStart(1), 'uint8=>char')'; % within PerFrameSQ
fclose(fid);

fStart(end+1) = s.PixelData.Start; % for later ind search
fStart = fStart - fStart(1) + 1; % 1-based index in b

flds = fieldnames(s1);
dict = dicm_dict(s.Manufacturer, flds);
len16 = 'AE AS AT CS DA DS DT FD FL IS LO LT PN SH SL SS ST TM UI UL US';
chDat = 'AE AS CS DA DT LO LT PN SH ST TM UI UT';
nf = numel(iFrame);

for i = 1:numel(flds)
    k = find(strcmp(dict.name, flds{i}), 1, 'last'); % GE has another ipp tag
    vr = dict.vr{k};
    group = dict.group(k);
    isBE = be && group~=2;
    isEX = expl || group==2;
    tg = char(typecast([group dict.element(k)], 'uint8'));
    if isBE, tg = tg([2 1 4 3]); end
    if isEX, tg = [tg vr]; end %#ok
    ind = strfind(b, tg);
    ind = ind(mod(ind,2)>0); % indice is odd
    if isempty(ind) % no tag in PerFrameSQ, try tag before PerFrameSQ
        ind = strfind(b0, tg);
        ind = ind(mod(ind,2)>0);
        if ~isempty(ind)
            k = ind(1) + numel(tg); % take 1st in case of multiple
            [n, nvr] = val_len(vr, uint8(b0(k+(0:5))), isEX, isBE); k = k + nvr;
            a = read_val(uint8(b0(k+(0:n-1))), vr, isBE);
            if ischar(a), a = {a}; end
            s1.(flds{i}) = repmat(a, 1, nf); % all frames have the same value
        end
        continue;
    end
    
    len = 4; % bytes of tag value length (uint32)
    if ~isEX % implicit, length irrevalent to VR
        ind = ind + 4; % tg(4)
    elseif ~isempty(strfind(len16, vr)) % data length in uint16
        ind = ind + 6; % tg(4), vr(2)
        len = 2;
    else % length in uint32: skip 2 bytes
        ind = ind + 8; % tg(4), vr(2), skip(2)
    end
    
    isCH = ~isempty(strfind(chDat, vr)); % char data
    isDS = strcmp(vr, 'DS') || strcmp(vr, 'IS');
    if ~isCH && ~isDS % numeric data, UN or SQ
        fmt = vr2fmt(vr);
        if isempty(fmt), continue; end % skip SQ
    end

    for k = 1:nf
        j = iFrame(k); % asked frame index
        j = find(ind>fStart(j) & ind<fStart(j+1), 1); % index in ind
        if isempty(j), continue; end % no tag for this frame
        if len==2, n = ch2int16(b(ind(j)+(0:1)), isBE);
        else,      n = ch2int32(b(ind(j)+(0:3)), isBE);
        end
        a = b(ind(j)+len+(0:n-1));
        if isDS
            a = sscanf(a, '%f\\'); % like 1\2\3
            try s1.(flds{i})(:,k) = a; end %#ok<*TRYNC> ignore in case of error
        elseif isCH
            try s1.(flds{i}){k} = deblank(a); end
        else
            a = typecast(uint8(a), fmt)';
            if isBE, a = swapbytes(a); end
            try s1.(flds{i})(:,k) = a; end
        end
    end
end
end

%% subfunction: read PAR file, return struct like that from dicm_hdr.
function [s, err] = philips_par(fname)
err = '';
fid = fopen(fname);
if fid<0, s = []; err = ['File not exist: ' fname]; return; end
str = fread(fid, inf, '*char')'; % read all as char
fname = fopen(fid); % name with full path
fclose(fid);
str = strrep(str, char([13 10]), char(10)); % remove char(13)

% In V4, offcentre and Angulation labeled as y z x, but actually x y z. We
% try not to use these info
V = regexpi(str, 'image export tool\s*(V[\d\.]+)', 'tokens', 'once');
if isempty(V), err = 'Not PAR file'; s = []; return; end
s.SoftwareVersion = [V{1} '\PAR'];
if strncmpi(s.SoftwareVersion, 'V3', 2)
    fprintf(2, ' V3 PAR file is not supported.\n');
    s = []; return;
end

s.PatientName = par_key(str, 'Patient name', 0);
s.StudyDescription = par_key(str, 'Examination name', 0);
[pth, nam] = fileparts(fname);
s.SeriesDescription = nam;
s.ProtocolName = par_key(str, 'Protocol name', 0);
a = par_key(str, 'Examination date/time', 0);
a = a(isstrprop(a, 'digit'));
s.AcquisitionDateTime = a;
s.SeriesNumber = par_key(str, 'Acquisition nr');
% s.ReconstructionNumberMR = par_key(str, 'Reconstruction nr');
% s.MRSeriesScanDuration = par_key(str, 'Scan Duration');
s.NumberOfEchoes = par_key(str, 'Max. number of echoes');
nSL = par_key(str, 'Max. number of slices/locations');
s.LocationsInAcquisition = nSL;
a = par_key(str, 'Patient position', 0);
if isempty(a), a = par_key(str, 'Patient Position', 0); end
if ~isempty(a)
    if numel(a)>4, s.PatientPosition = a(regexp(a, '\<.')); 
    else, s.PatientPosition = a; 
    end
end
s.MRAcquisitionType = par_key(str, 'Scan mode', 0);
s.ScanningSequence = par_key(str, 'Technique', 0); % ScanningTechnique
typ = par_key(str, 'Series Type', 0); typ(isspace(typ)) = '';
s.ImageType = ['PhilipsPAR\' typ '\' s.ScanningSequence];
s.RepetitionTime = par_key(str, 'Repetition time');
s.WaterFatShift = par_key(str, 'Water Fat shift');

a = regexp(str, 'Angulation midslice\s*\(\s*(\w{2}),\s*(\w{2}),\s*(\w{2})\)', 'tokens', 'once');
ax_order = cellfun(@(x)find(strcmpi(a, x)), {'rl' 'ap' 'fh'});
rotAngle = par_key(str, 'Angulation midslice'); % (ap,fh,rl) deg
rotAngle = rotAngle(ax_order);

a = regexp(str, 'Off Centre midslice\s*\(\s*(\w{2}),\s*(\w{2}),\s*(\w{2})\)', 'tokens', 'once');
ax_order = cellfun(@(x)find(strcmpi(a, x)), {'rl' 'ap' 'fh'});
posMid = par_key(str, 'Off Centre midslice'); % (ap,fh,rl) [mm]
posMid = posMid(ax_order); % better precision than those in the table
s.Stack.Item_1.MRStackOffcentreAP = posMid(2);
s.Stack.Item_1.MRStackOffcentreFH = posMid(3);
s.Stack.Item_1.MRStackOffcentreRL = posMid(1);
s.EPIFactor = par_key(str, 'EPI factor');
% s.DynamicSeries = par_key(str, 'Dynamic scan'); % 0 or 1
isDTI = par_key(str, 'Diffusion')>0;
if isDTI
    s.ImageType = [s.ImageType '\DIFFUSION\'];
    s.DiffusionEchoTime = par_key(str, 'Diffusion echo time'); % ms
end

a = par_key(str, 'Preparation direction', 0); % Anterior-Posterior
if ~isempty(a)
    a = a(regexp(a, '\<.')); % 'AP'
    s.Stack.Item_1.MRStackPreparationDirection = a;
    iPhase = strfind('LRAPFH', a(1));
    iPhase = ceil(iPhase/2); % 1/2/3
end

% Get list of para meaning for the table, and col index of each para
i1 = regexpi(str, 'IMAGE INFORMATION DEFINITION', 'once');
i2 = regexpi(str, '= IMAGE INFORMATION ='); i2 = i2(end);
ind = regexp(str(i1:i2), '\n#') + i1;
colLabel = {}; iColumn = [];
for i = 1:numel(ind)-1
    a = str(ind(i)+1:ind(i+1)-2); % a line
    i1 = regexp(a, '[<(]{1}'); % need first '<' or '(', and last '('
    if isempty(i1), continue; end
    nCol = sscanf(a(i1(end)+1:end), '%g');
    if isempty(nCol), nCol = 1; end
    colLabel{end+1} = strtrim(a(1:i1(1)-1)); %#ok para name
    iColumn(end+1) = nCol; %#ok number of columns in the table for this para
end
iColumn = cumsum([1 iColumn]); % col start ind for corresponding colLabel
keyInLabel = @(key)strcmpi(colLabel, key);
colIndex = @(key)iColumn(keyInLabel(key));

i1 = regexp(str(i2:end), '\n\s*\d+', 'once') + i2;
n = iColumn(end)-1; % number of items each row, 41 for V4
para = sscanf(str(i1:end), '%g'); % read all numbers
nImg = floor(numel(para) / n); 
para = reshape(para(1:n*nImg), n, nImg)'; % whole table now
getTableVal('index in REC file', 'IndexInREC', 1:nImg);
if isfield(s, 'IndexInREC') % why Philips includes this?
    if ~all(diff(s.IndexInREC) == 1) % not needed, just avoid accident
        para = para(s.IndexInREC, :); % in the order of REC img
    end
    s = rmfield(s, 'IndexInREC');
end

nVol = nImg / nSL;
s.Dim3IsVolume = (diff(para(1:2, colIndex('slice number'))) == 0);
if s.Dim3IsVolume % incomplete volume not taken care of due to REC file related
    iVol = 1:nVol;
    iSL = 1:nVol:nImg;
else
    if mod(nVol, 1) > 0 % incomplete volume in the end: drop it
        nVol = floor(nVol);
        nImg = nVol * nSL;
        para(nImg+1:end, :) = [];
    end
    iVol = 1:nSL:nImg;
    iSL = 1:nSL;
end
s.NumberOfFrames = nImg;
s.NumberOfTemporalPositions = nVol;

% PAR/REC file may not start with SliceNumber of 1, WHY?
sl = para(iSL, colIndex('slice number'));
if any(diff(sl,2)>0), s.SliceNumber = sl; end % slice order in REC file

imgType = para(iVol, colIndex('image_type_mr')); % 0 mag; 3, phase?
if any(diff(imgType) ~= 0) % more than 1 type of image
    s.ComplexImageComponent = 'MIXED';
    s.VolumeIsPhase = (imgType==3 | imgType==17); % one for each vol
    s.LastFile.RescaleIntercept = para(end, colIndex('rescale intercept'));
    s.LastFile.RescaleSlope = para(end, colIndex('rescale slope'));
elseif imgType(1)==0 || imgType(1)==16
    s.ComplexImageComponent = 'MAGNITUDE';
elseif imgType(1)==3 || imgType(1)==17
    s.ComplexImageComponent = 'PHASE';
end

% These columns should be the same for nifti-convertible images: 
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
a = para(:, ind);
a = abs(diff(a));
if any(a(:) > 1e-5)
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
getTableVal('scale slope', 'MRScaleSlope');
getTableVal('window center', 'WindowCenter', 1:nImg);
getTableVal('window width', 'WindowWidth', 1:nImg);
mx = max(s.WindowCenter + s.WindowWidth/2);
mn = min(s.WindowCenter - s.WindowWidth/2);
s.WindowCenter = round((mx+mn)/2);
s.WindowWidth = ceil(mx-mn);
getTableVal('slice thickness', 'SliceThickness');
getTableVal('echo_time', 'EchoTime');
getTableVal('image_flip_angle', 'FlipAngle');
getTableVal('number of averages', 'NumberOfAverages');
% getTableVal('trigger_time', 'TriggerTime', 1:nImg);
% getTableVal('dyn_scan_begin_time', 'TimeOfAcquisition', 1:nImg);
if isDTI
    getTableVal('diffusion_b_factor', 'B_value', iVol);
    fld = 'bvec_original';
    a = regexp(str, 'diffusion\s*\(\s*(\w{2}),\s*(\w{2}),\s*(\w{2})\)', 'tokens', 'once');
    ax_order = cellfun(@(x)find(strcmpi(a, x)), {'rl' 'ap' 'fh'});
    getTableVal('diffusion', fld, iVol);
    if isfield(s, fld), s.(fld) = s.(fld)(:, ax_order); end
end
getTableVal('TURBO factor', 'TurboFactor');

% Rotation order and signs are figured out by try and err, not 100% sure
ca = cosd(rotAngle); sa = sind(rotAngle);
rx = [1 0 0; 0 ca(1) -sa(1); 0 sa(1) ca(1)]; % 3D rotation
ry = [ca(2) 0 sa(2); 0 1 0; -sa(2) 0 ca(2)];
rz = [ca(3) -sa(3) 0; sa(3) ca(3) 0; 0 0 1];
R = rx * ry * rz; % seems right for Philips
% R = makehgtform('x', , 'y', , 'z', );

getTableVal('slice orientation', 'SliceOrientation'); % 1/2/3 for TRA/SAG/COR
a = regexp(str, 'slice orientation\s*\(\s*(\w{3})\s*/\s*(\w{3})\s*/\s*(\w{3})\s*\)', 'tokens', 'once');
iOri = find(strcmpi({'SAG' 'COR' 'TRA'}, a{s.SliceOrientation}));
if iOri == 1 
    s.SliceOrientation = 'SAGITTAL';
    R(:,[1 3]) = -R(:,[1 3]);
    R = R(:, [2 3 1]);
elseif iOri == 2
    s.SliceOrientation = 'CORONAL';
    R(:,3) = -R(:,3);
    R = R(:, [1 3 2]);
else
    s.SliceOrientation = 'TRANSVERSAL';
end

% 'pixel spacing' and 'slice gap' have poor precision for v<=4?
% It may be wrong to use FOV, maybe due to partial Fourier?
getTableVal('pixel spacing', 'PixelSpacing');
s.PixelSpacing = s.PixelSpacing(:);
getTableVal('slice gap', 'SpacingBetweenSlices');
s.SpacingBetweenSlices = s.SpacingBetweenSlices + s.SliceThickness;

if exist('iPhase', 'var')
    a = 'COL';
    if iPhase == (iOri==1)+1, a = 'ROW'; end
    s.InPlanePhaseEncodingDirection = a;
end

s.ImageOrientationPatient = R(1:6)';
R = R * diag([s.PixelSpacing; s.SpacingBetweenSlices]);
R = [R posMid; 0 0 0 1]; % 4th col is mid slice center position

a = regexp(str, 'image offcentre\s*\(\s*(\w{2}),\s*(\w{2}),\s*(\w{2})', 'tokens', 'once');
ax_order = cellfun(@(x)find(strcmpi(a, x)), {'rl' 'ap' 'fh'});
getTableVal('image offcentre', 'SliceLocation');
s.SliceLocation = s.SliceLocation(ax_order);
s.SliceLocation = s.SliceLocation(iOri); % center loc for 1st slice
if sign(R(iOri,3)) ~= sign(posMid(iOri)-s.SliceLocation)
    R(:,3) = -R(:,3);
end

R(:,4) = R * [-([s.Columns s.Rows nSL]-1)/2 1]'; % vol center to corner of 1st
y = R * [0 0 nSL-1 1]'; % last slice position
s.ImagePositionPatient = R(1:3,4);
s.LastFile.ImagePositionPatient = y(1:3);
s.Manufacturer = 'Philips';
s.Filename = fullfile(pth, [nam '.REC']); % rest for dicm_img
s.PixelData.Start = 0;
s.PixelData.Bytes = s.Rows * s.Columns * nImg * s.BitsAllocated / 8;

    % nested function: set field if the key is in colTable
    function getTableVal(key, fldname, iRow)
        if nargin<3, iRow = 1; end
        iCol = find(keyInLabel(key));
        if isempty(iCol), return; end
        s.(fldname) = para(iRow, iColumn(iCol):iColumn(iCol+1)-1);
    end

    % subfunction: return value specified by key in PAR file
    function val = par_key(str, key, isNum)
        expr = ['\n.\s*' key '.*?:(.*?)\n']; % \n. key ... : val \n
        val = strtrim(regexp(str, expr, 'tokens', 'once'));
        if isempty(val), val = ''; else, val = val{1}; end
        if nargin<3 || isNum, val = sscanf(val, '%g'); end
    end
end

%% subfunction: read AFNI HEAD file, return struct like that from dicm_hdr.
function [s, err] = afni_head(fname)
err = '';
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
s.ImageType = ['AFNIHEAD\' afni_key('TYPESTRING')];

foo = afni_key('BYTEORDER_STRING'); % "LSB_FIRST" or "MSB_FIRST".
if strcmpi(foo, 'MSB_FIRST'), s.TransferSyntaxUID = '1.2.840.10008.1.2.2'; end

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
s.PixelSpacing = abs(foo(1:2));
% s.SpacingBetweenSlices = foo(3);
s.SliceThickness = abs(foo(3));
foo = afni_key('BRICK_STATS');
foo = reshape(foo, 2, []);
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
        i1 = regexp(str, ['\nname\s*=\s*' key '\n']); % line 'name = key'
        if isempty(i1), val = []; return; end
        i1 = i1(1) + 1;
        typ = regexp(str(1:i1), 'type\s*=\s*(\w*)-attribute\n', 'tokens');
        [n, i2] = regexp(str(i1:end), 'count\s*=\s*(\d+)', 'tokens', 'end', 'once');
        n = sscanf(n{1}, '%g');
        if strcmpi(typ{end}{1}, 'string')
            val = regexp(str(i1:end), '(?<='').*?(?=~?\n)', 'match', 'once');
        else
            val = sscanf(str(i2+i1:end), '%g', n);
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

persistent subj folder % folder is used to update subj
if isempty(subj), subj = ''; folder = ''; end
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
try
    [~, nam] = fileparts(bv.FirstDataSourceFile);
    serN = sscanf(nam, [subj '-%f'], 1);
    if ~isempty(serN), s.SeriesNumber = serN; end
end
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

%% subfunction: read Freesurfer mgh or mgz file, return dicm info dicm_hdr.
function [s, err] = mgh_file(fname)
err = ''; s = [];
[~, ~, ext] = fileparts(fname);
isGZ = strcmpi(ext, '.mgz'); % .mgz = .mgh.gz
if isGZ
    nam = nii_tool('LocalFunc', 'gunzipOS', fname);
    fid = fopen(nam, 'r', 'b');
else
    fid = fopen(fname, 'r', 'b'); % always big endian?
end

if fid<0, err = sprintf('File not exists: %s', fname); return; end
cln = onCleanup(@() close_mgh(fid, isGZ)); % close file, delete if isGZ
v = fread(fid, 1, 'int32');
if v ~= 1, err = sprintf('Not mgh file: %s', fname); return; end

dim = fread(fid, 4, 'int32')';
typ = fread(fid, 1, 'int32');
dof = fread(fid, 1, 'int32'); %#ok not used
s.Filename = fname;
s.Columns = dim(1);
s.Rows = dim(2);
s.LocationsInAcquisition = dim(3);
if dim(4)>1, s.NumberOfTemporalPositions = dim(4); end

have_ras = fread(fid, 1, 'int16');
if have_ras % 3+9+3=15 single
    pixdim = fread(fid, 3, 'single');
    R = fread(fid, [3 3], 'single'); % direction cosine matrix
    c = fread(fid, 3, 'single'); % center xyz
    
    R(1:2,:) = -R(1:2,:); c(1:2) = -c(1:2); % RAS to dicom LPS
    s.PixelSpacing = pixdim(1:2);
    s.SliceThickness = pixdim(3);
    s.ImageOrientationPatient = R(1:6)';
    R = R * diag(pixdim);
    s.ImagePositionPatient = R * -dim(1:3)'/2 + c;
    s.LastFile.ImagePositionPatient = R * [-(dim(1:2))/2 dim(3)/2-1]' + c;
else
    s.ImageOrientationPatient = [1 0 0 0 0 -1]'; % coronal
end

switch typ
    case 0, bpp = 1; fmt = 'uint8';     % MRI_UCHAR
    case 1, bpp = 4; fmt = 'int32';     % MRI_INT
    case 2, bpp = 4; fmt = 'int32';     % MRI_LONG
    case 3, bpp = 4; fmt = 'single';    % MRI_FLOAT
    case 4, bpp = 2; fmt = 'int16';     % MRI_SHORT
%     case 5, bpp = 1; fmt = 'uint8';     % MRI_BITMAP *3?
%     case 6, bpp = 1; fmt = 'uint8';     % MRI_TENSOR *5?
    otherwise 
        err = sprintf('Unknown datatype: %s', fname); 
        s = []; return;
end
fseek(fid, 284, 'bof'); % start of img data
nv = prod(dim);
img = fread(fid, nv, ['*' fmt]);
if numel(img) ~= nv
    err = ['Not enough data in file: ' fname];
    s = []; return;
end
s.BitsAllocated = bpp * 8; % for dicm_img

flds = {'RepetitionTime' 'FlipAngle' 'EchoTime' 'InversionTime'};
parms4 = fread(fid, 4, 'single');
for i = 1:numel(parms4), s.(flds{i}) = parms4(i); end
if isfield(s, 'FlipAngle'), s.FlipAngle = s.FlipAngle/pi*180; end % to deg
s.PixelData = reshape(img, dim);

    function close_mgh(fid, isGZ)
        if isGZ
            uzip_nam = fopen(fid);
            fclose(fid);
            delete(uzip_nam);
        else
            fclose(fid);
        end
    end
end
