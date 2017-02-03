classdef CHARMED
    properties
        MRIinputs = {'MTdata','Mask'};
        xnames = {'fh','Dh','diameter_mean','fcsf'};
        
        % fitting options
        st           = [0.6     0.7        6       0.2          ]; % starting point
        lb            = [0       0.3        3          0               ]; % lower bound
        ub           = [1       3         10         1                ]; % upper bound
        fx            = [0      0           0           0               ]; % fix parameters
        
        % Protocol
        ProtFormat = {'Gx' 'Gy'  'Gz'   '|G|'  'Delta'  'delta'  'TE'}; % columns of the Protocol matrix. 
        Prot  = [ones(100,1) zeros(100,2) linspace(0,300,100)'*1e-3 0.040*ones(100,1) 0.003*ones(100,1) 0.070*ones(100,1)];
        
        % Model options
        buttons = {'Dcsf',3,'Dr',1.4,'Sigma of the noise',10,'Compute Sigma per voxel',true};
        options= struct();

    end
    
    methods
        function Smodel = equation(obj, x)
            x(5)=x(4); % parameter #4 is diameter STD, CSF is parameter #5
            opt=obj.options;
            opt.scheme=ConvertSchemeUnits(obj.Prot);
            Smodel = scd_model_CHARMED(x,opt);
        end
        
        
        function FitResults = fit(obj,data)
            % Prepare data
            data = data.MTdata; nT=length(data);
            if nT~=size(obj.Prot,1), error(['<strong>Error: your diffusion dataset has ' num2str(nT) ' volumes while your schemefile has ' num2str(size(obj.Prot,1)) ' rows.</strong>']); end

            Prot = ConvertSchemeUnits(obj.Prot);

            S0 = scd_preproc_getIb0(data,Prot);
            
            %% FITTING
            % initiate with Gaussian noise assumption --> more stable fitting
            fixedparam=obj.fx;
            [xopt, residue] = lsqcurvefit(@(x,scheme) S0.*equation(obj, addfixparameters(obj.st,x,fixedparam)),obj.st(~fixedparam),Prot,double(data),double(obj.lb(~fixedparam)),double(obj.ub(~fixedparam)),optimoptions('lsqcurvefit','MaxIter',20,'display','off'));
            obj.st(~fixedparam)=xopt; xopt = obj.st;
            
            % use Rician noise and fix fix b=0
            if obj.options.ComputeSigmaPerVoxel
                SigmaNoise = computesigmanoise(obj,data);
            else
                SigmaNoise = obj.options.SigmaOfTheNoise;
            end
            [xopt, residue]=fmincon(@(x) double(-2*sum(scd_model_likelihood_rician(data,max(eps,S0.*equation(obj, addfixparameters(obj.st,x,fixedparam))), SigmaNoise))), double(obj.st(~fixedparam)), [], [], [],[],double(obj.lb(~fixedparam)),double(obj.ub(~fixedparam)),[],optimoptions('fmincon','MaxIter',20,'display','off','DiffMinChange',0.03));
            obj.st(~fixedparam)=xopt; xopt = obj.st;
            
            %% OUTPUTS
            xopt(end+1) = residue;
            obj.xnames{end+1}='residue';
            
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),obj.xnames,1);
            
            
            
        end
        
        function plotmodel(obj, x, data)
            if isstruct(x) % if x is a structure, convert to vector
                for ix = 1:length(obj.xnames)
                    xtmp(ix) = x.(obj.xnames{ix});
                end
                x = xtmp;
            end
            Prot = ConvertSchemeUnits(obj.Prot);
            
            Smodel=obj.equation(x);
            % plot data
            if nargin>2
                S0 = scd_preproc_getIb0(data.MTdata,Prot); Smodel = Smodel.*S0;
                h = scd_display_qspacedata(data.MTdata,Prot);
                hold on
                % remove data legends
                for iD = 1:length(h)
                    hAnnotation = get(h(iD),'Annotation');
                    hLegendEntry = get(hAnnotation','LegendInformation');
                    set(hLegendEntry,'IconDisplayStyle','off');
                end
            end
            
            % plot fitting curves
            scd_display_qspacedata(Smodel,Prot,0,'none','-');
            
            % update legend
            legend('Location','NorthEast')


            hold off
        end
        
        
        function SigmaNoise = computesigmanoise(obj,data)
            Prot = ConvertSchemeUnits(obj.Prot);
            Prot(Prot(:,4)==0,[5 6])=0;
            % find images that where repeated
            [~,c,ind]=consolidator(Prot(:,1:8),[],'count');
            cmax = max(c); % find images repeated more than 5 times (for relevant STD)
            if cmax<5, errordlg('Your dataset doesn''t have 5 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise. use scd_noise_fit_histo_nii.m instead to estimate the noise STD.'); return; end
            
            repeated_measured = find(c==cmax);
            for irep=1:length(repeated_measured)
                STDs(irep)=std(data(ind==repeated_measured(irep)));
            end
            SigmaNoise = mean(STDs);
        end
    end
end





function x0 = addfixparameters(x0,x,fixedparam)
x0(~fixedparam)=x;
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

% differentiate session based on Delta/delta/TE values
list=unique(scheme(:,7:-1:5),'rows');
nnn = size(list,1);
for j = 1 : nnn
    for i = 1 : size(scheme,1)
        if  scheme(i,7:-1:5) == list(j,:)
            scheme(i,9) = j;
        end
    end
end
end