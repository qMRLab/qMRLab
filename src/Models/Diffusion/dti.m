classdef dti < AbstractModel
%dti: Compute a tensor from diffusion data
%
% Assumptions:
%   Anisotropic Gaussian diffusion tensor
%   Valid at relatively low b-value (i.e. ~< 2000 s/mm2)
%
% Inputs:
%   DiffusionData       4D DWI
%   (SigmaNoise)        map of the standard deviation of the noise per voxel. (OPTIONAL)
%   (Mask)              Binary mask to accelerate the fitting. (OPTIONAL)
%
% Outputs:
%   D                   [Dxx Dxy Dxz Dxy Dyy Dyz Dxz Dyz Dzz] Diffusion Tensor
%   L1                  1rst eigenvalue of D
%   L2                  2nd eigenvalue of D
%   L3                  3rd eigenvalue of D
%   FA                  Fractional Anisotropy: FA = sqrt(3/2)*sqrt(sum((L-L_mean).^2))/sqrt(sum(L.^2));
%   S0_TEXX             Signal at b=0 at TE=XX
%   (residue)           Fitting residuals
%
% Protocol:
%   At least 2 shells (e.g. b=1000 and b=0 s/mm2)
%   diffusion gradient direction in 3D
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
%   fitting type
%     'linear'                              Solves the linear problem (ln(S/S0) = -bD)
%     'non-linear (Rician Likelihood)'      Add an additional fitting step,
%                                            using the Rician Likelihood.
%   Rician noise bias                       only for non-linear fitting
%                                            SigmaNoise map is prioritary.
%     'Compute Sigma per voxel'             Sigma is estimated by computing the STD across repeated scans.
%     'fix sigma'                           Use scd_noise_std_estimation to measure noise level. Use 'value' to fix Sigma.
%
%
% Example of command line usage (see <a href="matlab: web(which('dti_batch.html'))"> dti_batch.html</a>):
%      Model = dti
%      %% LOAD DATA
%      data.DiffusionData = load_nii_data('DiffusionData.nii.gz');
%      data.SigmaNoise = load_nii_data('SigmaNoise.nii.gz');
%      data.Mask = load_nii_data('Mask.nii.gz');
%      %% FIT A SINGLE VOXEL
%      % Specific voxel:         datavox = extractvoxel(data,voxel);
%      % Interactive selection:  datavox = extractvoxel(data);
%      voxel       = round(size(data.DiffusionData(:,:,:,1))/2); % pick FOV center
%      datavox     = extractvoxel(data,voxel);
%      FitResults  = Model.fit(datavox);
%      Model.plotModel(FitResults, datavox); % plot fit results
%      %% FIT all voxels
%      FitResults = FitData(data,Model);
%      % SAVE results to NIFTI
%      FitResultsSave_nii(FitResults,'DiffusionData.nii.gz'); % use header from 'DiffusionData.nii.gz'
%
%   For more examples: <a href="matlab: qMRusage(dti);">qMRusage(dti)</a>
%
% Author: Tanguy Duval, 2016
%
% References:
%   Please cite the following if you use this module:
%     Basser, P.J., Mattiello, J., LeBihan, D., 1994. MR diffusion tensor spectroscopy and imaging. Biophys. J. 66, 259?267.
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
    onlineData_url = 'https://osf.io/qh87b/download?version=4';
