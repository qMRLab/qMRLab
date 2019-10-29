function [ KRlm ] = AMICO_RotateKernel( K, AUX, idx_IN, idx_OUT, isIsotropic )

	if ( isIsotropic == false )
		% fit SH and rotate kernel to 181*181 directions
		KRlm = zeros( size(AUX.fit,1), 181, 181, 'single' );
		for ox = 1:181
		for oy = 1:181
			Ylm_rot = AUX.Ylm_rot{ ox, oy };
			for s = 1 : numel(idx_IN)
				Klm = AUX.fit * K( idx_IN{s} );		% fit SH of shell to rotate
				Rlm = zeros( size(Klm) );
				idx = 1;
				for l = 0 : 2 : AUX.lmax
					const = sqrt(4.0*pi/(2.0*l+1.0)) * Klm( (l*l + l + 2.0)/2.0 );
					for m = -l : l
						Rlm(idx) = const * Ylm_rot(idx);
						idx = idx+1;
					end
				end
				KRlm( idx_OUT{s}, ox, oy ) = single( Rlm );
			end
		end
		end
	else
		% simply fit SH
		KRlm = zeros( size(AUX.fit,1), 1, 1, 'single' );
		Ylm_rot = AUX.Ylm_rot{ 1, 1 };
		for s = 1:numel(idx_IN)
			KRlm( idx_OUT{s}, 1, 1 ) = single( AUX.fit * K( idx_IN{s} ) );
		end
end
