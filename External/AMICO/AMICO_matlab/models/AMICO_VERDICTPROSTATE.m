classdef AMICO_VERDICTPROSTATE

properties
    id, name                % id and name of the model
    max_dirs                % maximum number of directions to fit
    dIC                     %
    Rs                      %
    dEES                    %
    P                       %
    OUTPUT_names            % suffix of the output maps
    OUTPUT_descriptions     % description of the output maps
end


methods

    % =================================
    % Setup the parameters of the model
    % =================================
    function obj = AMICO_VERDICTPROSTATE()
        global CONFIG

        % set the parameters of the model
        obj.id        = 'VerdictProstate';
        obj.name      = 'VERDICT prostate';
        obj.max_dirs  = 0; % no need to estimate directions, it's an isotropic model
        obj.dIC       = 2.0 * 1E-3;
        obj.Rs        = linspace(0.01,20.1,20);
        obj.dEES      = 2.0 * 1E-3;
        obj.P         = 8.0 * 1E-3;
        obj.OUTPUT_names        = {'R', 'fIC', 'fEES', 'fVASC', 'Fobj'};
        obj.OUTPUT_descriptions = {'R', 'fIC', 'fEES', 'fVASC', 'Fobj'};

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
        global CONFIG AMICO_data_path CAMINO_path

        % check if high-resolution scheme has been created
        schemeHrFilename = fullfile(ATOMS_path,'protocol_HR.scheme');
        if ~exist( schemeHrFilename, 'file' )
            error( '[AMICO_VERDICTPROSTATE.GenerateKernels] File "protocol_HR.scheme" not found in folder "%s"', ATOMS_path )
        end

        filenameHr = [tempname '.Bfloat'];
        progress = ProgressBar( numel(obj.Rs) + 2 );

        % IC compartment
        % ==============
        for R = obj.Rs
            % generate
            if exist( filenameHr, 'file' ), delete( filenameHr ); end
            CMD = sprintf( '%s/datasynth -synthmodel compartment 1 SPHEREGPD %E %E -schemefile %s -voxels 1 -outputfile %s 2> /dev/null', CAMINO_path, obj.dIC*1e-6, R*1e-6, schemeHrFilename, filenameHr );
            [status result] = system( CMD );
            if status>0
                disp(result)
                error( '[AMICO_VERDICTPROSTATE.GenerateKernels] Problems generating the signal with datasynth' );
            end

            % rotate and save
            fid = fopen( filenameHr, 'r', 'b' );
            signal = fread(fid,'float');
            fclose(fid);
            delete( filenameHr );
            lm = AMICO_RotateKernel( signal, AUX, idx_IN, idx_OUT, true );
            save( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), '-v6', 'lm' )
            progress.update();
        end


        % EES compartment
        % ===============
        % generate
        if exist( filenameHr, 'file' ), delete( filenameHr ); end
        CMD = sprintf( '%s/datasynth -synthmodel compartment 1 BALL %E -schemefile %s -voxels 1 -outputfile %s 2> /dev/null', CAMINO_path, obj.dEES*1e-6, schemeHrFilename, filenameHr );
        [status result] = system( CMD );
        if status>0
            disp(result)
            error( '[AMICO_VERDICTPROSTATE.GenerateKernels] problems generating the signal' );
        end

        % resample and save
        fid = fopen( filenameHr, 'r', 'b' );
        signal = fread(fid,'float');
        fclose(fid);
        delete( filenameHr );
        lm = AMICO_RotateKernel( signal, AUX, idx_IN, idx_OUT, true );
        save( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), '-v6', 'lm' )
        progress.update();

    
        % VASC compartment
        % ================
        % generate
        if exist( filenameHr, 'file' ), delete( filenameHr ); end
        CMD = sprintf( '%s/datasynth -synthmodel compartment 1 ASTROSTICKS %E -schemefile %s -voxels 1 -outputfile %s 2> /dev/null', CAMINO_path, obj.P*1e-6, schemeHrFilename, filenameHr );
        [status result] = system( CMD );
        if status>0
            disp(result)
            error( '[AMICO_VERDICTPROSTATE.GenerateKernels] problems generating the signal' );
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
        nIC = numel(obj.Rs);

        KERNELS = {};
        KERNELS.model    = 'VERDICTPROSTATE';
        KERNELS.nS       = CONFIG.scheme.nS;
        KERNELS.nA       = nIC + 2; % number of atoms

        KERNELS.Aic      = zeros( [KERNELS.nS nIC], 'single' );
        KERNELS.Aic_R    = zeros( 1, nIC, 'single' );

        KERNELS.Aees      = zeros( [KERNELS.nS 1], 'single' );
        KERNELS.Aees_d    = NaN;

        KERNELS.Avasc     = zeros( [KERNELS.nS 1], 'single' );
        KERNELS.Avasc_P   = NaN;
        
        progress = ProgressBar( KERNELS.nA );


        % IC compartment
        % ==============
        for i = 1:nIC
            load( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), 'lm' );
            KERNELS.Aic(:,i) = AMICO_ResampleKernel( lm, idx_OUT, Ylm_OUT, true );
            KERNELS.Aic_R(i) = obj.Rs(i);
            progress.update();
        end
        
        % Precompute norms of coupled atoms (for the l1 minimization)
        A = double( KERNELS.Aic(CONFIG.scheme.dwi_idx,:) );
        KERNELS.Aic_norm = repmat( 1./sqrt( sum(A.^2) ), [size(A,1),1] );
        clear A

        % EES compartment
        % ===============
        load( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), 'lm' );
        KERNELS.Aees   = AMICO_ResampleKernel( lm, idx_OUT, Ylm_OUT, true );
        KERNELS.Aees_d = obj.dEES;
        progress.update();

        % VASC compartment
        % ================
        load( fullfile( ATOMS_path, sprintf('A_%03d.mat',progress.i) ), 'lm' );
        KERNELS.Avasc   = AMICO_ResampleKernel( lm, idx_OUT, Ylm_OUT, true );
        KERNELS.Avasc_P = obj.P;
        progress.update();

        progress.close();
    end


    % ===========================
    % Fit the model to each voxel
    % ===========================
    function [ MAPs ] = Fit( obj, y, i1, i2 )
        global CONFIG KERNELS

