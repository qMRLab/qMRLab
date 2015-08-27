function s = dicomLoadAllSeries(dicomDir, studyId, sortByFilenameFlag, ignoreAcquisition)
%
% s = dicomLoadAllSeries(dicomDir, [studyId=''], [sortByFilenameFlag=false])
%
% Loads all the dicom files found in the specified directory
% (recursively searches all sub-directories too). A structure
% array is returned, with one entry for each series found in the
% directory tree.
%
% If studyID (a string) is provided, then only series with a matching
% StudyID tag will be processed. Otherwise, all studies are processed.
%
% To save each series in a directory of DICOMs to separate NIFTI files, try
% niftiFromDicom.
%
% HISTORY:
% 2007.01.?? RFD: wrote it.
% 2009.12.08 RFD: completely replaced code to compute the imToScanner
% xform. I now use code that is modeled on NYU's dinifti, so we should now
% produce results consistent with that program. Which, BTW, are more
% accurate than what we did before. 

if(~exist('sortByFilenameFlag','var')||isempty(sortByFilenameFlag))
    sortByFilenameFlag = false;
end
if(~exist('ignoreAcquisition','var')||isempty(ignoreAcquisition))
    ignoreAcquisition = false;
end

n = 0;
% Get a recursive dump of all sub-directories. We'll
% process every file in the dicomDir tree.
d = genpath(dicomDir);
if(isempty(d))
  error(['Dicom dir "' d '" not found or empty.']);
end
if(isunix)
    d = strsplit(genpath(dicomDir),':');
else
    d = strsplit(genpath(dicomDir),';');
end
d = d(1:end-1);
for(ii=1:length(d))
  d2 = dir(fullfile(d{ii},'*'));
  for(jj=1:length(d2))
	if(~d2(jj).isdir)
	  n = n+1;
	  dicomFiles{n} = fullfile(d{ii},d2(jj).name);
	end
  end
end

clear d;
numSeries = 0;
% We might need this if the dicoms are gzipped.
tmp = tempdir;
tmpName = tempname;

if(~exist('studyId','var'))
    studyId = [];
