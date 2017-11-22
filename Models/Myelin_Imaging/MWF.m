classdef MWF
% MWF :  Myelin Water Fraction from Multi-Exponential T2w data
%
% Assumptions:
%
% Inputs:
%   MET2data    Multi-Exponential T2 data
%   (Mask)        Binary mask to accelerate the fitting (OPTIONAL)
%
% Outputs:
%   MWF       Myelin Wanter Fraction
%   T2MW      Spin relaxation time for Myelin Water (MW) [ms]
%   T2IEW     Spin relaxation time for Intra/Extracellular Water (IEW) [ms]
%
% Options:
%   Cutoff          Cutoff time [ms]
%   Sigma           Noise standard deviation. Currently not corrected for rician bias
%   Relaxation Type
%        'T2'       For a SE sequence
%       'T2*'      For a GRE sequence
%
% Protocol:
%   1 .txt files or 1 .mat file :
%     TE    [TE1 TE2 ...] % list of echo times [ms]
%
% Example of command line usage (see also <a href="matlab: showdemo MWF_batch">showdemo MWF_batch</a>):
%   Model = MWF;  % Create class from model
%   Model.Prot.Echo.Mat=[10:10:320];
%   data = struct;  % Create data structure
%   data.MET2data ='MET2data.mat';  % Load data
%   data.Mask = 'Mask.mat';
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_mat(FitResults);
%
%       For more examples: <a href="matlab: qMRusage(MWF);">qMRusage(MWF)</a>
%
% Author: Ian Gagnon, 2017
%
% References:
%   Please cite the following if you use this module:
%     MacKay, A., Whittall, K., Adler, J., Li, D., Paty, D., Graeb, D.,
%     1994. In vivo visualization of myelin water in brain by magnetic
%     resonance. Magn. Reson. Med. 31, 673?677.
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG,
%     Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and
%     Stikov N. (2016), Quantitative magnetization transfer imaging made
%     easy with qMTLab: Software for data simulation, analysis, and
%     visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

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
        Prot  = struct('MET2data',struct('Format',{{'Echo Time (ms)'}},...
            'Mat', [10; 20; 30; 40; 50; 60; 70; 80; 90; 100; 110; 120; 130; 140; 150; 160; 170;
            180; 190; 200; 210; 220; 230; 240; 250; 260; 270; 280; 290; 300; 310; 320]));

        % Model options
        buttons = {'Cutoff (ms)',40, 'Sigma', 20, 'Relaxation Type' {'T2', 'T2star'}};
        options = struct(); % structure filled by the buttons. Leave empty in the code

        % Simulation Options
        Sim_Single_Voxel_Curve_buttons = {'SNR',200,'PANEL','T2 Spectrum variance',2,'Myelin',5,'IE (Intra/Extracellular Water)',20};
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

        function [Smodel, Spectrum] = equation(obj,x,Opt)
            if isnumeric(x), xbu = x; x=struct; x.MWF = xbu(1); x.T2MW = xbu(2); x.T2IEW = xbu(3); end
            if nargin < 3, Opt.T2Spectrumvariance_Myelin = 5; Opt.T2Spectrumvariance_IEIntraExtracellularWater = 20; end
            x.MWF = x.MWF/100;
            % EchoTimes, T2 and DecayMatrix
            EchoTimes   = obj.Prot.MET2data.Mat;
            T2          = getT2(obj,EchoTimes);
            DecayMatrix = getDecayMatrix(EchoTimes,T2.vals);
            % MF (Myelin Fraction) and IEF (Intra/Extracellular Fraction)
            % with their index (index of the closest value)
            MF  = x.MWF;
            IEF = 1 - MF;
            varT2 = Opt.T2Spectrumvariance_Myelin+eps; meanT2 = x.T2MW; beta=varT2/meanT2; alpha = meanT2/beta;
            SpectrumMW = gampdf(T2.vals,alpha,beta); SpectrumMW(isnan(SpectrumMW))=0;
            SpectrumMW = SpectrumMW/sum(SpectrumMW);
            varT2 = Opt.T2Spectrumvariance_IEIntraExtracellularWater+eps; meanT2 = x.T2IEW; beta=varT2/meanT2; alpha = meanT2/beta;
            SpectrumIEW = gampdf(T2.vals,alpha,beta); SpectrumIEW(isnan(SpectrumIEW))=0;
            SpectrumIEW = SpectrumIEW/sum(SpectrumIEW);
            % Create the spectrum
            Spectrum = MF*SpectrumMW + IEF*SpectrumIEW;
            % Generate the signal
            Smodel = DecayMatrix * Spectrum;
        end

        function [FitResults,Spectrum] = fit(obj,data)
            % EchoTimes, T2 and DecayMatrix
            EchoTimes   = obj.Prot.MET2data.Mat;
            T2          = getT2(obj,EchoTimes);
            DecayMatrix = getDecayMatrix(EchoTimes,T2.vals);
            % Options
            Opt.RelaxationType   = obj.options.RelaxationType;
            Opt.Sigma            = obj.options.Sigma;
            Opt.lower_cutoff_MW  = 1.5*obj.Prot.MET2data.Mat(1); % 1.5 * FirstEcho
            Opt.upper_cutoff_MW  = obj.options.Cutoffms;
            Opt.upper_cutoff_IEW = obj.ub(3);
            % Fitting
            if isempty(data.Mask), data.Mask = 1; end
            [FitResults,Spectrum] = multi_comp_fit_v2(reshape(data.MET2data,[1 1 1 length(obj.Prot.MET2data.Mat)]), EchoTimes, DecayMatrix, T2, Opt, 'tissue', data.Mask);
        end

        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            % Example: obj.Sim_Single_Voxel_Curve(obj.st,button2opts(obj.Sim_Single_Voxel_Curve_buttons))
            if ~exist('display','var'), display = 1; end
            if ~exist('Opt','var'), Opt = button2opts(obj.Sim_Single_Voxel_Curve_buttons); end
            [Smodel, Spectrum] = equation(obj,x,Opt);
            sigma = 1./Opt.SNR;
            data.MET2data = ricernd(Smodel,sigma);
            data.Mask = 1;
            FitResults = fit(obj,data);
            if display
                plotModel(obj, [], data);
                subplot(2,1,1)
                EchoTimes   = obj.Prot.MET2data.Mat;
                T2          = getT2(obj,EchoTimes);
                hold on
                plot(T2.vals,Spectrum,'b');
                if ~moxunit_util_platform_is_octave
                legend({'Fitted Spectrum','Simulated Spectrum'},'FontSize',10);
                end
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

        function plotModel(obj, x, data, PlotSpectrum)
            if nargin<2, x = mean([obj.lb(:),obj.ub(:)],2); end
            if ~exist('PlotSpectrum','var'), PlotSpectrum = 1; end % Spectrum is plot per default
            EchoTimes   = obj.Prot.MET2data.Mat;
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
                title('Spectrums','FontSize',12);
                xlabel('T2 (ms)');
                ylabel('Proton density');
                %----------------------- subplot 2 -----------------------%
                subplot(2,1,2)
                if exist('data','var')
                    plot(EchoTimes,data.MET2data,'+')
                    hold on
                end
                plot(EchoTimes,Smodel,'r')
                hold off
                title('Fitting','FontSize',12);
                if ~moxunit_util_platform_is_octave
                legend({'Simulated data','Fitted curve'},'Location','best','FontSize',12);
                end
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
                if ~moxunit_util_platform_is_octave
                legend('Simulated data','Fitted curve','Location','best','FontSize',10);
                end
                xlabel('EchoTimes (ms)');
                ylabel('MET2 ()');
                %---------------------------------------------------------%
            end
        end
    end
end
