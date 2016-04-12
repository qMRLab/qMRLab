function varargout = dicm2nii(src, dataFolder, varargin)
% Convert dicom and more into nii or img/hdr files. 
% 
% DICM2NII(dcmSource, niiFolder, outFormat, MoCoOption)
% 
% The input arguments are all optional:
%  1. source file or folder. It can be a zip or tgz file, a folder containing
%     dicom files, or other convertible files. It can also contain wildcards
%     like 'run1_*' for all files start with 'run1_'.
%  2. folder to save result files.
%  3. output file format:
%      0 or 'nii'           for single nii uncompressed.
%      1 or 'nii.gz'        for single nii compressed (default).
%      2 or 'hdr'           for hdr/img pair uncompressed.
%      3 or 'hdr.gz'        for hdr/img pair compressed.
%      4 or '3D.nii'        for 3D nii uncompressed (SPM12).
%      5 or '3D.nii.gz'     for 3D nii compressed.
%      6 or '3D.hdr'        for 3D hdr/img pair uncompressed (SPM8).
%      7 or '3D.hdr.gz'     for 3D hdr/img pair compressed.
%  4. MoCo series options:
%      0 create files for both original and MoCo series.
%      1 ignore MoCo series if both present (default).
%      2 ignore original series if both present.
%     Note that if only one of the two series is present, it will be converted
%     always. In the future, this option may be removed, and all files will be
%     converted. 
% 
% The optional output is converted PatientName(s).
% 
% Typical examples:
%  dicm2nii; % bring up user interface if there is no input argument
%  dicm2nii('D:/myProj/zip/subj1.zip', 'D:/myProj/subj1/data'); % zip file
%  dicm2nii('D:/myProj/subj1/dicom/', 'D:/myProj/subj1/data'); % folder
% 
% Less useful examples:
%  dicm2nii('D:/myProj/dicom/', 'D:/myProj/subj2/data', 'nii'); % no gz compress
%  dicm2nii('D:/myProj/dicom/run2*', 'D:/myProj/subj/data'); % convert run2 only
%  dicm2nii('D:/dicom/', 'D:/data', '3D.nii'); % SPM style files
% 
% If there is no input, or any of the first two input is empty, the graphic user
% interface will appear.
% 
% If the first input is a zip/tgz file, such as those downloaded from dicom
% server, DICM2NII will extract files into a temp folder, create NIfTI files
% into the data folder, and then delete the temp folder. For this reason, it is
% better to keep the compressed file as backup.
% 
% If a folder is the data source, DICM2NII will convert all files in the folder
% and its subfolders (there is no need to sort files for different series).
% 
% Please note that, if a file in the middle of a series is missing, the series
% will normally be skipped without converting, and a warning message in red text
% will be shown in Command Window. The message will also be saved into a text
% file under the data folder.
% 
% A Matlab data file, dcmHeaders.mat, is always saved into the data folder. This
% file contains dicom header from the first file for created series and some
% information from last file in field LastFile. Some extra information may also
% be saved into this file. For MoCo series, motion parameters (RBMoCoTrans and
% RBMoCoRot) are also saved.
% 
% Slice timing information, if available, is stored in nii header, such as
% slice_code and slice_duration. But the simple way may be to use the field
% SliceTiming in dcmHeaders.mat. That timing is actually those numbers for FSL
% when using custom slice timing. This is the universal method to specify any
% kind of slice order, and for now, is the only way which works for multiband.
% Slice order is one of the most confusing parameters, and it is recommended to
% use this method to avoid mistake. Following shows how to convert this timing
% into slice timing in ms and slice order for SPM:
%   
%  load('dcmHeaders.mat'); % or drag and drop the MAT file into Matlab
%  s = h.myFuncSeries; % field name is the same as nii file name
%  spm_ms = (0.5 - s.SliceTiming) * s.RepetitionTime;
%  [~, spm_order] = sort(-s.SliceTiming);
% 
% Some information, such as TE, phase encoding direction and effective dwell
% time are stored in descrip of nii header. These are useful for fieldmap B0
% unwarp correction. Acquisition start time and date are also stored, and this
% may be useful if one wants to align the functional data to some physiological
% recording, like pulse, respiration or ECG.
% 
% If there is DTI series, bval and bvec files will be generated for FSL etc.
% bval and bvec are also saved into the dcmHeaders.mat file.
% 
% Starting from 20150514, the converter stores some useful information in NIfTI
% text extension (ecode=6). nii_tool can decode these information easily:
%  ext = nii_tool('ext', 'myNiftiFile.nii'); % read NIfTI extension
% ext.edata_decoded contains all above mentioned information, and more. The
% inlcuded nii_viewer can show the extension by Window->Show NIfTI ext.
% 
% Starting from 20151120, the converter can optionally save a .json file for
% each converted NIfTI. This can be turned on by running following line from
% Command Window for a new session:
%  setpref('dicm2nii_gui_para', 'save_json', true);
% It will stay on (saving json files) until a new session with
%  setpref('dicm2nii_gui_para', 'save_json', false);
% For more information about the purpose of json file, check
%  http://bids.neuroimaging.io/ 
% 
% Please note that some information, such as the slice order information, phase
% encoding direction and DTI bvec are in image reference, rather than NIfTI
% coordinate system. This is because most analysis packages require information
% in image space. For this reason, in case the image in a NIfTI file is flipped
% or re-oriented, these information may not be correct anymore.
% 
% The output file names adopt SeriesDescription or ProtocolName of each series
% used on scanner console. If both original and MoCo series are converted,
% '_MoCo' will be appended for MoCo series. For phase image, such as those from
% field map, '_phase' will be appended to the name. If multiple subjects data
% are mixed (highly discouraged), subject name will be in file name. In case of
% name conflict, SeriesNumber, such as '_s005', will be appended to make file
% names unique. It is suggested to use short and descriptive SeriesDescription
% on the scanner console.
% 
% For SPM 3D files, the file names will have volume index in format of '_00001'
% appended to above name.
% 
% Please report any bug to xiangrui.li@gmail.com or at
% http://www.mathworks.com/matlabcentral/fileexchange/42997

% Thanks to:
% Jimmy Shen's Tools for NIfTI and ANALYZE image,
% Chris Rorden's dcm2nii pascal source code,
% Przemyslaw Baranski for direction cosine matrix to quaternions. 