end
fprintf('Processing %d files in %s:\n', n, dicomDir);
for(imNum=1:length(dicomFiles))
    curFile = dicomFiles{imNum};
    if(length(curFile)>3 && strcmpi(curFile(end-2:end),'.gz'))
        if(exist(tmpName,'file')) delete(tmpName); end
        curFile = gunzip(curFile,tmp);
        movefile(curFile{1}, tmpName);
        curFile = tmpName;
    end
	try
	  info = dicominfo(curFile);
	  if((isempty(studyId) || strcmp(studyId,info.StudyID)) &&  isfield(info,'PatientPosition'))
        if(numSeries==0)
            curSeries = [];
        else
            if(ignoreAcquisition)
                curSeries = find(str2double(info.SeriesTime)==[s(:).acqTime]);
            else
                curSeries = find(info.AcquisitionNumber==[s(:).acqNum] & str2double(info.SeriesTime)==[s(:).acqTime]);
            end
        end
        if(isempty(curSeries))
		  numSeries = numSeries+1;
          curSeries = numSeries;
		  numSlice = 1;
		  s(curSeries).studyID = info.StudyID;
		  s(curSeries).studyDescription = getFieldVal(info, 'StudyDescription', '');
		  s(curSeries).studyDateTime = [info.SeriesDate ' ' info.StudyTime];
		  s(curSeries).patientName = info.PatientName.FamilyName;
		  s(curSeries).patientPosition = getFieldVal(info, 'PatientPosition', 'NONE');
		  s(curSeries).fieldStrength = getFieldVal(info, 'MagneticFieldStrength', []);
		  s(curSeries).seriesDescription = getFieldVal(info, 'SeriesDescription', []);
		  s(curSeries).acqTime = str2double(getFieldVal(info, 'SeriesTime', []));
		  s(curSeries).acqMatrix = getFieldVal(info, 'AcquisitionMatrix',[]);
		  s(curSeries).percentFOV = [getFieldVal(info, 'PercentSampling', []) getFieldVal(info, 'PercentPhaseFieldOfView', [])];
		  s(curSeries).reconDiam = getFieldVal(info, 'ReconstructionDiameter', []);
		  s(curSeries).sliceThickness = info.SliceThickness;
          if(isfield(info,'SpacingBetweenSlices'))
              s(curSeries).mmPerVox = [info.PixelSpacing(:)' info.SpacingBetweenSlices];
          else
              s(curSeries).mmPerVox = [info.PixelSpacing(:)' s(curSeries).sliceThickness];
          end
		  s(curSeries).TR = getFieldVal(info, 'RepetitionTime', []);
		  s(curSeries).TE = getFieldVal(info, 'EchoTime', []);
		  s(curSeries).inversionTime = getFieldVal(info, 'InversionTime', []);
		  s(curSeries).SAR = getFieldVal(info, 'SAR', []);
		  s(curSeries).pixBandwidth = getFieldVal(info, 'PixelBandwidth', []);
          if(~isempty(s(curSeries).pixBandwidth) && numel(s(curSeries).acqMatrix>=2))
              s(curSeries).Bandwidth = s(curSeries).pixBandwidth*s(curSeries).acqMatrix(2);
          else
              s(curSeries).Bandwidth = [];
          end
		  s(curSeries).NEX = getFieldVal(info, 'NumberOfAverages', []);
		  s(curSeries).imageFreq = getFieldVal(info, 'ImagingFrequency',[]);
		  s(curSeries).flipAngle = getFieldVal(info, 'FlipAngle', []);
		  s(curSeries).phaseEncodeDir = getFieldVal(info, 'InPlanePhaseEncodingDirection', []);
		  % We'll fill in the 3rd and 4th dims below
		  %s(curSeries).dims = [info.Rows info.Columns info.ImagesInAcquisition];
		  s(curSeries).dims = [info.Rows info.Columns 0 0];
		  s(curSeries).seriesNum = getFieldVal(info, 'SeriesNumber', []);
		  s(curSeries).acqNum = getFieldVal(info, 'AcquisitionNumber', []);
		  s(curSeries).imageOrientation = getFieldVal(info, 'ImageOrientationPatient', []);
          if(strcmp(info.Manufacturer,'GE MEDICAL SYSTEMS'))
              % *** TO DO: these should be pulse-sequence dependent
              s(curSeries).sequenceName = getFieldVal(info, 'Private_0019_109e',[]);
              s(curSeries).mtOffset = getFieldVal(info, 'Private_0043_1034',[]);
              s(curSeries).dtiBValue = str2double(char(getFieldVal(info, 'Private_0019_10b0',[])));
              s(curSeries).dtiGradsCode = str2double(char(getFieldVal(info, 'Private_0019_10b2',[])));
          elseif(strcmp(info.Manufacturer,'SIEMENS'))
              bmtx = getFieldVal(info, 'Private_0019_1027', []);
              if(isempty(bmtx))
                  s(curSeries).dtiBMatrix = [];
                  s(curSeries).dtiBValue = 0;
                  s(curSeries).dtiGradDir = [1 0 0]';
              else
                  s(curSeries).dtiBMatrix = typecast(bmtx,'double');
                  s(curSeries).dtiBValue = norm(sqrt(s(curSeries).dtiBMatrix([1 4 6])))^2;
                  s(curSeries).dtiGradDir = sign(sign(s(curSeries).dtiBMatrix([1:3])) + 0.01).*sqrt(s(curSeries).dtiBMatrix([1 4 6])/s(curSeries).dtiBValue);
              end
          end
		  %ReferencedImageSequence
		  
		  %s(curSeries).imData = zeros(s(curSeries).dims);
		  %s(curSeries).imagePosition = zeros(3,s(curSeries).dims(3));
		  %s(curSeries).sliceNum = zeros(1,s(curSeries).dims(3));
		  % We'll set this to more meaningful values below
		  s(curSeries).imToScanXform = eye(4);
		  
		  fprintf('Loading series %d, acquisition %d...\n', s(curSeries).seriesNum, s(curSeries).acqNum);
        end
        s(curSeries).sliceNum(numSlice) = info.InstanceNumber;
        s(curSeries).imagePosition(:,numSlice) = info.ImagePositionPatient;
        s(curSeries).sliceLoc(numSlice) = info.SliceLocation;
        s(curSeries).fileName{numSlice} = dicomFiles{imNum};
        % Matlab seems to flip permute x and y when reading the data, so we do
        % a transpose here. Seems to make everything work better down the line.
        % *** RFD: need to flip dim 2 also?
        s(curSeries).imData(:,:,numSlice) = dicomread(info)';
        numSlice = numSlice+1;
	  end
	catch
	  disp(['failed to load ' curFile]);
	end
end

% sort the series properly
[junk,ind] = sort([s(:).seriesNum]);
s = s(ind);

% Sort the slices based on sliceNum and break timeseries up into separate
% volumes (good for fMRI and DTI acquisitions).

for(ii=1:numSeries)
    if(sortByFilenameFlag)
        [s(ii).sliceNum,sortInd] = sort(s(ii).fileName);
    else
        % Sort based on sliceNum (DICOM InstanceNumber).
        [s(ii).sliceNum,sortInd] = sort(s(ii).sliceNum);
    end
    s(ii).sliceLoc = s(ii).sliceLoc(sortInd);
    s(ii).imagePosition = s(ii).imagePosition(:,sortInd);
    s(ii).imData = s(ii).imData(:,:,sortInd);
    % Now compute the actual number of slices per timepoint
    uniqueSliceLoc = unique(s(ii).sliceLoc);
    s(ii).dims(3) = length(uniqueSliceLoc);
    s(ii).dims(4) = floor(length(sortInd)./s(ii).dims(3));
    if(prod(double(s(ii).dims))==numel(s(ii).imData))
        s(ii).imData = reshape(s(ii).imData, s(ii).dims);
    else
        warning(['Series ' num2str(ii) ' appears to contain >1 volume, but I can not guess the dimensions- keeping it a single vol.']);
    end
end

for(ii=1:length(s))
    if(isempty(s(ii).imData)) s(ii) = []; end
end
numSeries = length(s);

% Compute the scanner-to-image xform and resort the slices based on the
% slice normal.
for(ii=1:numSeries)
    % 2009.12.07 RFD: Pulled orientation code from NYU's dinifti
    dim = size(s(ii).imData);

    % Orientation information
    %-------------------------------------------------------------------
    % Axial Analyze voxel co-ordinate system:
    % x increases     right to left
    % y increases posterior to anterior
    % z increases  inferior to superior

    % DICOM patient co-ordinate system:
    % x increases     right to left
    % y increases  anterior to posterior
    % z increases  inferior to superior

    % T&T co-ordinate system:
    % x increases      left to right
    % y increases posterior to anterior
    % z increases  inferior to superior

    % Code lifted from dinifti source:
    % patient orientation cosines, in [Sag, Cor, Ax] order
    rowCosines = s(ii).imageOrientation(1:3);
    colCosines = s(ii).imageOrientation(4:6);
    sliceNorm = cross(rowCosines, colCosines);
    
    qto_xyz = zeros(4,4);
    qto_xyz(1,1) = -rowCosines(1); % -image->RowSagCos();
	qto_xyz(1,2) = -colCosines(1); % -image->ColSagCos();
	qto_xyz(1,3) = -sliceNorm(1); % -(rowCosines(2) * colCosines(3) - rowCosines(3) * colCosines(2)); % -image->SagNorm();

	qto_xyz(2,1) = -rowCosines(2); % -image->RowCorCos();
	qto_xyz(2,2) = -colCosines(2); % -image->ColCorCos();
	qto_xyz(2,3) = -sliceNorm(2); % -(rowCosines(3) * colCosines(1) - rowCosines(1) * colCosines(3)); % -image->CorNorm();

	qto_xyz(3,1) = rowCosines(3); % image->RowTraCos();
	qto_xyz(3,2) = colCosines(3); % image->ColTraCos();
	qto_xyz(3,3) = sliceNorm(3); % rowCosines(1) * colCosines(2) - rowCosines(2) * colCosines(1); % image->TraNorm();

    % *** TO DO: The most robust wayt to define slice order and slice
    % spacing is to project slice position onto slice normal.
    % From: http://nifti.nimh.nih.gov/board/read.php?f=1&i=579&t=508
    % Slice normal vector is the cross product of ImageOrientationPatient vectors.
    % Project each slice's ImagePositionPatient projection onto the slice normal 
    % to find it's position in the slice order list. 
    % pfirst = dot(sliceNorm,s(ii).imagePosition(:,1)) * sliceNorm;
    % plast = dot(sliceNorm,s(ii).imagePosition(:,end)) * sliceNorm;
    
    % Simple hack to decide if we need to flip the slice order:
    if(dot(sliceNorm,s(ii).imagePosition(:,1)) > dot(sliceNorm,s(ii).imagePosition(:,end)))
        s(ii).sliceNum = flipdim(s(ii).sliceNum,2);
        s(ii).sliceLoc = flipdim(s(ii).sliceLoc,2);
        s(ii).imagePosition = flipdim(s(ii).imagePosition,2);
        s(ii).imData = flipdim(s(ii).imData,3);
    end
    
	% offset = slicePosition(center) - M*(i,j,k of center) since we are working with the first slice k = 0.
        
    % For matlab's 1-indexing, we have to subtract mmPerVox from the origin
    % (imagePosition) to reflect the fact that the first voxel is [1,1,1]
    % rather than [0,0,0].
    pos = s(ii).imagePosition(:,1);
    qto_xyz(:,4) = [-pos(1) -pos(2) pos(3) 1]';
    qto_xyz(1:3,1:3) = qto_xyz(1:3,1:3)*diag(s(ii).mmPerVox);
    
    % Apply a 1-voxel offset to the origin to account for Matlab's
    % 1-indexing.
    qto_xyz = inv(inv(qto_xyz)+[0 0 0 1;0 0 0 1;0 0 0 1; 0 0 0 0]);
    
    
    s(ii).imToScanXform  = qto_xyz;
    
% OLD CODE:
%     s(ii).imToScanXform = eye(4);
%     % DICOM +Xd is Left, +Yd is Posterior, +Zd is Superior,
%     % while NIFTI is +x is Right, +y is Anterior, +z is Superior.
%     % So, x and y offsets get flipped.
%     %s(ii).imToScanXform(1:3,4) = s(ii).imagePosition(:,1).*[-1 -1 1]';
%     s(ii).imToScanXform(1:3,4) = -s(ii).imagePosition(:,1);
% 
%     % From the NIFTI-1 standard (Bob Cox):
%     % The DICOM attribute (0020,0037) "Image Orientation (Patient)"
%     % gives the orientation of the x- and y-axes of the image data
%     % in terms of 2 3-vectors. The first vector is a unit vector
%     % along the x-axis, and the second is along the y-axis. If the
%     % (0020,0037) attribute is extracted into the value
%     % (xa,xb,xc,ya,yb,yc), then the first two columns of the R
%     % matrix would be
%     %            [ -xa  -ya ]
%     %            [ -xb  -yb ]
%     %            [  xc   yc ]
%     % The negations are because DICOM's x- and y-axes are reversed
%     % relative to NIFTI's. The third column of the R matrix gives
%     % the direction of displacement (relative to the subject) along
%     % the slice-wise direction. This orientation is not encoded in
%     % the DICOM standard in a simple way; DICOM is mostly concerned
%     % with 2D images.  The third column of R will be either the
%     % cross-product of the first 2 columns or its negative.  It is
%     % possible to infer the sign of the 3rd column by examining the
%     % coordinates in DICOM attribute (0020,0032) "Image Position
%     % (Patient)" for successive slices.  However, this method
%     % occasionally fails for reasons that I (RW Cox) do not understand.
%     s(ii).imToScanXform(1:3,1) = s(ii).imageOrientation(1:3).*[-1 -1 1]';
%     s(ii).imToScanXform(1:3,2) = s(ii).imageOrientation(4:6).*[-1 -1 1]';
%     s(ii).imToScanXform(1:3,3) = cross(s(ii).imToScanXform(1:3,1),s(ii).imToScanXform(1:3,2));
%     if(s(ii).sliceLoc(1)>s(ii).sliceLoc(end))
%         % Slices run S-I, so signal a flip in this dim.
%         s(ii).imToScanXform(1:3,3) = -s(ii).imToScanXform(1:3,3);
%         s(ii).imToScanXform(3,4) = -s(ii).imToScanXform(3,4);
%     end
% 
%     % CHECK THIS: How to infer the orientation?
%     % Check to see if the image plane normal goes away from the
%     % center of the volume?
%     %if(s(ii).slicePos(1)<s(ii).slicePos(end))
%     %  s(ii).imToScanXform(1:3,3) = -s(ii).imToScanXform(1:3,3);
%     %end
%     s(ii).imToScanXform = s(ii).imToScanXform*diag([s(ii).mmPerVox 1]);
end


return;


function val = getFieldVal(s, fieldName, defaultValue)
    if(isfield(s,fieldName))
        val = s.(fieldName);
    else
        val = defaultValue;
    end
return;


