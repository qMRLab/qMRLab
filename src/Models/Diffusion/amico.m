classdef amico < noddi
% amico:   Accelerated Microstructure Imaging via Convex Optimization
%          Sub-module of noddi
%<a href="matlab: figure, imshow Diffusion.png ;">Pulse Sequence Diagram</a>
%
% ASSUMPTIONS:
%   Neuronal fibers model:
%     geometry                          sticks (Dperp = 0)
%     Orientation dispersion            YES (Watson distribution). Note that NODDI is more robust to
%                                                                   crossing fibers that DTI  (Campbell, NIMG 2017)
%
%     Permeability                      NO
%   Diffusion properties:
%     intra-axonal                      totally restricted
%       diffusion coefficient (Dr)      fixed by default.
%     extra-axonal                      Tortuosity model. Parallel diffusivity is equal to
%                                         intra-diffusivity.Perpendicular diffusivity is
%                                         proportional to fiber density
%       diffusion coefficient (Dh)      Constant
%
% Inputs:
%   DiffusionData       4D diffusion weighted dataset
%   (Mask)               Binary mask to accelerate the fitting (OPTIONAL)
%
% Outputs:
%   di                  Diffusion coefficient in the restricted compartment.
%   ficvf               Fraction of water in the restricted compartment.
%   fiso                Fraction of water in the isotropic compartment (e.g. CSF/Veins)
%   fr                  Fraction of restricted water in the entire voxel (e.g. intra-cellular volume fraction)
%                        fr = ficvf*(1-fiso)
%   irfrac              Fraction of isotropically restricted compartment (Dot for ex vivo model)
%   diso (fixed)        diffusion coefficient of the isotropic compartment (CSF)
%   kappa               Orientation dispersion index
%   b0                  Signal at b=0
%   theta               angle of the fibers
%   phi                 angle of the fibers
%
% Protocol:
%   Multi-shell diffusion-weighted acquisition
%    at least 2 non-zeros bvalues
%    at least 5 b=0 (used to compute noise standard deviation
%
%   DiffusionData       Array [NbVol x 7]
%     Gx                Diffusion Gradient x
%     Gy                Diffusion Gradient y
%     Gz                Diffusion Gradient z
%     Gnorm (T/m)         Diffusion gradient magnitude
%     Delta (s)         Diffusion separation
%     delta (s)         Diffusion duration
%     TE (s)            Echo time
%
% Options:
%   Model               Model part of NODDI.
%                         Available models are:
%                           -WatsonSHStickTortIsoVIsoDot_B0 is a four model compartment used for ex-vivo datasets
%
% Example of command line usage
%   For more examples: <a href="matlab: qMRusage(noddi);">qMRusage(noddi)</a>
%
% Author: Tanguy Duval
%
% References:
%   Please cite the following if you use this module:
%     Alessandro Daducci, Erick Canales-Rodriguez, Hui Zhang, Tim Dyrby, Daniel Alexander, Jean-Philippe Thiran, 2015. Accelerated Microstructure Imaging via Convex Optimization (AMICO) from diffusion MRI data. NeuroImage 105, pp. 32-44
%     Zhang, H., Schneider, T., Wheeler-Kingshott, C.A., Alexander, D.C., 2012. NODDI: practical in vivo neurite orientation dispersion and density imaging of the human brain. Neuroimage 61, 1000?1016.
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

methods (Hidden=true)
% Hidden methods goes here.
end

    methods
        function obj = amico
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
            AMICO_Setup;            
        end

        function obj = UpdateFields(obj)
            global CONFIG
            obj = UpdateFields@noddi(obj);
            AMICO_SetModel( 'NODDI' );
            
            % Dot compartment?
            if strcmp(obj.options.modelname,'WatsonSHStickTortIsoVIsoDot_B0')
                CONFIG.model.isExvivo=true; % Dot compartment in ex vivo
            end

            CONFIG.model.dPar = obj.st(strcmp(obj.xnames,'di')).* 1E-3;
            CONFIG.model.dIso = obj.st(strcmp(obj.xnames,'diso')).* 1E-3;
            
            % fix di and diso
            obj.fx(strcmp(obj.xnames,'di'))  = 1;
            obj.fx(strcmp(obj.xnames,'diso')) = 1;
        end

        function obj = Precompute(obj)
            global CONFIG AMICO_data_path KERNELS ProtLUTable
            % Read scheme
            CONFIG.b0_thr = 1;
            CONFIG.scheme = AMICO_LoadSchemeMAT(obj.Prot.DiffusionData.Mat,CONFIG.b0_thr);

            AMICO_SetModel( 'NODDI' );
            
            % Dot compartment?
            if strcmp(obj.options.modelname,'WatsonSHStickTortIsoVIsoDot_B0')
                CONFIG.model.isExvivo=true; % Dot compartment in ex vivo
            end
            
            % rotation matrices
            lmax = 12;
            AMICO_PrecomputeRotationMatrices(lmax);
            
            if ~isempty(KERNELS) && isfield(ProtLUTable,'scheme') && isequal(ProtLUTable.scheme,obj.Prot.DiffusionData.Mat)
                doResampleKernels = false;
            else
                doResampleKernels = true;
            end
            
            ModelDefault = noddi;
            if isequal(obj.Prot.DiffusionData.Mat(:,4:end),ModelDefault.Prot.DiffusionData.Mat(:,4:end))
                CONFIG.protocol = 'example';
            elseif isfield(ProtLUTable,'scheme') && isequal(ProtLUTable.scheme(:,4:end),obj.Prot.DiffusionData.Mat(:,4:end))
                CONFIG.protocol = ProtLUTable.name;
            else
                CONFIG.protocol = 'custom';
                if exist(fullfile(AMICO_data_path,'custom'),'dir')
                    rmdir(fullfile(AMICO_data_path,'custom'),'s')
                end
            end
            CONFIG.schemeFilename = [];
            % COMPUTE KERNELS
            h = msgbox('Generate Kernels (Lookup Table) for this protocol...');
            AMICO_GenerateKernels( false );
            if ishandle(h), delete(h); end
                        
            if doResampleKernels
                h = msgbox('Resample Kernels for this protocol...');
                AMICO_ResampleKernels();
                if ishandle(h), delete(h); end
            end

            % SAVE SCHEME ASSOCIATED WITH THIS KERNEL
            ProtLUTable.name = CONFIG.protocol;
            ProtLUTable.scheme = obj.Prot.DiffusionData.Mat;

        end

        function FitResults = fit(obj,data)
            global CONFIG ProtLUTable
            % Check CONFIG
            if ~isfield(CONFIG,'scheme') || ~isfield(CONFIG,'model') || ~isfield(ProtLUTable,'scheme') || ~isequal(ProtLUTable.scheme,obj.Prot.DiffusionData.Mat)
                obj.Precompute();
            end
            
            % B-matrix to be used in DTI fitting
            % ==================================
            XYZB = CONFIG.scheme.camino(:,1:3);
            XYZB(:,4) = CONFIG.scheme.b;
            bMATRIX = zeros([3 3 size(XYZB,1)]);
            for ii = 1:size(XYZB,1)
                bMATRIX(:,:,ii) = XYZB(ii,4) * XYZB(ii,1:3)' * XYZB(ii,1:3);
            end
            bMATRIX = squeeze([bMATRIX(1,1,:),2*bMATRIX(1,2,:),2*bMATRIX(1,3,:),bMATRIX(2,2,:),2*bMATRIX(2,3,:),bMATRIX(3,3,:)])';
            clear XYZB
            
            % Read the signal
            b0 = mean( squeeze( data.DiffusionData(CONFIG.scheme.b0_idx) ) );
            if ( b0 < 1e-3 )
                vox_MAPs = [NaN NaN NaN];
                vox_DIRs = [NaN; NaN; NaN];
            else
                y = double( squeeze( data.DiffusionData ) ./ ( b0 + eps ) );
                y( y < 0 ) = 0; % [NOTE] this should not happen!
                
                % Find the MAIN DIFFUSION DIRECTIONS
                % using DTI
                [ ~, ~, V ] = AMICO_FitTensor( y, bMATRIX );
                vox_DIRs = V(:,1);
                if ( vox_DIRs(2)<0 ), vox_DIRs = -vox_DIRs; end
                [ i1, i2 ] = AMICO_Dir2idx( vox_DIRs );
                % Dispatch to the right handler for each model
                vox_MAPs = CONFIG.model.Fit( y, i1, i2 );
            end
            
            outputsName = CONFIG.model.OUTPUT_names;
            outputsName = {'ficvf' 'ODI' 'fiso' 'irfrac'}; 
            for io = 1:length(CONFIG.model.OUTPUT_names)
                FitResults.(outputsName{io}) = vox_MAPs(io);
            end
            FitResults.kappa = 1 ./ tan(FitResults.ODI*pi/2)/10;
            FitResults.di = CONFIG.model.dPar * 1E3;
            FitResults.diso = CONFIG.model.dIso * 1E3;
            FitResults.b0 = b0;
            FitResults.theta = acos(vox_DIRs(3));
            FitResults.phi = asin(vox_DIRs(2)/sin(FitResults.theta));
            FitResults.fr  = FitResults.ficvf*(1-FitResults.fiso);
        end


    end

    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);

            if checkanteriorver(version,[2 4 1])
            
                obj.tabletip = struct('table_name',{{'DiffusionData'}},'tip', ...
                {{sprintf(['G[x,y,z]: Diffusion gradient directions.\nGnorm (T / m): Diffusion gradient magnitudes.\nDelta (s): Diffusion separation\n' ...
                'delta (s): Diffusion duration\nTE (s): Echo time.\n\n------------------------\n You can populate these fields using bvec and bval files by following the prompted instructions.\n------------------------'])}},'link',{{'https://github.com/qMRLab/qMRLab/issues/299#issuecomment-451210324'}});
                
            end

        end
    end

end
