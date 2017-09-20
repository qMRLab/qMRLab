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
        MRIinputs = {'Diffusiondata','Mask'};
        xnames = { 'L1','L2','L3'};
        voxelwise = 1;
        
        % fitting options
        st           = [ 2      0.7     0.7]; % starting point
        %         lb            = [  0       0       0       0]; % lower bound
        %         ub           = [ 1        3       3       3]; % upper bound
        fx            = [ 0        0        0]; % fix parameters
        
        % Protocol
        Prot = struct('DiffusionData',...
                    struct('Format',{{'Gx' 'Gy'  'Gz'   '|G|'  'Delta'  'delta'  'TE'}},...
                            'Mat',txt2mat(fullfile(fileparts(which('qMRLab.m')),'Data', 'NODDI_DTI_demo', 'Protocol.txt'),'InfoLevel',0))); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options = struct();
        
    end
    
    methods
        function obj = DTI
            obj.options = button2opts(obj.buttons);
        end
        function obj = UpdateFields(obj)
            obj.fx = [0 0 0]; 
        end
        
        function [Smodel, fiberdirection] = equation(obj, x)
            if isnumeric(x), x = mat2struct(x,obj.xnames); end
            Prot   = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,0,1);
            bvec   = Prot(:,1:3);
            bvalue = scd_scheme_bvalue(Prot);
            D      = zeros(3,3);
            if isnumeric(x)
                if min(size(x)==[3 3])
                    D = x;
                else
                    D = diag(x);
                end
            else
                if isfield(x,'D'), D(:) = x.D;
                else D(1,1) = x.L1; D(2,2) = x.L2; D(3,3) = x.L3;
                end
            end
            Smodel = exp(-bvalue.*diag(bvec*D*bvec'));
            
            % compute Fiber Direction
            [V,L] = eig(D);
            [L,I] = max(diag(L));
            fiberdirection = V(:,I);
        end
        
        function FitResults = fit(obj,data)
            if isempty(obj.Prot.DiffusionData.Mat) || size(obj.Prot.DiffusionData.Mat,1) ~= length(data.Diffusiondata(:)), errordlg('Load a valid protocol'); FitResults = []; return; end
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,0,1);
            data = data.Diffusiondata;
            % fit
            D=scd_model_dti(data./scd_preproc_getS0(data,Prot),Prot);
            [~,L] = eig(D); L = sort(diag(L),'descend');
            FitResults.L1 = L(1);
            FitResults.L2 = L(2);
            FitResults.L3 = L(3);
            FitResults.D  = D(:);
            % compute metrics
            L_mean = sum(L)/3;
            FitResults.FA = sqrt(3/2)*sqrt(sum((L-L_mean).^2))/sqrt(sum(L.^2));
            
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
                data = data.Diffusiondata;
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
            sigma  = max(Smodel)/Opt.SNR;
            data.Diffusiondata = ricernd(Smodel,sigma);
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
        
        function SimVaryResults = Sim_Sensitivity_Analysis(obj, SNR, runs)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, SNR, runs);
            
        end
        
        
    end
end