% History (yymmdd):
% 130512 Publish to CCBBI users (Xiangrui Li).
% 130513 Convert img from uint16 to int16 if range allows;
%        Support output file format of img/hdr/mat.
% 130515 Change creation order to acquisition order (more natural).
%        If MoCo series is included, append _MoCo in file names.
% 130516 Use SpacingBetweenSlices, if exists, for SliceThickness. 
% 130518 Use NumberOfImagesInMosaic in CSA header (work for some old data).
% 130604 Add scl_inter/scl_slope and special naming for fieldmap.
% 130614 Work out the way to get EffectiveEchoSpacing for B0 unwarp.
% 130616 Add needed dicom field check, so it won't err later.
% 130618 Reorient if non-mosaic or slice_dim is still 3 and no slice flip.
% 130619 Simplify DERIVED series detection. No '_mag' in fieldmap name.
% 130629 Improve the method to get phase direction;
%        Permute img dim1&2 (no -90 rotation) & simplify xform accordingly.
% 130711 Make MoCoOption smarter: create nii if only 1 of 2 series exists.
% 130712 Remove 5th input (allHeader). Save memory by using partial header.
% 130712 Bug fix: dim_info with reorient. No problem since no EPI reorient.
% 130715 Use 2 slices for xform. No slice flip needed except revNum mosaic.
% 130716 Take care of lower/upper cases for output file names;
%        Apply scl_slope and inter to img if range allows and no rounding;
%        Save motion parameters, if any, into dcmHeader.mat.
% 130722 Ugly fix for isMos, so it works for '2004A 4VA25A' phase data;
%        Store dTE instead of TE if two TE are used, such as fieldmap.
% 130724 Add two more ways for dwell time, useful for '2004A 4VA25A' dicom.
% 130801 Can't use DERIVED since MoCoSeries may be labeled as DERIVED.
% 130807 Check PixelSpacing consistency for a series;
%        Prepare to publish to Matlab Central.
% 130809 Add 5th input for subjName, so one can choose a subject.
% 130813 Store ImageComments, if exists and is meaningful, into aux_file.
% 130818 Expand source to dicom file(s) and wildcards like run1*.dcm.
%        Update fields in dcmHeader.mat, rather than overwriting the file.
%        Include save_nii etc in the code for easy distribution.
% 130821 Bug fix for cellstr input as dicom source.
%        Change file name from dcm2nii.m to reduce confusion from MRICron.
%        GUI implemented into the single file.
% 130823 Remove dependency on Image Processing Toolbox.
% 130826 Bug fix for '*' src input. Minor improvement for dicm_hdr.
% 130827 Try and suggest to use pigz for compression (thanks Chris R.).
% 130905 Avoid the missing-field error for DTI data with 2 excitations.
%        Protect GUI from command line plotting.
% 130912 Use lDelayInTR for slice_dur, possibly useful for old data.
% 130916 Store B_matrix for DTI image, if exists.
% 130919 Make the code work for GE and Philips dicom at Chris R website.
% 130922 Remove dependence on normc from nnet toolbox (thank Zhiwei);
%        Prove no slice order info in Philips, at least for Intera 10.4.1.
% 130923 Make the code work for Philips PAR/REC pair files.
% 130926 Take care of non-mosaic DTI for Siemens (img/bval/bvec);
% 130930 Use verify_slice_dir subfun to get slice_dir even for a single file.
% 131001 dicm_hdr can deal with VR of SQ. This slows down it a little.
% 131002 Avoid fullfile for cellstr input (not supported in old ver matlab).
% 131006 Tweak dicm_hdr for multiframe dicom (some bug fixes);
%        First working version for multiframe (tested with Philips dicom).
% 131009 Put dicm_hdr, dicm_img, dicm_dict outside this file;
%        dicm_hdr can read implicit VR, and is faster with single fread;
%        Fix problem in gzipOS when folder name contains space.
% 131020 Make TR & ProtocolName non-mandatory; Set cal_min & cal_max.
% 131021 Check SamplesPerPixel, skip run if it is 1+.
% 131021 Implement conversion for AFNI HEAD/BRIK.
% 131024 Bug fix for dealing with current folder as src folder.
% 131029 Bug fix: Siemens, 2D, non-mosaic, rev-num slices were flipped.
% 131105 DTI parameters: field names more consistent; read DTI flds in
%        save_dti_para for GE/Philips (make others faster); convert Philips
%        bvec from deg into vector (need to be verified).
% 131114 Treak for multiframe dicm_hdr: MUCH faster by using only 1,2,n frames;
%        Bug fix for Philips multiframe DTI parameters;
%        Split multiframe Philips B0 map into mag and phase nii.
% 131117 Make the order of phase/mag image in Philips B0 map irrelevant.
% 131219 Write warning message to a file in data folder (Gui's suggestion).
% 140120 Bug fix in save_dti_para due to missing Manufacturer (Thank Paul).
% 140121 Allow missing instance at beginning of a series.
% 140123 save_nii: bug fix for gzip.m detection, take care of ~ as home dir.
% 140206 bug fix: MoCo detetion bug introduced by removing empty cell earlier.
% 140223 add missing-file check for Philips data by slice locations.
% 140312 use slice timing to set slice_code for both GE and Siemens.
%        Interleaved order was wrong for GE data with even number of slices. 
% 140317 Use MosaicRefAcqTimes from last vol for multiband (thank Chris).
%        Don't re-orient fieldmap, so make FSL happy in case of non_axial. 
%        Ugly fix for wrong dicom item VR 'OB': Avoid using main header 
%        in csa_header(), convert DTI parameters to correct type. There may
%        be other wrong parameters we don't realize. 
% 140319 Store SliceTiming field in dcmHeaders.mat for FSL custom slice timing.
%        Re-orient even if flipping slices for 2D MRAcquisitionType.
% 140324 Not set cal_min, cal_max anymore.
% 140327 Return unconverted subject names in 2nd output.
% 140401 Always flip image so phase dir is correct.
% 140409 Store nii extension (not enabled due to nifti ext issue).
% 140501 Fix for GE: use LocationsInAcquisition to replace ImagesInAcquisition;
%            isDTI=DiffusionDirection>0; Gradient already in image reference.
% 140505 Always re-orient DTI. bvec fix for GE DTI (thx Chris).
% 140506 Remove last DTI vol if it is computed ADC (as dcm2niix);
%        Use SeriesDescription to replace ProtocolName for file name;
%        Improved dim_info and phase direction.
% 140512 Decode GE ProtocolDataBlock for phase direction;
%        strtrim SeriesDescription for nii file name.
% 140513 change stored phase direction to image space for FSL unwarp;
%        Simplify code for dim_info.
% 140516 Switch back to ProtocolName for SIEMENS to take care of MOCO series;
%        Detect Philips Dim3IsVolume (for multi files) during dicom check; 
%        Work for GE interleaved slices even if InstanceNumber is in time order;
%        Do ImagePositionPatient check for all vendors;
%        Simplify code for save_dti_para.
% 140517 Store img with first dim flipped, to take care of DTI bvec problems. 
% 140522 Use SliceNormalVector for mosaic slice_dir, so no worry for revNumb;
%        Bug fix for interleaved descending slice_code.
% 140525 xform sliceCenter to SliceLocation in verify_slice_dir. 
% 140526 Take care of non-unique ixyz. 
% 140608 Bug fix for GE interleaved slices;
%        Take care all ixyz, put verify_slice_dir into xform_mat.
% 140610 Compute readout time for DTI, rather than dwell time.
% 140621 Support tgz file as data source.
% 140716 Bug fix due to empty src for GUI subject option.
% 140808 Simplify mosaic detection, and remove isMosaic.
% 140816 Simplify DTI detection.
% 140911 Minor fix for Siemens ProtocolName for error message.
% 141016 Remember GUI settings from last conversion;
%        Make multi-subject error message friendly.
% 141021 Show percent progress for validating dicom files.
% 141023 Get LocationsInAcquisition for GE multiframe dicom.
% 141024 Use unique ImagePositionPatient to determine LocationsInAcquisition.
% 141028 Use matlabpool if available and worthy.
% 141125 Store NumberOfTemporalPositions in dicom header.
% 141128 Minor tweaks for Octave 3.8.1 command line (GUI not working).
% 141216 Use ImagePositionPatient to derive SliceThickness if possible.
% 141217 Override LocationsInAcquisition with computed nSL (thx Luigi);
%        Check RescaleIntercept and RescaleSlope consistency.
% 141218 Allow 1e-4 diff for ImagePositionPatient of same slice location.
% 141223 multiFrameFields: return earlier if only single frame (thx Sander);
%        No re-orient for single slice (otherwise problem for mricron to read).
% 141224 mos2vol: use nSL loop (faster unless many slices).
% 141229 Save nii ext (ecode=40) if FSL is detected & it is not 5.0.5/5.0.6.
% 141230 nojvm: no matlabpool; no dicm_hdr progress due to '\b' issue for WIN.
% 150109 dicm_img(s, 0) to follow the update for dicm_img.
% 150112 Use nii_tool.m, remove make_nii, save_nii etc from this file.
% 150115 Allow SamplesPerPixel>1, but likely not very useful.
% 150117 Store seq name in intent_name.
% 150119 Add phase img detection for Philips (still need it for GE).
% 150120 No file skip by EchoTime: keep all data by using EchoNumber.
% 150209 Add more output format for SPM style: 3D output;
%        GUI includes SPM 3D, separates GZ option. 
% 150211 No missing file check for all vendors, relying on ImagePosition check;
%        csa_header() relies on dicm_hdr decoding (avoid error on old data);
%        Deal with dim3-RGB and dim4-frames due to dicm_img.m update.
% 150222 Remove useless, mis-used TriggerTime for partial hdr; also B_matrix.
% 150302 No hardcoded sign change for DTI bvec, except for GE;
%        set_nii_header: do flip only once after permute;
% 150303 Bug fix for phPos: result was right by lucky mistake;
%        Progress shows nii dim, more informative than number of files.
% 150305 Replace null with cross: null gives inconsistent signs;
%        Use SPM method for xform: account for shear; no qform setting if shear.
% 150306 GE: fully sort slices by loc to ease bvec sign (test data needed);
%        bvec sign simplified by above sort & corrected R for Philips/Siemens.
% 150309 GUI: added the little popup for 'about/license'.  
% 150323 Siemens non-mosaic: RefAcqTimes from ucMode, AcquisitionTime(disabled).   
% 150324 mandatory flds reduced to 5; get info by asc_header if possible;
% 150325 Use SeriesInstanceUID to take care of multiple Study and PatientName; 
%        Remove 5th input (subj); GUI updated; subjName in file name if needed;
%        Deal with MoCo series by output file names;
%        Convert GLM and DTI junk too; no Manufacturer check in advance.
% 150405 Implement BrainVoyager dmr/fmr/vmr conversion; GUI updated accordingly. 
% 150413 InstanceNumber is not mandatory (now total 4);
%        Check missing files for non-DTI mosaic by InstanceNumber.
% 150418 phaseDirection: bug fix for Philips, simplify for others.
% 150420 store raw timing in RefAcqTimes, avoid confusion with SliceTiming.
% 150423 fix matlabpool for later matlab versions; no auto-close anymore;
%        GUI figure handle can't be uint32 for matlab 2015;
%        Turn off saveExt40: FSL 5.0.8 may read vox_offset as 352.
% 150430 xform_mat: GE, no LastScanLoc needed since sorted by ImagePosition. 
% 150508 csa2pos: bug fix for revNum, iSL==1; treat dInPlaneRot specially.
% 150514 set_nii_ext: start to store txt edata (ecode=6).
%        Avoid dict change in dicm_hdr due to vendor change (GE/Philips faster);
% 150517 Octave compatibility fix in multiple files.
% 150526 multiFrameFields: LocationsInAcquisition by ImagePosition if needed.
% 150531 Check slice loc for all volumes to catch missing files (thx CarloR).
% 150604 phaseDirection: typo fix for Philips 'RLAPFH'; Show converter version.
% 150606 csa_header read both CSA image/series header.
% 150609 No t_unit and SliceTiming for DTI.
% 150613 mb_slicetiming: try to fix SOME broken multiband slice timing.
% 150620 use 'bval' for nii.ext and dcmHeaders.mat, so keep original B_value.
% 150910 bug fix for scl_slope/inter: missing double for max/min(nii.img(:)).
% 150924 PAR: fix weird SliceNumber; fix mean-ADC removal if not last vol.
% 150925 Bug fix for nSL=1 (vol-dim was at slice-dim);
% 150926 multiFrameFields: add SliceNumber & simplify code; 
%        save_dti_para: tidy format; try to avoid genvarname.
% 150927 Repalce misused length with numel in all files. 
% 150928 checkImagePostion: skip most irregular spacing.
% 150929 Take care of SL order for regular dicom: GE no longer special case.
% 150930 Remove slice_dir guess; Use NiftiName for error info.
% 151115 GUI: remove srcType; Implement drag&drop for src and dst.
% 151117 save_json proposed by ChrisG; won't flush nii_viewer para.
% 151212 Bug fix for missing pref_file.
% 151217 gui callback uses subfunc directly, also include fh as argument.
% 151221 dim_info stores phaseDir at highest 2 bits (1 pos, 2 neg, 0 unknown).
% 160110 Implement "Check update" based on findjobj; Preference method updated.
% 160112 SeriesInstanceUID & SeriesNumber only need one (thx DavidR).
% 160115 checkUpdate: fix problem to download & unzip to pwd.
% 160127 dicm_hdr & dicm_img: support big endian dicom.
% End of history. Don't edit this line!

% TODO: need testing files to figure out following parameters:
%    flag for MOCO series for GE/Philips
%    GE non-axial slice bvec sign
%    Phase image flag for GE

if nargout, varargout{1} = ''; end
if nargin==3 && ischar(varargin{1}) && strcmp(varargin{1}, 'func_handle')
    if strcmp(dataFolder, 'all') % for command line test
        fcns = localfunctions; % only for Matlab since 2013b
        for i = 1:numel(fcns)
            nam = func2str(fcns{i});
            assignin('base', nam, eval(['@' nam]));
        end
    else
        varargout{1} = eval(['@' dataFolder]);
    end
    return;
end

%% Deal with output format first, and error out if invalid
if nargin<3 || isempty(varargin{1}), fmt = 1; % default .nii.gz
else fmt = varargin{1};
end

if (isnumeric(fmt) && any(fmt==[0 1 4 5])) || ...
      (ischar(fmt) && ~isempty(regexpi(fmt, 'nii')))
    ext = '.nii';
elseif (isnumeric(fmt) && any(fmt==[2 3 6 7])) || (ischar(fmt) && ...
        (~isempty(regexpi(fmt, 'hdr')) || ~isempty(regexpi(fmt, 'img'))))
    ext = '.img';
else
    error(' Invalid output file format (the 3rd input).');
end

if (isnumeric(fmt) && mod(fmt,2)) || (ischar(fmt) && ~isempty(regexpi(fmt, '.gz')))
    ext = [ext '.gz']; % gzip file
end

rst3D = (isnumeric(fmt) && fmt>3) || (ischar(fmt) && ~isempty(regexpi(fmt, '3D')));

%% Deal with MoCo option
if nargin<4 || isempty(varargin{2})
    MoCo = 1; % by default, use original series if both present 
else
    MoCo = varargin{2};
    if ~any(MoCo==0:2)
        error(' Invalid MoCoOption. The 4th input must be 0, 1 or 2.');
    end
end

%% Deal with data source
if nargin<1 || isempty(src) || (nargin<2 || isempty(dataFolder))
    create_gui; % show GUI if input is not enough
    return;
end

tic;
unzip_cmd = '';
if isnumeric(src)
    error('Invalid dicom source.');    
elseif iscellstr(src) % multiple files
    dcmFolder = folderFromFile(src{1});
    n = numel(src);
    fnames = src;
    for i = 1:n
        foo = dir(src{i});
        if isempty(foo), error('%s does not exist.', src{i}); end
        fnames{i} = fullfile(dcmFolder, foo.name); 
    end
elseif ~exist(src, 'file') % like input: run1*.dcm
    fnames = dir(src);
    if isempty(fnames), error('%s does not exist.', src); end
    fnames([fnames.isdir]) = [];
    dcmFolder = folderFromFile(src);
    fnames = strcat(dcmFolder, filesep, {fnames.name});    
elseif isdir(src) % folder
    dcmFolder = src;
elseif ischar(src) % 1 dicom or zip/tgz file
    dcmFolder = folderFromFile(src);
    unzip_cmd = compress_func(src);
    if isempty(unzip_cmd)
        fnames = dir(src);
        fnames = strcat(dcmFolder, filesep, {fnames.name});
    end
else 
    error('Unknown dicom source.');
end
dcmFolder = fullfile(getfield(what(dcmFolder), 'path'));

%% Deal with dataFolder
if ~isdir(dataFolder), mkdir(dataFolder); end
dataFolder = fullfile([getfield(what(dataFolder), 'path') filesep]);
converter = ['dicm2nii.m 20' reviseDate];
if errorLog('', dataFolder) % let it remember dataFolder for later call
    more off;
    disp(['Xiangrui Li''s ' converter ' (feedback to xiangrui.li@gmail.com)']);
end

%% Unzip if compressed file is the source
if ~isempty(unzip_cmd)
    [~, fname, ext1] = fileparts(src);
    dcmFolder = sprintf('%stmpDcm%s/', dataFolder, fname);
    if ~isdir(dcmFolder), mkdir(dcmFolder); end
    disp(['Extracting files from ' fname ext1 ' ...']);

    if strcmp(unzip_cmd, 'unzip')
        cmd = sprintf('unzip -qq -o %s -d %s', src, dcmFolder);
        err = system(cmd); % first try system unzip
        if err, unzip(src, dcmFolder); end % Matlab's unzip is too slow
    elseif strcmp(unzip_cmd, 'untar')
        if isempty(which('untar')), error('No untar found in matlab path.'); end
        untar(src, dcmFolder);
    end
    drawnow;
end 

%% Get all file names including those in subfolders, if not specified
if ~exist('fnames', 'var')
    dirs = genpath(dcmFolder);
    dirs = textscan(dirs, '%s', 'Delimiter', pathsep);
    dirs = dirs{1}; % cell str
    fnames = {};
    for i = 1:numel(dirs)
        curFolder = [dirs{i} filesep];
        foo = dir(curFolder); % all files and folders
        foo([foo.isdir]) = []; % remove folders
        foo = strcat(curFolder, {foo.name});
        fnames = [fnames foo]; %#ok<*AGROW>
    end
end
nFile = numel(fnames);
if nFile<1, error(' No files found in the data source.'); end

%% Check each file, store partial header in cell array hh
% first 3 fields are must, 4 or 5 must have one
flds = {'Columns' 'Rows' 'BitsAllocated' 'SeriesInstanceUID' 'SeriesNumber' ...
    'ImageOrientationPatient' 'ImagePositionPatient' 'PixelSpacing' ...
    'PixelRepresentation' 'BitsStored' 'HighBit' 'SamplesPerPixel' ...
    'PlanarConfiguration' 'EchoNumber' 'RescaleIntercept' 'RescaleSlope' ...
    'InstanceNumber' 'NumberOfFrames' 'B_value' 'DiffusionGradientDirection' ...
    'RTIA_timer' 'RBMoCoTrans' 'RBMoCoRot' ...
    'SliceThickness' 'SpacingBetweenSlices'};
dict = dicm_dict('SIEMENS', flds); % dicm_hdr will update vendor if needed

% read header for all files, use parpool if available and worthy
fprintf('Validating %g files ...\n', nFile);
hh = cell(1, nFile); errStr = cell(1, nFile);
doPar = useParTool(nFile>1000); % use it if already open or nFile>1000
for k = 1:nFile
    [hh{k}, errStr{k}, dict] = dicm_hdr(fnames{k}, dict);
    if doPar && ~isempty(hh{k}) % parfor wont allow updating dict
        parfor i = k+1:nFile
            [hh{i}, errStr{i}] = dicm_hdr(fnames{i}, dict); 
        end
        break; 
    end
end

%% sort headers into cell h by SeriesInstanceUID, EchoNumber and InstanceNumber
h = {}; % in case of no dicom files at all
errInfo = '';
seriesUIDs = {};
for k = 1:nFile
    s = hh{k};
    if isempty(s) || any(~isfield(s, flds(1:3))) || ~any(isfield(s, flds(4:5)))
        if ~isempty(errStr{k}) % && isempty(strfind(errInfo, errStr{k}))
            errInfo = sprintf('%s\n%s\n', errInfo, errStr{k});
        end
        continue; % skip the file
    end

    if ~isfield(s, 'SeriesInstanceUID')
        s.SeriesInstanceUID = num2str(s.SeriesNumber); % make up UID
    end
    m = find(strcmp(s.SeriesInstanceUID, seriesUIDs));
    if isempty(m)
        m = numel(seriesUIDs)+1;
        seriesUIDs{m} = s.SeriesInstanceUID;
    end
    
    % EchoNumber is needed for Siemens fieldmap mag series
    i = tryGetField(s, 'EchoNumber', 1); if i<1, i = 1; end
    j = tryGetField(s, 'InstanceNumber');
    if isempty(j) || j<1
        try j = numel(h{m}{i}) + 1;
        catch, j = 1; 
        end
    end
    h{m}{i}{j} = s; % store partial header
end
clear hh errStr;

%% Check headers: remove file-missing and dim-inconsistent series
nRun = numel(h);
if nRun<1
    errorLog(sprintf('No valid files found:\n%s.', errInfo)); 
    return;
end
keep = true(1, nRun); % true for useful runs
subjs = cell(1, nRun); vendor = cell(1, nRun);
sNs = ones(1, nRun); studyIDs = cell(1, nRun);
fldsCk = {'ImageOrientationPatient' 'NumberOfFrames' 'Columns' 'Rows' ...
          'PixelSpacing' 'RescaleIntercept' 'RescaleSlope' 'SamplesPerPixel' ...
          'SpacingBetweenSlices' 'SliceThickness'}; % last for thickness
for i = 1:nRun
    h{i} = [h{i}{:}]; % concatenate different EchoNumber
    ind = cellfun(@isempty, h{i});
    h{i}(ind) = []; % remove all empty cell for all vendors
    
    s = h{i}{1};
    if ~isfield(s, 'LastFile') % avoid re-read for PAR/HEAD/BV file
        s = dicm_hdr(s.Filename); % full header for 1st file
    end
    if ~isfield(s, 'Manufacturer'), s.Manufacturer = 'Unknown'; end
    subjs{i} = PatientName(s);
    vendor{i} = s.Manufacturer;
    sNs(i) = tryGetField(s, 'SeriesNumber', 1);
    studyIDs{i} = tryGetField(s, 'StudyID', '1');
    series = sprintf('Subject %s, %s (Series %g)', subjs{i}, ProtocolName(s), sNs(i));
    s = multiFrameFields(s); % no-op if non multi-frame
    if isempty(s), keep(i) = 0; continue; end % invalid multiframe series
    s.isDTI = isDTI(s);
    h{i}{1} = s; % update record in case of full hdr or multiframe
    
    % check consistency in 'fldsCk'
    nFile = numel(h{i});
    if nFile<2, continue; end
    nFlds = numel(fldsCk);
    if isfield(s, 'SpacingBetweenSlices'), nFlds = nFlds - 1; end % check 1 of 2
    for k = 1:nFlds
        val1  = tryGetField(s, fldsCk{k});
        if isempty(val1), continue; end
        for j = 2:nFile
            % At least some GE ImageOrientationPatient can have diff of 1e-6
            val2 = tryGetField(h{i}{j}, fldsCk{k});
            if isempty(val2) || any(abs(val1 - val2) > 1e-4)
                errorLog(['Inconsistent ''' fldsCk{k} ''' for ' series '. Series skipped.']);
                keep(i) = 0;
                break;
            end
        end
        if ~keep(i), break; end % skip
    end
    
    if ~isempty(csa_header(s, 'NumberOfImagesInMosaic'))
        if s.isDTI, continue; end % allow missing directions for DTI
        a = zeros(1, nFile);
        for j = 1:nFile, a(j) = tryGetField(h{i}{j}, 'InstanceNumber', 1); end
        if any(diff(a) ~= 1)
            errorLog(['Missing file(s) detected for ' series '. Series skipped.']);
            keep(i) = 0;
        end
        continue; % no other check for mosaic
    end
        
    if ~keep(i) || ~isfield(s, 'ImagePositionPatient'), continue; end
    
    ipp = zeros(nFile, 3);
    for j = 1:nFile, ipp(j,:) = h{i}{j}.ImagePositionPatient; end
    [err, nSL, sliceN, isTZ] = checkImagePostion(ipp);
    if ~isempty(err)
        errorLog([err ' for ' series '. Series skipped.']);
        keep(i) = 0; continue; % skip
    end
    
    h{i}{1}.LocationsInAcquisition = uint16(nSL); % best way for nSL?

    nVol = nFile / nSL;
    if isTZ % Dim3IsVolume: Philips
        ind = reshape(1:nFile, [nVol nSL])';
        h{i} = h{i}(ind(:));
        h{i}{1}.Dim3IsVolume = true; % not needed, info only
    end
       
    % re-order slices within vol. No SliceNumber since files are organized
    if any(diff(sliceN, 2) > 0) % neither 1:nSL nor nSL:-1:1
        if sliceN(end) == 1, sliceN = sliceN(nSL:-1:1); end % not important
        inc = repmat((0:nVol-1)*nSL, nSL, 1);
        ind = repmat(sliceN(:), nVol, 1) + inc(:);
        h{i} = h{i}(ind); % sorted by slice locations
        if sliceN(1)>1 % first file changed: update info for h{i}{1}
            h{i}{1} = dicm_hdr(h{i}{1}.Filename); % read full hdr
            s = h{i}{sliceN==1}; % original first file
            fldsCp = {'AcquisitionDateTime' 'isDTI' 'Dim3IsVolume' ...
                'LocationsInAcquisition'};
            for j = 1:numel(fldsCp)
                if isfield(s, fldsCp{j})
                    h{i}{1}.(fldsCp{j}) = s.(fldsCp{j}); 
                end
            end
            if ~isfield(s, fldsCp{1}) % assumption: 1st instance is earliest
                h{i}{1}.(fldsCp{1}) = [tryGetField(s, 'AcquisitionDate', '') ...
                                       tryGetField(s, 'AcquisitionTime', '')];
            end
        end
    end
end
h = h(keep); sNs = sNs(keep); studyIDs = studyIDs(keep); 
subjs = subjs(keep); vendor = vendor(keep);

%% sort h by PatientName, then StudyID, then SeriesNumber
% Also get correct order for subjs/studyIDs/nStudy/sNs for nii file names
[subjs, ind] = sort(subjs);
subj = unique(subjs); 
h = h(ind); sNs = sNs(ind); studyIDs = studyIDs(ind); % by subjs now
nStudy = ones(1, nRun); % one for each series
for i = 1:numel(subj)
    iSub = find(strcmp(subj{i}, subjs));
    study = studyIDs(iSub);
    [study, iStudy] = sort(study); % by study for each subject
    a = h(iSub);   h(iSub)   = a(iStudy);
    a = sNs(iSub); sNs(iSub) = a(iStudy);
    studyIDs(iSub) = study; % done for h/sNs/studyIDs by studyIDs for a subj
    uID = unique(study);
    nStudy(iSub) = numel(uID);
    for k = 1:numel(uID) % now sort h/sNs by sNs for each studyID
        iStudy = strcmp(uID{k}, study);
        ind = iSub(iStudy); 
        [sNs(ind), iSN] = sort(sNs(ind));
        a = h(ind); h(ind) = a(iSN);
    end
end

%% Generate unique result file names
% Unique names are in format of SeriesDescription_s007. Special cases are: 
%  for phase image, such as field_map phase, append '_phase' to the name;
%  for MoCo series, append '_MoCo' to the name if both series are created.
%  for multiple subjs, it is SeriesDescription_subj_s007
%  for multiple Study, it is SeriesDescription_subj_Study1_s007
nRun = numel(h); % update it, since we have removed some
if nRun<1
    errorLog('No valid series found');
    return;
end
rNames = cell(1, nRun);
isMoCo = false(1, nRun);
multiSubj = numel(subj)>1; 
for i = 1:nRun
    s = h{i}{1};
    a = strtrim(ProtocolName(s));
    if isType(s, '\P\') || strcmpi(tryGetField(s, 'ComplexImageComponent', ''), 'PHASE')
        a = [a '_phase']; % phase image
    end
    isMoCo(i) = isType(s, '\MOCO\');
    if MoCo==0 && isMoCo(i), a = [a '_MoCo']; end
    if multiSubj, a = [a '_' subjs{i}]; end
    if nStudy(i)>1, a = [a '_Study' studyIDs{i}]; end
    if ~isstrprop(a(1), 'alpha'), a = ['x' a]; end % genvarname behavior
    a(~isstrprop(a, 'alphanum')) = '_'; % make str valid for field name
    while true % remove repeated underscore
        ind = strfind(a, '__');
        if isempty(ind), break; end
        a(ind) = '';
    end
    sN = sNs(i);
    if sN>100 && strncmp(s.Manufacturer, 'Philips', 7)
        sN = tryGetField(s, 'AcquisitionNumber', floor(sN/100));
    end
    rNames{i} = sprintf('%s_s%03.0f', a, sN);
end
if any(cellfun(@numel, rNames)>namelengthmax)
    rNames = genvarname(rNames); %#ok also guarantee unique names
end 

% deal with MoCo series
if MoCo>0 && any(isMoCo)
    keep = true(1, nRun);
    for i = 2:nRun
        if isMoCo(i) && sNs(i)==sNs(i-1)+1 && ...
                strcmp(rNames{i}(1:end-5), rNames{i-1}(1:end-5))
            if MoCo==1
                keep(i) = 0; % skip MOCO
            elseif MoCo==2
                keep(i-1) = 0; % skip original
            end
        end
    end
    h = h(keep); rNames = rNames(keep);
    vendor = vendor(keep); subj = unique(subjs(keep));
    nRun = numel(h);
end

vendor = strtok(unique(vendor));
if nargout>0, varargout{1} = subj; end % return converted subject IDs
if nargout>1, varargout{2} = {}; end % will remove in the future

% After following sort, we need to compare only neighboring names. Remove
% _s007 if there is no conflict. Have to ignore letter case for Windows & MAC
fnames = rNames; % copy it, keep letter cases
[rNames, iRuns] = sort(lower(fnames));
for i = 1:nRun
    a = rNames{i}(1:end-5); % remove _s003
    % no conflict with both previous and next name
    if nRun==1 || ... % only one run
         (i==1    && ~strcmpi(a, rNames{2}(1:end-5))) || ... % first
         (i==nRun && ~strcmpi(a, rNames{i-1}(1:end-5))) || ... % last
         (i>1 && i<nRun && ~strcmpi(a, rNames{i-1}(1:end-5)) ...
                        && ~strcmpi(a, rNames{i+1}(1:end-5))); % middle ones
        fnames{iRuns(i)}(end+(-4:0)) = [];
    end
end
fmtStr = sprintf(' %%-%gs %%gx%%gx%%gx%%g\n', max(cellfun(@numel, fnames))+6);

%% Now ready to convert nii series by series
subjStr = sprintf('''%s'', ', subj{:}); subjStr(end+(-1:0)) = [];
vendor = sprintf('%s, ', vendor{:}); vendor(end+(-1:0)) = [];
fprintf('Converting %g series (%s) into %g-D %s: subject %s\n', ...
            nRun, vendor, 4-rst3D, ext, subjStr);
for i = 1:nRun
    nFile = numel(h{i});
    h{i}{1}.NiftiName = fnames{i}; % for convenience of error info
    s = h{i}{1};
    if nFile>1 && ~isfield(s, 'LastFile')
        h{i}{1}.LastFile = h{i}{nFile}; % store partial last header into 1st
    end
    
    img = dicm_img(s, 0); % initialize data type and img size. No transpose
    if ndims(img)>4 % err out, likely won't work for other series
        error('Image with 5 or more dim not supported: %s', s.NiftiName);
    end
    img(:, :, :, 2:nFile) = 0; % pre-allocate
    for j = 2:nFile, img(:,:,:,j) = dicm_img(h{i}{j}, 0); end
    if size(img,3)<2, img = permute(img, [1 2 4 3]); end % put frames into dim3
    
    nSL = csa_header(s, 'NumberOfImagesInMosaic', 1);
    if tryGetField(s, 'SamplesPerPixel', 1) > 1 % color image
        img = permute(img, [1 2 4:8 3]); % put RGB into dim8 for nii_tool
    elseif nSL>1 % SIEMENS mosaic
        img = mos2vol(img, nSL); % mosaic to volume
    elseif ndims(img)==4 && tryGetField(s, 'Dim3IsVolume', false) % BV/BRIK
        img = permute(img, [1 2 4 3]);
    elseif ndims(img) == 3 % may need to reshape to 4D
        nSL = double(tryGetField(s, 'LocationsInAcquisition'));
        if ~isempty(nSL)
            dim = size(img);
            dim(3:4) = [nSL dim(3)/nSL]; % verified integer earlier
            if nFile==1 && tryGetField(s, 'Dim3IsVolume', false)
                % for PAR and single multiframe dicom
                img = reshape(img, dim([1 2 4 3]));
                img = permute(img, [1 2 4 3]);
            else
                img = reshape(img, dim);
            end
        end
        % fix weird slice ordering for PAR (seen) and multiframe
        if isfield(s, 'SliceNumber'), img(:,:,s.SliceNumber,:) = img; end
    end

    dim = size(img);
    if numel(dim)<3, dim(3) = 1; end % single slice
    fld = 'NumberOfTemporalPositions';
    if ~isfield(s, fld) && numel(dim)>3 && dim(4)>1, h{i}{1}.(fld) = dim(4); end

    if any(~isfield(s, {'ImageOrientationPatient' 'ImagePositionPatient'}))
        h{i}{1} = csa2pos(h{i}{1}, dim(3));
    end
    
    % Store GE slice timing. No slice order info for Philips at all!
    if isfield(s, 'RTIA_timer') && ~s.isDTI
        t = zeros(dim(3), 1);
        for j = 1:dim(3), t(j) = tryGetField(h{i}{j}, 'RTIA_timer', nan); end
        if ~all(diff(t)==0), h{i}{1}.RefAcqTimes = t/10; end % in ms
        
%     % Get slice timing for non-mosaic Siemens file. Could remove Manufacturer
%     % check, but GE/Philips AcquisitionTime seems useless
%     elseif numel(dim)>3 && dim(4)>2 && ~isfield(s, 'MosaicRefAcqTimes') ...
%             && strncmpi(s.Manufacturer, 'SIEMENS', 7) && ~s.isDTI
%         dict = dicm_dict('', {'AcquisitionDate' 'AcquisitionTime'});
%         t = zeros(dim(3), 1);
%         for j = 1:dim(3)
%             s1 = dicm_hdr(h{i}{j}.Filename, dict);
%             str = [s1.AcquisitionDate s1.AcquisitionTime];
%             t(j) = datenum(str, 'yyyymmddHHMMSS.fff');
%         end
%         h{i}{1}.RefAcqTimes = (t - min(t)) * 24 * 3600 * 1000; % day to ms
    end
    
    % Store motion parameters for MoCo series
    if all(isfield(s, {'RBMoCoTrans' 'RBMoCoRot'})) && numel(dim)>3
        inc = nFile / dim(4);
        trans = zeros(dim(4), 3);
        rotat = zeros(dim(4), 3);
        for j = 1:inc:nFile
            trans(j,:) = tryGetField(h{i}{j}, 'RBMoCoTrans', [0 0 0]);
            rotat(j,:) = tryGetField(h{i}{j}, 'RBMoCoRot',   [0 0 0]);
        end
        h{i}{1}.RBMoCoTrans = trans;
        h{i}{1}.RBMoCoRot = rotat;
    end
    
    if isa(img, 'uint16') && max(img(:))<32768
        img = int16(img); % use int16 if lossless. seems always true
    end
    
    nii = nii_tool('init', img); % create nii struct based on img
    fname = [dataFolder fnames{i}]; % name without ext

    % Compute bval & bvec in dicom image reference for DTI series
    if s.isDTI, [h{i}, nii] = get_dti_para(h{i}, nii); end
    
    [nii, h{i}{1}] = set_nii_header(nii, h{i}{1}); % set most nii header
    h{i}{1}.NiftiCreator = converter;
    nii.ext = set_nii_ext(h{i}{1}); % NIfTI extension
    try save_json(h{i}{1}, fname); catch, end

    % Save bval and bvec files after bvec perm/sign adjusted in set_nii_header
    if s.isDTI, save_dti_para(h{i}{1}, fname); end

    [nii, niiP] = split_philips_phase(nii, s); % split Philips mag&phase img
    if ~isempty(niiP)
        fprintf(fmtStr, [fnames{i} '_phase'], niiP.hdr.dim(2:5));
        nii_tool('save', niiP, [fname '_phase' ext], rst3D); % save phase nii
    end
    
    fprintf(fmtStr, fnames{i}, nii.hdr.dim(2:5)); % show info and progress
    nii_tool('save', nii, [fname ext], rst3D);
    h{i} = h{i}{1}; % keep 1st dicm header only
    if isnumeric(h{i}.PixelData), h{i} = rmfield(h{i}, 'PixelData'); end % BV
end

h = cell2struct(h, fnames, 2); % convert into struct
fname = [dataFolder 'dcmHeaders.mat'];
if exist(fname, 'file') % if file exists, we update fields only
    S = load(fname);
    for i = 1:numel(fnames), S.h.(fnames{i}) = h.(fnames{i}); end
    h = S.h; %#ok
end
save(fname, 'h', '-v7'); % -v7 better compatibility
fprintf('Elapsed time by dicm2nii is %.1f seconds\n\n', toc);
if ~isempty(unzip_cmd), rmdir(dcmFolder, 's'); end % delete tmp dicom folder
return;

%% Subfunction: return folder name for a file name
function folder = folderFromFile(fname)
folder = fileparts(fname);
if isempty(folder), folder = pwd; end

%% Subfunction: return PatientName
function subj = PatientName(s)
subj = tryGetField(s, 'PatientName');
if isempty(subj), subj = tryGetField(s, 'PatientID', 'Anonymous'); end

%% Subfunction: return SeriesDescription
function name = ProtocolName(s)
name = tryGetField(s, 'SeriesDescription');
if isempty(name) || (strncmp(s.Manufacturer, 'SIEMENS', 7) && ...
        numel(name)>9 && strcmp(name(end+(-9:0)), 'MoCoSeries'))
    name = tryGetField(s, 'ProtocolName');
end
if isempty(name), [~, name] = fileparts(s.Filename); end

%% Subfunction: return true if any of keywords is in s.ImageType
function tf = isType(s, keywords)
typ = tryGetField(s, 'ImageType', '');
if ischar(keywords) % single keyword
    tf = ~isempty(strfind(typ, keywords));
    return;
end
for i = 1:numel(keywords)
    tf = ~isempty(strfind(typ, keywords{i}));
    if tf, return; end
end

%% Subfunction: return true if series is DTI
function tf = isDTI(s)
tf = isType(s, '\DIFFUSION'); % Siemens, Philips
if tf, return; end
if strncmp(s.Manufacturer, 'GE', 2) % not labeled as \DIFFISION
    tf = tryGetField(s, 'DiffusionDirection', 0)>0;
elseif strncmpi(s.Manufacturer, 'Philips', 7)
    tf = strcmp(tryGetField(s, 'MRSeriesDiffusion', 'N'), 'Y');
else % Some Siemens DTI are not labeled as \DIFFUSION
    tf = ~isempty(csa_header(s, 'B_value'));
end
        
%% Subfunction: get field if exist, return default value otherwise
function val = tryGetField(s, field, dftVal)
if isfield(s, field), val = s.(field); 
elseif nargin>2, val = dftVal;
else val = [];
end

%% Subfunction: Set most nii header and re-orient img
function [nii, s] = set_nii_header(nii, s)
% Transformation matrix: most important feature for nii
dim = nii.hdr.dim(2:4); % space dim, set by nii_tool according to img
[ixyz, R, pixdim, xyz_unit] = xform_mat(s, dim);
R(1:2,:) = -R(1:2,:); % dicom LPS to nifti RAS, xform matrix before reorient

% dim_info byte: freq_dim, phase_dim, slice_dim low to high, each 2 bits
[phPos, iPhase] = phaseDirection(s); % phPos relative to image in FSL feat!
if     iPhase == 2, fps_bits = [1 4 16];
elseif iPhase == 1, fps_bits = [4 1 16]; 
else                fps_bits = [0 0 16];
end

% set TR and slice timing related info before re-orient
[s, nii.hdr] = sliceTiming(s, nii.hdr);
nii.hdr.xyzt_units = xyz_unit + nii.hdr.xyzt_units; % normally: mm (2) + sec (8)

% Reorient if MRAcquisitionType==3D || isDTI && nSL>1
% If FSL etc can read dim_info for STC, we can always reorient.
[~, perm] = sort(ixyz); % may permute 3 dimensions in this order
if (strcmp(tryGetField(s, 'MRAcquisitionType', ''), '3D') || s.isDTI) && ...
        dim(3)>1 && (~isequal(perm, 1:3)) % skip if already standard view
    R(:, 1:3) = R(:, perm); % xform matrix after perm
    fps_bits = fps_bits(perm);
    ixyz = ixyz(perm); % 1:3 after perm
    dim = dim(perm);
    pixdim = pixdim(perm);
    nii.hdr.dim(2:4) = dim;
    nii.img = permute(nii.img, [perm 4:8]);
    if isfield(s, 'bvec'), s.bvec = s.bvec(:, perm); end
end
iSL = find(fps_bits==16);
iPhase = find(fps_bits==4); % axis index for phase_dim in re-oriented img

nii.hdr.dim_info = (1:3) * fps_bits'; % useful for EPI only
nii.hdr.pixdim(2:4) = pixdim; % voxel zize

% Flip image to make first axis negative and other two positive
ind4 = ixyz + [0 4 8]; % index in 4xN matrix
flp = R(ind4)<0; % flip an axis if true
flp(1) = ~flp(1); % first axis negative: comment this to make all positive
rotM = diag([1-flp*2 1]); % 1 or -1 on diagnal
rotM(1:3, 4) = (dim-1) .* flp; % 0 or dim-1
R = R / rotM; % xform matrix after flip
for k = 1:3, if flp(k), nii.img = flipdim(nii.img, k); end; end %#ok
if flp(iPhase), phPos = ~phPos; end
if isfield(s, 'bvec'), s.bvec(:, flp) = -s.bvec(:, flp); end
if isfield(s, 'SliceTiming') && flp(iSL) % slices flipped
    s.SliceTiming = s.SliceTiming(end:-1:1);
    sc = nii.hdr.slice_code;
    if sc>0, nii.hdr.slice_code = sc+mod(sc,2)*2-1; end % 1<->2, 3<->4, 5<->6
end

% sform
frmCode = all(isfield(s, {'ImageOrientationPatient' 'ImagePositionPatient'}));
frmCode = tryGetField(s, 'TemplateSpace', frmCode); % 1: SCANNER_ANAT
nii.hdr.sform_code = frmCode;
nii.hdr.srow_x = R(1,:);
nii.hdr.srow_y = R(2,:);
nii.hdr.srow_z = R(3,:);

% qform
if abs(sum(R(:,iSL).^2) - pixdim(iSL)^2) < 0.01 % no shear at slice direction
    nii.hdr.qform_code = frmCode;
    nii.hdr.qoffset_x = R(1,4);
    nii.hdr.qoffset_y = R(2,4);
    nii.hdr.qoffset_z = R(3,4);

    R = R(1:3, 1:3); % for quaternion
    R = bsxfun(@rdivide, R, sqrt(sum(R.^2))); % normalize
    [q, nii.hdr.pixdim(1)] = dcm2quat(R); % 3x3 dir cos matrix to quaternion
    nii.hdr.quatern_b = q(2);
    nii.hdr.quatern_c = q(3);
    nii.hdr.quatern_d = q(4);
end

% store some possibly useful info in descrip and other text hdr
str = tryGetField(s, 'ImageComments');
if isType(s, '\MOCO\'), str = ''; end % useless for MoCo
foo = tryGetField(s, 'StudyComments');
if ~isempty(foo), str = [str ';' foo]; end
str = [str ';' strtok(s.Manufacturer)];
foo = tryGetField(s, 'ProtocolName');
if ~isempty(foo), str = [str ';' foo]; end
nii.hdr.aux_file = str; % char[24], info only
seq = asc_header(s, 'tSequenceFileName'); % like '%SiemensSeq%\ep2d_bold'
if isempty(seq), seq = tryGetField(s, 'ScanningSequence'); 
else [~, seq] = strtok(seq, '\'); seq = strtok(seq, '\'); % like 'ep2d_bold'
end
nii.hdr.db_name = PatientName(s); % char[18], optional
nii.hdr.intent_name = seq; % char[16], meaning of the data

if ~isfield(s, 'AcquisitionDateTime') && isfield(s, 'AcquisitionTime')
    s.AcquisitionDateTime = [tryGetField(s, 'AcquisitionDate', '') ...
                             tryGetField(s, 'AcquisitionTime', '')];
end
foo = tryGetField(s, 'AcquisitionDateTime');
descrip = sprintf('time=%s;', foo(1:min(18,end))); 
TE0 = asc_header(s, 'alTE[0]')/1000; % s.EchoTime stores only 1 TE
TE1 = asc_header(s, 'alTE[1]')/1000;
if ~isempty(TE1), s.SecondEchoTime = TE1; end
dTE = abs(TE1 - TE0); % TE difference
if isempty(TE0), TE0 = tryGetField(s, 'EchoTime'); end % GE, philips
if isempty(dTE) && tryGetField(s, 'NumberOfEchoes', 1)>1
    dTE = tryGetField(s, 'SecondEchoTime') - TE0; % need to update
end
if ~isempty(dTE)
    descrip = sprintf('dTE=%.4g;%s', dTE, descrip);
    s.deltaTE = dTE;
elseif ~isempty(TE0)
    descrip = sprintf('TE=%.4g;%s', TE0, descrip);
end

% Get dwell time
if ~strcmp(tryGetField(s, 'MRAcquisitionType'), '3D') && ~isempty(iPhase)
    hz = csa_header(s, 'BandwidthPerPixelPhaseEncode');
    dwell = 1000 ./ hz / dim(iPhase); % in ms
    if isempty(dwell) % true for syngo MR 2004A
        % ppf = [1 2 4 8 16] represent [4 5 6 7 8] 8ths PartialFourier
        % ppf = asc_header(s, 'sKSpace.ucPhasePartialFourier');
        lns = asc_header(s, 'sKSpace.lPhaseEncodingLines');
        dur = csa_header(s, 'SliceMeasurementDuration');
        dwell = dur ./ lns; % ./ (log2(ppf)+4) * 8;
    end
    if isempty(dwell) % next is not accurate, so as last resort
        dur = csa_header(s, 'RealDwellTime') * 1e-6; % ns to ms
        dwell = dur * asc_header(s, 'sKSpace.lBaseResolution');
    end
    if isempty(dwell)
        dwell = double(tryGetField(s, 'EffectiveEchoSpacing')) / 1000; % GE
    end
    % http://www.spinozacentre.nl/wiki/index.php/NeuroWiki:Current_developments
    if isempty(dwell) % Philips
        wfs = tryGetField(s, 'WaterFatShift');
        epiFactor = tryGetField(s, 'EPIFactor');
        dwell = wfs ./ (434.215 * (double(epiFactor)+1)) * 1000;
    end
    if ~isempty(dwell)
        if s.isDTI
            % ppf = asc_header(s, 'sKSpace.ucPhasePartialFourier');
            % lns = asc_header(s, 'sKSpace.lPhaseEncodingLines');
            % pat = asc_header(s, 'sPat.ucPATMode');
            % readout = dwell*pat * (lns * (log2(ppf)+4)/8 / pat - 1) / 1000;
            readout = dwell * dim(iPhase) / 1000; % in sec
            descrip = sprintf('readout=%.3g;%s', readout, descrip);
            s.ReadoutSeconds = readout;
        else
            descrip = sprintf('dwell=%.3g;%s', dwell, descrip);
            s.EffectiveEPIEchoSpacing = dwell;
        end
    end
end

if ~isempty(iPhase)
    if isempty(phPos), pm = '?'; b67 = 0;
    elseif phPos,      pm = '';  b67 = 1;
    else               pm = '-'; b67 = 2;
    end
    nii.hdr.dim_info = nii.hdr.dim_info + b67*64;
    axes = 'xyz'; % actually ijk
    phDir = [pm axes(iPhase)];
    s.UnwarpDirection = phDir;
    descrip = sprintf('phase=%s;%s', phDir, descrip);
end
nii.hdr.descrip = descrip; % char[80], drop from end if exceed

% data slope and intercept: apply to img if no rounding error 
if any(isfield(s, {'RescaleSlope' 'RescaleIntercept'}))
    slope = tryGetField(s, 'RescaleSlope', 1); 
    inter = tryGetField(s, 'RescaleIntercept', 0); 
    val = sort(double([max(nii.img(:)) min(nii.img(:))]) * slope + inter);
    dClass = class(nii.img);
    if isa(nii.img, 'float') || (mod(slope,1)==0 && mod(inter,1)==0 ... 
            && val(1)>=intmin(dClass) && val(2)<=intmax(dClass))
        nii.img = nii.img * slope + inter; % apply to img if no rounding
    else
        nii.hdr.scl_slope = slope;
        nii.hdr.scl_inter = inter;
    end
end

% Possible patient position: HFS/HFP/FFS/FFP / HFDR/HFDL/FFDR/FFDL
% Seems dicom takes care of this, and maybe nothing needs to do here.
% patientPos = tryGetField(s, 'PatientPosition', '');

%% Subfunction, reshape mosaic into volume, remove padded zeros
function vol = mos2vol(mos, nSL)
nMos = ceil(sqrt(nSL)); % always nMos x nMos tiles
[nr, nc, nv] = size(mos); % number of row, col and vol in mosaic

nr = nr / nMos; nc = nc / nMos; % number of row and col in slice
vol = zeros([nr nc nSL nv], class(mos)); %#ok
for i = 1:nSL
    r =    mod(i-1, nMos) * nr + (1:nr); % 2nd slice is tile(2,1)
    c = floor((i-1)/nMos) * nc + (1:nc);
    % r = floor((i-1)/nMos) * nr + (1:nr); % 2nd slice is tile(1,2)
    % c =    mod(i-1, nMos) * nc + (1:nc);
    vol(:, :, i, :) = mos(r, c, :);
end

%% subfunction: set slice timing related info
function [s, hdr] = sliceTiming(s, hdr)
TR = tryGetField(s, 'RepetitionTime'); % in ms
if isempty(TR), TR = tryGetField(s, 'TemporalResolution'); end
if isempty(TR), return; end
hdr.pixdim(5) = TR / 1000;
if tryGetField(s, 'isDTI', 0), return; end
hdr.xyzt_units = 8; % seconds
if hdr.dim(5)<3, return; end % skip structual, fieldmap etc

delay = asc_header(s, 'lDelayTimeInTR')/1000; % in ms now
if isempty(delay), delay = 0; end
TA = TR - delay;
t = csa_header(s, 'MosaicRefAcqTimes'); % in ms
if ~isempty(t) && isfield(s, 'LastFile') && max(t)-min(t)>TA % MB wrong vol 1
    try t = mb_slicetiming(s, TA); catch, end
end
if isempty(t), t = tryGetField(s, 'RefAcqTimes'); end % GE or Siemens non-mosaic

nSL = hdr.dim(4);
if isempty(t) % non-mosaic Siemens: create 't' based on ucMode
    ucMode = asc_header(s, 'sSliceArray.ucMode'); % 1/2/4: Asc/Desc/Inter
    if isempty(ucMode), return; end
    t = linspace(0, TA, nSL+1)'; t(end) = [];
    if ucMode==2
        t = t(nSL:-1:1);
    elseif ucMode==4
        if mod(nSL,2), t([1:2:nSL 2:2:nSL]) = t;
        else t([2:2:nSL 1:2:nSL]) = t;
        end
    end
    if asc_header(s, 'sSliceArray.ucImageNumb'), t = t(nSL:-1:1); end % rev-num
    s.RefAcqTimes = t;
end

if numel(t)<2, return; end
t = t - min(t); % it may be relative to 1st slice

t1 = sort(t);
dur = mean(diff(t1));
dif = mean(diff(t));
if dur==0 || (t1(end)>TA), sc = 0; % no useful info, or bad timing MB
elseif t1(1) == t1(2), sc = 7; % timing available MB, madeup code 7
elseif abs(dif-dur)<1e-3, sc = 1; % ascending
elseif abs(dif+dur)<1e-3, sc = 2; % descending
elseif t(1)<t(3) % ascending interleaved
    if t(1)<t(2), sc = 3; % odd slices first
    else sc = 5; % Siemens even number of slices
    end
elseif t(1)>t(3) % descending interleaved
    if t(1)>t(2), sc = 4;
    else sc = 6; % Siemens even number of slices
    end
else sc = 0; % unlikely to reach
end

s.SliceTiming = 0.5 - t/TR; % as for FSL custom timing
hdr.slice_code = sc;
hdr.slice_end = nSL-1; % 0-based, slice_start default to 0
hdr.slice_duration = min(diff(t1))/1000;

%% subfunction: extract bval & bvec, store in 1st header
function [h, nii] = get_dti_para(h, nii)
nSL = nii.hdr.dim(4);
nDir = nii.hdr.dim(5);
if nDir<2, return; end
bval = nan(nDir, 1);
bvec = nan(nDir, 3);
s = h{1};

if isfield(s, 'bvec_original')
    bval = s.B_value;
    bvec = tryGetField(s, 'bvec_original');
elseif isfield(s, 'PerFrameFunctionalGroupsSequence')
    if tryGetField(s, 'Dim3IsVolume', false), iDir = 1:nDir;
    else iDir = 1:nSL:nSL*nDir;
    end
    flds = {'DiffusionGradientDirectionSequence' 'DiffusionGradientDirection'};
    dict = dicm_dict(s.Manufacturer, [MF_val('B_value') flds]);
    s2 = dicm_hdr(s.Filename, dict, iDir); % re-read needed frames
    for j = 1:nDir
        a = MF_val('B_value', s2, iDir(j));
        if ~isempty(a), bval(j) = a; end
        a = MF_val(flds{1}, s2, iDir(j));
        if ~isempty(a), bvec(j,:) = a.Item_1.(flds{2}); end
    end
else % multiple files: order already in slices then volumes
    dict = dicm_dict(s.Manufacturer, {'B_value' 'B_factor' 'SlopInt_6_9' ...
       'DiffusionDirectionX' 'DiffusionDirectionY' 'DiffusionDirectionZ'});
    iDir = (0:nDir-1) * numel(h)/nDir + 1; % could be mosaic 
    for j = 1:nDir % no these values for 1st file of each excitation
        s2 = h{iDir(j)};
        val = tryGetField(s2, 'B_value');
        if val == 0, continue; end
        vec = tryGetField(s2, 'DiffusionGradientDirection'); % Siemens/Philips
        imgRef = isempty(vec); % likely GE if true. B_value=0 won't reach here
        if isempty(val) || isempty(vec) % likely GE
            s2 = dicm_hdr(s2.Filename, dict);
        end
        
        if isempty(val), val = tryGetField(s2, 'B_factor'); end % old Philips
        if isempty(val) && isfield(s2, 'SlopInt_6_9') % GE
            val = s2.SlopInt_6_9(1);
        end
        if isempty(val), val = 0; end % may be B_value=0
        bval(j) = val;
        
        if isempty(vec) % GE, old Philips
            vec(1) = tryGetField(s2, 'DiffusionDirectionX', 0);
            vec(2) = tryGetField(s2, 'DiffusionDirectionY', 0);
            vec(3) = tryGetField(s2, 'DiffusionDirectionZ', 0);
        end
        bvec(j,:) = vec;
    end
end

if all(isnan(bval)) && all(isnan(bvec(:)))
    errorLog(['Failed to get DTI parameters: ' s.NiftiName]);
    return; 
end
bval(isnan(bval)) = 0;
bvec(isnan(bvec)) = 0;

if strncmpi(s.Manufacturer, 'Philips', 7)
    if max(sum(bvec.^2, 2)) > 2 % guess in degree
        for j = 1:nDir, bvec(j,:) = ang2vec(bvec(j,:)); end % deg to dir cos mat
        errorLog(['Please validate bvec (direction in deg): ' s.NiftiName]);
    end
    
    % Remove computed ADC: it may not be the last vol
    ind = find(bval>1e-4 & sum(abs(bvec),2)<1e-4);
    if ~isempty(ind)
        try isISO = s.LastFile.DiffusionDirectionality;
        catch, isISO = false;
        end
        if ~isISO
            bval(ind) = [];
            bvec(ind,:) = [];
            nii.img(:,:,:,ind) = [];
            nDir = nDir - numel(ind);
            nii.hdr.dim(5) = nDir;
        end
    end
end

h{1}.bval = bval; % store all into header of 1st file
h{1}.bvec_original = bvec; % original from dicom

% http://wiki.na-mic.org/Wiki/index.php/NAMIC_Wiki:DTI:DICOM_for_DWI_and_DTI
[ixyz, R] = xform_mat(s, nii.hdr.dim(2:4)); % R takes care of slice dir
if exist('imgRef', 'var') && imgRef % GE bvec already in image reference
    % Following sign change is based on FSL result. non-axial slice not tested
    if strcmp(tryGetField(s, 'InPlanePhaseEncodingDirection'), 'ROW')
        bvec = bvec(:, [2 1 3]);
        bvec(:, 2:3) = -bvec(:, 2:3);
    else
        bvec(:, 1:2) = -bvec(:, 1:2);
    end
    for i=1:3, if R(ixyz(i),i)<0, bvec(:,i) = -bvec(:,i); end; end
    if ixyz(3)<3
        errorLog(sprintf(['%s: bvec sign for non-axial slices not tested.\n' ...
         ' Please check the result and report problem to author.'], s.NiftiName));
    end
else % Siemens/Philips
    R = R(1:3, 1:3);
    R = bsxfun(@rdivide, R, sqrt(sum(R.^2))); % normalize
    bvec = bvec * R; % dicom plane to image plane
end

h{1}.bvec = bvec; % computed bvec

%% subfunction: save bval & bvec files
function save_dti_para(s, fname)
if ~isfield(s, 'bvec') || all(s.bvec(:)==0), return; end
if isfield(s, 'bval')
    fid = fopen([fname '.bval'], 'w');
    fprintf(fid, '%g\t', s.bval); % one row
    fclose(fid);
end

str = repmat('%9.6f\t', 1, size(s.bvec,1));
fid = fopen([fname '.bvec'], 'w');
fprintf(fid, [str '\n'], s.bvec); % 3 rows by # direction cols
fclose(fid);

%% Subfunction: convert rotation angles to vector
function vec = ang2vec(ang)
% do the same as in philips_par: not sure it is right
ca = cosd(ang); sa = sind(ang);
rx = [1 0 0; 0 ca(1) -sa(1); 0 sa(1) ca(1)]; % standard 3D rotation
ry = [ca(2) 0 sa(2); 0 1 0; -sa(2) 0 ca(2)];
rz = [ca(3) -sa(3) 0; sa(3) ca(3) 0; 0 0 1];
R = rx * ry * rz;
% [~, iSL] = max(abs(R(:,3)));
% if iSL == 1 % Sag
%     R(:,[1 3]) = -R(:,[1 3]);
%     R = R(:, [2 3 1]);
% elseif iSL == 2 % Cor
%     R(:,3) = -R(:,3);
%     R = R(:, [1 3 2]);
% end
% http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToAngle/index.htm
vec = [R(3,2)-R(2,3); R(1,3)-R(3,1); R(2,1)-R(1,2)];
vec = vec / sqrt(sum(vec.^2));

%% Subfunction, return a parameter from CSA Image/Series header
function val = csa_header(s, key, dft)
if isfield(s, 'CSAImageHeaderInfo') && isfield(s.CSAImageHeaderInfo, key)
    val = s.CSAImageHeaderInfo.(key);
elseif isfield(s, 'CSASeriesHeaderInfo') && isfield(s.CSASeriesHeaderInfo, key)
    val = s.CSASeriesHeaderInfo.(key);
elseif nargin>2
    val = dft;
else
    val = [];
end

%% Subfunction, Convert 3x3 direction cosine matrix to quaternion
% Simplied from Quaternions by Przemyslaw Baranski 
function [q, proper] = dcm2quat(R)
proper = sign(det(R)); % always -1 if flip_dim1
if proper<0, R(:,3) = -R(:,3); end

q = sqrt([1 1 1; 1 -1 -1; -1 1 -1; -1 -1 1] * diag(R) + 1) / 2;
if ~isreal(q(1)), q(1) = 0; end % if trace(R)+1<0, zero it
[m, ind] = max(q);

switch ind
    case 1
        q(2) = (R(3,2) - R(2,3)) /m/4;
        q(3) = (R(1,3) - R(3,1)) /m/4;
        q(4) = (R(2,1) - R(1,2)) /m/4;
    case 2
        q(1) = (R(3,2) - R(2,3)) /m/4;
        q(3) = (R(1,2) + R(2,1)) /m/4;
        q(4) = (R(3,1) + R(1,3)) /m/4;
    case 3
        q(1) = (R(1,3) - R(3,1)) /m/4;
        q(2) = (R(1,2) + R(2,1)) /m/4;
        q(4) = (R(2,3) + R(3,2)) /m/4;
    case 4
        q(1) = (R(2,1) - R(1,2)) /m/4;
        q(2) = (R(3,1) + R(1,3)) /m/4;
        q(3) = (R(2,3) + R(3,2)) /m/4;
end
if q(1)<0, q = -q; end % as MRICron

%% Subfunction: get dicom xform matrix and related info
function [ixyz, R, pixdim, xyz_unit] = xform_mat(s, dim)
R = reshape(tryGetField(s, 'ImageOrientationPatient', [1 0 0 0 1 0]), 3, 2);
R(:,3) = cross(R(:,1), R(:,2)); % right handed, but sign may be wrong
foo = abs(R);
[~, ixyz] = max(foo); % orientation info: perm of 1:3
if ixyz(2) == ixyz(1), foo(ixyz(2),2) = 0; [~, ixyz(2)] = max(foo(:,2)); end
if any(ixyz(3) == ixyz(1:2)), ixyz(3) = setdiff(1:3, ixyz(1:2)); end
iSL = ixyz(3); % 1/2/3 for Sag/Cor/Tra slice
cosSL = R(iSL, 3);

pixdim = tryGetField(s, 'PixelSpacing');
if isempty(pixdim)
    pixdim = [1 1]; % fake
    xyz_unit = 0; % not uint information
else
    xyz_unit = 2; % mm
end
thk = tryGetField(s, 'SpacingBetweenSlices');
if isempty(thk), thk = tryGetField(s, 'SliceThickness', pixdim(1)); end
pixdim = [pixdim(:); thk];
R = R * diag(pixdim); % apply vox size
% Next is almost dicom xform matrix, except mosaic trans and unsure slice_dir
R = [R tryGetField(s, 'ImagePositionPatient', -dim'/2); 0 0 0 1];

% rest are former: R = verify_slice_dir(R, s, dim, iSL)
if dim(3)<2, return; end % don't care direction for single slice

if s.Columns > dim(1) % Siemens mosaic: use dim(1) since no transpose to img
    R(:,4) = R * [ceil(sqrt(dim(3))-1)*dim(1:2)/2 0 1]'; % real slice location
    vec = csa_header(s, 'SliceNormalVector'); % mosaic has this
    if ~isempty(vec) % exist for all tested data
        if sign(vec(iSL)) ~= sign(cosSL), R(:,3) = -R(:,3); end
        return;
    end
elseif isfield(s, 'LastFile') && isfield(s.LastFile, 'ImagePositionPatient')
    R(1:3, 3) = (s.LastFile.ImagePositionPatient - R(1:3,4)) / (dim(3)-1);
    pixdim(3) = abs(R(iSL,3) / cosSL); % override slice thickness from dcm hdr
    return; % almost all non-mosaic images return from here
end

% Rest of the code is almost unreachable
if isfield(s, 'CSASeriesHeaderInfo') % Siemens both mosaic and regular
    ori = {'Sag' 'Cor' 'Tra'}; ori = ori{iSL};
    sNormal = asc_header(s, ['sSliceArray.asSlice[0].sNormal.d' ori]);
    % csa_header(s, 'ProtocolSliceNumber') won't work for Mprage 
    if asc_header(s, ['sSliceArray.ucImageNumb' ori]), sNormal = -sNormal; end
    if sign(sNormal) ~= sign(cosSL), R(:,3) = -R(:,3); end
    return;
end

pos = []; % SliceLocation for last or center slice we try to retrieve
if isfield(s, 'LastScanLoc') && isfield(s, 'FirstScanLocation') % GE
    pos = mean([s.LastScanLoc s.FirstScanLocation]); % mid-slice center
    if iSL<3, pos = -pos; end % RAS convention!
    pos = [R(iSL, 1:2) pos] * [-(dim(1:2)-1)/2 1]'; % mid-slice location
end

if isempty(pos) && isfield(s, 'Stack') % Philips
    ori = {'RL' 'AP' 'FH'}; ori = ori{iSL};
    pos = tryGetField(s.Stack.Item_1, ['MRStackOffcentre' ori]);
    if ~isempty(pos)
        pos = [R(iSL, 1:2) pos] * [-dim(1:2)/2 1]'; % mid-slice location
    end
end

if isempty(pos) % keep right-handed, and warn user
    errorLog(['Please check whether slices are flipped: ' s.NiftiName]);
elseif sign(pos-R(iSL,4)) ~= sign(cosSL) % same direction?
    R(:,3) = -R(:,3);
end

%% Subfunction: get a parameter in CSA series ASC header: MrPhoenixProtocol
function val = asc_header(s, key)
val = []; 
fld = 'CSASeriesHeaderInfo';
if ~isfield(s, fld), return; end
if isfield(s.(fld), 'MrPhoenixProtocol')
    str = s.(fld).MrPhoenixProtocol;
elseif isfield(s.(fld), 'MrProtocol') % older version dicom
    str = s.(fld).MrProtocol;
else
    str = char(s.(fld)');
    k0 = strfind(str, '### ASCCONV BEGIN ###');
    k  = strfind(str, '### ASCCONV END ###');
    str = str(k0:k); % avoid key before BEGIN and after END
end
k = strfind(str, [char(10) key]); % start with new line: safer
if isempty(k), return; end
str = strtok(str(k(1):end), char(10)); % the line
[~, str] = strtok(str, '='); % '=' and the vaule
str = strtrim(strtok(str, '=')); % remvoe '=' and space 

if strncmp(str, '""', 2) % str parameter
    val = str(3:end-2);
elseif strncmp(str, '"', 1) % str parameter for version like 2004A
    val = str(2:end-1);
elseif strncmp(str, '0x', 2) % hex parameter, convert to decimal
    val = sscanf(str(3:end), '%x', 1);
else % decimal
    val = str2double(str);
end

%% Subfunction: return matlab decompress command if the file is compressed
function func = compress_func(fname)
func = '';
fid = fopen(fname);
if fid<0, return; end
sig = fread(fid, 2, '*uint8')';
fclose(fid);
if isequal(sig, [80 75]) % zip file
    func = 'unzip';
elseif isequal(sig, [31 139]) % gz, tgz, tar
    func = 'untar';
end
% ! "c:\program Files (x86)\7-Zip\7z.exe" x -y -oF:\tmp\ F:\zip\3047ZL.zip

%% Subfuction: for GUI callbacks
function gui_callback(h, evt, cmd, fh)
hs = guidata(fh);
drawnow;
switch cmd
    case 'do_convert'
        src = get(fh, 'UserData');
        dst = hs.dst.Text;
        if isempty(src) || isempty(dst)
            str = 'Source folder/file(s) and Result folder must be specified';
            errordlg(str, 'Error Dialog');
            return;
        end
        rstFmt = (get(hs.rstFmt, 'Value') - 1) * 2; % 0 or 2
        if get(hs.gzip,  'Value'), rstFmt = rstFmt + 1; end % 1 or 3 
        if get(hs.rst3D, 'Value'), rstFmt = rstFmt + 4; end % 4 to 7
        mocoOpt = get(hs.mocoOpt, 'Value') - 1;
        set(h, 'Enable', 'off', 'string', 'Conversion in progress');
        clnObj = onCleanup(@()set(h, 'Enable', 'on', 'String', 'Start conversion')); 
        drawnow;
        dicm2nii(src, dst, rstFmt, mocoOpt);
        
        % save parameters if last conversion succeed
        pf = getpref('dicm2nii_gui_para');
        pf.rstFmt = get(hs.rstFmt, 'Value');
        pf.rst3D = get(hs.rst3D, 'Value');
        pf.gzip = get(hs.gzip, 'Value');
        pf.mocoOpt = get(hs.mocoOpt, 'Value');
        pf.src = hs.src.Text;
        ind = strfind(pf.src, '{');
        if ~isempty(ind), pf.src = strtrim(pf.src(1:ind-1)); end
        pf.dst = hs.dst.Text;
        setpref('dicm2nii_gui_para', fieldnames(pf), struct2cell(pf));
    case 'dstDialog'
        folder = hs.dst.Text; % current folder
        if ~isdir(folder), folder = hs.src.Text; end
        if ~isdir(folder), folder = fileparts(folder); end
        if ~isdir(folder), folder = pwd; end
        dst = uigetdir(folder, 'Select a folder for result files');
        if isnumeric(dst), return; end
        hs.dst.Text = dst;
    case 'srcDir'
        folder = hs.src.Text; % initial folder
        if ~isdir(folder), folder = fileparts(folder); end
        if ~isdir(folder), folder = pwd; end
        src = uigetdir(folder, 'Select a folder containing convertible files');
        if isnumeric(src), return; end
        hs.src.Text = src;
        set(hs.fig, 'UserData', src);
    case 'srcFile'
        folder = hs.src.Text; % initial folder
        if ~isdir(folder), folder = fileparts(folder); end
        if ~isdir(folder), folder = pwd; end
        ext = '*.zip;*.tgz;*.tar;*.tar.gz;*.dcm;*.PAR;*.HEAD;*.fmr;*.vmr;*.dmr';
        [src, folder] = uigetfile([folder '/' ext], ['Select one or more ' ...
            'convertible files, or a zip file containing convertible files'], ...
            'MultiSelect', 'on');
        if isnumeric(src), return; end
        src = cellstr(src); % in case only 1 file selected
        src = strcat(folder, filesep, src);
        set(fh, 'UserData', src);
        n = numel(src);
        if n > 1 % +1 files
            src = strcat(folder, sprintf(' {%g files}', n));
        end
        hs.src.Text = src;
    case 'set_src'
        str = hs.src.Text;
        ind = strfind(str, '{');
        if ~isempty(ind), return; end % no check with multiple files
        if ~isempty(str) && ~exist(str, 'file')
            val = dir(str);
            folder = fileparts(str);
            if isempty(val)
                val = get(fh, 'UserData');
                if iscellstr(val)
                    val = [fileparts(val{1}), sprintf(' {%g files}', numel(val))];
                end
                if ~isempty(val), hs.src.Text = val; end
                errordlg('Invalid input', 'Error Dialog');
                return;
            end
            str = {val.name};
            str = strcat(folder, filesep, str);
        end
        set(fh, 'UserData', str);
    case 'set_dst'
        str = hs.dst.Text;
        if isempty(str), return; end
        if ~exist(str, 'file') && ~mkdir(str)
            hs.dst.Text = '';
            errordlg(['Invalid folder name ''' str ''''], 'Error Dialog');
            return;
        end
    case 'SPMStyle' % turn off compression
        if get(hs.rst3D, 'Value'), set(hs.gzip, 'Value', 0); end
    case 'about'
        item = get(hs.about, 'Value');
        if item == 1 % about
            str = sprintf(['dicm2nii.m by Xiangrui Li\n\n' ...
                'Feedback to: xiangrui.li@gmail.com\n\n' ...
                'Last updated on 20%s\n'], reviseDate);
            helpdlg(str, 'About dicm2nii')
        elseif item == 2 % license
            fid = fopen([fileparts(which(mfilename)) '/license.txt']);
            if fid<1
                str = 'license.txt file not found';
            else
                str = strtrim(fread(fid, '*char')');
                fclose(fid);
            end
            helpdlg(str, 'License')
        elseif item == 3
            doc dicm2nii;
        elseif item == 4
            checkUpdate(mfilename);
        end
        set(hs.about, 'Value', 1);
    case 'drop_src' % Java drop source
        try
            if strcmp(evt.DropType, 'file')
                n = numel(evt.Data);
                if n == 1
                    hs.src.Text = evt.Data{1};
                    set(hs.fig, 'UserData', evt.Data{1});
                else
                    hs.src.Text = sprintf('%s {%g files}', ...
                        fileparts(evt.Data{1}), n);
                    set(fh, 'UserData', evt.Data);
                end
            else % string
                hs.src.Text = strtrim(evt.Data);
                gui_callback([], [], 'set_src', fh);
            end
        catch me
            errordlg(me.message);
        end
    case 'drop_dst' % Java drop dst
        try
            if strcmp(evt.DropType, 'file')
                nam = evt.Data{1};
                if ~isdir(nam), nam = fileparts(nam); end
                hs.dst.Text = nam;
            else
                hs.dst.Text = strtrim(evt.Data);
                gui_callback([], [], 'set_dst', fh);
            end
        catch me
            errordlg(me.message);
        end
    otherwise
        create_gui;
end

%% Subfuction: create GUI or bring it to front if exists
function create_gui
fh = figure('dicm' * 256.^(0:3)'); % arbitury integer
if strcmp('dicm2nii_fig', get(fh, 'Tag')), return; end

scrSz = get(0, 'ScreenSize');
clr = [1 1 1]*206/256;
clrButton = [1 1 1]*216/256;
cb = @(cmd) {@gui_callback cmd fh}; % callback shortcut
uitxt = @(txt,pos) uicontrol('Style', 'text', 'Position', pos, 'FontSize', 9, ...
    'HorizontalAlignment', 'left', 'String', txt, 'BackgroundColor', clr);

set(fh, 'Toolbar', 'none', 'Menubar', 'none', 'Resize', 'off', 'Color', clr, ...
    'Tag', 'dicm2nii_fig', 'Position', [200 scrSz(4)-500 420 256], ...
    'Name', 'dicm2nii - DICOM to NIfTI Converter', 'NumberTitle', 'off');

uitxt('Browse source', [8 218 88 16]);
uicontrol('Style', 'Pushbutton', 'Position', [98 214 48 24], ...
    'FontSize', 9, 'String', 'Folder', 'Background', clrButton, ...
    'TooltipString', ['Browse source folder (can have subfolders) containing' ...
    ' convertible files'], 'Callback', cb('srcDir'));
uitxt('or', [148 218 20 16]);
uicontrol('Style', 'Pushbutton', 'Position', [166 214 48 24], 'FontSize', 9, ...
    'String', 'File(s)', 'Background', clrButton, 'Callback', cb('srcFile'), ...
    'TooltipString', ['Browse convertible file(s), such as dicom, Philips PAR,' ...
    ' AFNI HEAD, BrainVoyager files, or a zip file containing those files']);
uitxt('or drag&drop source folder/file(s)', [216 218 200 16]);

uitxt('Source folder/files', [8 180 106 16]);
jSrc = javaObjectEDT('javax.swing.JTextField');
hs.src = javacomponent(jSrc, [114 176 294 24], fh);
hs.src.FocusLostCallback = cb('set_src');
% hs.src.ActionPerformedCallback = cb('set_src'); % fire when pressing ENTER
hs.src.ToolTipText = 'Source folder or file';

uicontrol('Style', 'Pushbutton', 'Position', [8 136 104 24], ...
    'FontSize', 9, 'String', 'Result folder', 'Background', clrButton, ...
    'TooltipString', 'Browse result folder', 'Callback', cb('dstDialog'));
jDst = javaObjectEDT('javax.swing.JTextField');
hs.dst = javacomponent(jDst, [114 136 294 24], fh);
hs.dst.FocusLostCallback = cb('set_dst');
hs.dst.ToolTipText = ['Input folder name to save result files, or drag ' ...
    'and drop a folder'];

uitxt('Output format', [8 96 82 16]);
hs.rstFmt = uicontrol('Style', 'popup', 'Background', 'white', ...
    'Value', 1, 'Position', [92 92 92 24], 'String', ' .nii| .hdr/.img', ...
    'TooltipString', 'Choose output file format');

hs.gzip = uicontrol('Style', 'checkbox', 'Position', [220 96 82 18], ...
    'HorizontalAlignment', 'left', 'String', 'Compress', 'FontSize', 9, ...
    'Background', clr, 'TooltipString', 'Compress into .gz files');

hs.rst3D = uicontrol('Style', 'checkbox', 'Position', [330 96 68 18], ...
    'HorizontalAlignment', 'left', 'String', 'SPM 3D', 'FontSize', 9, ...
    'Background', clr, 'Callback', cb('SPMStyle'), ...
    'TooltipString', 'Save one file for each volume (SPM style)');
           
uitxt('MoCoSeries', [12 56 90 16]);
hs.mocoOpt = uicontrol('Style', 'popup', 'Background', 'w', ...
     'Position', [92 52 316 24], 'Value', 2, ...
     'String', {' Convert both original and MoCo series' ...
                ' Convert only original series if both exist' ...
                ' Convert only MoCo series if both exist'}, ...
    'TooltipString', 'Choose the way to deal with SIEMENS MoCo series');

hs.convert = uicontrol('Style', 'pushbutton', 'Position', [104 10 200 30], ...
    'FontSize', 9, 'String', 'Start conversion', ...
    'Background', clrButton, 'Callback', cb('do_convert'), ...
    'TooltipString', 'Dicom source and Result folder needed before start');

hs.about = uicontrol('Style', 'popup', ...
    'String', 'About|License|Help text|Check update', ...
    'Position', [348 14 64 20], 'Callback', cb('about'));
hs.fig = fh;
guidata(fh, hs); % store handles
set(fh, 'HandleVisibility', 'callback'); % protect from command line

try % java_dnd is based on dndcontrol by Maarten van der Seijs
    java_dnd(jSrc, cb('drop_src'));
    java_dnd(jDst, cb('drop_dst'));
catch me
    fprintf(2, '%s\n', me.message);
end

pf = getpref('dicm2nii_gui_para');
if isempty(pf)
    pf = struct('rstFmt', 1, 'rst3D', 0, 'gzip', 1, 'mocoOpt', 2, ...
        'src', pwd, 'dst', pwd, 'save_json', false);
    setpref('dicm2nii_gui_para', fieldnames(pf), struct2cell(pf));
end
fn = fieldnames(pf);
for i = 1:numel(fn)
    tag = fn{i};
    if ~isfield(hs, tag)
        continue;  % avoid error
    elseif strcmp(tag, 'src') || strcmp(tag, 'dst')
        hs.(tag).Text = pf.(tag);
    elseif strcmpi(get(hs.(tag), 'Style'), 'edit')
        set(hs.(tag), 'String', pf.(tag));
    else 
        set(hs.(tag), 'Value', pf.(tag));
    end
end
gui_callback([], [], 'set_src', fh);

%% subfunction: return phase positive and phase axis (1/2) in image reference
function [phPos, iPhase] = phaseDirection(s)
phPos = []; iPhase = [];
fld = 'InPlanePhaseEncodingDirection';
if isfield(s, fld)
    if     strncmpi(s.(fld), 'COL', 3), iPhase = 2; % based on dicm_img(s,0)
    elseif strncmpi(s.(fld), 'ROW', 3), iPhase = 1;
    else errorLog(['Unknown ' fld ' for ' s.NiftiName ': ' s.(fld)]);
    end
end

if strncmpi(s.Manufacturer, 'SIEMENS', 7)
    phPos = csa_header(s, 'PhaseEncodingDirectionPositive'); % image ref
elseif strncmpi(s.Manufacturer, 'GE', 2)
    fld = 'ProtocolDataBlock';
    if isfield(s, fld) && isfield(s.(fld), 'VIEWORDER')
        phPos = s.(fld).VIEWORDER == 1; % 1 == bottom_up
    end
elseif strncmpi(s.Manufacturer, 'Philips', 7)
    if ~isfield(s, 'ImageOrientationPatient'), return; end
    fld = 'MRStackPreparationDirection';
    if ~isfield(s, 'Stack') || ~isfield(s.Stack.Item_1, fld), return; end
    R = reshape(s.ImageOrientationPatient, 3, 2);
    [~, ixy] = max(abs(R)); % like [1 2]
    d = s.Stack.Item_1.(fld)(1); % 2-letter like 'AP'
    if isempty(iPhase) % if no InPlanePhaseEncodingDirection
        iPhase = strfind('RLAPFH', d);
        iPhase = ceil(iPhase/2); % 1/2/3 for RL/AP/FH
        iPhase = find(ixy==iPhase); % now 1 or 2
    end
    if     any(d == 'LPH'), phPos = false; % in dicom ref
    elseif any(d == 'RAF'), phPos = true;
    end
    if R(ixy(iPhase), iPhase)<0, phPos = ~phPos; end % tricky! in image ref
end

%% subfunction: extract useful fields for multiframe dicom
function s = multiFrameFields(s)
pffgs = 'PerFrameFunctionalGroupsSequence';
if any(~isfield(s, {'SharedFunctionalGroupsSequence' pffgs})), return; end

flds = {'EchoTime' 'PixelSpacing' 'SpacingBetweenSlices' 'SliceThickness' ...
        'RepetitionTime' 'FlipAngle' 'RescaleIntercept' 'RescaleSlope' ...
        'ImageOrientationPatient' 'ImagePositionPatient' ...
        'InPlanePhaseEncodingDirection'};
for i = 1:numel(flds)
    if isfield(s, flds{i}), continue; end
    a = MF_val(flds{i}, s, 1);
    if ~isempty(a), s.(flds{i}) = a; end
end

if ~isfield(s, 'EchoTime')
    a = MF_val('EffectiveEchoTime', s, 1);
    if ~isempty(a), s.EchoTime = a;
    elseif isfield(s, 'EchoTimeDisplay'), s.EchoTime = s.EchoTimeDisplay;
    end
end

nFrame = tryGetField(s, 'NumberOfFrames');
if isempty(nFrame)
    a = fieldnames(s.(pffgs));
    nFrame = sscanf(a{end}, 'Item_%g');
end

% check ImageOrientationPatient consistency for 1st and last frame only
fld = 'ImageOrientationPatient';
val = MF_val(fld, s, nFrame);
if ~isempty(val) && isfield(s, fld) && any(abs(val-s.(fld))>1e-4)
    s = []; % silently ignore it
    return; % inconsistent orientation, remove the field
end

flds = {'DiffusionDirectionality' 'ImagePositionPatient' ...
        'ComplexImageComponent' 'RescaleIntercept' 'RescaleSlope'};
for i = 1:numel(flds) % For last frame
    a = MF_val(flds{i}, s, nFrame);
    if ~isempty(a), s.LastFile.(flds{i}) = a; end
end

fld = 'ImagePositionPatient';
val = MF_val(fld, s, 2); % 2nd frame
if isempty(val), return; end
if isfield(s, fld) && all(abs(s.(fld)-val)<1e-4)
    s.Dim3IsVolume = true;
end

if ~isfield(s, 'LocationsInAcquisition') % use all frames -- slow
    dict = dicm_dict(s.Manufacturer, MF_val(fld));
    s2 = dicm_hdr(s.Filename, dict, 'all');
    ipp = nan(nFrame, 3);
    for i = 1:nFrame, ipp(i,:) = MF_val(fld, s2, i); end
    [err, s.LocationsInAcquisition, sliceN] = checkImagePostion(ipp);
    if ~isempty(err)
        errorLog([err ' for "' s.Filename '". Series skipped.']);
        s = []; return; % skip
    end
end

% Lastly check whether weird slice ordering: only seen in PAR though
nSL = double(s.LocationsInAcquisition);
i = MF_val('SliceNumberMR', s, 1); % Philips
if ~isempty(i) 
    i(2) = MF_val('SliceNumberMR', s, nFrame);
    if isequal(i, [1 nSL]) || isequal(i, [nSL 1]), return; end % not 100% safe
end

if tryGetField(s, 'Dim3IsVolume', false)
    iFrame = 1:(nFrame/nSL):nFrame;
else
    iFrame = 1:nSL;
end
if ~exist('sliceN', 'var') % save time if done by checkImagePostion
    dict = dicm_dict(s.Manufacturer, MF_val(fld));
    s2 = dicm_hdr(s.Filename, dict, iFrame);
    n = numel(iFrame);
    ipp = nan(n, 3);
    for i = 1:n, ipp(i,:) = MF_val(fld, s2, iFrame(i)); end
    [~, iSL] = max(var(ipp));
    [~, sliceN] = sort(ipp(:,iSL));
end
if any(diff(sliceN, 2)>0) % just avoid accident
    s.SliceNumber = sliceN; % will be used to re-order img
    s.(fld) = MF_val(fld, s2, iFrame(sliceN==1));
    s.LastFile.(fld) = MF_val(fld, s2, iFrame(sliceN==nSL));
end

%% subfunction: return value from Shared or PerFrame FunctionalGroupsSequence
function val = MF_val(fld, s, iFrame)
switch fld
    case 'EffectiveEchoTime'
        sq = 'MREchoSequence';
    case {'DiffusionDirectionality' 'B_value' 'DiffusionGradientDirection' ...
            'DiffusionGradientDirectionSequence'}
        sq = 'MRDiffusionSequence';
    case 'ComplexImageComponent'
        sq = 'MRImageFrameTypeSequence';
    case {'DimensionIndexValues' 'InStackPositionNumber' 'TemporalPositionIndex'}
        sq = 'FrameContentSequence';
    case {'RepetitionTime' 'FlipAngle'}
        sq = 'MRTimingAndRelatedParametersSequence';
    case 'ImagePositionPatient'
        sq = 'PlanePositionSequence';
    case 'ImageOrientationPatient'
        sq = 'PlaneOrientationSequence';
    case {'PixelSpacing' 'SpacingBetweenSlices' 'SliceThickness'}
        sq = 'PixelMeasuresSequence';
    case {'RescaleIntercept' 'RescaleSlope' 'RescaleType'}
        sq = 'PixelValueTransformationSequence';
    case {'InPlanePhaseEncodingDirection' 'MRAcquisitionFrequencyEncodingSteps' ...
            'MRAcquisitionPhaseEncodingStepsInPlane'}
        sq = 'MRFOVGeometrySequence';
    case {'SliceNumberMR' 'EchoTime'}
        sq = 'PrivatePerFrameSq'; % Philips
    otherwise
        error('Sequence for %s not set.', fld);
end
pffgs = 'PerFrameFunctionalGroupsSequence';
if nargin<2, val = {'SharedFunctionalGroupsSequence' pffgs sq fld}; return; end
try 
    val = s.SharedFunctionalGroupsSequence.Item_1.(sq).Item_1.(fld);
catch
    try
        val = s.(pffgs).(sprintf('Item_%g', iFrame)).(sq).Item_1.(fld);
    catch
        val = [];
    end
end

%% subfunction: split nii into mag and phase for Philips single file
function [nii, niiP] = split_philips_phase(nii, s)
niiP = [];
if ~strcmp(tryGetField(s, 'ComplexImageComponent', ''), 'MIXED') ... % multiframe
        && (~isfield(s, 'VolumeIsPhase') || ... 
            all(s.VolumeIsPhase) || ~any(s.VolumeIsPhase)) % not MIXED
    return;
end

if ~isfield(s, 'VolumeIsPhase') % PAR file and single-frame file have this
    dim = nii.hdr.dim(4:5);
    if tryGetField(s, 'Dim3IsVolume'), iFrames = 1:dim(2);
    else iFrames = 1:dim(1):dim(1)*dim(2);
    end
    flds = {'PerFrameFunctionalGroupsSequence' ...
        'MRImageFrameTypeSequence' 'ComplexImageComponent'};
    if dim(2) == 2 % 2 volumes, no need to re-read ComplexImageComponent
        iFrames(2) = dim(1)*dim(2); % use last frame
        s1.(flds{1}) = s.(flds{1});        
    else
        dict = dicm_dict(s.Manufacturer, flds);
        s1 = dicm_hdr(s.Filename, dict, iFrames);
    end
    s.VolumeIsPhase = false(dim(2), 1);
    for i = 1:dim(2)
        Item = sprintf('Item_%g', iFrames(i));
        foo = s1.(flds{1}).(Item).(flds{2}).Item_1.(flds{3});
        s.VolumeIsPhase(i) = strcmp(foo, 'PHASE');
    end
end

niiP = nii;
niiP.img = nii.img(:,:,:,s.VolumeIsPhase);
n = sum(s.VolumeIsPhase);
niiP.hdr.dim(5) = n; % may be 1 always
niiP.hdr.dim(1) = 3 + (n>1);

nii.img(:,:,:,s.VolumeIsPhase) = []; % now only mag
n = sum(~s.VolumeIsPhase);
nii.hdr.dim(5) = n; % may be 1 always
nii.hdr.dim(1) = 3 + (n>1);

% undo scale for 2nd set img if it was applied in set_nii_header
if (nii.hdr.scl_inter==0) && (nii.hdr.scl_slope==1) && ...
        (tryGetfield(s, 'RescaleIntercept') ~=0 ) && ...
        (tryGetfield(s, 'RescaleSlope') ~= 1)
    if s.VolumeIsPhase(1)
        nii.img = (nii.img - s.RescaleIntercept) / s.RescaleSlope;
        nii.hdr.scl_inter = s.LastFile.RescaleIntercept;
        nii.hdr.scl_slope = s.LastFile.RescaleSlope;
    else
        niiP.img = (niiP.img - s.RescaleIntercept) / s.RescaleSlope;
        niiP.hdr.scl_inter = s.LastFile.RescaleIntercept;
        niiP.hdr.scl_slope = s.LastFile.RescaleSlope;
    end
end

%% Write error info to a file in case user ignores Command Window output
function firstTime = errorLog(errInfo, folder)
persistent dataFolder;
if nargin>1, firstTime = isempty(dataFolder); dataFolder = folder; end
if isempty(errInfo), return; end
fprintf(2, ' %s\n', errInfo); % red text in Command Window
fid = fopen([dataFolder 'dicm2nii_warningMsg.txt'], 'a');
fseek(fid, 0, -1); 
fprintf(fid, '%s\n', errInfo);
fclose(fid);

%% Get the last date string in history
function dStr = reviseDate(mfile)
if nargin<1, mfile = mfilename; end
dStr = '151117?';
fid = fopen(which(mfile));
if fid<1, return; end
str = fread(fid, '*char')';
fclose(fid);
ind = strfind(str, '% End of history. Don''t edit this line!');
if isempty(ind), return; end
ind = ind(1);
ret = str(ind-1); % new line char: \r or \n
str = str(max(1, ind-500):ind+2); % go back several lines
ind = strfind(str, [ret '% ']); % new line with % and space
for i = 1:numel(ind)-1
    ln = str(ind(i)+3 : ind(i+1)-1);
    if numel(ln)>5 && all(isstrprop(ln(1:6), 'digit'))
        dStr = ln(1:6);
    end
end

%% Get position info from Siemens CSA header
% The only case this is useful for now is for DTI_ColFA, where Siemens omit 
% ImageOrientationPatient, ImagePositionPatient, PixelSpacing.
% This shows how to get info from Siemens CSA header.
function s = csa2pos(s, nSL)
if ~isfield(s, 'CSASeriesHeaderInfo'); return; end
if ~isfield(s, 'PixelSpacing')
    a = asc_header(s, 'sSliceArray.asSlice[0].dReadoutFOV');
    a = a ./ asc_header(s, 'sKSpace.lBaseResolution');
    interp = asc_header(s, 'sKSpace.uc2DInterpolation');
    if interp, a = a ./ 2; end
    if ~isempty(a), s.PixelSpacing =  a * [1 1]'; end
end

revNum = ~isempty(asc_header(s, 'sSliceArray.ucImageNumb'));
isMos = ~isempty(csa_header(s, 'NumberOfImagesInMosaic'));
ori = {'Sag' 'Cor' 'Tra'}; % 1/2/3
if ~isfield(s, 'ImageOrientationPatient')
    R = zeros(3);
    for i = 1:3
        a = asc_header(s, ['sSliceArray.asSlice[0].sNormal.d' ori{i}]);
        if ~isempty(a), R(i,3) = a; end
    end
    
    % set SliceNormalVector for mosaic if it is missing
    if isMos && ~isfield(s.CSAImageHeaderInfo, 'SliceNormalVector')
        sNormal = R(:,3);
        if revNum, sNormal = -sNormal; end
        s.CSAImageHeaderInfo.SliceNormalVector = sNormal;
    end

    [~, iSL] = max(abs(R(:,3)));
    if iSL==3
        R(:,2) = [0 R(3,3) -R(2,3)] / sqrt(sum(R(2:3,3).^2));
        R(:,1) = cross(R(:,2), R(:,3));
    elseif iSL==2
        R(:,1) = [R(2,3) -R(1,3) 0] / sqrt(sum(R(1:2,3).^2));
        R(:,2) = cross(R(:,3), R(:,1));
    elseif iSL==1
        R(:,1) = [-R(2,3) R(1,3) 0] / sqrt(sum(R(1:2,3).^2));
        R(:,2) = cross(R(:,1), R(:,3));
    end

    rot = asc_header(s, 'sSliceArray.asSlice[0].dInPlaneRot');
    if isempty(rot), rot = 0; end
    rot = rot - round(rot/pi*2)*pi/2; % -45 to 45 deg, is this right?
    ca = cos(rot); sa = sin(rot);
    R = R * [ca sa 0; -sa ca 0; 0 0 1];
    s.ImageOrientationPatient = R(1:6)';
end

if ~isfield(s, 'ImagePositionPatient')
    pos = zeros(3,2);
    sl = [0 nSL-1];
    for j = 1:2
        key = sprintf('sSliceArray.asSlice[%g].sPosition.d', sl(j));
        for i = 1:3
            a = asc_header(s, [key ori{i}]);
            if ~isempty(a), pos(i,j) = a; end
        end
    end
    
    R = reshape(s.ImageOrientationPatient, 3, 2);
    R = R * diag(s.PixelSpacing);
    dim = double([s.Columns s.Rows]');
    if all(pos(:,2) == 0) % Mprage: dThickness and sPosition are for volume
        sNormal = zeros(3,1);
        for i = 1:3
            a = asc_header(s, ['sSliceArray.asSlice[0].sNormal.d' ori{i}]);
            if ~isempty(a), sNormal(i) = a; end
        end
        v3 = asc_header(s, 'sSliceArray.asSlice[0].dThickness');
        R = [R sNormal*v3/nSL];
        x = [-dim/2*[1 1]; (1-nSL)/2*[1 -1]];
        pos = R * x + pos(:,1) * [1 1];
    else % likely mosaic
        pos = pos - R * dim/2 * [1 1];
    end
    if revNum, pos = pos(:, [2 1]); end
    if isMos, pos(:,2) = pos(:,1); end % set LastFile same as first for mosaic
    s.ImagePositionPatient = pos(:,1);
    s.LastFile.ImagePositionPatient = pos(:,2);
end

%% subfuction: check whether parpool is available
% Return true if it is already open, or open it if available
function doParal = useParTool(toOpen)
doParal = usejava('jvm');
if ~doParal, return; end

if isempty(which('parpool')) % for early matlab versions
    try 
        if matlabpool('size')<1 %#ok<*DPOOL>
            try
                if toOpen, matlabpool; 
                else doParal = false;
                end
            catch me
                fprintf(2, '%s\n', me.message);
                doParal = false;
            end
        end
    catch
        doParal = false;
    end
    return;
end

% Following for later matlab with parpool
try 
    if isempty(gcp('nocreate'))
        try
            if toOpen, parpool; 
            else doParal = false;
            end
        catch me
            fprintf(2, '%s\n', me.message);
            doParal = false;
        end
    end
catch
    doParal = false;
end

%% subfunction: return nii ext from dicom struct
% The txt extension is in format of: name = parameter;
% Each parameter ends with [';' char(0 10)]. Examples:
% Modality = 'MR'; % str parameter enclosed in single quotation marks
% FlipAngle = 72; % single numeric value, brackets may be used, but optional
% SliceTiming = [0.5 0.1 ... ]; % vector parameter enclosed in brackets
% bvec = [0 -0 0 
% -0.25444411 0.52460458 -0.81243353 
% ...
% 0.9836791 0.17571079 0.038744]; % matrix rows separated by char(10) and/or ';'
function ext = set_nii_ext(s)
flds = { % fields to put into nifti ext
  'NiftiCreator' 'SeriesNumber' 'SeriesDescription' 'ImageType' 'Modality' ...
  'AcquisitionDateTime' 'bval' 'bvec' 'ReadoutSeconds' 'SliceTiming' ...
  'UnwarpDirection' 'EffectiveEPIEchoSpacing' 'EchoTime' 'deltaTE' ...
  'PatientName' 'PatientSex' 'PatientAge' 'PatientSize' 'PatientWeight' ...
  'PatientPosition' 'SliceThickness' 'FlipAngle' 'RBMoCoTrans' 'RBMoCoRot' ...
  'Manufacturer' 'SoftwareVersion' 'MRAcquisitionType' 'InstitutionName' ...
  'ScanningSequence' 'SequenceVariant' 'ScanOptions' 'SequenceName'};

ext.ecode = 6; % text ext
ext.edata = '';
for i = 1:numel(flds)
    val = tryGetField(s, flds{i});
    if isempty(val)
        continue;
    elseif ischar(val)
        str = sprintf('''%s''', val);
    elseif numel(val) == 1 % single numeric
        str = sprintf('%.8g', val);
    elseif isvector(val) % row or column
        str = sprintf('%.8g ', val);
        str = sprintf('[%s]', str(1:end-1)); % drop last space
    elseif isnumeric(val) % matrix, like DTI bvec
        fmt = repmat('%.8g ', 1, size(val, 2));
        str = sprintf([fmt char(10)], val');
        str = sprintf('[%s]', str(1:end-2)); % drop last space and char(10)
    else % in case of struct etc, skip
        continue;
    end
    ext.edata = [ext.edata flds{i} ' = ' str ';' char([0 10])];
end

% % Matlab ext: ecode = 40
% fname = [tempname '.mat'];
% save(fname, '-struct', 's', '-v7'); % field as variable
% fid = fopen(fname);
% b = fread(fid, inf, '*uint8'); % data bytes
% fclose(fid);
% delete(fname);
% 
% % first 4 bytes (int32) encode real data length, endian-dependent
% if exist('ext', 'var'), n = numel(ext)+1; else n = 1; end
% ext(n).edata = [typecast(int32(numel(b)), 'uint8')'; b];
% ext(n).ecode = 40; % Matlab
 
% % Dicom ext: ecode = 2
% if isfield(s, 'SOPInstanceUID') % make sure it is dicom
%     if exist('ext', 'var'), n = numel(ext)+1; else n = 1; end
%     ext(n).ecode = 2; % dicom
%     fid = fopen(s.Filename);
%     ext(n).edata = fread(fid, s.PixelData.Start, '*uint8');
%     fclose(fid);
% end

%% Fix some broken multiband sliceTiming. Hope this won't be needed in future.
% Odd number of nShot is fine, but some even nShot may have problem.
% This gives inconsistent result to the following example in PDF doc, but I
% would rather believe the example is wrong:
% nSL=20; mb=2; nShot=nSL/mb; % inc=3
% In PDF: 0,10 - 3,13 - 6,16 - 9,19 - 1,11 - 4,14 - 7,17 - 2,12 - 5,15 - 8,18
% result: 0,10 - 3,13 - 6,16 - 9,19 - 2,12 - 5,15 - 8,18 - 1,11 - 4,14 - 7,17
function t = mb_slicetiming(s, TA)
dict = dicm_dict(s.Manufacturer, 'MosaicRefAcqTimes');
s2 = dicm_hdr(s.LastFile.Filename, dict);
t = s2.MosaicRefAcqTimes; % try last volume first

% No SL acc factor. Not even multiband flag. This is UGLY
nSL = double(s.LocationsInAcquisition);
mb = ceil((max(t) - min(t)) ./ TA); % based on the wrong timing pattern
if isempty(mb) || mb==1 || mod(nSL,mb)>0, return; end % not MB or wrong mb guess

nShot = nSL / mb;
ucMode = asc_header(s, 'sSliceArray.ucMode'); % 1/2/4: Asc/Desc/Inter
if isempty(ucMode), return; end
t = linspace(0, TA, nShot+1)'; t(end) = [];
t = repmat(t, mb, 1); % ascending, ucMode==1
if ucMode == 2 % descending
    t = t(nSL:-1:1);
elseif ucMode == 4 % interleaved
    if mod(nShot,2) % odd number of shots
        inc = 2;
    else
        inc = nShot / 2 - 1;
        if mod(inc,2) == 0, inc = inc - 1; end
        errorLog([s.NiftiName ': multiband interleaved order, even' ...
            ' number of shots.\nThe SliceTiming information may be wrong.']);
    end
    
% % This gives the result in the PDF doc for example above
%     ind = nan(nShot, 1); j = 0; i = 1; k = 0;
%     while 1
%         ind(i) = j + k*inc;
%         if ind(i)+(mb-1)*nShot > nSL-1
%             j = j + 1; k = 0;
%         else
%             i = i + 1; k = k + 1;
%         end
%         if i>nShot, break; end
%     end
    
    ind = mod((0:nShot-1)*inc, nShot)'; % my guess based on chris data
    
    if nShot==6, ind = [0 2 4 1 5 3]'; end % special case
    ind = bsxfun(@plus, ind*ones(1,mb), (0:mb-1)*nShot);
    ind = ind + 1;

    t = zeros(nSL, 1);
    for i = 1:nShot
        t(ind(i,:)) = (i-1) / nShot;
    end
    t = t * TA;
end
if csa_header(s, 'ProtocolSliceNumber')>0, t = t(nSL:-1:1); end % rev-num

%% subfunction: check ImagePostionPatient from multiple slices/volumes
function [err, nSL, sliceN, isTZ] = checkImagePostion(ipp)
v = var(ipp); % ipp rows for slices
[~, iSL] = max(v);
ipp1 = ipp(:, v>1e-6); % remove constant columns which give corr 0 or nan
ipp = ipp(:,iSL); % ipp at SL dimension
del = mean(diff(sort(ipp))) * 0.02; % allow 2% error: have seen error of 0.1/7
nSL = sum(diff(sort(ipp)) > del) + 1;
sliceN = []; err = '';
nVol = numel(ipp) / nSL;
if mod(nVol,1), err = 'Missing file(s) detected'; return; end
if nSL<2, isTZ = false; return; end

isTZ = nVol>1 && all(abs(diff(ipp(1:nVol))) < del);
if isTZ % Philips XYTZ
    a = ipp(1:nVol:end);
    b = reshape(ipp, nVol, nSL);
else
    a = ipp(1:nSL);
    b = reshape(ipp, nSL, nVol)';
end
[~, sliceN] = sort(a); % no descend since wrong for PAR/singleDicom
if any(abs(diff(a,2))>del), err = 'Inconsistent slice spacing'; return; end
if nVol>1
    b = diff(b);
    if any(abs(b(:))>del), err = 'Irregular slice order'; return; end
end

if size(ipp1,2)<2, return; end
c = cov(ipp1);
d = sqrt(diag(c));
c = c ./ (d*d'); % corr(ipp1') should be 1 or -1 after removing constant
c = c(triu(true(size(c)), 1)); % value above diagonal
c = abs(abs(c) - 1);
if ~isempty(c) && any(c>0.02), err = 'Irregular ImagePosition detected'; end

%% Save JSON file, proposed by Chris G
function save_json(s, fname)
global dicm2nii_SAVE_JSON; % remove this in the future
persistent save_json;
if isempty(save_json)
    if ~isempty(dicm2nii_SAVE_JSON)
        save_json = logical(dicm2nii_SAVE_JSON(1));
        setpref('dicm2nii_gui_para', 'save_json', save_json);
    else
        try 
            save_json = getpref('dicm2nii_gui_para', 'save_json');
        catch
            save_json = false; % default
            setpref('dicm2nii_gui_para', 'save_json', save_json);
        end
    end
end
if ~save_json, return; end
   
flds = {
  'NiftiCreator' 'SeriesNumber' 'SeriesDescription' 'ImageType' 'Modality' ...
  'AcquisitionDateTime' 'bval' 'bvec' 'ReadoutSeconds' 'SliceTiming' 'RepetitionTime' ...
  'UnwarpDirection' 'EffectiveEPIEchoSpacing' 'EchoTime' 'SecondEchoTime' ...
  'PatientName' 'PatientSex' 'PatientAge' 'PatientSize' 'PatientWeight' ...
  'PatientPosition' 'SliceThickness' 'FlipAngle' 'RBMoCoTrans' 'RBMoCoRot' ...
  'Manufacturer' 'SoftwareVersion' 'MRAcquisitionType' 'InstitutionName' ...
  'ScanningSequence' 'SequenceVariant' 'ScanOptions' 'SequenceName'};

nFields = numel(flds);
fid = fopen([fname '.json'], 'w'); % overwrite silently if exist
fprintf(fid, '{\n');
for i = 1:nFields
    nam = flds{i};
    if ~isfield(s, nam), continue; end
    val = s.(nam);
    
    % this if-elseif block takes care of name/val change
    if strcmp(nam, 'RepetitionTime')
        val = val / 1000; % in sec now
    elseif strcmp(nam, 'UnwarpDirection')
        nam = 'PhaseEncodingDirection';
        if val(1) == '-' || val(1) == '?', val = val([2 1]); end
    elseif strcmp(nam, 'EffectiveEPIEchoSpacing')
        nam = 'EffectiveEchoSpacing';
        val = val / 1000;
    elseif strcmp(nam, 'ReadoutSeconds')
        nam = 'TotalReadoutTime';
    elseif strcmp(nam, 'SliceTiming')
        val = (0.5 - val) * s.RepetitionTime / 1000; % FSL style to secs
    elseif strcmp(nam, 'SecondEchoTime')
        nam = 'EchoTime2';
        val = val / 1000;
    elseif strcmp(nam, 'EchoTime')
        % if there are two TEs we are dealing with a fieldmap
        if isfield(s, 'SecondEchoTime')
            nam = 'EchoTime1';
        end
        val = val / 1000;
    elseif strcmp(nam, 'bval')
        nam = 'DiffusionBValue';
    elseif strcmp(nam, 'bvec')
        nam = 'DiffusionGradientOrientation';
    end
    
    fprintf(fid, '\t"%s": ', nam);
    if isempty(val)
        fprintf(fid, 'null,\n');
    elseif ischar(val)
        fprintf(fid, '"%s",\n', strrep(val, '\', '\\'));
    elseif numel(val) == 1 % scalar numeric
        fprintf(fid, '%.8g,\n', val);
    elseif isvector(val) % row or column
        fprintf(fid, '[\n');
        fprintf(fid, '\t\t%.8g,\n', val);
        fseek(fid, -2, 'cof');
        fprintf(fid, '\t],\n');
    elseif isnumeric(val) % matrix
        fprintf(fid, '[\n');
        fmt = repmat('%.8g ', 1, size(val, 2));
        fprintf(fid, ['\t\t[' fmt(1:end-1) '],\n'], val');
        fseek(fid, -2, 'cof');
        fprintf(fid, '\n\t],\n');
    else % in case of struct etc, skip
        fprintf(2, 'Unknown type of data for %s.\n', nam);
        fprintf(fid, 'null,\n');
    end
end
fseek(fid, -2, 'cof'); % remove trailing comma and \n
fprintf(fid, '\n}\n');
fclose(fid);

%% Check for newer version for 42997 at Matlab Central
% Simplified from checkVersion in findjobj.m by Yair Altman
function checkUpdate(mfile)
webUrl = 'http://www.mathworks.com/matlabcentral/fileexchange/42997';
try
    str = urlread(webUrl);
    ind = strfind(str, '>Updates<');
    str = str(ind:end);
    ind = strfind(str, 'class="date">');
    if isempty(ind), error('Date info not found'); end
catch me
    errordlg(me.message, 'Web access error');
    return;
end

try
    i0 = ind(end)+27;
    i1 = i0 + strfind(str(i0:i0+999), '<td>');
    i2 = i0 + strfind(str(i0:i0+999), '</td>');
    latestStr = str(i1(1)+3 : i2(1)-2); % use date as version
    latestNum = datenum(latestStr, 'yyyy.mm.dd');
catch
    latestStr = str(ind(end)+13:ind(end)+23); % website recorded date
    latestNum = datenum(latestStr, 'dd mmm yyyy')-2; % allow 2-day off
end

d = {reviseDate('nii_viewer') reviseDate('nii_tool') reviseDate('dicm2nii')};
d = sort(d);
myFileDate = datenum(d{end}, 'yymmdd');

if myFileDate >= latestNum
    msgbox([mfile ' and the package are up to date.'], 'Check update');
    return;
end

msg = ['A newer version (' latestStr ') is available on the ' ...
       'MathWorks File Exchange. Update to the new version?'];
answer = questdlg(msg, ['Update ' mfile], 'Yes', 'Later', 'Yes');
if ~strcmp(answer, 'Yes'), return; end

fileUrl = [webUrl '?controller=file_infos&download=true'];
pth = fileparts(which(mfile));
zipFileName = fullfile(pth, 'dicm2nii.zip');
try
    urlwrite(fileUrl, zipFileName);
    unzip(zipFileName, pth);
catch me
    errordlg(['Error in updating: ' me.message], mfile);
    return;
end
rehash;
warndlg(['Package updated successfully. Please restart ' mfile ', otherwise ' ...
         'it may give error.'], 'Check update');
%%
