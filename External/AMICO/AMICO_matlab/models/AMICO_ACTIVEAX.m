classdef AMICO_ACTIVEAX

properties
    id, name                % id and name of the model
    dPar                    % parallel diffusivity of the tensors [units of mm^2/s]
    dIso                    % isotropic diffusivity [units of mm^2/s]
    IC_Rs                   % radii of the axons [units of 1E-6 (micrometers)]
    IC_VFs                  % volume fractions of the axons
    OUTPUT_names            % suffix of the output maps
    OUTPUT_descriptions     % description of the output maps
end


methods

    % =================================
    % Setup the parameters of the model
    % =================================
    function obj = AMICO_ACTIVEAX()
        global CONFIG

        % set the parameters of the model
        obj.id        = 'ACTIVEAX';
        obj.name      = 'ActiveAx';
        obj.dPar      = 0.6 * 1E-3;
        obj.dIso      = 2.0 * 1E-3;
        obj.IC_Rs     = [0.01 linspace(0.5,10,20)];
        obj.IC_VFs    = [0.3:0.1:0.9];

        obj.OUTPUT_names        = { 'v', 'a', 'd' };
        obj.OUTPUT_descriptions = {'Intra-cellular volume fraction', 'Mean axonal diameter', 'Axonal density'};

        % set the parameters to fit it
        CONFIG.OPTIMIZATION.SPAMS_param.mode    = 2;
        CONFIG.OPTIMIZATION.SPAMS_param.pos     = true;
        CONFIG.OPTIMIZATION.SPAMS_param.lambda  = 0.25; % l1 regularization
        CONFIG.OPTIMIZATION.SPAMS_param.lambda2 = 4;    % l2 regularization
    end


    % ==================================================================
    % Generate high-resolution kernels and rotate them in harmonic space
    % ==================================================================
    function GenerateKernels( obj, ATOMS_path, schemeHR, AUX, idx_IN, idx_OUT )
        global CONFIG AMICO_data_path CAMINO_path

        % check if high-resolution scheme has been created
        schemeHrFilename = fullfile(ATOMS_path,'protocol_HR.scheme');
        if ~exist( schemeHrFilename, 'file' )
            error( '[AMICO_GenerateKernels_ACTIVEAX] File "protocol_HR.scheme" not found in folder "%s"', ATOMS_path )
        end

        filenameHr = [tempname '.Bfloat'];
        progress = ProgressBar( numel(obj.IC_Rs) + numel(obj.IC_VFs) + 1 );

        % Restricted
        % ==========
        for R = obj.IC_Rs
            % generate
            if exist( filenameHr, 'file' ), delete( filenameHr ); end
            CMD = sprintf( '%s/datasynth -synthmodel compartment 1 CYLINDERGPD %E 0 0 %E -schemefile %s -voxels 1 -outputfile %s 2> /dev/null', CAMINO_path, obj.dPar*1e-6, R*1e-6, schemeHrFilename, filenameHr );
            [status result] = system( CMD );
            if status>0
                disp(result)
                error( '[AMICO_ACTIVEAX.GenerateKernels] Problems generating the signal with datasynth' );
            end

            % rotate and save
            fid = fopen( filenameHr, 'r', 'b' );
            signal = fread(fid,'float');
            fclose(fid);
            delete( filenameHr );
            lm = AMICO_RotateKernel( signal, AUX, idx_IN, idx_OUT, false );
            save( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), '-v6', 'lm' )
            progress.update();
        end


        % Hindered
        % ========
        for ICVF = obj.IC_VFs
            % generate
            d_perp = obj.dPar * ( 1.0 - ICVF );
            if exist( filenameHr, 'file' ), delete( filenameHr ); end
            CMD = sprintf( '%s/datasynth -synthmodel compartment 1 ZEPPELIN %E 0 0 %E -schemefile %s -voxels 1 -outputfile %s 2> /dev/null', CAMINO_path, obj.dPar*1e-6, d_perp*1e-6, schemeHrFilename, filenameHr );
            [status result] = system( CMD );
            if status>0
                disp(result)
                error( '[AMICO_ACTIVEAX.GenerateKernels] problems generating the signal' );
            end

            % rotate and save
            fid = fopen( filenameHr, 'r', 'b' );
            signal = fread(fid,'float');
            fclose(fid);
            delete( filenameHr );
            lm = AMICO_RotateKernel( signal, AUX, idx_IN, idx_OUT, false );
            save( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), '-v6', 'lm' )

            progress.update();
        end


        % Isotropic
        % =========
        % generate
        if exist( filenameHr, 'file' ), delete( filenameHr ); end
        CMD = sprintf( '%s/datasynth -synthmodel compartment 1 BALL %E -schemefile %s -voxels 1 -outputfile %s 2> /dev/null', CAMINO_path, obj.dIso*1e-6, schemeHrFilename, filenameHr );
        [status result] = system( CMD );
        if status>0
            disp(result)
            error( '[AMICO_ACTIVEAX.GenerateKernels] problems generating the signal' );
        end

        % resample and save
        fid = fopen( filenameHr, 'r', 'b' );
        signal = fread(fid,'float');
        fclose(fid);
        delete( filenameHr );
        lm = AMICO_RotateKernel( signal, AUX, idx_IN, idx_OUT, true );
        save( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), '-v6', 'lm' )
        progress.update();
        
        progress.close();
    end


    % ==============================================
    % Project kernels from harmonic to subject space
    % ==============================================
    function ResampleKernels( obj, ATOMS_path, idx_OUT, Ylm_OUT )
        global CONFIG AMICO_data_path KERNELS

        % Setup the KERNELS structure
        % ===========================
        nIC = numel(obj.IC_Rs);
        nEC = numel(obj.IC_VFs);

        KERNELS = {};
        KERNELS.model    = 'ACTIVEAX';
        KERNELS.nS       = CONFIG.scheme.nS;
        KERNELS.nA       = nIC + nEC + 1; % number of atoms

        KERNELS.dPar     = obj.dPar;

        KERNELS.Aic      = zeros( [KERNELS.nS nIC 181 181], 'single' );
        KERNELS.Aic_R    = zeros( 1, nIC, 'single' );

        KERNELS.Aec      = zeros( [KERNELS.nS nEC 181 181], 'single' );
        KERNELS.Aec_icvf = zeros( 1, nEC, 'single' );

        KERNELS.Aiso     = zeros( [KERNELS.nS 1], 'single' );
        KERNELS.Aiso_d   = NaN;
        
        progress = ProgressBar( KERNELS.nA );

        % Restricted
        % ==========
        for i = 1:nIC
            load( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), 'lm' );
            KERNELS.Aic(:,i,:,:) = AMICO_ResampleKernel( lm, idx_OUT, Ylm_OUT, false );
            KERNELS.Aic_R(i)     = obj.IC_Rs(i);
            progress.update();
        end

        % Hindered
        % ========
        for i = 1:nEC
            load( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), 'lm' );
            KERNELS.Aec(:,i,:,:) = AMICO_ResampleKernel( lm, idx_OUT, Ylm_OUT, false );
            KERNELS.Aec_icvf(i)  = obj.IC_VFs(i);
            progress.update();
        end

        % Isotropic
        % =========
        load( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), 'lm' );
        KERNELS.Aiso   = AMICO_ResampleKernel( lm, idx_OUT, Ylm_OUT, true );
        KERNELS.Aiso_d = obj.dIso;
        progress.update();

        progress.close();
    end


    % ===========================
    % Fit the model to each voxel
    % ===========================
    function [ MAPs ] = Fit( obj, y, i1, i2 )
        global CONFIG KERNELS

        % prepare SIGNAL and DICTIONARY
        if numel(KERNELS.Aiso_d) > 0
            A = double( [ KERNELS.Aic(CONFIG.scheme.dwi_idx,:,i1,i2) KERNELS.Aec(CONFIG.scheme.dwi_idx,:,i1,i2) KERNELS.Aiso(CONFIG.scheme.dwi_idx) ] );
        else
            A = double( [ KERNELS.Aic(CONFIG.scheme.dwi_idx,:,i1,i2) KERNELS.Aec(CONFIG.scheme.dwi_idx,:,i1,i2) ] );
        end
        AA = [ ones(1,KERNELS.nA) ; A ];
        yy = [ 1 ; y(CONFIG.scheme.dwi_idx) ];

        % estimate coefficients
        x = full( mexLasso( yy, AA, CONFIG.OPTIMIZATION.SPAMS_param ) );

        % compute MAPS
        nIC = numel(obj.IC_Rs);
        nEC = numel(obj.IC_VFs);
        f1 = sum( x( 1:nIC ) );
        f2 = sum( x( (nIC+1):(nIC+nEC) ) );
        MAPs(1) = f1 / ( f1 + f2 + eps );                           % intra-cellular volume fraction (v)
        MAPs(2) = 2 * KERNELS.Aic_R * x(1:nIC) / ( f1 + eps );      % mean axonal diameter
        MAPs(3) = (4*MAPs(1)) / ( pi*MAPs(2)^2 + eps );             % axonal density
    end

end

end
