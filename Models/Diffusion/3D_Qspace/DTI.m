classdef DTI
%-----------------------------------------------------------------------------------------------------
% DTI :  FILL
%-----------------------------------------------------------------------------------------------------
%-------------%
% ASSUMPTIONS %
%-------------% 
% (1) FILL
% (2) 
% (3) 
% (4) 
%
%-----------------------------------------------------------------------------------------------------
%--------%
% INPUTS %
%--------%
%   FILL 
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%	FILL
%      
%-----------------------------------------------------------------------------------------------------
%----------%
% PROTOCOL %
%----------%
%   FILL
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OPTIONS %
%---------%
%   FILL
%
%---------%
% METHODS %
%---------%
%  plotmodel - Plot the diffusion-weighted signal as a function of Gparallel
%               EXAMPLE:
%               A = DTI;
%               L1 = 1; L2 = 1; L3 = 3; % um2/ms
%               A.plotmodel([L1 L2 L3]);
%  doThat - Description of doThat
%-----------------------------------------------------------------------------------------------------
% Written by: FILL
% Reference: FILL
%-----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'DiffusionData','SigmaNoise','Mask'};
        xnames = { 'L1','L2','L3'};
        voxelwise = 1;
        
        % fitting options
        st           = [ 2      0.7     0.7]; % starting point
        lb           = [ 0       0       0 ]; % lower bound
        ub           = [ 5       5       5 ]; % upper bound
        fx           = [ 0       0        0]; % fix parameters
        
        % Protocol
        Prot = struct('DiffusionData',...
                    struct('Format',{{'Gx' 'Gy'  'Gz'   '|G|'  'Delta'  'delta'  'TE'}},...
                            'Mat',txt2mat(fullfile(fileparts(which('qMRLab.m')),'Data', 'NODDI_DTI_demo', 'Protocol.txt'),'InfoLevel',0))); % You can define a default protocol here.
        
        % Model options
        buttons = {'PANEL','Rician noise bias',2,'Method', {'Compute Sigma per voxel','fix sigma'}, 'value',10,...
            'Compute Sigma per voxel',true};
        options = struct();
        
    end
    
    methods
        function obj = DTI
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        function obj = UpdateFields(obj)
            obj.fx = [0 0 0]; 
            Prot = obj.Prot.DiffusionData.Mat;
            Prot(Prot(:,4)==0,1:6) = 0;
            [~,c,ind] = consolidator(Prot(:,1:7),[],'count');
            cmax = max(c); % find images repeated more than 5 times (for relevant STD)
            if cmax<2
                warndlg({'Your dataset doesn''t have 2 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise. Specify a fixed Sigma Noise in the option panel instead.'  'See Methods Noise/NoiseLevel.m to estimate the noise standard deviation.'},'Noise estimation method')
                obj.options.Riciannoisebias_Method = 'fix sigma';
            elseif cmax<4
                warndlg({'Your dataset doesn''t have 4 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise accurately. Specify a fixed Sigma Noise in the option panel instead.'  'See Methods Noise/NoiseLevel.m to estimate the noise standard deviation.'},'Noise estimation method')
            end
            if strcmp(obj.options.Riciannoisebias_Method,'Compute Sigma per voxel')
                obj.options.Riciannoisebias_value  = 'auto';
            elseif isempty(obj.options.Riciannoisebias_value)
                obj.options.Riciannoisebias_value=10;
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
            % fit
            D=scd_model_dti(data.DiffusionData./S0,Prot);
            % RICIAN NOISE
            % use Rician noise and fix b=0
            % use Rician noise and fix b=0
            if isfield(data,'SigmaNoise') && ~isempty(data.SigmaNoise)
                SigmaNoise = data.SigmaNoise(1);
            elseif strcmp(obj.options.Riciannoisebias_Method,'Compute Sigma per voxel')
                SigmaNoise = computesigmanoise(obj.Prot.DiffusionData.Mat,data.DiffusionData);
                if ~SigmaNoise, return; end
            else
                SigmaNoise = obj.options.Riciannoisebias_value;
            end
            
            if ~moxunit_util_platform_is_octave
                [xopt, residue] = fminunc(@(x) double(-2*sum(scd_model_likelihood_rician(data.DiffusionData,max(eps,S0.*equation(obj, x)), SigmaNoise))), D(:), optimoptions('fminunc','MaxIter',20,'display','off','DiffMinChange',0.03));
                D(:)=xopt;
                FitResults.residue = residue;
            end

            % compute metrics
            [~,L] = eig(D); L = sort(diag(L),'descend');
            FitResults.L1 = L(1);
            FitResults.L2 = L(2);
            FitResults.L3 = L(3);
            FitResults.D  = D(:);
            L_mean = sum(L)/3;
            FitResults.FA = sqrt(3/2)*sqrt(sum((L-L_mean).^2))/sqrt(sum(L.^2));
                % S0
            S0vals = unique([S0 Prot(:,7)],'rows');
            for ii = 1:size(S0vals,1)
                FitResults.(['S0_TE' num2str(round(S0vals(ii,2)))]) = S0vals(ii,1);
            end

        end
        
        function plotmodel(obj, FitResults, data)
            % plotmodel(obj, FitResults, data)
            % EXAMPLE: 
            %   A = DTI;
            %   L1 = 1; L2 = 1; L3 = 3;
            %   A.plotmodel([L1 L2 L3]);
            
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
                    if ~moxunit_util_platform_is_octave
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
            scd_scheme_display_3D_Delta_delta_G(ConvertProtUnits(obj.Prot.DiffusionData.Mat))
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
                plotmodel(obj, FitResults, data);
                hold on
                Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1,1);
                h = scd_display_qspacedata3D(Smodel,Prot,fiberdirection,'o','none');
                set(h,'LineWidth',.5)
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
end