end

    properties
        MRIinputs = {'DiffusionData','SigmaNoise','Mask'};
        xnames = {'L1','L2','L3'};
        voxelwise = 1;

        % fitting options
        st           = [ 2      0.7     0.7]; % starting point
        lb           = [ 0       0       0 ]; % lower bound
        ub           = [ 5       5       5 ]; % upper bound
        fx           = [ 0       0        0]; % fix parameters

        % Protocol
        Prot = struct('DiffusionData',...
                    struct('Format',{{'Gx' 'Gy'  'Gz'   'Gnorm'  'Delta'  'delta'  'TE'}},...
                            'Mat', txt2mat('NODDIProtocol.txt','InfoLevel',0))); % You can define a default protocol here.

        % Model options
        buttons = {'fitting type',{'non-linear (Rician Likelihood)','linear'},'PANEL','Rician noise bias',2,'Method', {'Compute Sigma per voxel','fix sigma'}, 'value',10};
        options = struct();

        tabletip = struct('table_name',{{'DiffusionData'}},'tip', ...
        {{sprintf(['G[x,y,z]: Diffusion gradient directions.\nGnorm (T / m): Diffusion gradient magnitudes.\nDelta (s): Diffusion separation\n' ...
        'delta (s): Diffusion duration\nTE (s): Echo time.\n\n------------------------\n You can populate these fields using bvec and bval files by following the prompted instructions.\n------------------------'])}},'link',{{'https://github.com/qMRLab/qMRLab/issues/299#issuecomment-451210324'}});

    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods
        function obj = dti
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        function obj = UpdateFields(obj)
            obj.fx = [0 0 0];
            Prot = obj.Prot.DiffusionData.Mat;
            Prot(Prot(:,4)==0,1:6) = 0;
            [~,c,ind] = consolidator(Prot(:,1:7),[],'count');
            cmax = max(c); % find images repeated more than 5 times (for relevant STD)
            if ~strcmp(obj.options.fittingtype,'linear') && ~strcmp(obj.options.Riciannoisebias_Method,'fix sigma')
            if cmax<2
                warndlg({'Your dataset doesn''t have 2 repeated measures (same bvec/bvals) --> you can''t estimate noise STD per voxel.' 'Using linear fitting instead (noise bias will impact your results).'},'Noise estimation method')
                obj.options.fittingtype = 'linear';
            elseif cmax<4
                warndlg({'Your dataset doesn''t have 4 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise accurately.'},'Noise estimation method')
            end
            end
            if strcmp(obj.options.Riciannoisebias_Method,'Compute Sigma per voxel')
                obj.options.Riciannoisebias_value  = 'auto';
            end

            % disable Rician noise panel if linear
            if strcmp(obj.options.fittingtype,'linear')
                obj.buttons{strcmp(obj.buttons,'Rician noise bias') | strcmp(obj.buttons,'###Rician noise bias')} = '###Rician noise bias';
            else
                obj.buttons{strcmp(obj.buttons,'Rician noise bias') | strcmp(obj.buttons,'###Rician noise bias')} = 'Rician noise bias';
            end
        end


        function [Smodel, fiberdirection] = equation(obj, x)
            if isnumeric(x) && length(x(:))==9, xtmp=x; clear x; x.D=xtmp(:); end
            x = mat2struct(x,obj.xnames);
            Prot   = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,0,1);
            bvec   = Prot(:,1:3);
            bvalue = scd_scheme_bvalue(Prot);
            D      = zeros(3,3);
            % parse input
            if isfield(x,'D'), D(:) = x.D; % full tensor
            else D(1,1) = x.L1; D(2,2) = x.L2; D(3,3) = x.L3;
            end

            % equation
            Smodel = exp(-bvalue.*diag(bvec*D*bvec'));

            % compute Fiber Direction
            [V,L] = eig(D);
            [L,I] = max(diag(L));
            fiberdirection = V(:,I);
        end

        function FitResults = fit(obj,data)
            if isempty(obj.Prot.DiffusionData.Mat) || size(obj.Prot.DiffusionData.Mat,1) ~= length(data.DiffusionData(:)), errordlg('Load a valid protocol'); FitResults = []; return; end
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,0,1);
            % normalize with respect to b0
            S0 = scd_preproc_getS0(data.DiffusionData,Prot);

            % Detect negative values
            if min(data.DiffusionData)<0
                %warning('Negative values detected in DiffusionData. threshold to 0.');
                data.DiffusionData = max(0,data.DiffusionData);
            end

            % fit
            D=scd_model_dti(max(eps,data.DiffusionData)./max(eps,S0),Prot);
            % RICIAN NOISE
            % use Rician noise and fix b=0
            residue=0;
            if strcmp(obj.options.fittingtype,'non-linear (Rician Likelihood)')
                if isfield(data,'SigmaNoise') && ~isempty(data.SigmaNoise)
                    SigmaNoise = data.SigmaNoise(1);
                elseif strcmp(obj.options.Riciannoisebias_Method,'Compute Sigma per voxel')
                    SigmaNoise = computesigmanoise(obj.Prot.DiffusionData.Mat,data.DiffusionData);
                else
                    SigmaNoise = obj.options.Riciannoisebias_value;
                end
                if isempty(SigmaNoise), SigmaNoise = max(data.DiffusionData/100); end


                if ~moxunit_util_platform_is_octave && SigmaNoise
                    [xopt, residue] = fminunc(@(x) double(-2*sum(scd_model_likelihood_rician(data.DiffusionData,max(eps,S0.*equation(obj, x)), SigmaNoise))), D(:), optimoptions('fminunc','MaxIter',20,'display','off','DiffMinChange',0.03,'Algorithm','quasi-newton'));
                    D(:)=xopt;
                end
            end
            % compute metrics
            [~,L] = eig(D); L = sort(diag(L),'descend');
            L_mean = sum(L)/3;
            FitResults.FA = sqrt(3/2)*sqrt(sum((L-L_mean).^2))/sqrt(sum(L.^2));
            FitResults.L1 = L(1);
            FitResults.L2 = L(2);
            FitResults.L3 = L(3);
            FitResults.D  = D(:);
            FitResults.residue = residue;
                % S0
            S0vals = unique([S0 Prot(:,7)],'rows');
            for ii = 1:size(S0vals,1)
                FitResults.(['S0_TE' num2str(round(S0vals(ii,2)))]) = S0vals(ii,1);
            end

        end

        function plotModel(obj, FitResults, data)
            % plotModel(obj, FitResults, data)
            % EXAMPLE:
            %   A = DTI;
            %   L1 = 1; L2 = 1; L3 = 3;
            %   A.plotModel([L1 L2 L3]);

            if nargin<2, FitResults=obj.st; end

            % Prepare inputs
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1,1);

            % compute model
            [Smodel, fiberdirection] = equation(obj, FitResults);

            % plot
            if exist('data','var')
                data = data.DiffusionData;
                h = scd_display_qspacedata3D(data,Prot,fiberdirection);
                S0 = scd_preproc_getS0(data,Prot);
                Smodel = S0.*Smodel;
                hold on
                % remove data legends
                for iD = 1:length(h)
                    if ~moxunit_util_platform_is_octave || (moxunit_util_platform_is_octave && ~str2double(getenv('ISCITEST')))
                        hAnnotation = get(h(iD),'Annotation');
                        hLegendEntry = get(hAnnotation','LegendInformation');
                        set(hLegendEntry,'IconDisplayStyle','off');
                    end
                end
            end

            % plot fitting curves
            scd_display_qspacedata3D(Smodel,Prot,fiberdirection,'none','-');
        end

        function plotProt(obj)
            % round bvalue
            Prot      = obj.Prot.DiffusionData.Mat;
            Prot(:,4) = round(scd_scheme2bvecsbvals(Prot)*100)*10;
            % display
            scd_scheme_display(Prot)
            subplot(2,2,4)
            scd_scheme_display_3D_Delta_delta_G(ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1,1))
        end

        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            if ~exist('display','var'), display=1; end
            Smodel = equation(obj, x);
            Opt.SNR=min(Opt.SNR,500);
            sigma  = max(Smodel)/Opt.SNR;
            data.DiffusionData = ricernd(Smodel,sigma);
            FitResults = fit(obj,data);
            D = zeros(3,3); D(:) = FitResults.D;
            [V,L] = eig(D);
            [L,I] = max(diag(L));
            fiberdirection = V(:,I);

            if display
                Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1,1);
                h = scd_display_qspacedata3D(Smodel,Prot,fiberdirection,'o','none');
                if ~moxunit_util_platform_is_octave || (moxunit_util_platform_is_octave && ~str2double(getenv('ISCITEST')))
                    set(h,'LineWidth',.5);
                end
                % remove data legends
                for iD = 1:length(h)
                    if ~moxunit_util_platform_is_octave || (moxunit_util_platform_is_octave && ~str2double(getenv('ISCITEST')))
                        hAnnotation  = get(h(iD),'Annotation');
                        hLegendEntry = get(hAnnotation','LegendInformation');
                        set(hLegendEntry,'IconDisplayStyle','off');
                    end
                end
                hold on
                plotModel(obj, FitResults, data);
            end
        end

        function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opt)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, Opt.Nofrun, OptTable, Opt);
        end

        function SimRndResults = Sim_Multi_Voxel_Distribution(obj, RndParam, Opt)
            % SimVaryGUI
            SimRndResults = SimRnd(obj, RndParam, Opt);
        end

    end

    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            obj.Prot.DiffusionData.Format{4}='Gnorm'; % old: '|G| (T/m)', new Gnorm (T/m)
            if checkanteriorver(version,[2 0 8])
                index = find(strcmp(obj.buttons,'Compute Sigma per voxel'));
               obj.buttons(index:(index+1)) = [];
               obj.options = rmfield(obj.options, 'ComputeSigmapervoxel');
            end

            % New fitting method
            if checkanteriorver(version,[2 0 9])
                obj.buttons = ['fitting type',{{'non-linear (Rician Likelihood)','linear'}}, obj.buttons];
                obj.options.fittingtype = 'non-linear (Rician Likelihood)';
            end
        end
    end

end
