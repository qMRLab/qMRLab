classdef MWF
    %-----------------------------------------------------------------------------------------------------
    % MWF :  Myelin Water Fraction
    %-----------------------------------------------------------------------------------------------------
    %-------------%
    % ASSUMPTIONS %
    %-------------%
    % (1) FILL
    % (2)
    % (3)
    % (4)
    %-----------------------------------------------------------------------------------------------------
    %--------%
    % INPUTS %
    %--------%
    %   1) MET2data : Multi-Exponential T2 data
    %   2) Mask     : Binary mask to accelerate the fitting (OPTIONAL)
    %
    %-----------------------------------------------------------------------------------------------------
    %---------%
    % OUTPUTS %
    %---------%
    %	* MWF   : Myelin Water Fraction
    %	* T2MW  : Spin relaxation time for Myelin Water (MW)
    %   * T2IEW : Spin relaxation time for Intra/Extracellular Water (IEW)
    %
    %-----------------------------------------------------------------------------------------------------
    %----------%
    % PROTOCOL %
    %----------%
    %	* First   : Time of the first echo (s)
    %	* Spacing : Time interval between each echo (s)
    %
    %-----------------------------------------------------------------------------------------------------
    %---------%
    % OPTIONS %
    %---------%
    %   * Cutoff : Time cutoff (s)
    %   * Sigma  : Noise's sigma ?????
    %
    %-----------------------------------------------------------------------------------------------------
    % Written by: Ian Gagnon, 2017
    % Reference: FILL
    %-----------------------------------------------------------------------------------------------------
    
    properties
        MRIinputs = {'MET2data','Mask'};
        xnames = {'MWF','T2MW','T2IEW'};
        voxelwise = 1;
        
        % Parameters options
        lb           = [   0     0     40 ]; % lower bound
        ub           = [ 100    40    200 ]; % upper bound. T2_IEW<200ms. Kolind et al. doi: 10.1002/mrm.21966.
        fx           = [   0     0      0 ]; % fix parameters
        
        % Protocol
        % You can define a default protocol here.
        Prot  = struct('Echo',struct('Format',{{'Time (ms)'}},...
            'Mat', [10; 20; 30; 40; 50; 60; 70; 80; 90; 100; 110; 120; 130; 140; 150; 160; 170;
            180; 190; 200; 210; 220; 230; 240; 250; 260; 270; 280; 290; 300; 310; 320]));
        
        % Model options
        buttons = {'Cutoff (ms)',40, 'Sigma', 20, 'Relaxation Type' {'T2', 'T2star'}};
        options = struct(); % structure filled by the buttons. Leave empty in the code
        
        % Simulation Options
        Sim_Single_Voxel_Curve_buttons = {'SNR',200,'PANEL','Spectrum variance',2,'T2 Myelin',5,'T2 Intra/Extracellular Water',20};
        Sim_Sensitivity_Analysis_buttons = {'# of run',5};
        
    end
    
    methods
        
        function obj = MWF
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            % Update the Cutoff value in the fitting parameters
            obj.ub(2) = obj.options.Cutoffms;
            obj.lb(3) = obj.options.Cutoffms;            
        end
        
        function [FitResults,Spectrum] = fit(obj,data)
            % EchoTimes, T2 and DecayMatrix
            EchoTimes   = obj.Prot.Echo.Mat;
            T2          = getT2(obj,EchoTimes);
            DecayMatrix = getDecayMatrix(EchoTimes,T2.vals);
            % Options
            Opt.RelaxationType   = obj.options.RelaxationType;
            Opt.Sigma            = obj.options.Sigma;
            Opt.lower_cutoff_MW  = 1.5*obj.Prot.Echo.Mat(1); % 1.5 * FirstEcho
            Opt.upper_cutoff_MW  = obj.options.Cutoffms;
            Opt.upper_cutoff_IEW = obj.ub(3);
            % Fitting
            if isempty(data.Mask), data.Mask = 1; end
            [FitResults,Spectrum] = multi_comp_fit_v2(reshape(data.MET2data,[1 1 1 length(obj.Prot.Echo.Mat)]), EchoTimes, DecayMatrix, T2, Opt, 'tissue', data.Mask);
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            % Example: obj.Sim_Single_Voxel_Curve(obj.st,button2opts(obj.Sim_Single_Voxel_Curve_buttons))
            if ~exist('display','var'), display = 1; end
            if ~exist('Opt','var'), Opt = button2opts(obj.Sim_Single_Voxel_Curve_buttons); end
            [Smodel, Spectrum] = equation(obj,x,Opt);
            sigma = 1./Opt.SNR;
            data.MET2data = random('rician',Smodel,sigma);
            data.Mask = 1;
            FitResults = fit(obj,data);
            if display
                plotmodel(obj, [], data);
                subplot(2,1,1)
                EchoTimes   = obj.Prot.Echo.Mat;
                T2          = getT2(obj,EchoTimes);
                hold on
                plot(T2.vals,Spectrum,'b');
                Legend          = legend('Fitted Spectrum','Simulated Spectrum','Location','Best');
                Legend.FontSize = 10;
                hold off
            end
        end
        
        function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opt)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, Opt.Nofrun, OptTable, Opt);
        end
        
        function SimRndResults = Sim_Multi_Voxel_Distribution(obj, RndParam, Opt)
            % SimRndGUI
            SimRndResults = SimRnd(obj, RndParam, Opt);
        end
        
        function plotmodel(obj, x, data, PlotSpectrum)
            if ~exist('PlotSpectrum','var'), PlotSpectrum = 1; end % Spectrum is plot per default
            EchoTimes   = obj.Prot.Echo.Mat;
            T2          = getT2(obj,EchoTimes);
            if exist('data','var')
                [~,Spectrum] = fit(obj,data);
                DecayMatrix = getDecayMatrix(EchoTimes,T2.vals);
                Smodel = DecayMatrix*Spectrum;
            else
                [Smodel, Spectrum] = equation(obj,x);
            end
            
            if PlotSpectrum
                % Figure with SPECTRUM
                %----------------------- subplot 1 -----------------------%
                subplot(2,1,1)
                plot(T2.vals,Spectrum,'r');
                Title           = title('Spectrums comparison');
                Title.FontSize  = 12;
                xlabel('T2 (ms)');
                ylabel('Proton density');
                %----------------------- subplot 2 -----------------------%
                subplot(2,1,2)
                plot(EchoTimes,data.MET2data,'+')
                hold on
                plot(EchoTimes,Smodel,'r')
                hold off
                Title           = title('Fitting');
                Title.FontSize  = 12;
                Legend          = legend('Simulated data','Fitted curve','Location','Best');
                Legend.FontSize = 10;
                xlabel('EchoTimes (ms)');
                ylabel('MET2 ()'); 
                %---------------------------------------------------------%
            else
                % Figure without SPECTRUM
                %---------------------------------------------------------%
                plot(EchoTimes,data.MET2data,'+')
                hold on
                plot(EchoTimes,Smodel,'r')
                hold off
                Title           = title('Fitting');
                Title.FontSize  = 12;
                Legend          = legend('Simulated data','Fitted curve','Location','Best');
                Legend.FontSize = 10;
                xlabel('EchoTimes (ms)');
                ylabel('MET2 ()');
                %---------------------------------------------------------%
            end
        end
        
        function [Smodel, Spectrum] = equation(obj,x,Opt)
            if isnumeric(x), xbu = x; x=struct; x.MWF = xbu(1); x.T2MW = xbu(2); x.T2IEW = xbu(3); end
            if nargin < 3, Opt.T2MW_Var = 0; Opt.T2IEW_Var = 0; end
            x.MWF = x.MWF/100;
            % EchoTimes, T2 and DecayMatrix
            EchoTimes   = obj.Prot.Echo.Mat;
            T2          = getT2(obj,EchoTimes);
            DecayMatrix = getDecayMatrix(EchoTimes,T2.vals);
            % MF (Myelin Fraction) and IEF (Intra/Extracellular Fraction)
            % with their index (index of the closest value)
            MF  = x.MWF;
            IEF = 1 - MF;
            SpectrumMW = pdf('rician',T2.vals,x.T2MW,sqrt(Opt.Spectrumvariance_T2Myelin+eps));
            SpectrumMW = SpectrumMW/sum(SpectrumMW);
            SpectrumIEW = pdf('rician',T2.vals,x.T2IEW,sqrt(Opt.Spectrumvariance_T2IntraExtracellularWater+eps));
            SpectrumIEW = SpectrumIEW/sum(SpectrumIEW);
            
            % Create the spectrum
            Spectrum = MF*SpectrumMW + IEF*SpectrumIEW;
            % Generate the signal
            Smodel = DecayMatrix * Spectrum;
        end
    end
end

function T2 = getT2(obj,EchoTimes)
    T2.num = 120;
    switch obj.options.RelaxationType
        case 'T2'
            T2.range = [1.5*EchoTimes(1), 400]; % Kolind et al. doi: 10.1002/mrm.21966
        case 'T2star'
            T2.range = [1.5*EchoTimes(1), 300]; % Lenz et al. doi: 10.1002/mrm.23241
            %             T2_range = [1.5*echo_times(1), 600]; % Use this to look at CSF component
    end
    T2.vals = T2.range(1)*(T2.range(2)/T2.range(1)).^(0:(1/(T2.num-1)):1)';
end

function DecayMatrix = getDecayMatrix(EchoTimes,T2vals)
    DecayMatrix = zeros(length(EchoTimes),length(T2vals));
    for j = 1:length(T2vals)
        DecayMatrix(:,j) = exp(-EchoTimes/T2vals(j))';
    end
end
