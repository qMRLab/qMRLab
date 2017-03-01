classdef MTSAT
    properties
        MRIinputs = {'MT','T1', 'PD', 'Mask'};
        xnames = {};
        
        % fitting options
        st           =  [ ]; % starting point
        lb            = [ ]; % lower bound
        ub           = [ ]; % upper bound
        fx            = []; % fix parameters
        
        % Protocol
        ProtFormat ={'Flip Angle' 'TR'}; 
        Prot  = [5 0.031; 5 0.031; 15 0.011]; % You can define a default protocol here.

        % Model options
        buttons = {'offset frequency (Hz)', 1000};
        options= struct();
        
    end
    
    methods
        function Smodel = equation(obj, x)
            Prot = ConvertSchemeUnits(obj.Prot);
            bvec = Prot(:,1:3);
            bvalue = scd_scheme_bvalue(Prot);
            D = zeros(3,3); D(:) = x.D;
            Smodel = exp(-bvalue.*diag(bvec*D*bvec'));
        end
        
        function FitResults = fit(obj,data)
            MTparams = obj.Prot(1,:);
            PDparams = obj.Prot(2,:);
            T1params = obj.Prot(3,:);
            MTSATdata = MTSAT_exec(data, MTparams, PDparams, T1params);
            Prot = ConvertSchemeUnits(obj.Prot);
            data = data.MTdata;
            % fit
            D=scd_model_dti(data./scd_preproc_getIb0(data,Prot),Prot);
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
            data = data.MTdata;
            % Prepare inputs
            Prot = ConvertSchemeUnits(obj.Prot);
            
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
                S0 = scd_preproc_getIb0(data,Prot);
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
scheme(ismember(scheme(:,9),find(list_G(:,1)==0)),9) = find(list_G(:,1)==0,1,'first');
end
