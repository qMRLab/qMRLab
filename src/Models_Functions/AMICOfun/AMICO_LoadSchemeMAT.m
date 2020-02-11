% Load scheme file (must be in camino format)
%
% Parameters
% ----------
% filename : string
% 	The filename of the Camino scheme file
% b0_thr : float
% 	The threshold on b-values to identify the b0 images
%
% Returns
% -------
% scheme : struct
% 	Contains all the information about the acquisition parameters for each image
function [ scheme ] = AMICO_LoadSchemeMAT( MAT, b0_thr )
	if nargin < 2, b0_thr = 1; end
	scheme = {};
	scheme.version = 'STEJSKALTANNER';
    scheme.camino = MAT;

	% ensure the directions are in the spherical range [0,180]x[0,180]
	idx = scheme.camino(:,2) < 0;
	scheme.camino(idx,1:3) = -scheme.camino(idx,1:3);

	scheme.nS = size(scheme.camino,1); % number of volumes

	switch ( scheme.version )
		case { '0', 'BVECTOR' }
			scheme.version = 0;
			scheme.b = scheme.camino(:,4);
		case { '1', 'STEJSKALTANNER' }
			scheme.version = 1;
			scheme.b = ( 267.513e6 * scheme.camino(:,4) .* scheme.camino(:,6) ).^2 .* (scheme.camino(:,5) - scheme.camino(:,6)/3) * 1e-6; % in mm^2/s
		otherwise
			error( '[AMICO_LoadScheme] Unrecognized scheme type' );
	end

	% store information about the volumes
	tmp = find( scheme.b > b0_thr );
	scheme.dwi_count = numel( tmp );
	scheme.dwi_idx   = tmp;
	tmp = find( scheme.b <= b0_thr );
	scheme.b0_count = numel( tmp );
	scheme.b0_idx   = tmp;


	% get unique parameters (ie shells)
	if scheme.version == 0
		[schemeUnique,ia] = unique( scheme.camino(:,4), 'rows', 'stable' );
	else
		[schemeUnique,ia] = unique( scheme.camino(:,4:7), 'rows', 'stable' );
	end

	% store information about each shell in a dictionary
	n = size(schemeUnique,1);
	bUnique = scheme.b(ia);
	scheme.shells = {};
	for i = 1:n
		if bUnique(i) > b0_thr
			scheme.shells{end+1}     = {};
			if scheme.version == 0
				scheme.shells{end}.G     = NaN;
				scheme.shells{end}.Delta = NaN;
				scheme.shells{end}.delta = NaN;
				scheme.shells{end}.TE    = NaN;
			else
				scheme.shells{end}.G     = schemeUnique(i,1);
				scheme.shells{end}.Delta = schemeUnique(i,2);
				scheme.shells{end}.delta = schemeUnique(i,3);
				scheme.shells{end}.TE    = schemeUnique(i,4);
			end
			scheme.shells{end}.b     = bUnique(i);

			if scheme.version == 0
				scheme.shells{end}.idx   = find( all(bsxfun(@eq,scheme.camino(:,4),schemeUnique(i,:)),2) );
			else
				scheme.shells{end}.idx   = find( all(bsxfun(@eq,scheme.camino(:,4:7),schemeUnique(i,:)),2) );
			end
			scheme.shells{end}.grad  = scheme.camino( scheme.shells{end}.idx, 1:3 );
		end
	end
