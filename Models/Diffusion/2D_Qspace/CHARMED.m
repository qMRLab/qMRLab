classdef CHARMED
    % ----------------------------------------------------------------------------------------------------
    % CHARMED :  Composite Hindered and Restricted Model for Diffusion
    % ----------------------------------------------------------------------------------------------------
    % Assumptions :
    % (1) Diffusion gradients are applied perpendicularly to the neuronal fibers
    % (2) Neuronal fibers are parallel (orientational dispersion is negligible)
    % (3) The intra-axonal diffusion coefficient (Dr) is fixed. this assumption
    % should have little impact if the average propagator is larger than axonal diameter (sqrt(2*Dr*Delta)>8µm).
    % (4) permeability of the neuronal fibers is negligible
    % ----------------------------------------------------------------------------------------------------
    %
    %  Fitted Parameters:
    %    * fh :     fraction of water in the hindered compartment
    %    * Dh :    Apparent diffusion coefficient of the hindered compartment
    %    * axon diameter index : Mean axonal diameter
    %                                           (weighted by the axonal area --> biased toward the larger axons).
    %                                            fixed to 0 --> stick model (recommended if Gmax < 300mT/m)
    %    * fcsf :  fraction of water in the CSF compartment. (fixed to 0 by default)
    %    * lc :   length of coherence. if >0, this parameter models the time dependence of the hindered
    %             diffusion coefficient Dh. Els Fieremans et al. Neuroimage 2016.
    %             Interpretation is not perfectly known. Use
    %             option "Time-Dependent Models" to get different interpretations.
    %
    %
    %  Non-Fitted Parameters:
    %    * fr = 1 - fh - fcsf : fraction of water in the restricted compartment (intra-axonal)
    %    * residue : Fitting residue.
    %
    %
    % Options:
    %   Sigma of the noise : Standard deviation of the noise, assuming Rician.
    %                        Use scd_noise_std_estimation to measure noise level
    %                        Not used if "Compute sigma noise per pixel" is checked. Instead, STD across >5 repetitions is used.
    %   S0 normalization :
    %     * 'Use b=0': Use b=0 images. In case of variable TE, your dataset requires a b=0 for each TE.
    %     * 'Single T2 compartment': in case of variable TE acquisition. fit T2 assuming Gaussian diffusion for data acquired at b<1000s/mm2
    % ----------------------------------------------------------------------------------------------------
    % Written by: Tanguy Duval, 2016
    % Reference: Assaf, Y., Basser, P.J., 2005. Composite hindered and restricted
    % model of diffusion (CHARMED) MR imaging of the human brain. Neuroimage 27, 48?58.
    % ----------------------------------------------------------------------------------------------------
    
    properties
        MRIinputs = {'DiffusionData','Mask'}; % input data required
        xnames = {'fh','Dh','diameter_mean','fcsf','lc'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [0.6     0.7        6         0         0      ]; % starting point
        lb            = [0       0.3        3          0         0    ]; % lower bound
        ub           = [1       3         10         1          20    ]; % upper bound
        fx            = [0      0           0           1          1  ]; % fix parameters
        
        % Protocol
        ProtFormat = {'Gx' 'Gy'  'Gz'   '|G| (T/m)'  'Delta (s)'  'delta (s)'  'TE (s)'}; % columns of the Protocol matrix.
        Prot  = cat(1,[ones(100,1) zeros(100,2) [0 0 0 0 linspace(0,300,96)]'*1e-3 0.020*ones(100,1) 0.008*ones(100,1) 0.070*ones(100,1)],...
                       [ones(100,1) zeros(100,2) [0 0 0 0 linspace(0,300,96)]'*1e-3 0.030*ones(100,1) 0.008*ones(100,1) 0.070*ones(100,1)],...
                       [ones(100,1) zeros(100,2) [0 0 0 0 linspace(0,300,96)]'*1e-3 0.040*ones(100,1) 0.008*ones(100,1) 0.070*ones(100,1)]);
        
        % Model options
        buttons = {'Dcsf',3,'Dr',1.4,'Sigma of the noise',10,'Compute Sigma per voxel',true,'Display Type',{'q-value','b-value'},'S0 normalization',{'Use b=0','Single T2 compartment'},'Time-dependent-models',{'Burcaw 2015','Ning MRM 2016'}};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = CHARMED
            obj = button2opts(obj);
        end
        
        function Smodel = equation(obj, x)
            if isstruct(x) % if x is a structure, convert to vector
                for ix = 1:length(obj.xnames)
                    xtmp(ix) = x.(obj.xnames{ix});
                end
                x = xtmp;
            end
            
            x = [x(1:3) 0 x(4:end)]; % add diameter STD parameter (used in the original AxCaliber model)
            opt=obj.options;
            opt.scheme=ConvertSchemeUnits(obj.Prot);
            Smodel = scd_model_CHARMED(x,opt);
        end
        
        
        function FitResults = fit(obj,data)
            
            % Prepare data
            data = max(eps,double(data.DiffusionData)); nT=length(data);
            if nT~=size(obj.Prot,1), errordlg(['Error: your diffusion dataset has ' num2str(nT) ' volumes while your schemefile has ' num2str(size(obj.Prot,1)) ' rows.']); end
            
            Prot = ConvertSchemeUnits(obj.Prot);
            
            switch obj.options.S0Normalization
                case 'Single T2 compartment'
                    [S0,T2,obj.st(2)] = scd_preproc_getS0_T2(Prot,data,0,1000);
                    S0 = S0*exp(-Prot(:,7)./T2);
                case 'Use b=0'
                    S0 = scd_preproc_getS0(data,Prot);
            end
            
            %% FITTING
            % initiate with Gaussian noise assumption --> more stable fitting
            fixedparam=obj.fx;
            [xopt, residue] = lsqcurvefit(@(x,scheme) S0.*equation(obj, addfixparameters(obj.st,x,fixedparam)),obj.st(~fixedparam),Prot,double(data),double(obj.lb(~fixedparam)),double(obj.ub(~fixedparam)),optimoptions('lsqcurvefit','MaxIter',20,'display','off'));
            obj.st(~fixedparam)=xopt; xopt = obj.st;
            
            %% RICIAN NOISE
            % use Rician noise and fix fix b=0
            if obj.options.ComputeSigmaPerVoxel
                SigmaNoise = computesigmanoise(obj.Prot,data);
                if ~SigmaNoise, return; end
            else
                SigmaNoise = obj.options.SigmaOfTheNoise;
            end
            
            %% FITTING (with rician assumption)
            [xopt, residue]=fmincon(@(x) double(-2*sum(scd_model_likelihood_rician(data,max(eps,S0.*equation(obj, addfixparameters(obj.st,x,fixedparam))), SigmaNoise))), double(obj.st(~fixedparam)), [], [], [],[],double(obj.lb(~fixedparam)),double(obj.ub(~fixedparam)),[],optimoptions('fmincon','MaxIter',20,'display','off','DiffMinChange',0.03));
            obj.st(~fixedparam)=xopt; xopt = obj.st;
            
            %% OUTPUTS
            % T2
            if exist('T2','var')
                xopt(end+1) = T2;
                obj.xnames{end+1}='T2';
            end
            % fr
            xopt(end+1) = 1 - xopt(4) - xopt(1);
            obj.xnames{end+1}='fr';
            % residue
            xopt(end+1) = residue;
            obj.xnames{end+1}='residue';
            % convert to structure
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),obj.xnames,1);
            
            
            
        end
        
        function plotmodel(obj, x, data)
            % u.plotmodel(u.st)
            Prot = ConvertSchemeUnits(obj.Prot);
            if ~isempty(x)
                Smodel=obj.equation(x);
            end
            % plot data
            S0 = 1;
            if nargin>2
                switch obj.options.S0Normalization
                    case 'Single T2 compartment'
                        [S0, T2]= scd_preproc_getS0_T2(Prot,data.DiffusionData,0,1000);
                        S0 = S0*exp(-Prot(:,7)./T2);
                    case 'Use b=0'
                        S0 = scd_preproc_getS0(data.DiffusionData,Prot);
                end
                h = scd_display_qspacedata(data.DiffusionData,Prot,strcmp(obj.options.DisplayType,'b-value'));
                hold on
                % remove data legends
                for iD = 1:length(h)
                    hAnnotation = get(h(iD),'Annotation');
                    hLegendEntry = get(hAnnotation','LegendInformation');
                    set(hLegendEntry,'IconDisplayStyle','off');
                end
            end
            
            % plot fitting curves
            if ~isempty(x)
                Smodel = Smodel.*S0;
                scd_display_qspacedata(Smodel,Prot,strcmp(obj.options.DisplayType,'b-value'),'none','-');
            end
            hold off
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, SNR,display)
            if ~exist('display','var'), display=1; end
            Smodel = equation(obj, x);
            sigma = max(Smodel)/SNR;
            data.DiffusionData = random('rician',Smodel,sigma);
            FitResults = fit(obj,data);
            if display
                plotmodel(obj, FitResults, data);
                hold on
                Prot = ConvertSchemeUnits(obj.Prot);
                h = scd_display_qspacedata(Smodel,Prot,strcmp(obj.options.DisplayType,'b-value'),'o','none');
                set(h,'LineWidth',.5)
            end
        end
        
        function SimVaryResults = Sim_Sensitivity_Analysis(obj, SNR, runs, OptTable)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, SNR, runs, OptTable);
            
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

function SigmaNoise = computesigmanoise(Prot,data)
Prot(Prot(:,4)==0,[5 6])=0;
% find images that where repeated
[~,c,ind]=consolidator(Prot(:,1:7),[],'count');
cmax = max(c); % find images repeated more than 5 times (for relevant STD)
if cmax<5, uiwait(errordlg('Your dataset doesn''t have 5 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise. Specify a fixed Sigma Noise in the option panel instead. (see scd_noise_fit_histo_nii.m to estimate the noise STD).')); end

repeated_measured = find(c==cmax);
for irep=1:length(repeated_measured)
    STDs(irep)=std(data(ind==repeated_measured(irep)));
end
SigmaNoise = mean(STDs);
end