%         A = double( [ KERNELS.Aic(CONFIG.scheme.dwi_idx,:) KERNELS.Aees(CONFIG.scheme.dwi_idx) KERNELS.Avasc(CONFIG.scheme.dwi_idx) ] );
%         AA = [ ones(1,KERNELS.nA) ; A ];
%         yy = [ 1 ; y(CONFIG.scheme.dwi_idx) ];
        A = double( [ KERNELS.Aic KERNELS.Aees KERNELS.Avasc ] );
        AA = A;%[ ones(1,KERNELS.nA) ; A ];
        yy = y;%[ 1 ; y(CONFIG.scheme.dwi_idx) ];

        switch( 1 )
        
            case 1
            % [ normal fitting ]
            norms = repmat( 1./sqrt(sum(AA.^2)), [size(AA,1),1] );
            AA = AA .* norms;
            x = full( mexLasso( yy, AA, CONFIG.OPTIMIZATION.SPAMS_param ) );
            x = x .* norms(1,:)';
            
            case 2
            params = CONFIG.OPTIMIZATION.SPAMS_param;
            params.loss = 'square';
            params.regul = 'group-lasso-l2';
            params.groups = int32([ repmat(1,1,numel(KERNELS.Aic_R)) 2 3 ]);  % all the groups are of size 2
            params.intercept = false;
            x = full( mexFistaFlat( yy, AA, zeros(size(A,2),1), params ) );

            case 3
            % [NODDI style] estimate and remove EES and VASC contributions
            y = y(CONFIG.scheme.dwi_idx);
            x = lsqnonneg( AA, yy, CONFIG.OPTIMIZATION.LS_param );
            y = y - x(end)*A(:,end);
            y = y - x(end-1)*A(:,end-1);

            % find sparse support for remaining signal
            An = A(:,1:size(KERNELS.Aic,2)) .* KERNELS.Aic_norm;
            x = full( mexLasso( y, An, CONFIG.OPTIMIZATION.SPAMS_param ) );

            % debias coefficients
            idx = [ x>0 ; true ; true ];
            x(idx) = lsqnonneg( AA(:,idx), yy, CONFIG.OPTIMIZATION.LS_param );
        end

        % compute MAPS
        xIC = x( 1:end-2 );
        fIC = sum( xIC );
        MAPs(1) = KERNELS.Aic_R * xIC / ( fIC + eps );           % cell radius
        MAPs(2) = fIC;                                           % fIC
        MAPs(3) = x( end-1 );                                    % fEES
        MAPs(4) = x( end );                                      % fVASC
        
        y_predicted = A*x;
        MAPs(5) = norm(y-y_predicted) / norm(y);
%         sigma = 0;
%         MAPs(5) = sum( (y - sqrt((y_predicted).^2+sigma^2) ) ).^2;
    end

    
end

end
