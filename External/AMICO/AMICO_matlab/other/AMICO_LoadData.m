%
% Load data and perform some preprocessing
%
fprintf( '\n-> Loading and setup:\n' );

fprintf( '\t* Loading DWI...\n' );


% Load DWI dataset
% ================
niiSIGNAL = load_untouch_nii( CONFIG.dwiFilename );
niiSIGNAL.img = single(niiSIGNAL.img);
niiSIGNAL.img = reshape(niiSIGNAL.img,niiSIGNAL.hdr.dime.dim(2:5));

% Scale signal intensities (if necessary)
if ( niiSIGNAL.hdr.dime.scl_slope ~= 0 && ( niiSIGNAL.hdr.dime.scl_slope ~= 1 || niiSIGNAL.hdr.dime.scl_inter ~= 0 ) )
    fprintf( '\t\t- rescaling data\n' );
	niiSIGNAL.img = niiSIGNAL.img * niiSIGNAL.hdr.dime.scl_slope + niiSIGNAL.hdr.dime.scl_inter;
end

%  print the dimensions of the data
CONFIG.dim    = niiSIGNAL.hdr.dime.dim(2:5);
CONFIG.pixdim = niiSIGNAL.hdr.dime.pixdim(2:4);
fprintf( '\t\t- dim    = %d x %d x %d x %d\n' , CONFIG.dim );
fprintf( '\t\t- pixdim = %.3f x %.3f x %.3f\n', CONFIG.pixdim );


% Acquisition scheme
% ==================
fprintf( '\t* Loading SCHEME...\n' );
CONFIG.scheme = AMICO_LoadScheme( CONFIG.schemeFilename, CONFIG.b0_thr );
if CONFIG.scheme.nS ~= CONFIG.dim(4)
	error( '[AMICO_LoadData] Data and scheme do not match\n' );
end
fprintf( '\t\t- %d measurements divided in %d shells (%d b=0)\n', CONFIG.scheme.nS, numel(CONFIG.scheme.shells), CONFIG.scheme.b0_count );


% BINARY mask
% ===========
fprintf( '\t* Loading MASK...\n' );
if exist(CONFIG.maskFilename,'file')
    niiMASK = load_untouch_nii( CONFIG.maskFilename );
    if nnz( CONFIG.dim(1:3) - niiMASK.hdr.dime.dim(2:4) ) > 0
        error( '[AMICO_LoadData] Data and mask do not match\n' );
    end
    fprintf( '\t\t- dim    = %d x %d x %d\n' , niiMASK.hdr.dime.dim(2:4) );
else
    niiMASK = [];
    niiMASK.hdr = niiSIGNAL.hdr;
    niiMASK.hdr.dime.datatype = 2;
    niiMASK.hdr.dime.bitpix = 8;
    niiMASK.hdr.dime.dim([1 5]) = [3 1];
    niiMASK.untouch =  1;
    niiMASK.img = ones( niiSIGNAL.hdr.dime.dim(2:4), 'uint8' );
end
fprintf( '\t\t- voxels = %d\n' , nnz(niiMASK.img) );


% B-matrix to be used in DTI fitting
% ==================================
XYZB = CONFIG.scheme.camino(:,1:3);
XYZB(:,4) = CONFIG.scheme.b;
bMATRIX = zeros([3 3 size(XYZB,1)]);
for i = 1:size(XYZB,1)
	bMATRIX(:,:,i) = XYZB(i,4) * XYZB(i,1:3)' * XYZB(i,1:3);
end
bMATRIX = squeeze([bMATRIX(1,1,:),2*bMATRIX(1,2,:),2*bMATRIX(1,3,:),bMATRIX(2,2,:),2*bMATRIX(2,3,:),bMATRIX(3,3,:)])';
clear XYZB i


fprintf( '   [ DONE ]\n' );
