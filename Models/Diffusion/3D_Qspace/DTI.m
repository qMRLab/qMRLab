classdef DTI
    properties
        MRIinputs = {'Diffusiondata','Mask'};
        xnames = { 'L1','L2','L3'};
        voxelwise = 1;
        
        % fitting options
        %         st           = [ 0.7	0.5    0.5	 0.5]; % starting point
        %         lb            = [  0       0       0       0]; % lower bound
        %         ub           = [ 1        3       3       3]; % upper bound
        %         fx            = [ 0        0        0       0]; % fix parameters
        
        % Protocol
        Prot = struct('DiffusionData',...
                    struct('Format',{{'Gx' 'Gy'  'Gz'   '|G|'  'Delta'  'delta'  'TE'}},...
                            'Mat',txt2mat('DefaultProtocol_NODDI.scheme'))); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options= struct();
        
    end
    
    methods
        function obj = DTI
            obj = button2opts(obj);
        end
        
        function Smodel = equation(obj, x)
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat);
            bvec = Prot(:,1:3);
            bvalue = scd_scheme_bvalue(Prot);
            D = zeros(3,3);
            if isfield(x,'D'), D(:) = x.D;
            else, D(1,1) = x.L1; D(2,2) = x.L2; D(3,3) = x.L3;
            end
            Smodel = exp(-bvalue.*diag(bvec*D*bvec'));
        end
        
        function FitResults = fit(obj,data)
            if isempty(obj.Prot.DiffusionData.Mat) || size(obj.Prot.DiffusionData.Mat,1)~=length(data.Diffusiondata(:)), errordlg('Load a valid protocol'); FitResults=[]; return; end
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat);
            data = data.Diffusiondata;
            % fit
            D=scd_model_dti(data./scd_preproc_getS0(data,Prot),Prot);
            [~,L]=eig(D); L = sort(diag(L),'descend');
            FitResults.L1=L(1);
            FitResults.L2=L(2);
            FitResults.L3=L(3);
            FitResults.D=D(:);
            % compute metrics
            L_mean = sum(L)/3;
            FitResults.FA = sqrt(3/2)*sqrt(sum((L-L_mean).^2))/sqrt(sum(L.^2));
            
        end
        
        function plotmodel(obj, FitResults, data)
            if isempty(FitResults), return; end
            data = data.Diffusiondata;
            % Prepare inputs
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat);
            
            % compute model
            Smodel = equation(obj, FitResults);
            
            % compute Xaxis
            D = zeros(3,3); D(:) = FitResults.D;
            [V,L]=eig(D);
            [L,I]=max(diag(L));
            fiberdirection=V(:,I);
            
            % plot
            if exist('data','var')
                h = scd_display_qspacedata3D(data,Prot,fiberdirection);
                S0 = scd_preproc_getS0(data,Prot);
                Smodel = S0.*Smodel;
                hold on
                % remove data legends
                for iD = 1:length(h)
                    hAnnotation = get(h(iD),'Annotation');
                    hLegendEntry = get(hAnnotation','LegendInformation');
                    set(hLegendEntry,'IconDisplayStyle','off');
                end
            end
            
            % plot fitting curves
            scd_display_qspacedata3D(Smodel,Prot,fiberdirection,'none','-');
        end
        
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, SNR,display)
            if ~exist('display','var'), display=1; end
            Smodel = equation(obj, x);
            sigma = max(Smodel)/SNR;
            data.Diffusiondata = random('rician',Smodel,sigma);
            FitResults = fit(obj,data);
            D = zeros(3,3); D(:) = FitResults.D;
            [V,L]=eig(D);
            [L,I]=max(diag(L));
            fiberdirection=V(:,I);
            
            if display
                plotmodel(obj, FitResults, data);
                hold on
                Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat);
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


function scheme = ConvertSchemeUnits(scheme)
% convert units
scheme(:,4)=scheme(:,4).*sqrt(sum(scheme(:,1:3).^2,2))*1e-3; % G mT/um
scheme(:,1:3)=scheme(:,1:3)./repmat(sqrt(scheme(:,1).^2+scheme(:,2).^2+scheme(:,3).^2),1,3); scheme(isnan(scheme))=0;
scheme(:,5) = scheme(:,5)*10^3; % DELTA ms
scheme(:,6) = scheme(:,6)*10^3; % delta ms
scheme(:,7) = scheme(:,7)*10^3; % TE ms
gyro = 42.57; % kHz/mT
scheme(:,8) = gyro*scheme(:,4).*scheme(:,6); % um-1

% Find different shells
list_G=unique(round(scheme(:,[4 5 6 7])*1e5)/1e5,'rows');
nnn = size(list_G,1);
for j = 1 : nnn
    for i = 1 : size(scheme,1)
        if  min(round(scheme(i,[4 5 6 7])*1e5)/1e5 == list_G(j,:))
            scheme(i,9) = j;
        end
    end
end
%scheme(ismember(scheme(:,9),find(list_G(:,1)==0)),9) = find(list_G(:,1)==0,1,'first');
end
