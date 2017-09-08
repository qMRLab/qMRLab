classdef CHARMED
%-----------------------------------------------------------------------------------------------------
% CHARMED :  Composite Hindered and Restricted Model for Diffusion
%-----------------------------------------------------------------------------------------------------
%-------------%
% ASSUMPTIONS %
%-------------%
% (1) Diffusion gradients are applied perpendicularly to the neuronal fibers.
% (2) Neuronal fibers are parallel (orientational dispersion is negligible).
% (3) The intra-axonal diffusion coefficient (Dr) is fixed. this assumption
%     should have little impact if the average propagator is larger than 
%     axonal diameter (sqrt(2*Dr*Delta)>8µm).
% (4) Permeability of the neuronal fibers is negligible.
%
%-----------------------------------------------------------------------------------------------------
%--------%
% INPUTS %
%--------%
%   1) DiffusionData
%   2) Mask : Binary mask to accelerate the fitting (OPTIONAL)
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%   Fitting Parameters
%       * fr            : Fraction of water in the restricted compartment.
%       * Dh            : Apparent diffusion coefficient of the hindered compartment.
%       * axon diameter : Mean axonal diameter
%         index           (weighted by the axonal area --> biased toward the larger axons)
%                          fixed to 0 --> stick model (recommended if Gmax < 300mT/m).
%                               
%       * fcsf          : Fraction of water in the CSF compartment. (fixed to 0 by default)
%       * lc            : Length of coherence. If > 0, this parameter models the time dependence 
%                         of the hindered diffusion coefficient Dh. 
%                         Els Fieremans et al. Neuroimage 2016.
%                         Interpretation is not perfectly known. 
%                         Use option "Time-Dependent Models" to get different interpretations.
%
%   Additional Outputs
%       * fr = 1 - fh - fcsf : fraction of water in the restricted compartment (intra-axonal)
%       * residue            : Fitting residue.
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OPTIONS %
%---------%
%   Sigma of the noise : Standard deviation of the noise, assuming Rician.
%                        Use scd_noise_std_estimation to measure noise level
%                        Not used if "Compute sigma noise per pixel" is checked. Instead, STD across >5 repetitions is used.
%   S0 normalization :
%     * 'Use b=0': Use b=0 images. In case of variable TE, your dataset requires a b=0 for each TE.
%     * 'Single T2 compartment': in case of variable TE acquisition. fit T2 assuming Gaussian diffusion for data acquired at b<1000s/mm2
%-----------------------------------------------------------------------------------------------------
% Written by: Tanguy Duval, 2016
% Reference: Assaf, Y., Basser, P.J., 2005. Composite hindered and restricted
% model of diffusion (CHARMED) MR imaging of the human brain. Neuroimage 27, 48?58.
%-----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'DiffusionData','Mask'}; % input data required
        xnames = {'fr','Dh','diameter_mean','fcsf','lc','Dcsf','Dintra'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [ 0.5    0.7     6      0      0      3      1.4 ]; % starting point
        lb           = [ 0      0.3     3      0      0      1      0.3 ]; % lower bound
        ub           = [ 1      3      10      1      8      4      3   ]; % upper bound
        fx           = [ 0      0       0      1      1      1      1   ]; % fix parameters
        
        % Protocol
        Prot = struct('DiffusionData',...
                 struct('Format',{{'Gx' 'Gy'  'Gz'   '|G|'  'Delta'  'delta'  'TE'}},...
                        'Mat',  txt2mat(fullfile(fileparts(which('qMRLab.m')),'Data', 'CHARMED_demo', 'Protocol.txt')))...
                     ); % You can define a default protocol here.

        % Model options
        buttons = {'Dcsf',3,...
                   'Dr',1.4,...
                   'Sigma of the noise',10,...
                   'Compute Sigma per voxel',true,...
                   'Display Type',{'q-value','b-value'},...
                   'S0 normalization',{'Use b=0','Single T2 compartment'},...
                   'Time-dependent-models',{'Burcaw 2015','Ning MRM 2016'}};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        Sim_Single_Voxel_Curve_buttons = {'SNR',50};
        Sim_Sensitivity_Analysis_buttons = {'# of run',5};
    end
    
    methods
% -------------CONSTRUCTOR-------------------------------------------------------------------------
        function obj = CHARMED
            obj.options = button2opts(obj.buttons);
        end
        
        function obj = UpdateFields(obj)
            Prot = obj.Prot.DiffusionData.Mat;
            Prot(Prot(:,4)==0,1:6) = 0;
            [~,c,ind] = consolidator(Prot(:,1:7),[],'count');
            cmax = max(c); % find images repeated more than 5 times (for relevant STD)
            if cmax<5
                warndlg({'Your dataset doesn''t have 5 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise. Specify a fixed Sigma Noise in the option panel instead.'  'See Methods Noise/NoiseLevel.m to estimate the noise standard deviation.'},'Noise estimation method')
                obj.options.ComputeSigmapervoxel = false;
            end
                
        end

% -------------CHARMED EQUATION-------------------------------------------------------------------------

        function [Smodel, x] = equation(obj, x)
            if isstruct(x) % if x is a structure, convert to vector
                for ix = 1:length(obj.xnames)
                    xtmp(ix) = x.(obj.xnames{ix});
                end
                x = xtmp;
            end
            
            x = [x(1:3) 0 x(4:end)]; % add diameter STD parameter (used in the original AxCaliber model)
            opt = obj.options;
            opt.scheme = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat);
            Smodel = scd_model_CHARMED(x,opt);
            x(4)=[];
        end
        
