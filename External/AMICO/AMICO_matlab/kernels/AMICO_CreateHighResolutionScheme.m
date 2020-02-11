%
% Create the folder to simulate data with Camino at higher q-space resolution (500 directions per shell)
%
function AMICO_CreateHighResolutionScheme( filenameHR )
	global CONFIG

	% check if original scheme exists
	if ~exist( CONFIG.schemeFilename, 'file' ) && isempty(CONFIG.scheme)
		error( '[AMICO_CreateHighResolutionScheme] Scheme file "%s" not found', CONFIG.schemeFilename )
	end

	% create a high-resolution version of it (to be used with Camino)
	n = numel( CONFIG.scheme.shells );
	schemeHR = zeros( 500*n, 7 );
	bs       = zeros( 500*n, 1 );
	grad500 = dlmread( '500_dirs.txt', '', 0, 0 );
	for i = 1:size(grad500,1)
		grad500(i,:) = grad500(i,:) ./ norm( grad500(i,:) );
		if grad500(i,2) < 0
			grad500(i,:) = -grad500(i,:); % to ensure they are in the spherical range [0,180]x[0,180]
		end
	end
	row = 1;
	for i = 1:n
		schemeHR(row:row+500-1,1:3) = grad500;
		schemeHR(row:row+500-1,4)   = CONFIG.scheme.shells{i}.G;
		schemeHR(row:row+500-1,5)   = CONFIG.scheme.shells{i}.Delta;
		schemeHR(row:row+500-1,6)   = CONFIG.scheme.shells{i}.delta;
		schemeHR(row:row+500-1,7)   = CONFIG.scheme.shells{i}.TE;
		bs(row:row+500-1)           = CONFIG.scheme.shells{i}.b;
		row = row + 500;
	end

	fidCAMINO = fopen( filenameHR,'w+');
	if CONFIG.scheme.version == 0
		fprintf(fidCAMINO,'VERSION: BVECTOR\n');
		for d = 1:size(schemeHR,1)
			fprintf(fidCAMINO,'%15e %15e %15e %15e\n', schemeHR(d,1),schemeHR(d,2),schemeHR(d,3), bs(d) );
		end
	else
		fprintf(fidCAMINO,'VERSION: STEJSKALTANNER\n');
		for d = 1:size(schemeHR,1)
			fprintf(fidCAMINO,'%15e %15e %15e %15e %15e %15e %15e\n', schemeHR(d,1),schemeHR(d,2),schemeHR(d,3), schemeHR(d,4), schemeHR(d,5), schemeHR(d,6), schemeHR(d,7) );
		end
	end
	fclose(fidCAMINO);
end
