function varargout = dicm2nii(src, niiFolder, fmt)
% Convert dicom and more into nii or img/hdr files. 
% 
% DICM2NII(dcmSource, niiFolder, outFormat)
% 
% The input arguments are all optional:
%  1. source file or folder. It can be a zip or tgz file, a folder containing
%     dicom files, or other convertible files. It can also contain wildcards
%     like 'run1_*' for all files start with 'run1_'.
%  2. folder to save result files.
%  3. output file format:
%      0 or '.nii'           for single nii uncompressed.
%      1 or '.nii.gz'        for single nii compressed (default).
%      2 or '.hdr'           for hdr/img pair uncompressed.
%      3 or '.hdr.gz'        for hdr/img pair compressed.
%      4 or '.nii 3D'        for 3D nii uncompressed (SPM12).
%      5 or '.nii.gz 3D'     for 3D nii compressed.
%      6 or '.hdr 3D'        for 3D hdr/img pair uncompressed (SPM8).
%      7 or '.hdr.gz 3D'     for 3D hdr/img pair compressed.
%      'bids'                for bids data structure (http://bids.neuroimaging.io/)
%
% Typical examples:
%  DICM2NII; % bring up user interface if there is no input argument
%  DICM2NII('D:/myProj/zip/subj1.zip', 'D:/myProj/subj1/data'); % zip file
%  DICM2NII('D:/myProj/subj1/dicom/', 'D:/myProj/subj1/data'); % folder
% 
% Less useful examples:
%  DICM2NII('D:/myProj/dicom/', 'D:/myProj/subj2/data', 'nii'); % no gz compress
%  DICM2NII('D:/myProj/dicom/run2*', 'D:/myProj/subj/data'); % convert run2 only
%  DICM2NII('D:/dicom/', 'D:/data', '3D.nii'); % SPM style files
% 
% If there is no input, or any of the first two input is empty, the graphic user
% interface will appear.
% 
% If the first input is a zip/tgz file, such as those downloaded from a dicom
% server, DICM2NII will extract files into a temp folder, create NIfTI files
% into the data folder, and then delete the temp folder. For this reason, it is
% better to keep the compressed file as backup.
% 
% If a folder is the data source, DICM2NII will convert all files in the folder
% and its subfolders (there is no need to sort files for different series).
% 
% The output file names adopt SeriesDescription or ProtocolName of each series
% used on scanner console. If both original and MoCo series are present, '_MoCo'
% will be appended for MoCo series. For phase image, such as those from field
% map, '_phase' will be appended to the name. If multiple subjects data are
% mixed (highly discouraged), subject name will be in file name. In case of name
% conflict, SeriesNumber, such as '_s005', will be appended to make file names
% unique. It is suggested to use short, descriptive and distinct
% SeriesDescription on the scanner console.
% 
% For SPM 3D files, the file names will have volume index in format of '_00001'
% appended to above name.
% 
% Please note that, if a file in the middle of a series is missing, the series
% will normally be skipped without converting, and a warning message in red text
% will be shown in Command Window. The message will also be saved into a text
% file under the data folder.
% 
% A Matlab data file, dcmHeaders.mat, is always saved into the data folder. This
% file contains dicom header from the first file for created series and some
% information from last file in field LastFile. Some extra information is also
% saved into this file. For MoCo series, motion parameters (RBMoCoTrans and
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
%  load('dcmHeaders.mat'); % or drag and drop the MAT file into Command Window
%  s = h.myFuncSeries; % field name is the same as nii file name
%  spm_ms = (0.5 - s.SliceTiming) * s.RepetitionTime;
%  [~, spm_order] = sort(-s.SliceTiming);
% 
% Some information, such as TE, phase encoding direction and effective dwell
% time, are stored in descrip of nii header. These are useful for fieldmap B0
% unwarp correction. Acquisition start time and date are also stored, and this
% may be useful if one wants to align the functional data to some physiological
% recording, like pulse, respiration or ECG.
% 
% If there is DTI series, bval and bvec files will be generated for FSL etc.
% bval and bvec are also saved in the dcmHeaders.mat file.
% 
% Starting from 20150514, the converter stores some useful information in NIfTI
% text extension (ecode=6). nii_tool can decode these information easily:
%  ext = nii_tool('ext', 'myNiftiFile.nii'); % read NIfTI extension
% ext.edata_decoded contains all above mentioned information, and more. The
% included nii_viewer can show the extension by Window->Show NIfTI ext.
% 
% Several preference can be set from dicm2nii GUI. The preference change will
% take effect until it is changed next time. 
% 
% One of preference is to save a .json file for each converted NIfTI. For more
% information about the purpose of json file, check
%  http://bids.neuroimaging.io/ 
% 
% By default, the converter will use parallel pool for dicom header reading if
% there are +2000 files. User can turn this off from GUI.
% 
% By default, the PatientName is stored in NIfTI hdr and ext. This can be turned
% off from GUI.
% 
% Please note that some information, such as the slice order information, phase
% encoding direction and DTI bvec are in image reference, rather than NIfTI
% coordinate system. This is because most analysis packages require information
% in image space. For this reason, in case the image in a NIfTI file is flipped
% or re-oriented, these information may not be correct anymore.
% 
% Please report any bug to xiangrui.li@gmail.com or at
% http://www.mathworks.com/matlabcentral/fileexchange/42997
% 
% To cite the work and for more detail about the conversion, check the paper at
% http://www.sciencedirect.com/science/article/pii/S0165027016300073
% 
% See also NII_VIEWER, NII_MOCO, NII_STC

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
% 130912 Use lDelayTimeInTR for slice_dur, possibly useful for old data.
% 130916 Store B_matrix for DTI image, if exists.
% 130919 Work for GE and Philips dicom at Chris R website.
% 130922 Remove dependence on normc from nnet toolbox (thank Zhiwei);
% 130923 Work for Philips PAR/REC pair files.
% 130926 Take care of non-mosaic DTI for Siemens (img/bval/bvec);
% 130930 Use verify_slice_dir subfun to get slice_dir even for a single file.
% 131001 dicm_hdr can deal with VR of SQ. This slows down it a little.
% 131002 Avoid fullfile for cellstr input (not supported in old matlab).
% 131006 Tweak dicm_hdr for multiframe dicom (some bug fixes);
%        First working version for multiframe (tested with Philips dicom).
% 131009 Put dicm_hdr, dicm_img, dicm_dict outside this file;
%        dicm_hdr can read implicit VR, and is faster with single fread;
%        Fix problem in gzipOS when folder name contains space.
% 131020 Make TR & ProtocolName non-mandatory; Set cal_min & cal_max.
% 131021 Implement conversion for AFNI HEAD/BRIK.
% 131024 Bug fix for dealing with current folder as src folder.
% 131029 Bug fix: Siemens, 2D, non-mosaic, rev-num slices were flipped.
% 131105 DTI parameters: field names more consistent across vendors; 
%        Read DTI flds in save_dti_para for GE/Philips (make others faster); 
%        Convert Philips bvec from deg into vector (need to be verified).
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
%        in csa_header(), convert DTI parameters to correct type. 
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
% 140513 change stored phase direction to image reference for FSL unwarp;
%        Simplify code for dim_info.
% 140516 Switch back to ProtocolName for SIEMENS to take care of MOCO series;
%        Detect Philips XYTZ (for multi files) during dicom check; 
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
% 150119 Add phase img detection for Philips.
% 150120 No fieldmap file skip by EchoTime: keep all data by using EchoNumber.
% 150209 Add more output format for SPM style: 3D output;
%        GUI includes SPM 3D, separates GZ option. 
% 150211 No missing file check for all vendors, relying on ImagePosition check;
%        csa_header() relies on dicm_hdr decoding (avoid error on old data);
%        Deal with dim3-RGB and dim4-frames due to dicm_img.m update.
% 150222 Remove useless, mis-used TriggerTime for partial hdr; also B_matrix.
% 150302 No hardcoded sign change for DTI bvec, except for GE;
%        set_nii_hdr: do flip only once after permute;
% 150303 Bug fix for phPos: result was right by lucky mistake;
%        Progress shows nii dim, more informative than number of files.
% 150305 Replace null with cross: null gives inconsistent signs;
%        Use SPM method for xform: account for shear; no qform setting if shear.
% 150306 GE: fully sort slices by loc to ease bvec sign (test data needed);
%        bvec sign simplified by above sort & corrected R for Philips/Siemens.
% 150309 GUI: added the little popup for 'about/license'.  
% 150323 Siemens non-mosaic: timing from ucMode, AcquisitionTime(disabled).   
% 150324 mandatory flds reduced to 5; get info by asc_header if possible;
% 150325 Use SeriesInstanceUID to take care of multiple Study and PatientName; 
%        Remove 5th input (subj); GUI updated; subjName in file name if needed;
%        Deal with MoCo series by output file names;
%        Convert GLM and DTI junk too; no Manufacturer check in advance.
% 150405 Implement BrainVoyager dmr/fmr/vmr conversion; GUI updated accordingly. 
% 150413 InstanceNumber is not mandatory (now total 4);
%        Check missing files for non-DTI mosaic by InstanceNumber.
% 150418 phaseDirection: bug fix for Philips, simplify for others.
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
% 150928 checkImagePosition: skip most irregular spacing.
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
% 160229 flip now makes det<0, instead negative 1st axis (cor slice affected).
% 160304 undo some changes on 140808 so it works for syngo 2004 phase masaic.
% 160309 nMosaic(): use CSAHeader to detect above unlabeled mosaic.
% 160324 nMosaic(): unsecure fix for dicom without CSA header.
% 160329 GUI: add link to the JNM paper about dicom to nifti conversion.
% 160330 nMosaic(): take care of case of uc2DInterpolation.
% 160404 Bug fix: put back nFile<2 continue for series check.
% 160405 Remove 4th input arg MoCoOption: always convert all series.
% 160405 nMosaic(): get nMos by finding zeros in img.
% 160407 remove ang2vec: likely never used and may be wrong.
% 160409 multi .m files: use sscanf/strfind/regexp, avoid str2double/strtok.
% 160504 asc_header: ignore invalid CSASeriesHeaderInfo in B15 (thx LaureSA).
% 160512 get_dti_para: fix bvec sign for GE cor/sag slices (thx paul for data).
% 160514 csa2pos: make it safer so it won't err.
% 160516 checkImagePosition: assign isTZ for missing files (thx TanH).
% 160519 set nii.hdr.slice_duration for MB although it is useless.
% 160601 Update ReadoutSeconds, and store it even if ~isDTI.
% 160607 Avoid skipping series by ignoring empty-image dicom (thx QR).
% 160610 Add pref save_patientName and use_parfor; simplify save_json flag.
% 160807 Store InversionTime for nii ext and json.
% 160826 Add pref use_seriesUID to take care of missed-up SeriesIntanceUID.
% 160829 fix problem with large SeriesNumber; only 3 dicm fields are must. 
% 160901 Put pref onto GUI. 
% 160920 Convert series with varying Rescale slope/inter.
% 160921 Quick bug fix introduced on 160920: slope/inter applied for 2nd+ files.
% 161129 Bug fix for irregular slice order in Philips multiframe dicm.
% 161216 xform_mat: only override SliceThickness if it is >1% off.
% 161227 Convert a series by ignoring the only inconsistent file;
% 	     checkImagePositions(): allow 10% error for gantry tilt (thx Qinwan).
% 161229 xform CT img with gantry tilt; add some flds in ext for CT.
% 170202 nMosaic(): bug fix for using LocationsInAcquisition.
% 170211 implement no_save for nii_viewer: return first nii without saving;
%        Bug fix: double(val) for fldsCk (needed for Rows and Columns).
% 170225 nMosaic: minor fix.
% 170320 check_ipp: slice tol = max(diff(sort(ipp)))/100. Thx navot.
% 170322 split_philips_phase: bug fix for vol>2. Thx RobertW.
% 170403 save_jason: add DelayTime for BIDS.
% 170404 set MB slice_code to 0 to avoid FreeSurfer error. Thx JacobM.
% 170417 checkUpdate(): use 'user_version' due to Matlab Central web change.
% 170625 phaseDirection(): GE VIEWORDER update due to dicm_hdr() update.
% 170720 Allow regularly missing InstanceNumbers, like CMRR ISSS.
% 170810 Use GE SLICEORDER for SliceTiming if needed (thx PatrickS).
% 170826 Use 'VolumeTiming' for missing volumes based on BIDS.
% 170923 Correct readout (thx Chris R and MH); Always store readout in descrip;
% 170924 Bug fix for long file name (avoid genvarname now).
% 170927 Store TE in descrip even if multiple TEs.
% 171211 Make it work for Siemens multiframe dicom (seems 3D only).
% 180116 Bug fix for EchoTime1 for phase image (thx DylanW)
% 180219 json: PhaseEncodingDirection use ijk, fix pf.save_PatientName (thx MichaelD)
% 180312 json: ImageType uses BIDS format (thx ChrisR).
% 180419 bug fix for long file name (thx NedaK).
% 180430 store VolumeTiming from FrameReferenceTime (thx ChrisR).
% 180519 get_dti_para: bug fix to remove Philips ADC vol (thx ChrisR).
% 180520 Make copy for vida CSA, so asc_header/csa_header faster if non-Siemens.
% 180523 set_nii_hdr: use MRScaleSlope for Philips, same as dcm2niiX default.
% 180526 split_philips_phase: fix the long time slope/inter bug for phase image;
%        move some code (eg SliceTiming related) out of main function.
% 180527 fix vida SliceTiming unit, but now turn it off, and rely on ucMode.
% 180530 store EchoTimes and CardiacTriggerDelayTimes;
%        split_components: not only phase, json for each file (thx ChrisR).
% 180601 use SortFrames for multiframe and PAR (thx JulienB & ChrisR); 
% 180602 extract sort_frames() for multiFrameFields() and philips_par()
% 180605 multiFrameFields: B=0 to first vol. 
% 180614 Implement scale_16bit: free precision for tools using 16-bit datatype. 
% 180619 use GetFullPath from Jan: (thx JulienB). 
% 180721 accept mixture of files and folders as input; GUI uses jFileChooser(). 
% 180914 support UIH dicm, both GRID (mosaic) and regular. 
% 180922 fix for UIH masaic -1 col; GE phPos from dcm2niix. 
% 190122 add BIDS support. tanguy.duval@inserm.fr

% TODO: need testing files to figure out following parameters:
%    flag for MOCO series for GE/Philips
%    GE non-axial slice (phase: ROW) bvec sign
%    Phase image flag for GE

if nargout, varargout{1} = ''; end
if nargin==3 && ischar(fmt) && strcmp(fmt, 'func_handle') % special purpose
    varargout{1} = str2func(niiFolder);
    return;
end

%% Deal with output format first, and error out if invalid
if nargin<3 || isempty(fmt), fmt = 1; end % default .nii.gz
no_save = ischar(fmt) && strcmp(fmt, 'no_save');
if no_save, fmt = 'nii'; end

bids = false;
if ischar(fmt) && strcmpi(fmt,'BIDS')
    bids = true;
    fmt = '.nii.gz';
end
if ischar(fmt) && strcmpi(fmt,'BIDSNII')
    bids = true;
    fmt = '.nii';
end
if bids && verLessThan('matlab','9.4')
    fprintf('BIDS conversion is easier with MATLAB R2018a or more.\n')
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

if nargin<1 || isempty(src) || (nargin<2 || isempty(niiFolder))
    create_gui; % show GUI if input is not enough
    return;
end

%% Deal with niiFolder
if ~isdir(niiFolder), mkdir(niiFolder); end
niiFolder = [GetFullPath(niiFolder) filesep];
converter = ['dicm2nii.m ' getVersion];
if errorLog('', niiFolder) && ~no_save % remember niiFolder for later call
    more off;
    disp(['Xiangrui Li''s ' converter ' (feedback to xiangrui.li@gmail.com)']);
end

%% Deal with data source
tic;
if isnumeric(src)
    error('Invalid dicom source.');    
elseif iscellstr(src) % multiple files/folders
    fnames = {};
    for i = 1:numel(src)
        if isdir(src{i})
            fnames = [fnames filesInDir(src{i})];
        else
            a = dir(src{i});
            if isempty(a), continue; end
            dcmFolder = fileparts(GetFullPath(src{i}));
            fnames = [fnames fullfile(dcmFolder, a.name)];
        end
    end
elseif isdir(src) % folder
    fnames = filesInDir(src);
elseif ~exist(src, 'file') % like input: run1*.dcm
    fnames = dir(src);
    if isempty(fnames), error('%s does not exist.', src); end
    fnames([fnames.isdir]) = [];
    dcmFolder = filepars(GetFullPath(src));
    fnames = strcat(dcmFolder, filesep, {fnames.name});    
elseif ischar(src) % 1 dicom or zip/tgz file
    dcmFolder = fileparts(GetFullPath(src));
    unzip_cmd = compress_func(src);
    if isempty(unzip_cmd)
        fnames = dir(src);
        fnames = strcat(dcmFolder, filesep, {fnames.name});
    else % unzip if compressed file is the source
        [~, fname, ext1] = fileparts(src);
        dcmFolder = sprintf('%stmpDcm%s/', niiFolder, fname);
        if ~isdir(dcmFolder)
            mkdir(dcmFolder);
            delTmpDir = onCleanup(@() rmdir(dcmFolder, 's'));
        end
        disp(['Extracting files from ' fname ext1 ' ...']);
        
        if strcmp(unzip_cmd, 'unzip')
            cmd = sprintf('unzip -qq -o %s -d %s', src, dcmFolder);
            err = system(cmd); % first try system unzip
            if err, unzip(src, dcmFolder); end % Matlab's unzip is too slow
        elseif strcmp(unzip_cmd, 'untar')
            if isempty(which('untar'))
                error('No untar found in matlab path.');
            end
            untar(src, dcmFolder);
        end
        fnames = filesInDir(dcmFolder);
    end
else
    error('Unknown dicom source.');
end
nFile = numel(fnames);
if nFile<1, error(' No files found in the data source.'); end

%% user preference
pf.save_patientName = getpref('dicm2nii_gui_para', 'save_patientName', true);
pf.save_json        = getpref('dicm2nii_gui_para', 'save_json', false);
pf.use_parfor       = getpref('dicm2nii_gui_para', 'use_parfor', true);
pf.use_seriesUID    = getpref('dicm2nii_gui_para', 'use_seriesUID', true);
pf.lefthand         = getpref('dicm2nii_gui_para', 'lefthand', true);
pf.scale_16bit      = getpref('dicm2nii_gui_para', 'scale_16bit', false);

%% Check each file, store partial header in cell array hh
% first 2 fields are must. First 10 indexed in code
flds = {'Columns' 'Rows' 'BitsAllocated' 'SeriesInstanceUID' 'SeriesNumber' ...
    'ImageOrientationPatient' 'ImagePositionPatient' 'PixelSpacing' ...
    'SliceThickness' 'SpacingBetweenSlices' ... % these 10 indexed in code
    'PixelRepresentation' 'BitsStored' 'HighBit' 'SamplesPerPixel' ...
    'PlanarConfiguration' 'EchoTime' 'RescaleIntercept' 'RescaleSlope' ...
    'InstanceNumber' 'NumberOfFrames' 'B_value' 'DiffusionGradientDirection' ...
    'RTIA_timer' 'RBMoCoTrans' 'RBMoCoRot' 'AcquisitionNumber'};
dict = dicm_dict('SIEMENS', flds); % dicm_hdr will update vendor if needed

% read header for all files, use parpool if available and worthy
if ~no_save, fprintf('Validating %g files ...\n', nFile); end
hh = cell(1, nFile); errStr = cell(1, nFile);
doParFor = pf.use_parfor && nFile>2000 && useParTool;
for k = 1:nFile
    [hh{k}, errStr{k}, dict] = dicm_hdr(fnames{k}, dict);
    if doParFor && ~isempty(hh{k}) % parfor wont allow updating dict
        parfor i = k+1:nFile
            [hh{i}, errStr{i}] = dicm_hdr(fnames{i}, dict); 
        end
        break; 
    end
end

%% sort headers into cell h by SeriesInstanceUID, EchoTime and InstanceNumber
h = {}; % in case of no dicom files at all
errInfo = '';
seriesUIDs = {}; ETs = {};
for k = 1:nFile
    s = hh{k};
    if isempty(s) || any(~isfield(s, flds(1:2))) || ~isfield(s, 'PixelData') ...
            || (isstruct(s.PixelData) && s.PixelData.Bytes<1)
        if ~isempty(errStr{k}) % && isempty(strfind(errInfo, errStr{k}))
            errInfo = sprintf('%s\n%s\n', errInfo, errStr{k});
        end
        continue; % skip the file
    end

    if isfield(s, flds{4}) && (pf.use_seriesUID || ~isfield(s, 'SeriesNumber'))
        sUID = s.SeriesInstanceUID;
    else
        if isfield(s, 'SeriesNumber'), sN = s.SeriesNumber; 
        else, sN = fix(toc*1e6);
        end
        sUID = num2str(sN); % make up UID
        if isfield(s, 'SeriesDescription')
            sUID = [s.SeriesDescription sUID];
        end
    end
    
    m = find(strcmp(sUID, seriesUIDs));
    if isempty(m)
        m = numel(seriesUIDs)+1;
        seriesUIDs{m} = sUID;
        ETs{m} = [];
    end
    
    % EchoTime is needed for Siemens fieldmap mag series
    et = tryGetField(s, 'EchoTime');
    if isempty(et), i = 1;
    else
        i = find(et == ETs{m}); % strict equal?
        if isempty(i)
            i = numel(ETs{m}) + 1;
            ETs{m}(i) = et;
            if i>1
                [ETs{m}, ind] = sort(ETs{m});
                i = find(et == ETs{m});
                h{m}{end+1}{1} = [];
                h{m} = h{m}(ind);
            end
        end
    end
    j = tryGetField(s, 'InstanceNumber');
    if isempty(j) || j<1
        try j = numel(h{m}{i}) + 1;
        catch, j = 1; 
        end
    end
    h{m}{i}{j} = s; % sort partial header
end
clear hh errStr;

%% Check headers: remove dim-inconsistent series
nRun = numel(h);
if nRun<1 % no valid series
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
    h{i} = [h{i}{:}]; % concatenate different EchoTime
    ind = cellfun(@isempty, h{i});
    h{i}(ind) = []; % remove all empty cell for all vendors
    
    s = h{i}{1};
    if ~isfield(s, 'LastFile') % avoid re-read for PAR/HEAD/BV file
        s = dicm_hdr(s.Filename); % full header for 1st file
    end
    if ~isfield(s, 'Manufacturer'), s.Manufacturer = 'Unknown'; end
    subjs{i} = PatientName(s);
    acqs{i} =  AcquisitionDateField(s);
    vendor{i} = s.Manufacturer;
    if isfield(s, 'SeriesNumber'), sNs(i) = s.SeriesNumber; 
    else, sNs(i) = fix(toc*1e6); 
    end
    studyIDs{i} = tryGetField(s, 'StudyID', '1');
    series = sprintf('Subject %s, %s (Series %g)', subjs{i}, ProtocolName(s), sNs(i));
    s = multiFrameFields(s); % no-op if non multi-frame
    if isempty(s), keep(i) = 0; continue; end % invalid multiframe series
    s.isDTI = isDTI(s);
    if ~isfield(s, 'AcquisitionDateTime') % assumption: 1st instance is earliest
        try s.AcquisitionDateTime = [s.AcquisitionDate s.AcquisitionTime]; end
    end
    
    h{i}{1} = s; % update record in case of full hdr or multiframe
    
    nFile = numel(h{i});
    if nFile>1 && tryGetField(s, 'NumberOfFrames', 1) > 1 % seen in vida
        for k = 2:nFile % this can be slow
            h{i}{k} = dicm_hdr(h{i}{k}.Filename); % full header
            h{i}{k} = multiFrameFields(h{i}{k});
        end
        if ~isfield(s, 'EchoTimes') && isfield(s, 'EchoTime')
            h{i}{1}.EchoTimes = nan(1, nFile);
            for k = 1:nFile
                h{i}{1}.EchoTimes(k) = tryGetField(h{i}{k}, 'EchoTime', 0); 
            end
        end
    end
    
    % check consistency in 'fldsCk'
    nFlds = numel(fldsCk);
    if isfield(s, 'SpacingBetweenSlices'), nFlds = nFlds - 1; end % check 1 of 2
    for k = 1:nFlds*(nFile>1)
        if isfield(s, fldsCk{k}), val = s.(fldsCk{k}); else, continue; end
        val = repmat(double(val), [1 nFile]);
        for j = 2:nFile
            if isfield(h{i}{j}, fldsCk{k}), val(:,j) = h{i}{j}.(fldsCk{k});
            else, keep(i) = 0; break;
            end
        end
        if ~keep(i), break; end % skip silently
        ind = any(abs(bsxfun(@minus, val, val(:,1))) > 1e-4, 1);
        if sum(ind)>1 % try 2nd, in case only 1st is inconsistent
            ind = any(abs(bsxfun(@minus, val, val(:,2))) > 1e-4, 1);
        end
        if ~any(ind), continue; end % good
        if any(strcmp(fldsCk{k}, {'RescaleIntercept' 'RescaleSlope'}))
            h{i}{1}.ApplyRescale = true;
            continue;
        end
        if numel(ind)>2 && sum(ind)==1 % 2+ files but only 1 inconsistent
            h{i}(ind) = []; % remove first or last, but keep the series
            nFile = nFile - 1;
            if ind(1) % re-do full header for new 1st file
                s = dicm_hdr(h{i}{1}.Filename);
                s.isDTI = isDTI(s);
                h{i}{1} = s;
            end
        else
            errorLog(['Inconsistent ''' fldsCk{k} ''' for ' series '. Series skipped.']);
            keep(i) = 0; break;
        end
    end
    
    nSL = nMosaic(s); % nSL>1 for mosaic
    if ~isempty(nSL) && nSL>1
        h{i}{1}.isMos = true;
        h{i}{1}.LocationsInAcquisition = nSL;
        if s.isDTI, continue; end % allow missing directions for DTI
        a = zeros(1, nFile);
        for j = 1:nFile, a(j) = tryGetField(h{i}{j}, 'InstanceNumber', 1); end
        if any(diff(a) ~= 1) % like CMRR ISSS seq or multi echo. Error for UIH
            errorLog(['InstanceNumber discontinuity detected for ' series '.' ...
                'See VolumeTiming in NIfTI ext or dcmHeaders.mat.']);
            dict = dicm_dict('', {'AcquisitionDate' 'AcquisitionTime'});
            vTime = nan(1, nFile);
            for j = 1:nFile
                s2 = dicm_hdr(h{i}{j}.Filename, dict);
                dt = [s2.AcquisitionDate s2.AcquisitionTime];
                vTime(j) = datenum(dt, 'yyyymmddHHMMSS.fff');
            end
            vTime = vTime - min(vTime);
            h{i}{1}.VolumeTiming = vTime * 86400; % day to seconds
        end
        continue; % no other check for mosaic
    end
        
    if ~keep(i) || nFile<2 || ~isfield(s, 'ImagePositionPatient'), continue; end
    if tryGetField(s, 'NumberOfFrames', 1) > 1, continue; end % Siemens Vida
    
    ipp = zeros(nFile, 1);
    iSL = xform_mat(s); iSL = iSL(3);
    for j = 1:nFile, ipp(j,:) = h{i}{j}.ImagePositionPatient(iSL); end
    gantryTilt = abs(tryGetField(s, 'GantryDetectorTilt', 0)) > 0.1;
    [err, nSL, sliceN, isTZ] = checkImagePosition(ipp, gantryTilt);
    if ~isempty(err)
        errorLog([err ' for ' series '. Series skipped.']);
        keep(i) = 0; continue; % skip
    end    
    h{i}{1}.LocationsInAcquisition = uint16(nSL); % best way for nSL?

    nVol = nFile / nSL;
    if isTZ % Philips
        ind = reshape(1:nFile, [nVol nSL])';
        h{i} = h{i}(ind(:));
    end
       
    % re-order slices within vol. No SliceNumber since files are organized
    if all(diff(sliceN, 2) == 0), continue; end % either 1:nSL or nSL:-1:1
    if sliceN(end) == 1, sliceN = sliceN(nSL:-1:1); end % not important
    inc = repmat((0:nVol-1)*nSL, nSL, 1);
    ind = repmat(sliceN(:), nVol, 1) + inc(:);
    h{i} = h{i}(ind); % sorted by slice locations
    
    if sliceN(1) == 1, continue; end % first file kept: following update h{i}{1}
    h{i}{1} = dicm_hdr(h{i}{1}.Filename); % read full hdr
    s = h{i}{sliceN==1}; % original first file
    fldsCp = {'AcquisitionDateTime' 'isDTI' 'LocationsInAcquisition'};
    for j = 1:numel(fldsCp)
        if isfield(h{i}{1}, fldsCk{k}), h{i}{1}.(fldsCp{j}) = s.(fldsCp{j}); end
    end
end
h = h(keep); sNs = sNs(keep); studyIDs = studyIDs(keep); 
subjs = subjs(keep); vendor = vendor(keep);
acqs  = acqs(keep);

%% sort h by PatientName, then StudyID, then SeriesNumber
% Also get correct order for subjs/studyIDs/nStudy/sNs for nii file names
[subjs, ind] = sort(subjs);
subj = unique(subjs); 
acq = unique(acqs);
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
%  for MoCo series, append '_MoCo' to the name if both series are present.
%  for multiple subjs, it is SeriesDescription_subj_s007
%  for multiple Study, it is SeriesDescription_subj_Study1_s007
nRun = numel(h); % update it, since we have removed some
if nRun<1
    errorLog('No valid series found');
    return;
end
rNames = cell(1, nRun);
multiSubj = numel(subj)>1;
j_s = nan(nRun, 1); % index-1 for _s003. needed if 4+ length SeriesNumbers
maxLen = namelengthmax - 3;
for i = 1:nRun
    s = h{i}{1};
    sN = sNs(i);
    a = strtrim(ProtocolName(s));
    if isPhase(s), a = [a '_phase']; end % phase image
    if i>1 && sN-sNs(i-1)==1 && isType(s, '\MOCO\'), a = [a '_MoCo']; end
    if multiSubj, a = [a '_' subjs{i}]; end
    if nStudy(i)>1, a = [a '_Study' studyIDs{i}]; end
    if ~isstrprop(a(1), 'alpha'), a = ['x' a]; end % genvarname behavior
    a(~isstrprop(a, 'alphanum')) = '_'; % make str valid for field name
    a = regexprep(a, '_{2,}', '_'); % remove repeated underscore
    if sN>100 && strncmp(s.Manufacturer, 'Philips', 7)
        sN = tryGetField(s, 'AcquisitionNumber', floor(sN/100));
    end
    j_s(i) = numel(a);
    rNames{i} = sprintf('%s_s%03.0f', a, sN);
    d = numel(rNames{i}) - maxLen;
    if d>0, rNames{i}(j_s(i)+(-d+1:0)) = ''; j_s(i) = j_s(i)-d; end % keep _s007
end

vendor = strtok(unique(vendor));
if nargout>0, varargout{1} = subj; end % return converted subject IDs

% After following sort, we need to compare only neighboring names. Remove
% _s007 if there is no conflict. Have to ignore letter case for Windows & MAC
fnames = rNames; % copy it, reserve letter cases
[rNames, iRuns] = sort(lower(fnames));
j_s = j_s(iRuns);
for i = 1:nRun
    if i>1 && strcmp(rNames{i}, rNames{i-1}) % truncated StudyID to PatientName
        a = num2str(i);
        rNames{i}(j_s(i)+(-numel(a)+1:0)) = a; % not 100% unique    
    end
    a = rNames{i}(1:j_s(i)); % remove _s003
    % no conflict with both previous and next name
    if nRun==1 || ... % only one run
         (i==1    && ~strcmpi(a, rNames{2}(1:j_s(2)))) || ... % first
         (i==nRun && ~strcmpi(a, rNames{i-1}(1:j_s(i-1)))) || ... % last
         (i>1 && i<nRun && ~strcmpi(a, rNames{i-1}(1:j_s(i-1))) ...
                        && ~strcmpi(a, rNames{i+1}(1:j_s(i+1)))) % middle ones
        fnames{iRuns(i)}(j_s(i)+1:end) = [];
    end
end
if numel(unique(fnames)) < nRun % may happen to user-modified dicom/par
    fnames = matlab.lang.makeUniqueStrings(fnames); % since R2014a
end
fmtStr = sprintf(' %%-%gs %%dx%%dx%%dx%%d\n', max(cellfun(@numel, fnames))+12);

%% Now ready to convert nii series by series
subjStr = sprintf('''%s'', ', subj{:}); subjStr(end+(-1:0)) = [];
vendor = sprintf('%s, ', vendor{:}); vendor(end+(-1:0)) = [];
if ~no_save
    fprintf('Converting %g series (%s) into %g-D %s: subject %s\n', ...
            nRun, vendor, 4-rst3D, ext, subjStr);
end

%% Parse BIDS
if bids
    if multiSubj
        fprintf(['Multiple subjects detected!!!!! Skipping...\n' ...
            'Please convert subjects one by one with BIDS options\n'])
        fprintf('%s\n',subj{:})
        return;
    end
    if numel(acq)>1
        fprintf('Multiple acquitisition detected!!!!! Skipping...\nPlease convert sessions one by one with BIDS options\n')
        fprintf('%s\n',acq{:})
        return;
    end

    % Table: subject Name
    try
        asciiInds=[1:47 58:64 91:96 123:127];
        for j=1:numel(asciiInds)
            subj=strrep(subj,char(asciiInds(j)),'');
        end
        Subject = subj;
    catch
        Subject = {'01'};
    end
    Session                = {'01'};
    AcquisitionDate        = datetime(acq{1},'InputFormat','yyyyMMdd');
    AcquisitionDate.Format = 'yyyy-MM-dd';
    Comment                = {'N/A'};
    S = table(Subject,Session,AcquisitionDate,Comment);
    
    % Table: Type/Modality
    valueset = {'skip','skip';
        'anat','T1w';
        'anat','T2w';
        'anat','T1rho';
        'anat','T1map';
        'anat','T2map';
        'anat','T2star';
        'anat','FLAIR';
        'anat','FLASH';
        'anat','PD';
        'anat','PDmap';
        'dwi' ,'dwi';
        'fmap','phasediff';
        'fmap','phase1';
        'fmap','phase2';
        'fmap','magnitude1';
        'fmap','magnitude2';
        'fmap','fieldmap'};
    Modality = categorical(repmat({'skip'},[length(fnames),1]),valueset(:,2));
    Type = categorical(repmat({'skip'},[length(fnames),1]),unique(valueset(:,1)));
    Name = fnames';
    T = table(Name,Type,Modality);
    
    ModalityTablePref = getpref('dicm2nii_gui_para', 'ModalityTable', T);
    for i = 1:nRun
        match = cellfun(@(Mod) strcmp(Mod,T{i,1}),table2cell(ModalityTablePref(:,1)));
        if any(match)
            T.Type(i) = ModalityTablePref.Type(match);
            T.Modality(i) = ModalityTablePref.Modality(match);
        end
    end

    % GUI
    setappdata(0,'Canceldicm2nii',false)
    scrSz = get(0, 'ScreenSize');
    clr = [1 1 1]*206/256;
    figargs = {'bids' * 256.^(0:3)','Position',[min(scrSz(4)+420,620) scrSz(4)-600 420 300],...
               'Color', clr,...
               'CloseRequestFcn',@my_closereq};
    if verLessThan('matlab','9.4')
        hf = figure(figargs{1});
        set(hf,figargs{2:end});
        % add help
        set(hf,'ToolBar','none')
        set(hf,'MenuBar','none')
    else
        hf = uifigure(figargs{:});
    end
    uimenu(hf,'Text','help','Callback',@(src,evnt) showHelp(valueset))
    set(hf,'Name', 'dicm2nii - BIDS Converter', 'NumberTitle', 'off')

    % tables
    if verLessThan('matlab','9.4')
        SCN = S.Properties.VariableNames;
        S   = table2cell(S); 
        S{3}= datestr(S{3},'yyyy-mm-dd');
        TCN = T.Properties.VariableNames;
        T   = cellfun(@char,table2cell(T),'uni',0);
    end
    TS = uitable(hf,'Data',S);
    TT = uitable(hf,'Data',T);
    TSpos = [20 hf.Position(4)-110 hf.Position(3)-160 90];
    TTpos = [20 20 hf.Position(3)-160 hf.Position(4)-120];
    if verLessThan('matlab','9.4')
        setpixelposition(TS,TSpos);
        set(TS,'Units','Normalized')
        setpixelposition(TT,TTpos);
        set(TT,'Units','Normalized')
    else
        TS.Position = TSpos;
        TT.Position = TTpos;
    end
    TS.ColumnEditable = [true true true true];
    if verLessThan('matlab','9.4')
        TS.ColumnName = SCN;
        TT.ColumnName = TCN;
    end
    TT.ColumnEditable = [false true true];
    setappdata(0,'ModalityTable',TT.Data)
    setappdata(0,'SubjectTable',TS.Data)

    % button
   	Bpos = [hf.Position(3)-120 20 100 30];
    BCB  = @(btn,event) BtnModalityTable(hf,TT, TS);
    if verLessThan('matlab','9.4')
        B = uicontrol(hf,'Style','pushbutton','String','OK');
        set(B,'Callback',BCB);
        setpixelposition(B,Bpos)
        set(B,'Units','Normalized')
    else
        B = uibutton(hf,'Position',Bpos);
        B.Text = 'OK';
        B.ButtonPushedFcn = BCB;
    end
    
    % preview panel
    axesArgs = {hf,'Position',[hf.Position(3)-120 70 100 hf.Position(4)-90],...
                   'Colormap',gray(64)};
    if verLessThan('matlab','9.4')
        ax = imagesc(dicm_img(h{1}{1}));
        ax = ax.Parent;
        setpixelposition(ax,axesArgs{3})
        colormap(ax,axesArgs{5})
    else
        ax = uiaxes(axesArgs{:});
    end
    previewDicom(ax,h{1});
    axis(ax,'off');
    ax.YTickLabel = [];
    ax.XTickLabel = [];
    TT.CellSelectionCallback = @(src,event) previewDicom(ax,h{event.Indices(1)});
    
    waitfor(hf);
    if getappdata(0,'Canceldicm2nii')
        return;
    end
    % get results
    ModalityTable = getappdata(0,'ModalityTable');
    SubjectTable = getappdata(0,'SubjectTable');
    % setpref
    if istable(ModalityTable)
        ModalityTable = cellfun(@char,table2cell(ModalityTable),'uni',0);
    end
    ModalityTableSavePref = ModalityTable(~any(ismember(ModalityTable(:,2:3),'skip'),2),:);
    for imod = 1:size(ModalityTableSavePref,1)
        match = cellfun(@(Mod) strcmp(Mod,ModalityTableSavePref{imod,1}),table2cell(ModalityTablePref(:,1)));
        if any(match) % replace old pref
            ModalityTablePref.Type(match) = ModalityTableSavePref{imod,2};
            ModalityTablePref.Modality(match) = ModalityTableSavePref{imod,3};
        else % append new pref
            ModalityTablePref = [ModalityTablePref;ModalityTableSavePref(end,:)];
        end
    end
    setpref('dicm2nii_gui_para', 'ModalityTable', ModalityTablePref);
end

%% Convert
for i = 1:nRun
    if bids
        if any(ismember(ModalityTable(i,2:3),'skip')), continue; end
        if isempty(char(SubjectTable{1,2})) % no session
            ses = '';
            session_id='01'; 
        else
            session_id=char(SubjectTable{1,2}); 
            ses = ['ses-' session_id];
        end
        % folder
        modalityfolder = fullfile(['sub-' char(SubjectTable{1,1})],...
                                    ses,...
                                    char(ModalityTable{i,2}));
        if ~exist(fullfile(niiFolder, modalityfolder),'dir')
            mkdir(fullfile(niiFolder, modalityfolder));
        end
        
        % filename
        fnames{i} = fullfile(modalityfolder,...
              ['sub-' char(SubjectTable{1,1}) '_' ses '_' char(ModalityTable{i,3})]);
        fnames{i} = strrep(fnames{i},'__','_');
                
        % _session.tsv
        tsvfile = fullfile(niiFolder, ['sub-' char(SubjectTable{1,1})],['sub-' char(SubjectTable{1,1}) '_sessions.tsv']);
        if verLessThan('matlab','9.4')
            write_tsv(session_id,tsvfile,'acq_time',datestr(SubjectTable{3},'yyyy-mm-dd'),'Comment',SubjectTable{4})
        else
            write_tsv(session_id,tsvfile,'acq_time',datestr(SubjectTable.AcquisitionDate,'yyyy-mm-dd'),'Comment',SubjectTable.Comment)
        end
    end
    
    nFile = numel(h{i});
    h{i}{1}.NiftiName = fnames{i}; % for convenience of error info
    s = h{i}{1};
    if nFile>1 && ~isfield(s, 'LastFile')
        h{i}{1}.LastFile = h{i}{nFile}; % store partial last header into 1st
    end
    
    for j = 1:nFile
        if j==1
            img = dicm_img(s, 0); % initialize img with dicm data type
            if ndims(img)>4 % err out, likely won't work for other series
                error('Image with 5 or more dim not supported: %s', s.NiftiName);
            end
            applyRescale = tryGetField(s, 'ApplyRescale', false);
            if applyRescale, img = single(img); end
        else
            if j==2, img(:,:,:,:,nFile) = 0; end % pre-allocate for speed
            img(:,:,:,:,j) = dicm_img(h{i}{j}, 0);
        end
        if applyRescale
            slope = tryGetField(h{i}{j}, 'RescaleSlope', 1);
            inter = tryGetField(h{i}{j}, 'RescaleIntercept', 0);
            img(:,:,:,:,j) = img(:,:,:,:,j) * slope + inter;
        end
    end
    if strcmpi(tryGetField(s, 'DataRepresentation', ''), 'COMPLEX')
        img = complex(img(:,:,:,1:2:end,:), img(:,:,:,2:2:end,:));
    end
    [~, ~, d3, d4, ~] = size(img);
    if strcmpi(tryGetField(s, 'SignalDomainColumns', ''), 'TIME') % no permute
    elseif d3<2 && d4<2, img = permute(img, [1 2 5 3 4]); % remove dim3,4
    elseif d4<2,         img = permute(img, [1:3 5 4]);   % remove dim4: Frames
    elseif d3<2,         img = permute(img, [1 2 4 5 3]); % remove dim3: RGB
    end

    nSL = double(tryGetField(s, 'LocationsInAcquisition'));
    if tryGetField(s, 'SamplesPerPixel', 1) > 1 % color image
        img = permute(img, [1 2 4:8 3]); % put RGB into dim8 for nii_tool
    elseif tryGetField(s, 'isMos', false) % mosaic
        img = mos2vol(img, nSL, strncmpi(s.Manufacturer, 'UIH', 3));
    elseif ndims(img)==3 && ~isempty(nSL) % may need to reshape to 4D
        if isfield(s, 'SortFrames'), img = img(:,:,s.SortFrames); end
        dim = size(img);
        dim(3:4) = [nSL dim(3)/nSL]; % verified integer earlier
        img = reshape(img, dim);
    end

    if any(~isfield(s, flds(6:8))) || ~any(isfield(s, flds(9:10)))
        h{i}{1} = csa2pos(h{i}{1}, size(img,3));
    end
    
    if isa(img, 'uint16') && max(img(:))<32768
        img = int16(img); % use int16 if lossless
    end
    
    h{i}{1}.ConversionSoftware = converter;
    nii = nii_tool('init', img); % create nii struct based on img
    [nii, h{i}] = set_nii_hdr(nii, h{i}, pf); % set most nii hdr

    % Save bval and bvec files after bvec perm/sign adjusted in set_nii_hdr
    fname = fullfile(niiFolder,fnames{i}); % name without ext
    if s.isDTI && ~no_save, save_dti_para(h{i}{1}, fname); end

    nii = split_components(nii, h{i}{1}); % split Philips vol components
    if no_save % only return the first nii
        nii(1).hdr.file_name = [fnames{i} '_no_save.nii'];
        nii(1).hdr.magic = 'n+1';
        varargout{1} = nii_tool('update', nii(1));
        if nRun>1, fprintf(2, 'Only one series is converted.\n'); end
        return;
    end
    
    for j = 1:numel(nii)
        nam = fnames{i};
        if numel(nii)>1, nam = nii(j).hdr.file_name; end
        fprintf(fmtStr, nam, nii(j).hdr.dim(2:5));
        nii(j).ext = set_nii_ext(nii(j).json); % NIfTI extension
        if pf.save_json, save_json(nii(j).json, fname); end
        nii_tool('save', nii(j), fullfile(niiFolder,[nam ext]), rst3D);
    end
        
    if isfield(nii(1).hdr, 'hdrTilt')
        nii = nii_xform(nii(1), nii.hdr.hdrTilt);
        fprintf(fmtStr, [fnames{i} '_Tilt'], nii.hdr.dim(2:5));
        nii_tool('save', nii, [fname '_Tilt' ext], rst3D); % save xformed nii
    end
    
    h{i} = h{i}{1}; % keep 1st dicm header only
    if isnumeric(h{i}.PixelData), h{i} = rmfield(h{i}, 'PixelData'); end % BV
end

if ~bids
    h = cell2struct(h, fnames, 2); % convert into struct
    fname = [niiFolder 'dcmHeaders.mat'];
    if exist(fname, 'file') % if file exists, we update fields only
        S = load(fname);
        for i = 1:numel(fnames), S.h.(fnames{i}) = h.(fnames{i}); end
        h = S.h;
    end
    save(fname, 'h', '-v7'); % -v7 better compatibility
else
    rmappdata(0,'ModalityTable');
    rmappdata(0,'SubjectTable');
end
fprintf('Elapsed time by dicm2nii is %.1f seconds\n\n', toc);
return;

%% Subfunction: return PatientName
function subj = PatientName(s)
subj = tryGetField(s, 'PatientName');
if isempty(subj), subj = tryGetField(s, 'PatientID', 'Anonymous'); end

%% Subfunction: return AcquisitionDate
function acq = AcquisitionDateField(s)
acq = tryGetField(s, 'AcquisitionDate');
if isempty(acq), acq = tryGetField(s, 'SeriesDate', ''); end
if isempty(acq), acq = tryGetField(s, 'StudyDate' , ''); end

%% Subfunction: return SeriesDescription
function name = ProtocolName(s)
name = tryGetField(s, 'SeriesDescription');
if isempty(name) || (strncmp(s.Manufacturer, 'SIEMENS', 7) && any(regexp(name, 'MoCoSeries$')))
    name = tryGetField(s, 'ProtocolName');
end
if isempty(name), [~, name] = fileparts(s.Filename); end

%% Subfunction: return true if keyword is in s.ImageType
function tf = isType(s, keyword)
typ = tryGetField(s, 'ImageType', '');
tf = ~isempty(strfind(typ, keyword)); %#ok<*STREMP>

%% Subfunction: return true if series is DTI
function tf = isDTI(s)
tf = isType(s, '\DIFFUSION'); % Siemens, Philips
if tf, return; end
if isfield(s, 'ProtocolDataBlock') % GE, not labeled as \DIFFISION
    IOPT = tryGetField(s.ProtocolDataBlock, 'IOPT');
    if isempty(IOPT), tf = tryGetField(s, 'DiffusionDirection', 0)>0;
    else, tf = ~isempty(regexp(IOPT, 'DIFF', 'once'));
    end
elseif strncmpi(s.Manufacturer, 'Philips', 7)
    tf = strcmp(tryGetField(s, 'MRSeriesDiffusion', 'N'), 'Y');
elseif isfield(s, 'ApplicationCategory') % UIH
    tf = ~isempty(regexp(s.ApplicationCategory, 'DTI', 'once'));
elseif isfield(s, 'AcquisitionContrast') % Bruker    
    tf = ~isempty(regexpi(s.AcquisitionContrast, 'DIFF', 'once'));
else % Some Siemens DTI are not labeled as \DIFFUSION
    tf = ~isempty(csa_header(s, 'B_value'));
end

%% Subfunction: return true if series is phase img
function tf = isPhase(s)
tf = isType(s, '\P\') || ...
    strcmpi(tryGetField(s, 'ComplexImageComponent', ''), 'PHASE'); % Philips

%% Subfunction: get field if exist, return default value otherwise
function val = tryGetField(s, field, dftVal)
if isfield(s, field), val = s.(field); 
elseif nargin>2, val = dftVal;
else, val = [];
end

%% Subfunction: Set most nii header and re-orient img
function [nii, h] = set_nii_hdr(nii, h, pf)
dim = nii.hdr.dim(2:4); nVol = nii.hdr.dim(5);
fld = 'NumberOfTemporalPositions';
if ~isfield(h{1}, fld) && nVol>1, h{1}.(fld) = nVol; end

% Transformation matrix: most important feature for nii
[ixyz, R, pixdim, xyz_unit] = xform_mat(h{1}, dim); % R: dicom xform matrix
R(1:2,:) = -R(1:2,:); % dicom LPS to nifti RAS, xform matrix before reorient

% Compute bval & bvec in image reference for DTI series before reorienting
if h{1}.isDTI, [h, nii] = get_dti_para(h, nii); end

% Store CardiacTriggerDelayTime
fld = 'CardiacTriggerDelayTime';
if ~isfield(h{1}, 'CardiacTriggerDelayTimes') && nVol>1 && isfield(h{1}, fld)
    if numel(h) == 1 % multi frames
        iFrames = 1:dim(3):dim(3)*nVol;
        if isfield(h{1}, 'SortFrames'), iFrames = h{1}.SortFrames(iFrames); end
        s2 = struct(fld, nan(1,nVol));
        s2 = dicm_hdr(h{1}, s2, iFrames);
        tt = s2.(fld);
    else
        tt = zeros(1, nVol);
        inc = numel(h) / nVol;
        for j = 1:nVol
            tt(j) = tryGetField(h{(j-1)*inc+1}, fld, 0);
        end
    end
    if ~all(diff(tt)==0), h{1}.CardiacTriggerDelayTimes = tt; end
end

% Get EchoTime for each vol
if ~isfield(h{1}, 'EchoTimes') && nVol>1 && isfield(h{1}, 'EchoTime')
    if numel(h) == 1 % 4D multi frames
        iFrames = 1:dim(3):dim(3)*nVol;
        if isfield(h{1}, 'SortFrames'), iFrames = h{1}.SortFrames(iFrames); end
        s2 = struct('EffectiveEchoTime', nan(1,nVol));
        s2 = dicm_hdr(h{1}, s2, iFrames);
        ETs = s2.EffectiveEchoTime;
    else % regular dicom. Vida done previously
        ETs = zeros(1, nVol);
        inc = numel(h) / nVol;
        for j = 1:nVol
            ETs(j) = tryGetField(h{(j-1)*inc+1}, 'EchoTime', 0);
        end
    end
    if ~all(diff(ETs)==0), h{1}.EchoTimes = ETs; end
end

% set TR and slice timing related info before re-orient
[h, nii.hdr] = sliceTiming(h, nii.hdr);
nii.hdr.xyzt_units = xyz_unit + nii.hdr.xyzt_units; % normally: mm (2) + sec (8)
s = h{1};

% Store motion parameters for MoCo series
if all(isfield(s, {'RBMoCoTrans' 'RBMoCoRot'})) && nVol>1
    inc = numel(h) / nVol;
    trans = zeros(nVol, 3);
    rotat = zeros(nVol, 3);
    for j = 1:nVol
        trans(j,:) = tryGetField(h{(j-1)*inc+1}, 'RBMoCoTrans', [0 0 0]);
        rotat(j,:) = tryGetField(h{(j-1)*inc+1}, 'RBMoCoRot',   [0 0 0]);
    end
    s.RBMoCoTrans = trans;
    s.RBMoCoRot = rotat;
end

% Store FrameReferenceTime: seen in Philips PET
if isfield(s, 'FrameReferenceTime') && nVol>1
    inc = numel(h) / nVol;
    vTime = zeros(1, nVol);
    dict = dicm_dict('', 'FrameReferenceTime');
    for j = 1:nVol
        s2 = dicm_hdr(h{(j-1)*inc+1}.Filename, dict);
        vTime(j) = tryGetField(s2, 'FrameReferenceTime', 0);
    end
    if vTime(1) > vTime(end) % could also re-read sorted h{i}{1}
        vTime = flip(vTime);
        nii.img = flip(nii.img, 4);
    end
    s.VolumeTiming = vTime / 1000; % ms to seconds
end

% dim_info byte: freq_dim, phase_dim, slice_dim low to high, each 2 bits
[phPos, iPhase] = phaseDirection(s); % phPos relative to image in FSL feat!
if     iPhase == 2, fps_bits = [1 4 16];
elseif iPhase == 1, fps_bits = [4 1 16]; 
else,               fps_bits = [0 0 16];
end

% Reorient if MRAcquisitionType==3D || isDTI && nSL>1
% If FSL etc can read dim_info for STC, we can always reorient.
[~, perm] = sort(ixyz); % may permute 3 dimensions in this order
if (strcmp(tryGetField(s, 'MRAcquisitionType', ''), '3D') || s.isDTI) && ...
        dim(3)>1 && (~isequal(perm, 1:3)) % skip if already XYZ order
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

flp = R(ixyz+[0 3 6])<0; % flip an axis if true
d = det(R(:,1:3)) * prod(1-flp*2); % det after all 3 axis positive
if (d>0 && pf.lefthand) || (d<0 && ~pf.lefthand)
    flp(1) = ~flp(1); % left or right storage
end
rotM = diag([1-flp*2 1]); % 1 or -1 on diagnal
rotM(1:3, 4) = (dim-1) .* flp; % 0 or dim-1
R = R / rotM; % xform matrix after flip
for k = 1:3, if flp(k), nii.img = flip(nii.img, k); end; end
if flp(iPhase), phPos = ~phPos; end
if isfield(s, 'bvec'), s.bvec(:, flp) = -s.bvec(:, flp); end
if flp(iSL) && isfield(s, 'SliceTiming') % slices flipped
    s.SliceTiming = flip(s.SliceTiming);
    sc = nii.hdr.slice_code;
    if sc>0, nii.hdr.slice_code = sc+mod(sc,2)*2-1; end % 1<->2, 3<->4, 5<->6
end

% sform
frmCode = all(isfield(s, {'ImageOrientationPatient' 'ImagePositionPatient'}));
frmCode = tryGetField(s, 'TemplateSpace', frmCode);
nii.hdr.sform_code = frmCode; % 1: SCANNER_ANAT
nii.hdr.srow_x = R(1,:);
nii.hdr.srow_y = R(2,:);
nii.hdr.srow_z = R(3,:);

R0 = normc(R(:, 1:3));
sNorm = null(R0(:, setdiff(1:3, iSL))');
if sign(sNorm(ixyz(iSL))) ~= sign(R(ixyz(iSL),iSL)), sNorm = -sNorm; end
shear = norm(R0(:,iSL)-sNorm) > 0.01;
R0(:,iSL) = sNorm;

% qform
nii.hdr.qform_code = frmCode;
nii.hdr.qoffset_x = R(1,4);
nii.hdr.qoffset_y = R(2,4);
nii.hdr.qoffset_z = R(3,4);
[q, nii.hdr.pixdim(1)] = dcm2quat(R0); % 3x3 dir cos matrix to quaternion
nii.hdr.quatern_b = q(2);
nii.hdr.quatern_c = q(3);
nii.hdr.quatern_d = q(4);

if shear
    nii.hdr.hdrTilt = nii.hdr; % copy all hdr for tilt version
    nii.hdr.qform_code = 0; % disable qform
    gantry = tryGetField(s, 'GantryDetectorTilt', 0);
    nii.hdr.hdrTilt.pixdim(iSL+1) = norm(R(1:3, iSL)) * cosd(gantry);
    R(1:3, iSL) = sNorm * nii.hdr.hdrTilt.pixdim(iSL+1);
    nii.hdr.hdrTilt.srow_x = R(1,:);
    nii.hdr.hdrTilt.srow_y = R(2,:);
    nii.hdr.hdrTilt.srow_z = R(3,:);
end

% store some possibly useful info in descrip and other text fields
str = tryGetField(s, 'ImageComments', '');
if isType(s, '\MOCO\'), str = ''; end % useless for MoCo
foo = tryGetField(s, 'StudyComments');
if ~isempty(foo), str = [str ';' foo]; end
str = [str ';' sscanf(s.Manufacturer, '%s', 1)];
foo = tryGetField(s, 'ProtocolName');
if ~isempty(foo), str = [str ';' foo]; end
nii.hdr.aux_file = str; % char[24], info only
seq = asc_header(s, 'tSequenceFileName'); % like '%SiemensSeq%\ep2d_bold'
if isempty(seq)
    seq = tryGetField(s, 'ScanningSequence'); 
else
    ind = strfind(seq, '\');
    if ~isempty(ind), seq = seq(ind(end)+1:end); end % like 'ep2d_bold'
end
if pf.save_patientName, nii.hdr.db_name = PatientName(s); end % char[18]
nii.hdr.intent_name = seq; % char[16], meaning of the data

foo = tryGetField(s, 'AcquisitionDateTime');
descrip = sprintf('time=%s;', foo(1:min(18,end))); 
TE0 = asc_header(s, 'alTE[0]')/1000; % s.EchoTime stores only 1 TE
if isempty(TE0), TE0 = tryGetField(s, 'EchoTime'); end % GE, philips
TE1 = asc_header(s, 'alTE[1]')/1000;
if ~isempty(TE1), s.SecondEchoTime = TE1; s.EchoTime = TE0; end
dTE = abs(TE1 - TE0); % TE difference
if isempty(dTE) && tryGetField(s, 'NumberOfEchoes', 1)>1
    dTE = tryGetField(s, 'SecondEchoTime') - TE0; % need to update
end
if ~isempty(dTE)
    descrip = sprintf('dTE=%.4g;%s', dTE, descrip);
    s.deltaTE = dTE;
end
if ~isempty(TE0), descrip = sprintf('TE=%.4g;%s', TE0, descrip); end

% Get dwell time
if ~strcmp(tryGetField(s, 'MRAcquisitionType'), '3D') && ~isempty(iPhase)
    dwell = double(tryGetField(s, 'EffectiveEchoSpacing')) / 1000; % GE
    % http://www.spinozacentre.nl/wiki/index.php/NeuroWiki:Current_developments
    if isempty(dwell) % Philips
        wfs = tryGetField(s, 'WaterFatShift');
        epiFactor = tryGetField(s, 'EPIFactor');
        dwell = wfs ./ (434.215 * (double(epiFactor)+1)) * 1000;
    end
    if isempty(dwell) % Siemens
        hz = csa_header(s, 'BandwidthPerPixelPhaseEncode');
        dwell = 1000 ./ hz / dim(iPhase); % in ms
    end
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
    if isempty(dwell) && strncmpi(s.Manufacturer, 'UIH', 3)
        try dwell = s.AcquisitionDuration; % not confirmed yet
        catch
            try dwell = s.MRVFrameSequence.Item_1.AcquisitionDuration; end
        end
        if ~isempty(dwell), dwell = dwell / dim(iPhase); end
    end
    
    if ~isempty(dwell)
        s.EffectiveEPIEchoSpacing = dwell;
        % https://github.com/rordenlab/dcm2niix/issues/130
        readout = dwell * (dim(iPhase)- 1) / 1000; % since 170923
        s.ReadoutSeconds = readout;
        descrip = sprintf('readout=%.3g;dwell=%.3g;%s', readout, dwell, descrip);
    end
end

if ~isempty(iPhase)
    if isempty(phPos), pm = '?'; b67 = 0;
    elseif phPos,      pm = '';  b67 = 1;
    else,              pm = '-'; b67 = 2;
    end
    nii.hdr.dim_info = nii.hdr.dim_info + b67*64;
    axes = 'xyz'; % actually ijk
    phDir = [pm axes(iPhase)];
    s.UnwarpDirection = phDir;
    descrip = sprintf('phase=%s;%s', phDir, descrip);
end
nii.hdr.descrip = descrip; % char[80], drop from end if exceed

% slope and intercept: apply to img if no rounding error 
sclApplied = tryGetField(s, 'ApplyRescale', false);
if any(isfield(s, {'RescaleSlope' 'RescaleIntercept'})) && ~sclApplied
    slope = tryGetField(s, 'RescaleSlope', 1); 
    inter = tryGetField(s, 'RescaleIntercept', 0);
    if isfield(s, 'MRScaleSlope') % Philips: see PAR file for detail
        inter = inter / (slope * double(s.MRScaleSlope));
        slope = 1 / double(s.MRScaleSlope);
    end
    val = sort(double([max(nii.img(:)) min(nii.img(:))]) * slope + inter);
    dClass = class(nii.img);
    if isa(nii.img, 'float') || (mod(slope,1)==0 && mod(inter,1)==0 ... 
            && val(1)>=intmin(dClass) && val(2)<=intmax(dClass))
        nii.img = nii.img * slope + inter; % apply to img if no rounding
    else
        nii.hdr.scl_slope = slope;
        nii.hdr.scl_inter = inter;
    end
elseif sclApplied && isfield(s, 'MRScaleSlope')
    slope = tryGetField(s, 'RescaleSlope', 1) * s.MRScaleSlope; 
    nii.img = nii.img / slope;
end

if pf.scale_16bit && any(nii.hdr.datatype==[4 512]) % like dcm2niix
    if nii.hdr.datatype == 4 % int16
        scale = floor(32000 / double(max(abs(nii.img(:)))));
    else % datatype==512 % uint16
        scale = floor(64000 / double((max(nii.img(:)))));
    end
    nii.img = nii.img * scale;
    nii.hdr.scl_slope = nii.hdr.scl_slope / scale;
end
h{1} = s;

% Possible patient position: HFS/HFP/FFS/FFP / HFDR/HFDL/FFDR/FFDL
% Seems dicom takes care of this, and maybe nothing needs to do here.
% patientPos = tryGetField(s, 'PatientPosition', '');

flds = { % store for nii.ext and json
  'ConversionSoftware' 'SeriesNumber' 'SeriesDescription' 'ImageType' 'Modality' ...
  'AcquisitionDateTime' 'bval' 'bvec' 'VolumeTiming' ...
  'ReadoutSeconds' 'DelayTimeInTR' 'SliceTiming' 'RepetitionTime' ...
  'UnwarpDirection' 'EffectiveEPIEchoSpacing' 'EchoTime' 'deltaTE' 'EchoTimes' ...
  'SecondEchoTime' 'InversionTime' 'CardiacTriggerDelayTimes' ...
  'PatientName' 'PatientSex' 'PatientAge' 'PatientSize' 'PatientWeight' ...
  'PatientPosition' 'SliceThickness' 'FlipAngle' 'RBMoCoTrans' 'RBMoCoRot' ...
  'Manufacturer' 'SoftwareVersion' 'MRAcquisitionType' ...
  'InstitutionName' 'InstitutionAddress' 'DeviceSerialNumber' ...
  'ScanningSequence' 'SequenceVariant' 'ScanOptions' 'SequenceName' ...
  'TableHeight' 'DistanceSourceToPatient' 'DistanceSourceToDetector'};
if ~pf.save_patientName, flds(strcmp(flds, 'PatientName')) = []; end
for i = 1:numel(flds)
    if ~isfield(s, flds{i}), continue; end
    nii.json.(flds{i}) = s.(flds{i});
end

%% Subfunction, reshape mosaic into volume, remove padded zeros
function vol = mos2vol(mos, nSL, isUIH)
nMos = ceil(sqrt(nSL)); % nMos x nMos tiles for Siemens, maybe nMos x nMos-1 UIH
[nr, nc, nv] = size(mos); % number of row, col and vol in mosaic
nr = nr / nMos; nc = nc / nMos; % number of row and col in slice
if isUIH && nMos*(nMos-1)>=nSL, nc = size(mos,2) / (nMos-1); end % one col less
vol = zeros([nr nc nSL nv], class(mos));
for i = 1:nSL
    r =    mod(i-1, nMos) * nr + (1:nr); % 2nd slice is tile(2,1)
    c = floor((i-1)/nMos) * nc + (1:nc);
    vol(:, :, i, :) = mos(r, c, :);
end

%% subfunction: set slice timing related info
function [h, hdr] = sliceTiming(h, hdr)
s = h{1};
TR = tryGetField(s, 'RepetitionTime'); % in ms
if isempty(TR), TR = tryGetField(s, 'TemporalResolution'); end
if isempty(TR), return; end
hdr.pixdim(5) = TR / 1000;
if tryGetField(s, 'isDTI', 0), return; end
hdr.xyzt_units = 8; % seconds
if hdr.dim(5)<3, return; end % skip structual, fieldmap etc

nSL = hdr.dim(4);
delay = asc_header(s, 'lDelayTimeInTR')/1000; % in ms now
if isempty(delay), delay = 0;
else, h{1}.DelayTimeInTR = delay;
end
TA = TR - delay;

% Siemens mosaic
t = csa_header(s, 'MosaicRefAcqTimes'); % in ms
if ~isempty(t) && isfield(s, 'LastFile') && max(t)-min(t)>TA % MB wrong vol 1
    try t = mb_slicetiming(s, TA); end %#ok<*TRYNC>
end

if isempty(t) && strncmpi(s.Manufacturer, 'UIH', 3)
    t = zeros(nSL, 1);
    if isfield(s, 'MRVFrameSequence') % mosaic
        for j = 1:nSL
            item = sprintf('Item_%g', j);
            str = s.MRVFrameSequence.(item).AcquisitionDateTime;
            t(j) = datenum(str, 'yyyymmddHHMMSS.fff');
        end
    else
        dict = dicm_dict('', 'AcquisitionDateTime');
        for j = 1:nSL
            s1 = dicm_hdr(h{j}.Filename, dict);
            t(j) = datenum(s1.AcquisitionDateTime, 'yyyymmddHHMMSS.fff');
        end
    end
    t = (t - min(t)) * 24 * 3600 * 1000; % day to ms
end

if isempty(t) && isfield(s, 'RTIA_timer') % GE
    t = zeros(nSL, 1);
    nFile = numel(h);
    % seen problem for 1st vol, so use last vol
    for j = 1:nSL, t(j) = tryGetField(h{nFile-nSL+j}, 'RTIA_timer', 0); end
    if all(diff(t)==0), t = []; 
    else
        t = t - min(t);
        ma = max(t) / TA;
        if ma>1, t = t / 10; % was ms*10, old dicom
        elseif ma<1e-3, t = t * 1000; % was sec, new dicom?
        end
    end
end

if isempty(t) && isfield(s, 'ProtocolDataBlock') && ...
        isfield(s.ProtocolDataBlock, 'SLICEORDER') % GE with invalid RTIA_timer
    SliceOrder = s.ProtocolDataBlock.SLICEORDER;
    t = (0:nSL-1)' * TA/nSL;
    if strcmp(SliceOrder, '1') % 0/1: sequential/interleaved based on limited data
        t([1:2:nSL 2:2:nSL]) = t;
    elseif ~strcmp(SliceOrder, '0')
        errorLog(['Unknown SLICEORDER (' SliceOrder ') for ' s.NiftiName]);
        return;
    end
end

% Siemens multiframe: read TimeAfterStart from last file
if isempty(t) && strncmpi(s.Manufacturer, 'SIEMENS', 7)
    % Use TimeAfterStart, not FrameAcquisitionDatetime. See
    % https://github.com/rordenlab/dcm2niix/issues/240#issuecomment-433036901
    try 
        s.PerFrameFunctionalGroupsSequence.Item_1.CSAImageHeaderInfo.Item_1.TimeAfterStart;
        % s2 = struct('FrameAcquisitionDatetime', {cell(nSL,1)});
        % s2 = dicm_hdr(h{end}, s2, 1:nSL); % avoid 1st volume
        % t = datenum(s2.FrameAcquisitionDatetime, 'yyyymmddHHMMSS.fff');
        % t = (t - min(t)) * 24 * 3600 * 1000; % day to ms
        s2 = struct('TimeAfterStart', nan(1, nSL));
        s2 = dicm_hdr(h{end}, s2, 1:nSL); % avoid 1st volume
        t = s2.TimeAfterStart; % in secs
        t = (t - min(t)) * 1000;
    end
end

% Get slice timing for non-mosaic Siemens file. Could remove Manufacturer
% check, but GE/Philips AcquisitionTime seems useless
if isempty(t) && ~tryGetField(s, 'isMos', 0) && strncmpi(s.Manufacturer, 'SIEMENS', 7)
    dict = dicm_dict('', {'AcquisitionDateTime' 'AcquisitionDate' 'AcquisitionTime'});
    t = zeros(nSL, 1);
    for j = 1:nSL
        s1 = dicm_hdr(h{j}.Filename, dict);
        try str = s1.AcquisitionDateTime;
        catch
            try str = [s1.AcquisitionDate s1.AcquisitionTime];
            catch, t = []; break;
            end
        end
        t(j) = datenum(str, 'yyyymmddHHMMSS.fff');
    end
    t = (t - min(t)) * 24 * 3600 * 1000; % day to ms
end

if isempty(t) % non-mosaic Siemens: create 't' based on ucMode
    ucMode = asc_header(s, 'sSliceArray.ucMode'); % 1/2/4: Asc/Desc/Inter
    if isempty(ucMode), return; end
    t = (0:nSL-1)' * TA/nSL;
    if ucMode==2
        t = t(nSL:-1:1);
    elseif ucMode==4
        if mod(nSL,2), t([1:2:nSL 2:2:nSL]) = t;
        else, t([2:2:nSL 1:2:nSL]) = t;
        end
    end
    if asc_header(s, 'sSliceArray.ucImageNumb'), t = t(nSL:-1:1); end % rev-num
end

if numel(t)<2, return; end
t = t - min(t); % it may be relative to 1st slice

t1 = sort(t);
dur = sum(diff(t1)) / (nSL-1);
dif = sum(diff(t))  / (nSL-1);
if dur==0 || (t1(end)>TA), sc = 0; % no useful info, or bad timing MB
elseif t1(1) == t1(2), sc = 0; t1 = unique(t1); % was 7 for MB but error in FS
elseif abs(dif-dur)<1e-3, sc = 1; % ascending
elseif abs(dif+dur)<1e-3, sc = 2; % descending
elseif t(1)<t(3) % ascending interleaved
    if t(1)<t(2), sc = 3; % odd slices first
    else, sc = 5; % Siemens even number of slices
    end
elseif t(1)>t(3) % descending interleaved
    if t(1)>t(2), sc = 4;
    else, sc = 6; % Siemens even number of slices
    end
else, sc = 0; % unlikely to reach
end

h{1}.SliceTiming = 0.5 - t/TR; % as for FSL custom timing
hdr.slice_code = sc;
hdr.slice_end = nSL-1; % 0-based, slice_start default to 0
hdr.slice_duration = min(diff(t1))/1000;

%% subfunction: extract bval & bvec, store in 1st header
function [h, nii] = get_dti_para(h, nii)
nDir = nii.hdr.dim(5);
if nDir<2, return; end
bval = nan(nDir, 1);
bvec = nan(nDir, 3);
s = h{1};
ref = 1; % not coded by Manufacturer, but by how we get bvec (since 190213).
% With this method, the code will get correct ref if bvec ref scheme changes 
% some day, e.g. if GE saves (0018,9089) in the future.
% ref = 0: IMG, UIH for now;
% ref = 1: PCS, Siemens/Philips or unknown vendor, this is default
% ref = 2: FPS, Bruker for now (need to verify)
% ref = 3: FPS_GE, confusing signs
%  Since some dicom do not save bval or bvec for bval=0 case, it is better to
%  loop all directions to detect 'ref'.

nSL = nii.hdr.dim(4);
nFile =  numel(h);
if isfield(s, 'bvec_original') % from BV or PAR file
    bval = s.B_value;
    bvec = s.bvec_original;
    % ref = tryGetField(s, 'bvec_ref', 1); % not implemented yet
elseif isfield(s, 'PerFrameFunctionalGroupsSequence')
    if nFile== 1 % all vol in 1 file, for Philips/Bruker
        iDir = 1:nSL:nSL*nDir;
        if isfield(s, 'SortFrames'), iDir = s.SortFrames(iDir); end
        s2 = struct('B_value', bval', 'DiffusionGradientDirection', bvec', ...
            'MRDiffusionGradOrientation', bvec');
        s2 = dicm_hdr(s, s2, iDir); % call search_MF_val
        bval = s2.B_value';
        bvec = s2.DiffusionGradientDirection';
        if all(isnan(bvec(:)))
            bvec = s2.MRDiffusionGradOrientation';
            if ~all(isnan(bvec(:))), ref = 0; end % UIH
        end
        if isfield(s, 'Private_0177_1100') && all(isnan(bvec(:))) % Bruker
            str = char(s.Private_0177_1100');
            expr = 'DwGradVec\s*=\s*\(\s*(\d+),\s*(\d+)\s*\)\s+'; % DwDir incomplete            
            [C, ind] = regexp(str, expr, 'tokens', 'end', 'once');
            if isequal(str2double(C), [nDir 3])
                ref = 2;
                bvec = sscanf(str(ind:end), '%f', nDir*3);
                bvec = normc(reshape(bvec, 3, []))';
                [~, i] = sort(iDir); bvec(i,:) = bvec;
            end
        end
    elseif nDir == nFile % 1 vol per file, e.g. Siemens/UIH
        for i = 1:nDir
            bval(i) = MF_val('B_value', h{i}, 1);
            a = MF_val('DiffusionGradientDirection', h{i}, 1);
            if isempty(a)
                a = MF_val('MRDiffusionGradOrientation', h{i}, 1);
                if ~isempty(a), ref = 0; end % UIH
            end
            if ~isempty(a), bvec(i,:) = a; end
        end
    else
        errorLog('Number of files and diffusion directions not match');
        return;
    end
elseif nFile>1 % multiple files: order already in slices then volumes
    dict = dicm_dict(s.Manufacturer, {'B_value' 'B_factor' 'SlopInt_6_9' ...
       'DiffusionDirectionX' 'DiffusionDirectionY' 'DiffusionDirectionZ' ...
       'MRDiffusionGradOrientation'});
    iDir = (0:nDir-1) * nFile/nDir + 1; % could be mosaic or multiframe
    for j = 1:nDir % no bval/bvec for B0 volume
        s2 = h{iDir(j)};
        val = tryGetField(s2, 'B_value');
        if val == 0, continue; end
        vec = tryGetField(s2, 'DiffusionGradientDirection'); % Siemens/Philips
        if isempty(val) || isempty(vec) % GE/UIH
            s2 = dicm_hdr(s2.Filename, dict);
        end
        
        if isempty(val), val = tryGetField(s2, 'B_factor'); end % old Philips
        if isempty(val) && isfield(s2, 'SlopInt_6_9') % GE
            val = mod(s2.SlopInt_6_9(1), 100000);
        end
        if isempty(val), val = 0; end % may be B_value=0
        bval(j) = val;
        
        if isempty(vec)
            vec = tryGetField(s2, 'MRDiffusionGradOrientation');
            if ref==1 && ~isempty(vec), ref = 0; end % UIH
        end
        if isempty(vec) % GE, old Philips
            vec(1) = tryGetField(s2, 'DiffusionDirectionX', 0);
            vec(2) = tryGetField(s2, 'DiffusionDirectionY', 0);
            vec(3) = tryGetField(s2, 'DiffusionDirectionZ', 0);
            if ref==1 && strncmpi(s.Manufacturer, 'GE', 2), ref = 3; end
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
    % Remove computed ADC: it may not be the last vol
    ind = find(bval>1e-4 & sum(abs(bvec),2)<1e-4);
    if ~isempty(ind) % DiffusionDirectionality: 'ISOTROPIC'
        bval(ind) = [];
        bvec(ind,:) = [];
        nii.img(:,:,:,ind) = [];
        nii.hdr.dim(5) = nDir - numel(ind);
    end
end

h{1}.bvec_original = bvec; % original from dicom

% http://wiki.na-mic.org/Wiki/index.php/NAMIC_Wiki:DTI:DICOM_for_DWI_and_DTI
[ixyz, R] = xform_mat(s, nii.hdr.dim(2:4)); % R takes care of slice dir
if ref == 1 % PCS: Siemens/Philips
    R = normc(R(:, 1:3));
    bvec = bvec * R; % dicom plane to image plane
elseif ref == 2 % FPS: Bruker in Freq/Phase/Slice reference
    if strcmp(tryGetField(s, 'InPlanePhaseEncodingDirection'), 'ROW')
        bvec = bvec(:, [2 1 3]);
    end
elseif ref == 3 % FPS: GE in Freq/Phase/Slice reference
    if strcmp(tryGetField(s, 'InPlanePhaseEncodingDirection'), 'ROW')
        bvec = bvec(:, [2 1 3]);
        bvec(:, 2) = -bvec(:, 2); % because of transpose?
        if ixyz(3)<3
            errorLog(sprintf(['%s: bvec sign for non-axial acquisition with' ...
             ' ROW phase direction not tested.\n Please check ' ...
             'the result and report problem to author.'], s.NiftiName));
        end
    end
    flp = R(ixyz+[0 3 6]) < 0; % negative sign
    flp(3) = ~flp(3); % GE slice dir opposite to LPS for all sag/cor/tra
    if ixyz(3)==1, flp(1) = ~flp(1); end % Sag slice: don't know why
    bvec(:, flp) = -bvec(:, flp);
end

% bval may need to be scaled by norm(bvec)
% https://mrtrix.readthedocs.io/en/latest/concepts/dw_scheme.html
nm = sum(bvec .^ 2, 2);
if any(nm>0.01 & abs(nm-1)>0.01) % this check may not be necessary
    h{1}.bval_original = bval; % before scaling
    bval = bval .* nm;
    nm(nm<1e-4) = 1; % remove zeros after correcting bval
    bvec = bsxfun(@rdivide, bvec, sqrt(nm));
end

h{1}.bval = bval; % store all into header of 1st file
h{1}.bvec = bvec; % computed bvec in image ref

%% subfunction: save bval & bvec files
function save_dti_para(s, fname)
if ~isfield(s, 'bvec') || all(s.bvec(:)==0), return; end
if isfield(s, 'bval')
    fid = fopen([fname '.bval'], 'w');
    fprintf(fid, '%.5g\t', s.bval); % one row
    fclose(fid);
end

str = repmat('%9.6f\t', 1, size(s.bvec,1));
fid = fopen([fname '.bvec'], 'w');
fprintf(fid, [str '\n'], s.bvec); % 3 rows by # direction cols
fclose(fid);

%% Subfunction, return a parameter from CSA Image/Series header
function val = csa_header(s, key)
val = [];
fld = 'CSAImageHeaderInfo';
if isfield(s, fld) && isfield(s.(fld), key), val = s.(fld).(key); return; end
if isfield(s, key), val = s.(key); return; end % general tag: 2nd choice
fld = 'CSASeriesHeaderInfo';
if isfield(s, fld) && isfield(s.(fld), key), val = s.(fld).(key); return; end

%% Subfunction, Convert 3x3 direction cosine matrix to quaternion
% Simplied from Quaternions by Przemyslaw Baranski 
function [q, proper] = dcm2quat(R)
% [q, proper] = dcm2quat(R)
% Retrun quaternion abcd from normalized matrix R (3x3)
proper = sign(det(R));
if proper<0, R(:,3) = -R(:,3); end

q = sqrt([1 1 1; 1 -1 -1; -1 1 -1; -1 -1 1] * diag(R) + 1) / 2;
if ~isreal(q(1)), q(1) = 0; end % if trace(R)+1<0, zero it
[mx, ind] = max(q);
mx = mx * 4;

if ind == 1
    q(2) = (R(3,2) - R(2,3)) /mx;
    q(3) = (R(1,3) - R(3,1)) /mx;
    q(4) = (R(2,1) - R(1,2)) /mx;
elseif ind ==  2
    q(1) = (R(3,2) - R(2,3)) /mx;
    q(3) = (R(1,2) + R(2,1)) /mx;
    q(4) = (R(3,1) + R(1,3)) /mx;
elseif ind == 3
    q(1) = (R(1,3) - R(3,1)) /mx;
    q(2) = (R(1,2) + R(2,1)) /mx;
    q(4) = (R(2,3) + R(3,2)) /mx;
elseif ind == 4
    q(1) = (R(2,1) - R(1,2)) /mx;
    q(2) = (R(3,1) + R(1,3)) /mx;
    q(3) = (R(2,3) + R(3,2)) /mx;
end
if q(1)<0, q = -q; end % as MRICron

%% Subfunction: get dicom xform matrix and related info
function [ixyz, R, pixdim, xyz_unit] = xform_mat(s, dim)
haveIOP = isfield(s, 'ImageOrientationPatient');
if haveIOP, R = reshape(s.ImageOrientationPatient, 3, 2);
else, R = [1 0 0; 0 1 0]';
end
R(:,3) = cross(R(:,1), R(:,2)); % right handed, but sign may be wrong
foo = abs(R);
[~, ixyz] = max(foo); % orientation info: perm of 1:3
if ixyz(2) == ixyz(1), foo(ixyz(2),2) = 0; [~, ixyz(2)] = max(foo(:,2)); end
if any(ixyz(3) == ixyz(1:2)), ixyz(3) = setdiff(1:3, ixyz(1:2)); end
if nargout<2, return; end
iSL = ixyz(3); % 1/2/3 for Sag/Cor/Tra slice
signSL = sign(R(iSL, 3));

try 
    pixdim = s.PixelSpacing([2 1]);
    xyz_unit = 2; % mm
catch
    pixdim = [1 1]'; % fake
    xyz_unit = 0; % no unit information
end
thk = tryGetField(s, 'SpacingBetweenSlices');
if isempty(thk), thk = tryGetField(s, 'SliceThickness', pixdim(1)); end
pixdim = [pixdim; thk];
haveIPP = isfield(s, 'ImagePositionPatient');
if haveIPP, ipp = s.ImagePositionPatient; else, ipp = -(dim'.* pixdim)/2; end
% Next is almost dicom xform matrix, except mosaic trans and unsure slice_dir
R = [R * diag(pixdim) ipp];

% rest are former: R = verify_slice_dir(R, s, dim, iSL)
if dim(3)<2, return; end % don't care direction for single slice

if s.Columns>dim(1) && ~strncmpi(s.Manufacturer, 'UIH', 3) % Siemens mosaic
    R(:,4) = R * [ceil(sqrt(dim(3))-1)*dim(1:2)/2 0 1]'; % real slice location
    vec = csa_header(s, 'SliceNormalVector'); % mosaic has this
    if ~isempty(vec) % exist for all tested data
        if sign(vec(iSL)) ~= signSL, R(:,3) = -R(:,3); end
        return;
    end
elseif isfield(s, 'LastFile') && isfield(s.LastFile, 'ImagePositionPatient')
    R(:, 3) = (s.LastFile.ImagePositionPatient - R(:,4)) / (dim(3)-1);
    thk = norm(R(:,3)); % override slice thickness if it is off
    if abs(pixdim(3)-thk)/thk > 0.01, pixdim(3) = thk; end
    return; % almost all non-mosaic images return from here
end

% Rest of the code is almost unreachable
if isfield(s, 'CSASeriesHeaderInfo') % Siemens both mosaic and regular
    ori = {'Sag' 'Cor' 'Tra'}; ori = ori{iSL};
    sNormal = asc_header(s, ['sSliceArray.asSlice[0].sNormal.d' ori]);
    if asc_header(s, ['sSliceArray.ucImageNumb' ori]), sNormal = -sNormal; end
    if sign(sNormal) ~= signSL, R(:,3) = -R(:,3); end
    if ~isempty(sNormal), return; end
end

pos = []; % volume center we try to retrieve
if isfield(s, 'LastScanLoc') && isfield(s, 'FirstScanLocation') % GE
    pos = (s.LastScanLoc + s.FirstScanLocation) / 2; % mid-slice center
    if iSL<3, pos = -pos; end % RAS convention!
    pos = pos - R(iSL, 1:2) * (dim(1:2)'-1)/2; % mid-slice location
end

if isempty(pos) && isfield(s, 'Stack') % Philips
    ori = {'RL' 'AP' 'FH'}; ori = ori{iSL};
    pos = tryGetField(s.Stack.Item_1, ['MRStackOffcentre' ori]);
    pos = pos - R(iSL, 1:2) * dim(1:2)'/2; % mid-slice location
end

if isempty(pos) % keep right-handed, and warn user
    if haveIPP && haveIOP
        errorLog(['Please check whether slices are flipped: ' s.NiftiName]);
    else
        errorLog(['No orientation/location information found for ' s.NiftiName]);
    end
elseif sign(pos-R(iSL,4)) ~= signSL % same direction?
    R(:,3) = -R(:,3);
end

%% Subfunction: get a parameter in CSA series ASC header: MrPhoenixProtocol
function val = asc_header(s, key)
val = []; 
csa = 'CSASeriesHeaderInfo';
if ~isfield(s, csa), return; end
if isfield(s.(csa), 'MrPhoenixProtocol')
    str = s.(csa).MrPhoenixProtocol;
elseif isfield(s.(csa), 'MrProtocol') % older version dicom
    str = s.(csa).MrProtocol;
else % in case of failure to decode CSA header
    str = char(s.(csa)(:)');
    str = regexp(str, 'ASCCONV BEGIN(.*)ASCCONV END', 'tokens', 'once');
    if isempty(str), return; end
    str = str{1};
end

% tSequenceFileName  = ""%SiemensSeq%\gre_field_mapping""
expr = ['\n' regexptranslate('escape', key) '.*?=\s*(.*?)\n'];
str = regexp(str, expr, 'tokens', 'once');
if isempty(str), return; end
str = strtrim(str{1});

if strncmp(str, '""', 2) % str parameter
    val = str(3:end-2);
elseif strncmp(str, '"', 1) % str parameter for version like 2004A
    val = str(2:end-1);
elseif strncmp(str, '0x', 2) % hex parameter, convert to decimal
    val = sscanf(str(3:end), '%x', 1);
else % decimal
    val = sscanf(str, '%g', 1);
end

%% Subfunction: return matlab decompress command if the file is compressed
function func = compress_func(fname)
func = '';
if any(regexpi(fname, '\.mgz$')), return; end
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
        if rstFmt == 4
            if verLessThan('matlab','9.4')
                fprintf('BIDS conversion is easier with MATLAB R2018a or more.\n');
            end
            if get(hs.gzip,  'Value')
                rstFmt = 'bids';
            else
                rstFmt = 'bidsnii';
            end % 1 or 3
        else
            if get(hs.gzip,  'Value'), rstFmt = rstFmt + 1; end % 1 or 3
            if get(hs.rst3D, 'Value'), rstFmt = rstFmt + 4; end % 4 to 7
        end
        set(h, 'Enable', 'off', 'string', 'Conversion in progress');
        clnObj = onCleanup(@()set(h, 'Enable', 'on', 'String', 'Start conversion')); 
        drawnow;
        dicm2nii(src, dst, rstFmt);
        
        % save parameters if last conversion succeed
        pf = getpref('dicm2nii_gui_para');
        pf.rstFmt = get(hs.rstFmt, 'Value');
        pf.rst3D = get(hs.rst3D, 'Value');
        pf.gzip = get(hs.gzip, 'Value');
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
        src = jFileChooser(folder, 'Select folders/files to convert');
        if isnumeric(src), return; end
        set(hs.fig, 'UserData', src);
        txt = src{1};
        if numel(src) > 1,  txt = [txt ' {and more}']; end 
        hs.src.Text = txt;
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
                'Last updated on %s\n'], getVersion);
            helpdlg(str, 'About dicm2nii')
        elseif item == 2 % license
            try
                str = fileread([fileparts(mfilename('fullpath')) '/LICENSE']);
            catch
                str = 'license.txt file not found';
            end
            helpdlg(strtrim(str), 'License')
        elseif item == 3
            doc dicm2nii;
        elseif item == 4
            checkUpdate(mfilename);
        elseif item == 5
            web('www.sciencedirect.com/science/article/pii/S0165027016300073', '-browser');
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
fSz = 9; % + ~(ispc || ismac);
clr = [1 1 1]*206/256;
clrButton = [1 1 1]*216/256;
cb = @(cmd) {@gui_callback cmd fh}; % callback shortcut
uitxt = @(txt,pos) uicontrol('Style', 'text', 'Position', pos, 'FontSize', fSz, ...
    'HorizontalAlignment', 'left', 'String', txt, 'BackgroundColor', clr);
getpf = @(p,dft)getpref('dicm2nii_gui_para', p, dft);
chkbox = @(parent,val,str,cbk,tip) uicontrol(parent, 'Style', 'checkbox', ...
    'FontSize', fSz, 'HorizontalAlignment', 'left', 'BackgroundColor', clr, ...
    'Value', val, 'String', str, 'Callback', cbk, 'TooltipString', tip);

set(fh, 'Toolbar', 'none', 'Menubar', 'none', 'Resize', 'off', 'Color', clr, ...
    'Tag', 'dicm2nii_fig', 'Position', [200 scrSz(4)-600 420 300], 'Visible', 'off', ...
    'Name', 'dicm2nii - DICOM to NIfTI Converter', 'NumberTitle', 'off');

uitxt('Move mouse onto button, text box or check box for help', [8 274 400 16]);
str = sprintf(['Browse convertible files or folders (can have subfolders) ' ...
    'containing files.\nConvertible files can be dicom, Philips PAR,' ...
    ' AFNI HEAD, BrainVoyager files, or a zip file containing those files']);
uicontrol('Style', 'Pushbutton', 'Position', [6 235 112 24], ...
    'FontSize', fSz, 'String', 'DICOM folder/files', 'Background', clrButton, ...
    'TooltipString', str, 'Callback', cb('srcDir'));

jSrc = javaObjectEDT('javax.swing.JTextField');
hs.src = javacomponent(jSrc, [118 234 294 24], fh);
hs.src.FocusLostCallback = cb('set_src');
hs.src.Text = getpf('src', pwd);
% hs.src.ActionPerformedCallback = cb('set_src'); % fire when pressing ENTER
hs.src.ToolTipText = ['<html>This is the source folder or file(s). You can<br>' ...
    'Type the source folder name into the box, or<br>' ...
    'Click DICOM folder/files button to browse, or<br>' ...
    'Drag and drop a folder or file(s) into the box'];

uicontrol('Style', 'Pushbutton', 'Position', [6 199 112 24], ...
    'FontSize', fSz, 'String', 'Result folder', 'Background', clrButton, ...
    'TooltipString', 'Browse result folder', 'Callback', cb('dstDialog'));
jDst = javaObjectEDT('javax.swing.JTextField');
hs.dst = javacomponent(jDst, [118 198 294 24], fh);
hs.dst.FocusLostCallback = cb('set_dst');
hs.dst.Text = getpf('dst', pwd);
hs.dst.ToolTipText = ['<html>This is the result folder name. You can<br>' ...
    'Type the folder name into the box, or<br>' ...
    'Click Result folder button to set the value, or<br>' ...
    'Drag and drop a folder into the box'];

uitxt('Output format', [8 166 82 16]);
hs.rstFmt = uicontrol('Style', 'popup', 'Background', 'white', 'FontSize', fSz, ...
    'Value', getpf('rstFmt',1), 'Position', [92 162 82 24], ...
    'String', {' .nii' ' .hdr/.img' ' BIDS (http://bids.neuroimaging.io)'}, ...
    'TooltipString', 'Choose output file format');

hs.gzip = chkbox(fh, getpf('gzip',true), 'Compress', '', 'Compress into .gz files');
sz = get(hs.gzip, 'Extent'); set(hs.gzip, 'Position', [220 166 sz(3)+24 sz(4)]);

hs.rst3D = chkbox(fh, getpf('rst3D',false), 'SPM 3D', cb('SPMStyle'), ...
    'Save one file for each volume (SPM style)');
sz = get(hs.rst3D, 'Extent'); set(hs.rst3D, 'Position', [330 166 sz(3)+24 sz(4)]);
           
hs.convert = uicontrol('Style', 'pushbutton', 'Position', [104 8 200 30], ...
    'FontSize', fSz, 'String', 'Start conversion', ...
    'Background', clrButton, 'Callback', cb('do_convert'), ...
    'TooltipString', 'Dicom source and Result folder needed before start');

hs.about = uicontrol('Style', 'popup',  'String', ...
    {'About' 'License' 'Help text' 'Check update' 'A paper about conversion'}, ...
    'Position', [326 12 88 20], 'Callback', cb('about'));

ph = uipanel(fh, 'Units', 'Pixels', 'Position', [4 50 410 102], 'FontSize', fSz, ...
    'BackgroundColor', clr, 'Title', 'Preferences (also apply to command line and future sessions)');
setpf = @(p)['setpref(''dicm2nii_gui_para'',''' p ''',get(gcbo,''Value''));'];

p = 'lefthand';
h = chkbox(ph, getpf(p,true), 'Left-hand storage', setpf(p), ...
    'Left hand storage works well for FSL, and likely doesn''t matter for others');
sz = get(h, 'Extent'); set(h, 'Position', [4 60 sz(3)+24 sz(4)]);

p = 'save_patientName';
h = chkbox(ph, getpf(p,true), 'Store PatientName', setpf(p), ...
    'Store PatientName in NIfTI hdr, ext and json');
sz = get(h, 'Extent'); set(h, 'Position', [180 60 sz(3)+24 sz(4)]);

p = 'use_parfor';
h = chkbox(ph, getpf(p,true), 'Use parfor if needed', setpf(p), ...
    'Converter will start parallel tool if necessary');
sz = get(h, 'Extent'); set(h, 'Position', [4 36 sz(3)+24 sz(4)]);

p = 'use_seriesUID';
h = chkbox(ph, getpf(p,true), 'Use SeriesInstanceUID if exists', setpf(p), ...
    'Only uncheck this if SeriesInstanceUID is messed up by some third party archive software');
sz = get(h, 'Extent'); set(h, 'Position', [180 36 sz(3)+24 sz(4)]);

p = 'save_json';
h = chkbox(ph, getpf(p,false), 'Save json file', setpf(p), ...
    'Save json file for BIDS (http://bids.neuroimaging.io/)');
sz = get(h, 'Extent'); set(h, 'Position', [4 12 sz(3)+24 sz(4)]);

p = 'scale_16bit';
h = chkbox(ph, getpf(p,false), 'Use 16-bit scaling', setpf(p), ...
    'Losslessly scale 16-bit integers to use dynamic range');
sz = get(h, 'Extent'); set(h, 'Position', [180 12 sz(3)+24 sz(4)]);

hs.fig = fh;
guidata(fh, hs); % store handles
drawnow; set(fh, 'Visible', 'on', 'HandleVisibility', 'callback');

try % java_dnd is based on dndcontrol by Maarten van der Seijs
    java_dnd(jSrc, cb('drop_src'));
    java_dnd(jDst, cb('drop_dst'));
catch me
    fprintf(2, '%s\n', me.message);
end

gui_callback([], [], 'set_src', fh);

%% subfunction: return phase positive and phase axis (1/2) in image reference
function [phPos, iPhase] = phaseDirection(s)
phPos = []; iPhase = [];
fld = 'InPlanePhaseEncodingDirection';
if isfield(s, fld)
    if     strncmpi(s.(fld), 'COL', 3), iPhase = 2; % based on dicm_img(s,0)
    elseif strncmpi(s.(fld), 'ROW', 3), iPhase = 1;
    else, errorLog(['Unknown ' fld ' for ' s.NiftiName ': ' s.(fld)]);
    end
end

if isfield(s, 'CSAImageHeaderInfo') % SIEMENS
    phPos = csa_header(s, 'PhaseEncodingDirectionPositive'); % image ref
% elseif isfield(s, 'ProtocolDataBlock') % GE
%     try % VIEWORDER "1" == bottom_up
%         phPos = s.ProtocolDataBlock.VIEWORDER == '1';
%     end
elseif isfield(s, 'UserDefineData') % GE
    % https://github.com/rordenlab/dcm2niix/issues/163
    try
    b = s.UserDefineData;
    i = typecast(b(25:26), 'uint16'); % hdr_offset
    v = typecast(b(i+1:i+4), 'single'); % 5.0 to 40.0
    if v >= 25.002, i = i + 76; flag2_off = 777; else, flag2_off = 917; end
    sliceOrderFlag = bitget(b(i+flag2_off), 2);
    phasePolarFlag = bitget(b(i+49), 3);
    phPos = ~xor(phasePolarFlag, sliceOrderFlag);
    end
else
    if isfield(s, 'Stack') % Philips
        try d = s.Stack.Item_1.MRStackPreparationDirection(1); catch, return; end
    elseif isfield(s, 'PEDirectionDisplayed') % UIH
        try d = s.PEDirectionDisplayed(1); catch, return; end
    elseif isfield(s, 'Private_0177_1100') % Bruker
        expr ='(?<=\<\+?)[LRAPSI]{1}(?=;\s*phase\>)'; % <+P;phase> or <P;phase>  
        d = regexp(char(s.Private_0177_1100'), expr, 'match', 'once');
        id = regexp('LRAPSI', d);
        id = id + mod(id,2)*2-1;
        str = 'LRAPFH'; d = str(id);
    else % unknown Manufacturer
        return;
    end
    try R = reshape(s.ImageOrientationPatient, 3, 2); catch, return; end
    [~, ixy] = max(abs(R)); % like [1 2]
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
if isfield(s, 'MRVFrameSequence') % not real multi-frame dicom
    try
    s.ImagePositionPatient = s.MRVFrameSequence.Item_1.ImagePositionPatient;
    s.AcquisitionDateTime = s.MRVFrameSequence.Item_1.AcquisitionDateTime;
    item = sprintf('Item_%g', s.LocationsInAcquisition);
    s.LastFile.ImagePositionPatient = s.MRVFrameSequence.(item).ImagePositionPatient;
    end
    return;
end
pffgs = 'PerFrameFunctionalGroupsSequence';
sfgs = 'SharedFunctionalGroupsSequence';
if any(~isfield(s, {sfgs pffgs})), return; end
try nFrame = s.NumberOfFrames; catch, nFrame = numel(s.(pffgs).FrameStart); end

% check slice ordering (Philips often needs SortFrames)
n = numel(MF_val('DimensionIndexValues', s, 1));
if n>0 && nFrame>1
    na = nan(1, nFrame);
    s2 = struct('InStackPositionNumber', na, 'TemporalPositionIndex', na, ...
                'DimensionIndexValues', nan(n,nFrame), 'B_value', zeros(1, nFrame));
    s2 = dicm_hdr(s, s2, 1:nFrame);
    if ~isnan(s2.InStackPositionNumber(1))
        SL = s2.InStackPositionNumber';
        VL = [s2.TemporalPositionIndex' s2.DimensionIndexValues([3:end 1],:)'];
    else % use DimensionIndexValues as backup (seen in GE)
        SL = s2.DimensionIndexValues(2,:)'; % Bruker slice dim in (3,:)?
        VL = s2.DimensionIndexValues([3:end 1],:)';
    end
    [ind, nSL] = sort_frames([SL s2.B_value'], VL);
    if isempty(ind), s = []; return; end
    if ~isequal(ind, 1:nFrame) % && strncmpi(s.Manufacturer, 'Philips', 7)
        if ind(1) ~= 1 || ind(end) ~= nFrame 
            s = dicm_hdr(s.Filename, [], ind([1 end])); % re-read new frames [1 end]
        end
        s.SortFrames = ind; % will use to sort img and get iVol/iSL for PerFrameSQ
    end
    if ~isfield(s, 'LocationsInAcquisition'), s.LocationsInAcquisition = nSL; end
end

% copy important fields into s
flds = {'EchoTime' 'PixelSpacing' 'SpacingBetweenSlices' 'SliceThickness' ...
        'RepetitionTime' 'FlipAngle' 'RescaleIntercept' 'RescaleSlope' ...
        'ImageOrientationPatient' 'ImagePositionPatient' ...
        'InPlanePhaseEncodingDirection' 'MRScaleSlope' 'CardiacTriggerDelayTime'};
iF = 1; if isfield(s, 'SortFrames'), iF = s.SortFrames(1); end
for i = 1:numel(flds)
    if isfield(s, flds{i}), continue; end
    a = MF_val(flds{i}, s, iF);
    if ~isempty(a), s.(flds{i}) = a; end
end

if ~isfield(s, 'EchoTime')
    a = MF_val('EffectiveEchoTime', s, iF);
    if ~isempty(a), s.EchoTime = a;
    else, try s.EchoTime = str2double(s.EchoTimeDisplay); end
    end
end

% for Siemens: the redundant copy makes non-Siemens code faster
if isfield(s.(sfgs).Item_1, 'CSASeriesHeaderInfo')
    s.CSASeriesHeaderInfo = s.(sfgs).Item_1.CSASeriesHeaderInfo.Item_1;
end
fld = 'CSAImageHeaderInfo';
if isfield(s.(pffgs).Item_1, fld)
    s.(fld) = s.(pffgs).(sprintf('Item_%g', iF)).(fld).Item_1;
end

% check ImageOrientationPatient consistency for 1st and last frame only
if nFrame<2, return; end
iF = nFrame; if isfield(s, 'SortFrames'), iF = s.SortFrames(iF); end
a = MF_val('ImagePositionPatient', s, iF);
if ~isempty(a), s.LastFile.ImagePositionPatient = a; end
fld = 'ImageOrientationPatient';
val = MF_val(fld, s, iF);
if ~isempty(val) && isfield(s, fld) && any(abs(val-s.(fld))>1e-4)
    s = []; return; % inconsistent orientation, skip
end

%% subfunction: return value from Shared or PerFrame FunctionalGroupsSequence
function val = MF_val(fld, s, iFrame)
pffgs = 'PerFrameFunctionalGroupsSequence';
switch fld
    case 'EffectiveEchoTime'
        sq = 'MREchoSequence';
    case {'DiffusionDirectionality' 'B_value'}
        sq = 'MRDiffusionSequence';
    case 'ComplexImageComponent'
        sq = 'MRImageFrameTypeSequence';
    case {'DimensionIndexValues' 'InStackPositionNumber' 'TemporalPositionIndex' ...
            'FrameReferenceDatetime' 'FrameAcquisitionDatetime'}
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
    case 'CardiacTriggerDelayTime'
        sq = 'CardiacTriggerSequence';
    case {'SliceNumberMR' 'EchoTime' 'MRScaleSlope'}
        sq = 'PrivatePerFrameSq'; % Philips
    case 'DiffusionGradientDirection' % 
        sq = 'MRDiffusionSequence';
        try
            s2 = s.(pffgs).(sprintf('Item_%g', iFrame)).(sq).Item_1;
            val = s2.DiffusionGradientDirectionSequence.Item_1.(fld);
        catch, val = [0 0 0]';
        end
        if nargin>1, return; end
    otherwise
        error('Sequence for %s not set.', fld);
end
if nargin<2
    val = {'SharedFunctionalGroupsSequence' pffgs sq fld 'NumberOfFrames'}; 
    return;
end
try 
    val = s.SharedFunctionalGroupsSequence.Item_1.(sq).Item_1.(fld);
catch
    try
        val = s.(pffgs).(sprintf('Item_%g', iFrame)).(sq).Item_1.(fld);
    catch
        val = [];
    end
end

%% subfunction: split nii components into multiple nii
function nii = split_components(nii, s)
fld = 'ComplexImageComponent';
if ~strcmp(tryGetField(s, fld, ''), 'MIXED'), return; end

if ~isfield(s, 'Volumes') % PAR file and single-frame file have this
    nSL = nii.hdr.dim(4); nVol = nii.hdr.dim(5);
    iFrames = 1:nSL:nSL*nVol;
    if isfield(s, 'SortFrames'), iFrames = s.SortFrames(iFrames); end
    s1 = struct(fld, {cell(1, nVol)}, 'MRScaleSlope', nan(1,nVol), ...
            'RescaleSlope', nan(1,nVol), 'RescaleIntercept', nan(1,nVol));
    s.Volumes = dicm_hdr(s, s1, iFrames);
end
if ~isfield(s, 'Volumes'), return; end

% suppose scl not applied in set_nii_hdr, since MRScaleSlope is not integer
flds = {'EchoTimes' 'CardiacTriggerDelayTimes'}; % to split
s1 = s.Volumes;
nii0 = nii;
% [c, ia] = unique(s.Volumes.(fld), 'stable'); % since 2013a?
[~, ia] = unique(s1.(fld));
ia = sort(ia);
c = s1.(fld)(ia);
for i = 1:numel(c)
    nii(i) = nii0;
    ind = strcmp(c{i}, s1.(fld));
    nii(i).img = nii0.img(:,:,:,ind);
    slope = s1.RescaleSlope(ia(i)); if isnan(slope), slope = 1; end 
    inter = s1.RescaleIntercept(ia(i)); if isnan(inter), inter = 0; end
    if ~isnan(s1.MRScaleSlope(ia(i)))
        inter = inter / (slope * s1.MRScaleSlope(ia(i)));
        slope = 1 / s1.MRScaleSlope(ia(i));
    end
    nii(i).hdr.scl_inter = inter;
    nii(i).hdr.scl_slope = slope;
    nii(i).hdr.file_name = [s.NiftiName '_' lower(c{i})];
    nii(i) = nii_tool('update', nii(i));
    
    for j = 1:numel(flds)
        if ~isfield(nii(i).json, flds{j}), continue; end
        nii(i).json.(flds{j}) = nii(i).json.(flds{j})(ind);
    end
end

%% Write error info to a file in case user ignores Command Window output
function firstTime = errorLog(errInfo, folder)
persistent niiFolder;
if nargin>1, firstTime = isempty(niiFolder); niiFolder = folder; end
if isempty(errInfo), return; end
fprintf(2, ' %s\n', errInfo); % red text in Command Window
fid = fopen([niiFolder 'dicm2nii_warningMsg.txt'], 'a');
fseek(fid, 0, -1); 
fprintf(fid, '%s\n', errInfo);
fclose(fid);

%% Get version yyyymmdd from README.md 
function dStr = getVersion(str)
dStr = '20190209';
if nargin<1 || isempty(str)
    pth = fileparts(mfilename('fullpath'));
    fname = fullfile(pth, 'README.md');
    if ~exist(fname, 'file'), return; end
    str = fileread(fname);
end
a = regexp(str, 'version\s(\d{4}\.\d{2}\.\d{2})', 'tokens', 'once');
if ~isempty(a), dStr = a{1}([1:4 6:7 9:10]); end

%% Get position info from Siemens CSA ASCII header
% The only case this is useful for now is for DTI_ColFA, where Siemens omit 
% ImageOrientationPatient, ImagePositionPatient, PixelSpacing.
% This shows how to get info from Siemens CSA header.
function s = csa2pos(s, nSL)
ori = {'Sag' 'Cor' 'Tra'}; % 1/2/3
sNormal = zeros(3,1);
for i = 1:3
    a = asc_header(s, ['sSliceArray.asSlice[0].sNormal.d' ori{i}]);
    if ~isempty(a), sNormal(i) = a; end
end
if all(sNormal==0); return; end % likely no useful info, give up

isMos = tryGetField(s, 'isMos', false);
revNum = ~isempty(asc_header(s, 'sSliceArray.ucImageNumb'));
[cosSL, iSL] = max(abs(sNormal));
if isMos && (~isfield(s, 'CSAImageHeaderInfo') || ...
        ~isfield(s.CSAImageHeaderInfo, 'SliceNormalVector'))
    a = sNormal; if revNum, a = -a; end
    s.CSAImageHeaderInfo.SliceNormalVector = a;
end

pos = zeros(3,2);
sl = [0 nSL-1];
for j = 1:2
    key = sprintf('sSliceArray.asSlice[%g].sPosition.d', sl(j));
    for i = 1:3
        a = asc_header(s, [key ori{i}]);
        if ~isempty(a), pos(i,j) = a; end
    end
end

if ~isfield(s, 'SpacingBetweenSlices')
    if all(pos(:,2)==0) % like Mprage: dThickness & sPosition for volume
        a = asc_header(s, 'sSliceArray.asSlice[0].dThickness') ./ nSL;
        if ~isempty(a), s.SpacingBetweenSlices = a; end
    else
        s.SpacingBetweenSlices = abs(diff(pos(iSL,:))) / (nSL-1) / cosSL;
    end
end

if ~isfield(s, 'PixelSpacing')
    a = asc_header(s, 'sSliceArray.asSlice[0].dReadoutFOV');
    a = a ./ asc_header(s, 'sKSpace.lBaseResolution');
    interp = asc_header(s, 'sKSpace.uc2DInterpolation');
    if interp, a = a ./ 2; end
    if ~isempty(a), s.PixelSpacing = a * [1 1]'; end
end

R(:,3) = sNormal; % ignore revNum for now
if isfield(s, 'ImageOrientationPatient')
    R(:, 1:2) = reshape(s.ImageOrientationPatient, 3, 2);
else
    if iSL==3
        R(:,2) = [0 R(3,3) -R(2,3)] / norm(R(2:3,3));
        R(:,1) = cross(R(:,2), R(:,3));
    elseif iSL==2
        R(:,1) = [R(2,3) -R(1,3) 0] / norm(R(1:2,3));
        R(:,2) = cross(R(:,3), R(:,1));
    elseif iSL==1
        R(:,1) = [-R(2,3) R(1,3) 0] / norm(R(1:2,3));
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
    dim = double([s.Columns s.Rows]');
    if all(pos(:,2) == 0) % pos(:,1) for volume center
        if any(~isfield(s,{'PixelSpacing' 'SpacingBetweenSlices'})), return; end
        R = R * diag([s.PixelSpacing([2 1]); s.SpacingBetweenSlices]);
        x = [-dim/2*[1 1]; (nSL-1)/2*[-1 1]];
        pos = R * x + pos(:,1) * [1 1]; % volume center to slice 1&nSL position
    else % this may be how Siemens sets unusual mosaic ImagePositionPatient 
        if ~isfield(s, 'PixelSpacing'), return; end
        R = R(:,1:2) * diag(s.PixelSpacing([2 1]));
        pos = pos - R * dim/2 * [1 1]; % slice centers to slice position
    end
    if revNum, pos = pos(:, [2 1]); end
    if isMos, pos(:,2) = pos(:,1); end % set LastFile same as first for mosaic
    s.ImagePositionPatient = pos(:,1);
    s.LastFile.ImagePositionPatient = pos(:,2);
end

%% subfuction: check whether parpool is available
% Return true if it is already open, or open it if available
function doParal = useParTool
doParal = usejava('jvm');
if ~doParal, return; end

if isempty(which('parpool')) % for early matlab versions
    try 
        if matlabpool('size')<1 %#ok<*DPOOL>
            try
                matlabpool; 
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
            parpool; 
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
flds = fieldnames(s);
ext.ecode = 6; % text ext
ext.edata = '';
for i = 1:numel(flds)
    try val = s.(flds{i}); catch, continue; end
    if ischar(val)
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
function [err, nSL, sliceN, isTZ] = checkImagePosition(ipp, gantryTilt)
a = diff(sort(ipp));
tol = max(a)/100; % max(a) close to SliceThichness. 1% arbituary
if nargin>1 && gantryTilt, tol = tol * 10; end % arbituary
nSL = sum(a > tol) + 1;
err = ''; sliceN = []; isTZ = false;
nVol = numel(ipp) / nSL;
if mod(nVol,1), err = 'Missing file(s) detected'; return; end
if nSL<2, return; end

isTZ = nVol>1 && all(abs(diff(ipp(1:nVol))) < tol);
if isTZ % Philips XYTZ
    a = ipp(1:nVol:end);
    b = reshape(ipp, nVol, nSL);
else
    a = ipp(1:nSL);
    b = reshape(ipp, nSL, nVol)';
end
[~, sliceN] = sort(a); % no descend since wrong for PAR/singleDicom
if any(abs(diff(a,2))>tol), warning('Inconsistent slice spacing'); end
if nVol>1
    b = diff(b);
    if any(abs(b(:))>tol), err = 'Irregular slice order'; return; end
end

%% Save JSON file, proposed by Chris G
% matlab.internal.webservices.toJSON(s)
function save_json(s, fname)
flds = fieldnames(s);
fid = fopen([fname '.json'], 'w'); % overwrite silently if exist
fprintf(fid, '{\n');
for i = 1:numel(flds)
    nam = flds{i};
    if ~isfield(s, nam), continue; end
    val = s.(nam);
    
    % this if-elseif block takes care of name/val change for BIDS json
    if any(strcmp(nam, {'RepetitionTime' 'InversionTime' 'EchoTimes' 'CardiacTriggerDelayTimes'}))
        val = val / 1000; % in sec now
    elseif strcmp(nam, 'UnwarpDirection')
        nam = 'PhaseEncodingDirection';
        if val(1) == '-' || val(1) == '?', val = val([2 1]); end
        if     val(1) == 'x', val(1) = 'i'; % BIDS spec
        elseif val(1) == 'y', val(1) = 'j';
        elseif val(1) == 'z', val(1) = 'k';
        end
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
    elseif strcmp(nam, 'DelayTimeInTR')
        nam = 'DelayTime';
        val = val / 1000; % secs 
    elseif strcmp(nam, 'ImageType')
        val = regexp(val, '\\', 'split');
    end
    
    fprintf(fid, '\t"%s": ', nam);
    if isempty(val)
        fprintf(fid, 'null,\n');
    elseif ischar(val)
        fprintf(fid, '"%s",\n', strrep(val, '\', '\\'));
    elseif iscellstr(val)
        fprintf(fid, '[');
        fprintf(fid, '"%s", ', val{:});
        fseek(fid, -2, 'cof'); % remove trailing comma and space
        fprintf(fid, '],\n');
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
verLink = 'https://github.com/xiangruili/dicm2nii/blob/master/README.md';
webUrl = 'https://www.mathworks.com/matlabcentral/fileexchange/42997';
if ~isdeployed
try
    str = webread(verLink);
catch me
    try
        str = urlread(verLink); %#ok
    catch
        str = sprintf('%s.\n\nPlease download manually.', me.message);
        errordlg(str, 'Web access error');
        web(webUrl, '-browser');
        return;
    end
end

latestStr = getVersion(str);
if datenum(getVersion(), 'yyyymmdd') >= datenum(latestStr, 'yyyymmdd')
    msgbox([mfile ' and the package are up to date.'], 'Check update');
    return;
end

msg = ['Update to the newer version (' latestStr ')?'];
answer = questdlg(msg, ['Update ' mfile], 'Yes', 'Later', 'Yes');
if ~strcmp(answer, 'Yes'), return; end

url = ['https://www.mathworks.com/matlabcentral/mlc-downloads/'...
       'downloads/e5a13851-4a80-11e4-9553-005056977bd0/' ...
       '80e748a3-0ae1-48a5-a2cb-b8380dac0232/packages/zip'];
tmp = tempdir;
try
    fname = websave('dicm2nii_github.zip', url); % 2014a
    unzip(fname, tmp); delete(fname);
    a = dir([tmp 'xiangruili*']);
    if isempty(a), tdir = tmp; else, tdir = [tmp a(1).name '/']; end
catch 
    % system('git clone https://github.com/xiangruili/dicm2nii.git')
    url = 'https://github.com/xiangruili/dicm2nii/archive/master.zip';
    try
        fname = [tmp 'dicm2nii_github.zip'];
        urlwrite(url, fname); %#ok
        unzip(fname, tmp); delete(fname);
        tdir = [tmp 'dicm2nii-master/'];
    catch me
        errordlg(['Error in updating: ' me.message], mfile);
        web(webUrl, '-browser');
        return;
    end
end
movefile([tdir '*.*'], [fileparts(which(mfile)) '/.'], 'f');
rmdir(tdir, 's');
rehash;
warndlg(['Package updated successfully. Please restart ' mfile ...
         ', otherwise it may give error.'], 'Check update');
end

%% Subfunction: return NumberOfImagesInMosaic if Siemens mosaic, or [] otherwise.
% If NumberOfImagesInMosaic in CSA is >1, it is mosaic, and we are done. 
% If not exists, it may still be mosaic due to Siemens bug seen in syngo MR
% 2004A 4VA25A phase image. Then we check EchoColumnPosition in CSA, and if it
% is smaller than half of the slice dim, sSliceArray.lSize is used as nMos. If
% no CSA at all, the better way may be to peek into img to get nMos. Then the
% first attempt is to check whether there are padded zeros. If so we count zeros
% either at top or bottom of the img to decide real slice dim. In case there is
% no padded zeros, we use the single zero lines along row or col seen in most
% (not all, for example some phase img, derived data like moco series or tmap
% etc) mosaic. If the lines are equally spaced, and nMos is divisible by mosaic
% dim, we accept nMos. Otherwise, we fall back to NumberOfPhaseEncodingSteps,
% which is used by dcm2nii, but is not reliable for most mosaic due to partial
% fourier or less 100% phase fov.
function nMos = nMosaic(s)
nMos = csa_header(s, 'NumberOfImagesInMosaic'); % healthy mosaic dicom
if ~isempty(nMos), return; end % seen 0 for GLM Design file and others

% The next fix detects mosaic which is not labeled as MOSAIC in ImageType, nor
% NumberOfImagesInMosaic exists, seen in syngo MR 2004A 4VA25A phase image.
res = csa_header(s, 'EchoColumnPosition'); % half or full of slice dim
if ~isempty(res)
    dim = max([s.Columns s.Rows]);
    interp = asc_header(s, 'sKSpace.uc2DInterpolation');
    if ~isempty(interp) && interp, dim = dim / 2; end
    if dim/res/2 >= 2 % nTiles>=2
        nMos = asc_header(s, 'sSliceArray.lSize'); % mprage lSize=1
    end
    return; % Siemens non-mosaic returns here
end

% The fix below is for dicom labeled as \MOSAIC in ImageType, but no CSA.
if ~isType(s, '\MOSAIC') && ~isType(s, '\VFRAME'), return; end % non-mosaic
try nMos = s.LocationsInAcquisition; return; end % try Siemens/UIH private tag
try nMos = numel(fieldnames(s.MRVFrameSequence)); return; end % UIH
    
dim = double([s.Columns s.Rows]); % slice or mosaic dim
img = dicm_img(s, 0) ~= 0; % peek into img to figure out nMos
nP = tryGetField(s, 'NumberOfPhaseEncodingSteps', 4); % sliceDim >= phase steps
c = img(dim(1)-nP:end, dim(2)-nP:end); % corner at bottom-right
done = false;
if all(~c(:)) % at least 1 padded slice: not 100% safe
    c = img(1:nP+1, dim(2)-nP:end); % top-right
    if all(~c(:)) % all right tiles padded: use all to determine
        ln = sum(img);
    else % use several rows at bottom to determine: not as safe as all
        ln = sum(img(dim(1)-nP:end, :));
    end
    z = find(ln~=0, 1, 'last');
    nMos = dim(2) / (dim(2) - z);
    done = mod(nMos,1)==0 && mod(dim(1),nMos)==0;
end
if ~done % this relies on zeros along row or col seen in most mosaic
    ln = sum(img, 2) == 0;
    if sum(ln)<2
        ln = sum(img) == 0; % likely PhaseEncodingDirectionPositive=0
        i = find(~ln, 1, 'last'); % last non-zero column in img
        ln(i+2:end) = []; % leave only 1 true for padded zeros
    end
    nMos = sum(ln);
    done = nMos>1 && all(mod(dim,nMos)==0) && all(diff(find(ln),2)==0);
end
if ~done && isfield(s, 'NumberOfPhaseEncodingSteps')
    nMos = min(dim) / nP;
    done = nMos>1 && mod(nMos,1)==0 && all(mod(dim,nMos)==0);
end

if ~done
    errorLog([ProtocolName(s) ': NumberOfImagesInMosaic not available.']);
    nMos = []; % keep mosaic as it is
    return;
end

nMos = nMos * nMos; % not work for UIH
img = mos2vol(uint8(img), nMos, 0); % find padded slices: useful for STC
while 1
    a = img(:,:,nMos);
    if any(a(:)), break; end
    nMos = nMos - 1;
end

%% Get sorting index for multi-frame and PAR/XML (also called by dicm_hdr)
function [ind, nSL] = sort_frames(sl, ic)
% sl is for slice index, and has B_value as 2nd column for DTI.
% ic contains other possible identifiers which will be converted into index. 
% The ic column order is important. 
nSL = max(sl(:, 1));
nFrame = size(sl, 1);
if nSL==nFrame, ind = 1:nSL; ind(sl(:,1)) = ind; return; end % single vol
nVol = floor(nFrame / nSL);
badVol = nVol*nSL < nFrame; % incomplete volume
ic(isnan(ic)) = 0;
id = zeros(size(ic));
for i = 1:size(ic,2)
    [~, ~, id(:,i)] = unique(ic(:,i)); % entries to index
end
n = max(id); id = id(:, n>1); n = n(n>1);
i = find(n == nVol+badVol, 1);
if ~isempty(i) % most fMRI/DTI
    id = id(:, i); % use a single column for sorting
elseif ~badVol && numel(n)>1
    [j, i] = find(tril(n' * n, -1) == nVol, 1); % need to ignore diag
    if ~isempty(i)
        id = id(:, [i j]); % 2 columns make nVol        
    elseif numel(n)>2
        i = find(cumprod(n) == nVol, 1);
        if ~isempty(i), id = id(:, 1:i); end % first i columns make nVol
    end
end
[~, ind] = sortrows([sl id]); % this sort idea is from julienbesle
if badVol % only seen in Philips
    try lastV = id(ind,1) > nVol; catch, lastV = []; end
    if sum(lastV) == nFrame-nSL*nVol
        ind(lastV) = []; % remove incomplete volume
    else % suppose extra later slices are from bad volume
        for i = 1:nSL
            a = ind==i;
            if sum(a) <= nVol, continue; end % shoule be ==
            ind(find(a, 'last')) = []; % remove last extra one
            if numel(ind) == nSL*nVol, break; end
        end
    end
end
ind = reshape(ind, [], nSL)'; % XYTZ to XYZT
ind = ind(:)';

%% this can be removed for matlab 2013b+
function y = flip(varargin)
if exist('flip', 'builtin')
    y = builtin('flip', varargin{:});
else
    if nargin<2, varargin{2} = find(size(varargin{1})>1, 1); end
    y = flipdim(varargin{:}); %#ok
end

%% return all file names in a folder, including in sub-folders
function files = filesInDir(folder)
dirs = genpath(folder);
dirs = regexp(dirs, pathsep, 'split');
files = {};
for i = 1:numel(dirs)
    if isempty(dirs{i}), continue; end
    curFolder = [dirs{i} filesep];
    a = dir(curFolder); % all files and folders
    a([a.isdir]) = []; % remove folders
    a = strcat(curFolder, {a.name});
    files = [files a]; %#ok<*AGROW>
end

%% Select both folders and files
function out = jFileChooser(folder, prompt, multi, button)
if nargin<4 || isempty(button), button = 'Select'; end
if nargin<3 || isempty(multi), multi = true; end
if nargin<2 || isempty(prompt)
    if multi, prompt = 'Choose files and/or folders';
    else,     prompt = 'Choose file or folder';
    end
end
if nargin<1 || isempty(folder), folder = pwd; end

jFC = javax.swing.JFileChooser(folder);
jFC.setFileSelectionMode(jFC.FILES_AND_DIRECTORIES);
set(jFC, 'MultiSelectionEnabled', logical(multi));
set(jFC, 'ApproveButtonText', button);
set(jFC, 'DialogTitle', prompt);
returnVal = jFC.showOpenDialog([]);
if returnVal ~= jFC.APPROVE_OPTION, out = returnVal; return; end % numeric

if multi
    files = jFC.getSelectedFiles();
    n = numel(files);
    out = cell(1, n);
    for i = 1:n, out{i} = char(files(i)); end
else
    out = char(jFC.getSelectedFile());
end

%% 
function v = normc(M)
den = sqrt(sum(M .* M));
den(den==0) = 1;
v = bsxfun(@rdivide, M, den);
%%

function BtnModalityTable(h,TT,TS)
if verLessThan('matlab','9.4')
    dat = TT.Data;
else
    dat = cellfun(@char,table2cell(TT.Data),'uni',0);
end
if all(any(ismember(dat(:,2:3),'skip'),2))
    warndlg('All images are skipped... Please select the type and modality for all scans','No scan selected');
    return;
end
setappdata(0,'ModalityTable',TT.Data)
setappdata(0,'SubjectTable',TS.Data)
delete(h)

function my_closereq(src,~)
% Close request function 
% to display a question dialog box
if verLessThan('matlab','9.4')
    selection = questdlg('Cancel Dicom conversion?','Close dicm2nii','OK','Cancel','Cancel');
else
    selection = uiconfirm(src,'Cancel Dicom conversion?',...
        'Close dicm2nii');
end
switch selection
    case 'OK'
        delete(src)
        setappdata(0,'Canceldicm2nii',true)
    case 'Cancel'
        return
end

function previewDicom(ax,s)
nSL = double(tryGetField(s{1}, 'LocationsInAcquisition'));
if isempty(nSL)
    nSL = length(s);
end
if verLessThan('matlab','9.4')
    axis(ax);
    imagesc(dicm_img(s{round(nSL/2)}));
    axis(ax,'off');
    colormap(ax,'gray')
    ax.YTickLabel = [];
    ax.XTickLabel = [];
else
    imagesc(ax,dicm_img(s{round(nSL/2)}));
end
ax.DataAspectRatio = [s{round(nSL/2)}.PixelSpacing' 1];

function showHelp(valueset)
%%
msg = {'BIDS Converter module for dicm2nii',...
    'tanguy.duval@inserm.fr',...
    'http://bids.neuroimaging.io',...
    '------------------------------------------',...
    'Info Table',...
    '  Subject:            subject id. 1rst layer in directory structure',...
    '                       ex: John',...
    '                       No space, no dash, no underscore!',...
    '  Session:            session id. 2nd  layer in directory structure',...
    '                       ex: 01',...
    '                       No space, no dash, no underscore!',...
    '  AcquisitionDate:    Session date. 1rst Column in the session',...
    '                        description file (sub-Subject_sessions.tsv).',...
    '  Comment:            Comments.     2nd  Column in the session',...
    '                        description file (sub-Subject_sessions.tsv).',...
    '------------------------------------------',...
    'Sequence Table',...
    '  Name:                 SerieDescription extracted from the dicom field.',...
    '  Type:                 type of imaging modality. 3rd layer in directory structure.',...
    ['                        ex: ' strjoin(unique(valueset(:,1)),', ')],...
    '                         ''skip'' to skip conversion',...
    '  Modality:             Modality. suffix of filename. ',...
    ['                        ex: ' strjoin(unique(valueset(:,2)),', ')],...
    '                         ''skip'' to skip conversion',...
    ''};
h = msgbox(msg,'Help on BIDS converter');
set(findall(h,'Type','Text'),'FontName','FixedWidth');
Pos = get(h,'Position'); Pos(3) = 450;
set(h,'Position',Pos)