% -------------DATA FITTING-------------------------------------------------------------------------
        function FitResults = fit(obj,data)
            
            % Prepare data
            data = max(eps,double(data.DiffusionData)); nT = length(data);
            if nT ~= size(obj.Prot.DiffusionData.Mat,1), errordlg(['Error: your diffusion dataset has ' num2str(nT) ' volumes while your schemefile has ' num2str(size(obj.Prot.DiffusionData.Mat,1)) ' rows.']); end
            
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat);
            
            switch obj.options.S0normalization
                case 'Single T2 compartment'
                    [S0,T2,obj.st(2)] = scd_preproc_getS0_T2(Prot,data,0,1000);
                    S0 = S0*exp(-Prot(:,7)./T2);
                case 'Use b=0'
                    S0 = scd_preproc_getS0(data,Prot);
            end
            
            %% FITTING
            % initiate with Gaussian noise assumption --> more stable fitting
            fixedparam = obj.fx;
            [xopt, residue] = lsqcurvefit(@(x,scheme) S0.*equation(obj, addfixparameters(obj.st,x,fixedparam)),obj.st(~fixedparam),Prot,double(data),double(obj.lb(~fixedparam)),double(obj.ub(~fixedparam)),optimoptions('lsqcurvefit','MaxIter',20,'display','off'));
            obj.st(~fixedparam) = xopt; xopt = obj.st;
            
            %% RICIAN NOISE
            % use Rician noise and fix b=0
            if obj.options.ComputeSigmapervoxel
                SigmaNoise = computesigmanoise(obj.Prot.DiffusionData.Mat,data);
                if ~SigmaNoise, return; end
            else
                SigmaNoise = obj.options.Sigmaofthenoise;
            end
            
            %% FITTING (with rician assumption)
            [xopt, residue] = fmincon(@(x) double(-2*sum(scd_model_likelihood_rician(data,max(eps,S0.*equation(obj, addfixparameters(obj.st,x,fixedparam))), SigmaNoise))), double(obj.st(~fixedparam)), [], [], [],[],double(obj.lb(~fixedparam)),double(obj.ub(~fixedparam)),[],optimoptions('fmincon','MaxIter',20,'display','off','DiffMinChange',0.03));
            obj.st(~fixedparam) = xopt; xopt = obj.st;
            
            %% OUTPUTS
            % S0
            S0vals = unique([S0 Prot(:,7)],'rows');
            for ii = 1:size(S0vals,1)
                xopt(end+1) = S0vals(ii,1);
                obj.xnames{end+1} = ['S0_TE' num2str(round(S0vals(ii,2)))];
            end
            % T2
            if exist('T2','var')
                xopt(end+1) = T2;
                obj.xnames{end+1} = 'T2';
            end
            % fr
            xopt(end+1) = 1 - xopt(4) - xopt(1);
            obj.xnames{end+1} = 'fh';
            % residue
            xopt(end+1) = residue;
            obj.xnames{end+1} = 'residue';
            % Noise Level
            if obj.options.ComputeSigmapervoxel
                xopt(end+1) = SigmaNoise;
                obj.xnames{end+1} = 'SigmaNoise';
            end
            % convert to structure
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),obj.xnames,1);
            
            
            
        end
     
