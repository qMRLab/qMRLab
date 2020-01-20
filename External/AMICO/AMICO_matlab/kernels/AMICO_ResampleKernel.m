function [ K ] = AMICO_ResampleKernel( Klm, idx_OUT, Ylm_OUT, isIsotropic )
	global CONFIG

	if ( isIsotropic == false )
		K = ones( CONFIG.scheme.nS, 181, 181, 'single' ); % initialize to 1 for b0
		for ox = 1:181
		for oy = 1:181
			K( idx_OUT, ox, oy ) = single( Ylm_OUT * Klm( :, ox, oy ) );
		end
		end
	else
		K = ones( CONFIG.scheme.nS, 1, 1, 'single' ); % initialize to 1 for b0
		K( idx_OUT, 1, 1 ) = single( Ylm_OUT * Klm );
	end
