classdef charmed < AbstractModel
%charmed: Composite Hindered and Restricted Model for Diffusion
%<a href="matlab: figure, imshow Diffusion.png ;">Pulse Sequence Diagram</a>
%
%
% Assumptions:
%   Diffusion gradients are applied perpendicularly to the neuronal fibers.
%   Neuronal fibers model:
%     geometry                          cylinders
%     Orientation dispersion            NO
%     Permeability                      NO
%   Diffusion properties:
%     intra-axonal                      restricted in cylinder with Gaussian
%                                        Phase approximation
%      diffusion coefficient (Dr)       fixed by default. this assumption should have
%                                                          little impact if the average
%                                                          propagator is larger than
%                                                          axonal diameter (sqrt(2*Dr*Delta)>8?m).
%     extra-axonal                      Gaussian
%      diffusion coefficient (Dh)       Constant by default. Time dependence (lc)
%                                                             can be added
%
% Inputs:
%   DiffusionData       4D DWI
%   (SigmaNoise)        map of the standard deviation of the noise per voxel. (OPTIONAL)
%   (Mask)              Binary mask to accelerate the fitting. (OPTIONAL)
%
% Outputs:
%   fr                  Fraction of water in the restricted compartment.
%   Dh                  Apparent diffusion coefficient of the hindered compartment.
%   diameter_mean       Mean axonal diameter weighted by the axonal area --> biased toward the larger axons
%                         fixed to 0 --> stick model (recommended if Gmax < 300mT/m).
%   fcsf                Fraction of water in the CSF compartment. (fixed to 0 by default)
%   lc                  Length of coherence. If > 0, this parameter models the time dependence
%                         of the hindered diffusion coefficient Dh.
%                         Els Fieremans et al. Neuroimage 2016.
%                         Interpretation is not perfectly known.
%                         Use option "Time-Dependent Models" to get different interpretations.
%   (fh)                Fraction of water in the hindered compartment, calculated as: 1 - fr - fcsf
%   (residue)           Fitting residuals
%
% Protocol:
%   Various bvalues
%   diffusion gradient direction perpendicular to the fibers
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
%   Rician noise bias               Used if no SigmaNoise map is provided.
%     'Compute Sigma per voxel'     Sigma is estimated by computing the STD across repeated scans.
%     'fix sigma'                   Use scd_noise_std_estimation to measure noise level. Use 'value' to fix Sigma.
%   Display Type
%     'q-value'                     abscissa for plots: q = gamma.delta.G (?m-1)
%     'b-value'                     abscissa for plots: b = (2.pi.q)^2.(Delta-delta/3) (s/mm2)
%   S0 normalization
%     'Use b=0'                     Use b=0 images. In case of variable TE, your dataset requires a b=0 for each TE.
%     'Single T2 compartment'       In case of variable TE acquisition:
%                                   fit single T2 using data acquired at b<1000s/mm2 (assuming Gaussian diffusion))
%   Time-dependent models
%     'Burcaw 2015'                 XXX
%     'Ning MRM 2016'               XXX
%
% Example of command line usage:
%   Model = charmed;  % Create class from model
%   Model.Prot.DiffusionData.Mat = txt2mat('Protocol.txt');  % Load protocol
%   data = struct;  % Create data structure
%   data.DiffusionData = load_nii_data('DiffusionData.nii.gz');  % Load data
%   data.Mask=load_nii_data('Mask.nii.gz');  % Load mask
%   FitResults = FitData(data,Model,1);  % Fit each voxel within mask
%   FitResultsSave_nii(FitResults,'DiffusionData.nii.gz');  % Save in local folder: FitResults/
%
%   For more examples: <a href="matlab: qMRusage(charmed);">qMRusage(charmed)</a>
%
% Author: Tanguy Duval, 2016
%
% References:
%   Please cite the following if you use this module:
%     Assaf, Y., Basser, P.J., 2005. Composite hindered and restricted model of diffusion (CHARMED) MR imaging of the human brain. Neuroimage 27, 48?58.
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
properties (Hidden=true)
% Hidden proprties goes here.
    onlineData_url = 'https://osf.io/u8n56/download?version=3';
    onlineData_filename = 'charmed.zip';
