%
% Precompute the rotation matrices to rotate the high-resolution kernels (500 directions)
%
% Parameters
% ----------
% lmax : unsigned int
%   Maximum spherical harmonics order to use for the rotation phase
%
function AMICO_PrecomputeRotationMatrices( lmax )
	if nargin < 1, lmax = 12; end
	global AMICO_data_path

	fprintf( '\n-> Precomputing rotation matrices for l_max=%d:\n', lmax );

	filename = fullfile(AMICO_data_path,sprintf('AUX_matrices__lmax=%d.mat',lmax) );
	if exist( filename, 'file' )
		fprintf( '   [ already computed ]\n' );
		return
	end

	TIME = tic();

	% load file with 500 directions
	grad500 = importdata( '500_dirs.txt' );
	for i = 1:size(grad500,1)
		grad500(i,:) = grad500(i,:) ./ norm( grad500(i,:) );
        if grad500(i,2) < 0
            grad500(i,:) = -grad500(i,:);
        end
	end

	% precompute the matrix to fit the SH coefficients
	[colatitude, longitude] = AMICO_Cart2sphere( grad500(:,1), grad500(:,2), grad500(:,3) );
	Ylm = AMICO_CreateYlm( lmax, colatitude, longitude );
	fit = pinv( Ylm'*Ylm ) * Ylm';

	% precompute the matrices to rotate the functions in SH space
	Ylm_rot = {};
	for ox = 0:180
	for oy = 0:180
		Ylm_rot{ox+1,oy+1} = AMICO_CreateYlm( lmax, ox/180.0*pi, oy/180.0*pi );
	end
	end

	save( filename , 'Ylm_rot', 'fit', 'lmax' );
	fprintf( '   [ %.1f seconds ]\n', toc(TIME) );
end
