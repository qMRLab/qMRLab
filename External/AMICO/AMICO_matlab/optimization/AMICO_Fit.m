%
% Call the Fit() method of the model to fit
%
function AMICO_Fit()

	global CONFIG niiSIGNAL niiMASK bMATRIX

	% Fit right model to each voxel
    % =============================
	if ~isempty(CONFIG.model)

        % fit the model to the data
        fprintf( '\n-> Fitting "%s" model to %d voxels:\n', CONFIG.model.name, nnz(niiMASK.img) );
        TIME = tic;
        progress = ProgressBar( nnz(niiMASK.img) );
        for iz = 1:niiSIGNAL.hdr.dime.dim(4)
        for iy = 1:niiSIGNAL.hdr.dime.dim(3)
        for ix = 1:niiSIGNAL.hdr.dime.dim(2)
            if niiMASK.img(ix,iy,iz)==0, continue, end
            progress.update();
            
            try
                % Read the signal
                b0 = mean( squeeze( niiSIGNAL.img(ix,iy,iz,CONFIG.scheme.b0_idx) ) );
                if ( b0 < 1e-3 ), continue, end
                y = double( squeeze( niiSIGNAL.img(ix,iy,iz,:) ) ./ ( b0 + eps ) );
                y( y < 0 ) = 0; % [NOTE] this should not happen!

                % Find the MAIN DIFFUSION DIRECTIONS
                if any(strcmp(properties(CONFIG.model), 'max_dirs'))==false || CONFIG.model.max_dirs>0
                    % using DTI
                    [ ~, ~, V ] = AMICO_FitTensor( y, bMATRIX );
                    vox_DIRs = V(:,1);
                    if ( vox_DIRs(2)<0 ), vox_DIRs = -vox_DIRs; end
                    [ i1, i2 ] = AMICO_Dir2idx( vox_DIRs );
                    DIRs(ix,iy,iz,:) = vox_DIRs;
                else
                    % not needed by the model
                    DIRs(ix,iy,iz,:) = 0;
                    i1 = 1;
                    i2 = 1;
                end

                % Dispatch to the right handler for each model
                vox_MAPs = CONFIG.model.Fit( y, i1, i2 );

                % Store results
                MAPs(ix,iy,iz,:) = vox_MAPs;
            catch exception
                % set output maps to NaN in case of problems
                MAPs(ix,iy,iz,:) = NaN;
            end
        end
        end
        end
        progress.close();

        TIME = toc(TIME);
        fprintf( '   [ %.0fh %.0fm %.0fs ]\n', floor(TIME/3600), floor(mod(TIME/60,60)), mod(TIME,60) )
		CONFIG.OPTIMIZATION.fit_time = TIME;
	else
		error( '[AMICO_Fit] Model not set' )
    end


	% Save CONFIGURATION and OUTPUT to file
    % =====================================
    fprintf( '\n-> Saving output to "AMICO/*":\n' );

    fprintf( '\t- CONFIG.mat' );
    save( fullfile(CONFIG.OUTPUT_path,'CONFIG.mat'), '-v6', 'CONFIG' )
    fprintf( ' [OK]\n' );

    fprintf( '\t- FIT_dir.nii' );
    niiMAP = niiMASK;
    niiMAP.hdr.dime.dim(1) = 4;
    niiMAP.hdr.dime.datatype = 16;
    niiMAP.hdr.dime.bitpix = 32;
    niiMAP.hdr.dime.glmin = -1;
    niiMAP.hdr.dime.glmax = 1;
    niiMAP.hdr.dime.calmin = niiMAP.hdr.dime.glmin;
    niiMAP.hdr.dime.calmax = niiMAP.hdr.dime.glmax;
    niiMAP.hdr.dime.scl_slope = 1;
    niiMAP.hdr.dime.scl_inter = 0;

    niiMAP.img = DIRs;
    niiMAP.hdr.dime.dim(5) = size(DIRs,4);
    save_untouch_nii( niiMAP, fullfile(CONFIG.OUTPUT_path,'FIT_dir.nii') );
    fprintf( ' [OK]\n' );

    niiMAP.hdr.dime.dim(5) = 1;
    for i = 1:numel(CONFIG.model.OUTPUT_names)
        fprintf( '\t- AMICO/FIT_%s.nii', CONFIG.model.OUTPUT_names{i} );

        niiMAP.img = MAPs(:,:,:,i);
        niiMAP.hdr.hist.descrip = CONFIG.model.OUTPUT_descriptions{i};
        niiMAP.hdr.dime.glmin = min(niiMAP.img(:));
        niiMAP.hdr.dime.glmax = max(niiMAP.img(:));
        niiMAP.hdr.dime.calmin = niiMAP.hdr.dime.glmin;
        niiMAP.hdr.dime.calmax = niiMAP.hdr.dime.glmax;
        save_untouch_nii( niiMAP, fullfile(CONFIG.OUTPUT_path,['FIT_' CONFIG.model.OUTPUT_names{i} '.nii']) );

        fprintf( ' [OK]\n' );
    end

    fprintf( '   [ DONE ]\n' )
end