% -------------PLOT EQUATION-------------------------------------------------------------------------
        function plotmodel(obj, x, data)
            % u.plotmodel(u.st)
            if nargin<2, x=obj.st; end
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat);
            if ~isempty(x)
                [Smodel, x]= obj.equation(x);
            end
            % plot data
            S0 = 1;
            if nargin>2
                switch obj.options.S0normalization
                    case 'Single T2 compartment'
                        [S0, T2] = scd_preproc_getS0_T2(Prot,data.DiffusionData,0,1000);
                        S0 = S0*exp(-Prot(:,7)./T2);
                    case 'Use b=0'
                        S0 = scd_preproc_getS0(data.DiffusionData,Prot);
                end
                h = scd_display_qspacedata(data.DiffusionData,Prot,strcmp(obj.options.DisplayType,'b-value'));
                hold on
                % remove data legends
                for iD = 1:length(h)
                    hAnnotation  = get(h(iD),'Annotation');
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
            title(strrep(strrep(cell2str_v2(Interleave(obj.xnames,repmat('=',1,length(obj.xnames)),x)),''', ''='',',' ='),'''',''),'FontSize',8)
        end

% -------------PLOT DIFFUSION PROTOCOL-------------------------------------------------------------------------
        function plotProt(obj)
            % round bvalue
            Prot      = obj.Prot.DiffusionData.Mat;
            Prot(:,4) = round(scd_scheme2bvecsbvals(Prot)*100)*10;
            % display
            scd_scheme_display(Prot)
            subplot(2,2,4)
            scd_scheme_display_3D_Delta_delta_G(ConvertSchemeUnits(obj.Prot.DiffusionData.Mat))
        end
        

% -------------SIMULATIONS-------------------------------------------------------------------------
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            if ~exist('display','var'), display=1; end
            if ~exist('Opt','var'), Opt.SNR=inf; end
            if ~exist('x','var'), x=obj.st; end
            Smodel = equation(obj, x);
            sigma  = max(Smodel)/Opt.SNR;
            data.DiffusionData = random('rician',Smodel,sigma);
            FitResults = fit(obj,data);
            if display
                plotmodel(obj, FitResults, data);
                hold on
                Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat);
                h = scd_display_qspacedata(Smodel,Prot,strcmp(obj.options.DisplayType,'b-value'),'o','none');
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

        function schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,nV,popSize,migrations)
            % schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,nV,popSize,migrations)
            % schemeLEADER = Sim_Optimize_Protocol(obj,obj.st,30,100,100)
            TEmax    = 120*1e-3;
            Treadout = 35*1e-3;
            T180     = 10*1e-3;
            deltamin = 3*1e-3;
            Gmax     = 80*1e-3;
            % |G| Delta delta
            planes = [ 0  -1  -1  TEmax     % TE-delta-DELTA>0
                       0   1  -1  0         % Delta-delta>0
                       0   0   1  -deltamin % delta - deltamin>0
                       1   0   0  0         % G>0
                      -1   0   0  Gmax    ];% Gmax - |G| > 0
            
            LSP = meshgrid_polyhedron(planes);
            
            T2     = 40*1e-3; 
            TE0    = 40*1e-3;
            sigma0 =.05; %SNR=20 at TE0 
            sigma  = @(Prot) sigma0*exp(((Prot(:,2)+Prot(:,3)+Treadout)-TE0)/T2);

            GenerateRandFunction = @() LSP(randi(size(LSP,1),nV,1),:);
            CheckProtInBoundFunc = @(Prot) checkInBoundsAndUptade(Prot,LSP,planes);
            %% Optimize Protocol
            [retVal] = soma_all_to_one(@(Prot) mean(SimCRLB(obj,[zeros(size(Prot,1),2) ones(size(Prot,1),1) Prot],xvalues,sigma(Prot),1:2)), GenerateRandFunction, CheckProtInBoundFunc, migrations, popSize, nV, obj.Prot.DiffusionData.Mat(:,4:6));
            
            %% Generate Rest
            schemeLEADER = retVal.schemeLEADER;
            % add b0 value
            schemeLEADER = [schemeLEADER(1,:);schemeLEADER]; % add b0 value
            schemeLEADER(1,1:4) = 0;
            schemeLEADER(1,8:9) = 0;
            
            % different acq
            acq = unique(schemeLEADER(:,5:6), 'rows');
            [~, index1] = sort(acq(:,1));
            acq = acq(index1,:);
            Nacq = size(acq, 1);
            for s=1:nV
                [ind,~] = find(sum(abs(acq - repmat(schemeLEADER(s,5:6),Nacq,1)), 2) == 0);
                schemeLEADER(s,9) = ind;
            end
            [~, index2]  = sort(schemeLEADER(:,9));
            schemeLEADER = schemeLEADER(index2,:);
            
            fprintf('SOMA HAS FINISHED \n')
                        
        end
    end
