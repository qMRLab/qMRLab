%
% Resample rotate kernels to the acquisition protocol used for the specific subject
%
% Parameters
% ----------
% lmax : unsigned int
%   Maximum spherical harmonics order to use for the rotation phase
%
function AMICO_ResampleKernels( lmax )
	if nargin < 1, lmax = 12; end
	global CONFIG AMICO_data_path KERNELS

	TIME = tic();
	fprintf( '\n-> Resampling rotated kernels:\n');

	% check if original scheme exists
	if ~exist( CONFIG.schemeFilename, 'file' ) && isempty(CONFIG.scheme)
		error( '[AMICO_ResampleKernels] File "%s" not found', CONFIG.schemeFilename )
	end

	% check if auxiliary matrices have been precomputed
	auxFilename = fullfile(AMICO_data_path,sprintf('AUX_matrices__lmax=%d.mat',lmax) );
	if ~exist( auxFilename, 'file' )
		error( '[AMICO_ResampleKernels] Auxiliary matrices "%s" not found', auxFilename )
	else
		AUX = load( auxFilename );
	end


	% Precompute aux data structures
	% ==============================
	nSH = (AUX.lmax+1)*(AUX.lmax+2)/2;
	idx_OUT = zeros(CONFIG.scheme.dwi_count,1,'single');
	Ylm_OUT = zeros(CONFIG.scheme.dwi_count,nSH*numel(CONFIG.scheme.shells),'single');
	idx = 1;
	for s = 1:numel(CONFIG.scheme.shells)
		nS = numel(CONFIG.scheme.shells{s}.idx);
		idx_OUT(idx:idx+nS-1) = CONFIG.scheme.shells{s}.idx;
		[colatitude, longitude] = AMICO_Cart2sphere( CONFIG.scheme.shells{s}.grad(:,1), CONFIG.scheme.shells{s}.grad(:,2), CONFIG.scheme.shells{s}.grad(:,3) );
		Ylm_OUT(idx:idx+nS-1, [1:nSH]+(s-1)*nSH) = AMICO_CreateYlm( AUX.lmax, colatitude, longitude ); % matrix from SH to real space
		idx = idx + nS;
	end
	
	
	% Dispatch to the right handler for each model
	% ============================================
    if ~isempty(CONFIG.model)
		CONFIG.model.ResampleKernels( fullfile(AMICO_data_path,CONFIG.protocol,'kernels',CONFIG.model.id), idx_OUT, Ylm_OUT );
	else
		error( '[AMICO_ResampleKernels] Model not set' )
	end


	fprintf( '   [ %.1f seconds ]\n', toc(TIME) );
end