end

    properties
        MRIinputs = {'DiffusionData','SigmaNoise','Mask'}; % input data required
        xnames = {'fr','Dh','diameter_mean','fcsf','lc','Dcsf','Dintra'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?

        % fitting options
        st           = [ 0.5    0.7     6      0      0      3      1.4 ]; % starting point
        lb           = [ 0      0.3     3      0      0      1      0.3 ]; % lower bound
        ub           = [ 1      3      10      1      8      4      3   ]; % upper bound
        fx           = [ 0      0       0      1      1      1      1   ]; % fix parameters

        % Protocol
        Prot = struct('DiffusionData',...
            struct('Format',{{'Gx' 'Gy'  'Gz'   'Gnorm (T/m)'  'Delta (s)'  'delta (s)'  'TE (s)'}},...
            'Mat',  txt2mat('CHARMEDProtocol.txt','InfoLevel',0))...
            ); % You can define a default protocol here.

        % Model options
        buttons = {'PANEL','Rician noise bias',2,'Method', {'Compute Sigma per voxel','fix sigma'}, 'value',10,...
            'Display Type',{'q-value','b-value'},...
            'S0 normalization',{'Use b=0','Single T2 compartment'},...
            'Time-dependent-models',{'Burcaw 2015','Ning MRM 2016'}};
        
        tabletip = struct('table_name',{{'DiffusionData'}},'tip', ...
        {{sprintf(['G[x,y,z]: Diffusion gradient directions.\nGnorm (T / m): Diffusion gradient magnitudes.\nDelta (s): Diffusion separation\n' ...
        'delta (s): Diffusion duration\nTE (s): Echo time.\n\n------------------------\n You can populate these fields using bvec and bval files by following the prompted instructions.\n------------------------'])}},'link',{{'https://github.com/qMRLab/qMRLab/issues/299#issuecomment-451210324'}});

        options= struct(); % structure filled by the buttons. Leave empty in the code
        Sim_Single_Voxel_Curve_buttons = {'SNR',50};
        Sim_Sensitivity_Analysis_buttons = {'# of run',5};
        Sim_Optimize_Protocol_buttons = {'# of volumes',30,'Population size',100,'# of migrations',100,'Gmax',80*1e-3};
    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods
        % -------------CONSTRUCTOR-------------------------------------------------------------------------
        function obj = charmed
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end

        function obj = UpdateFields(obj)
            Prot = obj.Prot.DiffusionData.Mat;
            Prot(Prot(:,4)==0,1:6) = 0;
            [~,c,ind] = consolidator(Prot(:,1:7),[],'count');
            cmax = max(c); % find images repeated more than 5 times (for relevant STD)
            if cmax<2 && ~strcmp(obj.options.Riciannoisebias_Method,'fix sigma')
                warndlg({'Your dataset doesn''t have 2 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise. Specify a fixed Sigma Noise in the option panel instead.'  'See Methods Noise/NoiseLevel.m to estimate the noise standard deviation.'},'Noise estimation method')
                obj.options.Riciannoisebias_Method = 'fix sigma';
            elseif cmax<5
                warning('Your dataset doesn''t have 5 repeated measures (same bvec/bvals) --> you can''t estimate noise STD voxel-wise accurately. Specify a fixed Sigma Noise in the option panel instead. See Methods Noise/NoiseLevel.m to estimate the noise standard deviation.')
            end

            if strcmp(obj.options.Riciannoisebias_Method,'Compute Sigma per voxel')
                obj.options.Riciannoisebias_value  = 'auto';
            elseif isempty(obj.options.Riciannoisebias_value)
                obj.options.Riciannoisebias_value=10;
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
            opt.scheme = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,0);
            Smodel = scd_model_CHARMED(x,opt);
            x(4)=[];
        end

        % -------------DATA FITTING-------------------------------------------------------------------------
        function FitResults = fit(obj,data)

            % Prepare data
            datadif = max(eps,double(data.DiffusionData)); nT = length(datadif);
            if nT ~= size(obj.Prot.DiffusionData.Mat,1), errordlg(['Error: your diffusion dataset has ' num2str(nT) ' volumes while your schemefile has ' num2str(size(obj.Prot.DiffusionData.Mat,1)) ' rows.']); end

            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,0);

            switch obj.options.S0normalization
                case 'Single T2 compartment'
                    [S0,T2,obj.st(2)] = scd_preproc_getS0_T2(Prot,datadif,0,1000);
                    S0 = S0*exp(-Prot(:,7)./T2);
                case 'Use b=0'
                    S0 = scd_preproc_getS0(datadif,Prot);
            end

            %% FITTING
            % initiate with Gaussian noise assumption --> more stable fitting
            fixedparam = obj.fx;
            optoptim.MaxIter = 20; optoptim.Display = 'off';
            [xopt, residue] = lsqcurvefit(@(x,scheme) S0.*equation(obj, addfixparameters(obj.st,x,fixedparam)),obj.st(~fixedparam),Prot,double(datadif),double(obj.lb(~fixedparam)),double(obj.ub(~fixedparam)),optoptim);
            obj.st(~fixedparam) = xopt; xopt = obj.st;

            %% RICIAN NOISE
            % use Rician noise and fix b=0
            if isfield(data,'SigmaNoise') && ~isempty(data.SigmaNoise)
                SigmaNoise = data.SigmaNoise(1);
            elseif strcmp(obj.options.Riciannoisebias_Method,'Compute Sigma per voxel')
                SigmaNoise = computesigmanoise(obj.Prot.DiffusionData.Mat,datadif);
                if ~SigmaNoise, return; end
            else
                SigmaNoise = obj.options.Riciannoisebias_value;
            end

            %% FITTING (with rician assumption)
            if ~moxunit_util_platform_is_octave
                [xopt, residue] = fmincon(@(x) double(-2*sum(scd_model_likelihood_rician(datadif,max(eps,S0.*equation(obj, addfixparameters(obj.st,x,fixedparam))), SigmaNoise))), double(obj.st(~fixedparam)), [], [], [],[],double(obj.lb(~fixedparam)),double(obj.ub(~fixedparam)),[],optimoptions('fmincon','MaxIter',20,'display','off','DiffMinChange',0.03));
                obj.st(~fixedparam) = xopt; xopt = obj.st;
            end
            %% OUTPUTS
            % S0
            S0vals = unique([S0 round(Prot(:,7))],'rows');
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
            if strcmp(obj.options.Riciannoisebias_Method,'Compute Sigma per voxel')
                xopt(end+1) = SigmaNoise;
                obj.xnames{end+1} = 'SigmaNoise';
            end
            % convert to structure
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),obj.xnames,1);



        end

        % -------------PLOT EQUATION-------------------------------------------------------------------------
        function plotModel(obj, x, data)
            % u.plotModel(u.st)
            if nargin<2, x=obj.st; end
            Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1);
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
                    if ~moxunit_util_platform_is_octave || (moxunit_util_platform_is_octave && ~str2double(getenv('ISCITEST')))
                        hAnnotation  = get(h(iD),'Annotation');
                        hLegendEntry = get(hAnnotation','LegendInformation');
                        set(hLegendEntry,'IconDisplayStyle','off');
                    end
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
            scd_scheme_display_3D_Delta_delta_G(ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1))
        end


        % -------------SIMULATIONS-------------------------------------------------------------------------
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            if ~exist('display','var'), display=1; end
            if ~exist('Opt','var'), Opt.SNR=1000; end
            if ~exist('x','var'), x=obj.st; end
            Smodel = equation(obj, x);
            sigma  = max(Smodel)/Opt.SNR;
            data.DiffusionData = ricernd(Smodel,sigma);
            FitResults = fit(obj,data);
            if display
                Prot = ConvertSchemeUnits(obj.Prot.DiffusionData.Mat,1);
                h = scd_display_qspacedata(Smodel,Prot,strcmp(obj.options.DisplayType,'b-value'),'o','none');
                if ~moxunit_util_platform_is_octave || (moxunit_util_platform_is_octave && ~str2double(getenv('ISCITEST')))
                    set(h,'LineWidth',.5)
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

        function [Signal, signal_intra, signal_extra] = Sim_MonteCarlo_Diffusion(obj, numelparticle, trans_mean, D, packing, axons)
            scheme = obj.Prot.DiffusionData.Mat;
            [Signal, signal_intra, signal_extra] = Sim_MonteCarlo_Diffusion(numelparticle, trans_mean, D, scheme, packing, axons);
            
            if ~moxunit_util_platform_is_octave || (moxunit_util_platform_is_octave && ~str2double(getenv('ISCITEST')))
            % plot and fit synthetic signal
            fig = figure(293);
            set(fig,'Name','Monte-Carlo simulated Signal')
            set(fig, 'Position', get(0, 'Screensize'));
            
            data.SigmaNoise = 0.01;
            subplot(3,1,1)
            data.DiffusionData = signal_intra(:);
            FitResults  = obj.fit(data);
            obj.plotModel(FitResults, data);
            txt = get(gca,'Title');
            set(txt,'String',sprintf(['intra axonal signal:\n' get(txt,'String')]));
            set(txt,'Color',[1 0 0])
            subplot(3,1,2)
            data.DiffusionData = signal_extra(:);
            FitResults  = obj.fit(data);
            obj.plotModel(FitResults, data);
            txt = get(gca,'Title');
            set(txt,'String',sprintf(['extra axonal signal:\n' get(txt,'String')]));
            set(txt,'Color',[0 0 1])
            subplot(3,1,3)
            data.DiffusionData = Signal(end,:)';
            FitResults  = obj.fit(data);
            obj.plotModel(FitResults, data);
            txt = get(gca,'Title');
            set(txt,'String',sprintf(['full signal:\n' get(txt,'String')]));
            
            uicontrol(293,'Style','pushbutton','String','Save','Callback',@(src,evnt) Sim_MonteCarlo_saveSignal(Signal(end,:),signal_intra,signal_extra),'BackgroundColor',[0.0 0.65 1]);
            end
        end
        
        function schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,Opt)
            % schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,nV,popSize,migrations)
            % schemeLEADER = Sim_Optimize_Protocol(obj,obj.st,30,100,100)
            nV         = Opt.Nofvolumes;
            popSize    = Opt.Populationsize;
            migrations = Opt.Nofmigrations;
            Gmax = Opt.Gmax;
            TEmax    = 120*1e-3;
            Treadout = 35*1e-3;
            T180     = 10*1e-3;
            deltamin = 3*1e-3;
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
            [retVal] = soma_all_to_one(@(Prot) mean(SimCRLB(obj,[zeros(size(Prot,1),2) ones(size(Prot,1),1) Prot],xvalues,sigma(Prot))), GenerateRandFunction, CheckProtInBoundFunc, migrations, popSize, nV, obj.Prot.DiffusionData.Mat(:,4:6));

            %% Generate Rest
            schemeLEADER = retVal.schemeLEADER;
            schemeLEADER = [ones(nV,1) zeros(nV,2) schemeLEADER];

            % keep 5 different delta / DELTA and sort different acquisition
            schemeLEADER=discrete_delta_Delta(schemeLEADER,5);
            % add b=0
            addb0 = find(diff(schemeLEADER(:,9)));
            for ib0 = 1:length(addb0)
                schemeLEADER = cat(1,schemeLEADER(1:addb0(ib0),:), [0 0 1 0 schemeLEADER(addb0(ib0),5:end)] ,schemeLEADER(addb0(ib0)+1:end,:));
            end
            fprintf('SOMA HAS FINISHED \n')

        end
    end

    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            obj.Prot.DiffusionData.Format{4}='Gnorm (T/m)'; % old: '|G| (T/m)', new Gnorm (T/m)
        end
    end
end