end





function x0 = addfixparameters(x0,x,fixedparam)
x0(~fixedparam) = x;
end

function scheme = ConvertSchemeUnits(scheme)
% convert units
scheme(:,4)   = scheme(:,4).*sqrt(sum(scheme(:,1:3).^2,2))*1e-3; % G mT/um
scheme(:,1:3) = scheme(:,1:3)./repmat(sqrt(scheme(:,1).^2+scheme(:,2).^2+scheme(:,3).^2),1,3); scheme(isnan(scheme))=0;
scheme(:,5)   = scheme(:,5)*10^3; % DELTA ms
scheme(:,6)   = scheme(:,6)*10^3; % delta ms
if size(scheme,2)>6
    scheme(:,7) = scheme(:,7)*10^3; % TE ms
else
    scheme(:,7) = scheme(:,5)+scheme(:,6)+35; % approximation
end
    gyro = 42.57; % kHz/mT
    scheme(:,8) = gyro*scheme(:,4).*scheme(:,6); % um-1

% differentiate session based on Delta/delta/TE values
list = unique(scheme(:,7:-1:5),'rows');
nnn  = size(list,1);
for j = 1 : nnn
    for i = 1 : size(scheme,1)
        if  scheme(i,7:-1:5) == list(j,:)
            scheme(i,9) = j;
        end
    end
end
end

function SigmaNoise = computesigmanoise(Prot,data)
Prot(Prot(:,4)==0,1:6) = 0;
% find images that where repeated
[~,c,ind] = consolidator(Prot(:,1:7),[],'count');
cmax = max(c); % find images repeated more than 5 times (for relevant STD)
if cmax<5, uiwait(errordlg('Your dataset doesn''t have 5 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise. Specify a fixed Sigma Noise in the option panel instead. (see scd_noise_fit_histo_nii.m to estimate the noise STD).')); end

repeated_measured = find(ismember(c,c(c>5)));
if ~isempty(repeated_measured)
    for irep = 1:length(repeated_measured)
        vars(irep) = var(data(ind==repeated_measured(irep)));
    end
    SigmaNoise = sqrt(median(vars));
else
    SigmaNoise=0;
end
end