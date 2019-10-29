classdef AMICO_WATERFREE

properties
    id, name                % id and name of the model
    dPar                    % parallel diffusivity of the tensors [units of mm^2/s]
    dPer                    % perpendicular diffusivities of the tensors [units of mm^2/s]
    dIso                    % isotropic diffusivities [units of mm^2/s]
    OUTPUT_names            % suffix of the output maps
    OUTPUT_descriptions     % description of the output maps
end


methods

    % =================================
    % Setup the parameters of the model
    % =================================
	function obj = AMICO_WATERFREE()
        global CONFIG

        % set the parameters of the model
        obj.id        = 'WATERFREE';
        obj.name      = 'Water free';
        obj.dPar      = 1.7 * 1E-3;
        obj.dIso      = [2.0 3.0] * 1E-3;
        obj.dPer      = linspace(0.1,1.0,10) * 1E-3;

        obj.OUTPUT_names        = { 'ICVF', 'ISOVF' };
        obj.OUTPUT_descriptions = {'Intra-cellular volume fraction', 'Isotropic volume fraction'};

        % set the parameters to fit it
        CONFIG.OPTIMIZATION.SPAMS_param.mode    = 2;
        CONFIG.OPTIMIZATION.SPAMS_param.pos     = true;
        CONFIG.OPTIMIZATION.SPAMS_param.lambda  = 0;    % l1 regularization
        CONFIG.OPTIMIZATION.SPAMS_param.lambda2 = 1e-3; % l2 regularization
    end


    % ==================================================================
    % Generate high-resolution kernels and rotate them in harmonic space
    % ==================================================================
    function GenerateKernels( obj, ATOMS_path, schemeHR, AUX, idx_IN, idx_OUT )
        global CONFIG AMICO_data_path

        % Tensor compartments
        % ===================
        idx = 1;
        for i = 1:numel(obj.dPer)
            TIME = tic();
            fprintf( '\t\t- A_%03d... ', idx );

            % generate
            D = diag( [obj.dPer(i) obj.dPer(i) obj.dPar] );
            signal = obj.TensorSignal( D, schemeHR.camino );

            % rotate and save
            lm = AMICO_RotateKernel( signal, AUX, idx_IN, idx_OUT, false );
            save( fullfile( ATOMS_path, sprintf('A_%03d.mat',idx) ), '-v6', 'lm' )
            idx = idx + 1;

            fprintf( '[%.1f seconds]\n', toc(TIME) );
        end


        % Isotropic compartments
        % ======================
        for i = 1:numel(obj.dIso)
            TIME = tic();
            fprintf( '\t\t- A_%03d... ', idx );

            % generate
            D = diag( [obj.dIso(i) obj.dIso(i) obj.dIso(i)] );
            signal = obj.TensorSignal( D, schemeHR.camino );

            % resample and save
            lm = AMICO_RotateKernel( signal, AUX, idx_IN, idx_OUT, true );
            save( fullfile( ATOMS_path, sprintf('A_%03d.mat',idx) ), '-v6', 'lm' )
            idx = idx + 1;

            fprintf( '[%.1f seconds]\n', toc(TIME) );
        end

    end


    % ==============================================
    % Project kernels from harmonic to subject space
    % ==============================================
    function ResampleKernels( obj, ATOMS_path, idx_OUT, Ylm_OUT )
        global CONFIG AMICO_data_path KERNELS

        % Setup the KERNELS structure
        % ===========================
        n1 = numel(obj.dPer);
        n2 = numel(obj.dIso);
        KERNELS = {};
        KERNELS.nS       = CONFIG.scheme.nS;
        KERNELS.nA       = n1 + n2; % number of atoms
        KERNELS.A1       = zeros( [KERNELS.nS n1 181 181], 'single' );
        KERNELS.A2       = zeros( [KERNELS.nS n2], 'single' );


        % Tensors
        % =======
        idx = 1;
        for i = 1:n1
            TIME = tic();
            fprintf( '\t- A_%03d...  ', idx );

            load( fullfile( ATOMS_path, sprintf('A_%03d.mat',idx) ), 'lm' );
            KERNELS.A1(:,i,:,:) = AMICO_ResampleKernel( lm, idx_OUT, Ylm_OUT, false );
            idx = idx + 1;

            fprintf( '[%.1f seconds]\n', toc(TIME) );
        end


        % Isotropic
        % =========
        for i = 1:n2
            TIME = tic();
            fprintf( '\t- A_%03d...  ', idx );

            load( fullfile( ATOMS_path, sprintf('A_%03d.mat',idx) ), 'lm' );
            KERNELS.A2(:,i,:,:) = AMICO_ResampleKernel( lm, idx_OUT, Ylm_OUT, true );
            idx = idx + 1;

            fprintf( '[%.1f seconds]\n', toc(TIME) );
        end

    end


    % ===========================
    % Fit the model to each voxel
    % ===========================
    function [DIRs, MAPs] = Fit( obj )
        global CONFIG
        global niiSIGNAL niiMASK
        global KERNELS bMATRIX

        % setup the output files
        MAPs         = zeros( [CONFIG.dim(1:3) numel(obj.OUTPUT_names)], 'single' );
        DIRs         = zeros( [CONFIG.dim(1:3) 3], 'single' );
        niiY = niiSIGNAL;
        
        n1 = numel(obj.dPer);
        n2 = numel(obj.dIso);

        fprintf( '\n-> Fitting "%s" model to data:\n', obj.name );
        TIME = tic();
        for iz = 1:niiSIGNAL.hdr.dime.dim(4)
        for iy = 1:niiSIGNAL.hdr.dime.dim(3)
        for ix = 1:niiSIGNAL.hdr.dime.dim(2)
            if niiMASK.img(ix,iy,iz)==0, continue, end

            % read the signal
            b0 = mean( squeeze( niiSIGNAL.img(ix,iy,iz,CONFIG.scheme.b0_idx) ) );
            if ( b0 < 1e-3 ), continue, end
            y = double( squeeze( niiSIGNAL.img(ix,iy,iz,:) ) ./ ( b0 + eps ) );
            y( y < 0 ) = 0; % [NOTE] this should not happen!

            % build the DICTIONARY
            [ i1, i2 ] = AMICO_Dir2idx( Vt );
            A = double( [ KERNELS.A1(CONFIG.scheme.dwi_idx,:,i1,i2) KERNELS.A2(CONFIG.scheme.dwi_idx,:) ] );

            % fit AMICO
            y = y(CONFIG.scheme.dwi_idx);
            yy = [ 1 ; y ];
            AA = [ ones(1,size(A,2)) ; A ];

            % estimate CSF partial volume and remove it
            x = full( mexLasso( yy, AA, CONFIG.OPTIMIZATION.SPAMS_param ) );
            
            % STORE results	
            DIRs(ix,iy,iz,:) = Vt; % fiber direction

            MAPs(ix,iy,iz,1) = sum( x(1:n1) ) / ( sum(x) + eps ); % intracellular volume fraction

            MAPs(ix,iy,iz,2) = 1 - MAPs(ix,iy,iz,1); % isotropic volume fraction
        
            x(n1+1:end) = 0;
            niiY.img(ix,iy,iz,CONFIG.scheme.dwi_idx) = AA(2:end,:)*x*b0;
                        
        end
        end
        end
        save_untouch_nii(niiY, 'dwi_fw_corrected.nii');
        TIME = toc(TIME);
        fprintf( '   [ %.0fh %.0fm %.0fs ]\n', floor(TIME/3600), floor(mod(TIME/60,60)), mod(TIME,60) )

        % compute MAPS
        n1 = numel(obj.dPer);
        MAPs    = zeros( [1 numel(obj.OUTPUT_names)], 'single' );
        MAPs(1) = sum( x(1:n1) ) / ( sum(x) + eps ); % intracellular volume fraction
        MAPs(2) = 1 - MAPs(1);                       % isotropic volume fraction
    end


    % ================================================================
    % Simulate signal according to tensor model (1 fiber along z-axis)
    % ================================================================
    function [ signal ] = TensorSignal( obj, D, XYZB )
        nDIR   = size( XYZB, 1 );
        signal = zeros( nDIR, 1 );
        for d = 1:nDIR
            signal(d) = exp(-XYZB(d,4) * XYZB(d,1:3) * D * XYZB(d,1:3)');
        end
    end

end

end
