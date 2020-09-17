
classdef inversion_recovery < AbstractModel
%inversion_recovery: Compute a T1 map using Inversion Recovery data
%
% Assumptions:
% (1) Gold standard for T1 mapping
% (2) Infinite TR
%
% Inputs:
%   IRData      Inversion Recovery data (4D)
%   (Mask)      Binary mask to accelerate the fitting (OPTIONAL)
%
% Outputs:
%   T1          transverse relaxation time [ms]
%   b           arbitrary fit parameter (S=a + b*exp(-TI/T1))
%   a           arbitrary fit parameter (S=a + b*exp(-TI/T1))
%   idx         index of last polarity restored datapoint (only used for magnitude data)
%   res         Fitting residual
%
%
% Protocol:
%	IRData  [TI1 TI2...TIn] inversion times [ms]
%   TimingTable   [TR] repetition time [ms]
%
% Options:
%   method          Method to use in order to fit the data, based on whether complex or only magnitude data acquired.
%     'complex'     Complex dataset.
%     'magnitude'   Magnitude dataset.
%
%
%   fitModel        T1 fitting moddel.
%     'Barral'      Fitting equation: a+bexp(-TI/T1)
%     'General'     Fitting equation: c(1-2exp(-TI/T1)+exp(-TR/T1))
%
% Example of command line usage (see also <a href="matlab: showdemo inversion_recovery_batch">showdemo inversion_recovery_batch</a>):
%   Model = inversion_recovery;  % Create class from model
%   Model.Prot.IRData.Mat=[350.0000; 500.0000; 650.0000; 800.0000; 950.0000; 1100.0000; 1250.0000; 1400.0000; 1700.0000];
%   data = struct;  % Create data structure
%   data.MET2data ='IRData.mat';  % Load data
%   data.Mask = 'Mask.mat';
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_mat(FitResults);
%
%       For more examples: <a href="matlab: qMRusage(minversion_recovery);">qMRusage(inversion_recovery)</a>
%
% Author: Ilana Leppert, 2017
%
% References:
%   Please cite the following if you use this module:
%       A robust methodology for in vivo T1 mapping. Barral JK, Gudmundson E, Stikov N, Etezadi-Amoli M, Stoica P, Nishimura DG. Magn Reson Med. 2010 Oct;64(4):1057-67. doi: 10.1002/mrm.22497.
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
    onlineData_url = 'https://osf.io/cmg9z/download?version=3';
end

	properties
        MRIinputs = {'IRData','Mask'}; % input data required
        xnames = {'T1','rb','ra'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?

        % fitting options
        st           = [  600    -1000      500 ]; % starting point
        lb           = [    0.0001   -10000        0.0001 ]; % lower bound
        ub           = [ 5000        0    10000 ]; % upper bound
        fx           = [    0        0        0 ]; % fix parameters

        % Protocol
        Prot = struct('IRData', struct('Format',{'TI(ms)'},'Mat',[350 500 650 800 950 1100 1250 1400 1700]'),...
                      'TimingTable', struct('Format',{{'TR(ms)'}},'Mat',2500)); %default protocol
        % Model options
        buttons = {'method',{'Magnitude','Complex'}, 'fitModel',{'Barral','General'}}; %selection buttons
        options = struct(); % structure filled by the buttons. Leave empty in the code

        % Simulation Options
        Sim_Single_Voxel_Curve_buttons = {'SNR',50,'T1',600,'M0',1000,'TR',3000,'FAinv',180,'FAexcite',90,'Update input variables','pushbutton'};%'FArefocus',180
        Sim_Optimize_Protocol_buttons = {'# of volumes',5,'Population size',100,'# of migrations',100};

    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods
        % -------------CONSTRUCTOR-------------------------------------------------------------------------
        function  obj = inversion_recovery()
            obj.options = button2opts(obj.buttons);
        end

        function obj = UpdateFields(obj)
            obj.Prot.IRData.Mat = sort(obj.Prot.IRData.Mat);
        end
        function xnew = SimOpt(obj,x,Opt)
            [ra,rb] = ComputeRaRb(obj,x,Opt);
            xnew = [Opt.T1 rb ra];

        end

        % -------------IR EQUATION-------------------------------------------------------------------------
        function Smodel = equation(obj, x)
            % Generates an IR signal based on fit parameters
            x = mat2struct(x,obj.xnames); % if x is a structure, convert to vector

            % equation
            Smodel = x.ra + x.rb * exp(-obj.Prot.IRData.Mat./x.T1);
            if (strcmp(obj.options.method, 'Magnitude'))
                Smodel = abs(Smodel);
            end
        end

        % -------------EXPLICIT IR EQUATION-------------------------------------------------------------------------
        function [ra,rb] = ComputeRaRb(obj,x,Opt)

            % Some sanity checks
            [ErrMsg]=[];

            for brkloop=1:1
                if Opt.TR < max(obj.Prot.IRData.Mat) %TR can't be less than max TI
                    txt=['The TR (' num2str(Opt.TR) ') cannot be less than max TI (' num2str(max(obj.Prot.IRData.Mat)),')'];
                    ErrMsg = txt; break
                end
                if Opt.T1 < 0 || Opt.T1 > 10000
                    txt='Choose a reasonable value for T1 (0-10000 s)';
                    ErrMsg = txt; break
                end
                if Opt.FAinv < 120 || Opt.FAinv > 220
                    txt='Choose a reasonable value for the inversion FA (120-220 deg)';
                    ErrMsg = txt; break
                end
                 if Opt.FAexcite < 50 || Opt.FAexcite > 120
                    txt='Choose a reasonable value for the excitation FA (50-120 deg)';
                    ErrMsg = txt; break
                end
            end
            if ~isempty(ErrMsg)
                if moxunit_util_platform_is_octave
                    errordlg(ErrMsg,'Input Error');
                else
                    Mode = struct('WindowStyle','modal','Interpreter','tex');
                    errordlg(ErrMsg,'Input Error', Mode);
                    error(ErrMsg);
                end
            end

            % equation for GRE-IR
            ra = Opt.M0 * (1-cos(Opt.FAinv*pi/180)*exp(-Opt.TR/Opt.T1))/(1-cos(Opt.FAinv*pi/180)*cos(Opt.FAexcite*pi/180)*exp(-Opt.TR/Opt.T1));
            rb = -Opt.M0 * (1-cos(Opt.FAinv*pi/180))/(1-cos(Opt.FAinv*pi/180)*cos(Opt.FAexcite*pi/180)*exp(-Opt.TR/Opt.T1));
            %Smodel = ra + rb * exp(-obj.Prot.IRData.Mat./x.T1);
            %if (strcmp(obj.options.method, 'Magnitude'))
            %    Smodel = abs(Smodel);
            %end
        end

        % -------------DATA FITTING-------------------------------------------------------------------------
        function FitResults = fit(obj,data)
            % Fits the data
            %
            
            data = data.IRData;
            
            switch obj.options.fitModel
                case 'Barral'
                    [T1,rb,ra,res,idx] = fitT1_IR(data,obj.Prot.IRData.Mat,obj.options.method);
                    FitResults.T1  = T1;
                    FitResults.rb  = rb;
                    FitResults.ra  = ra;
                    FitResults.res = res;
                    if (strcmp(obj.options.method, 'Magnitude'))
                        FitResults.idx = idx;
                    end
                case 'General'
                    approxFlag = 3; % Selects the equation c(1-2exp(-TI/T1)+exp(TR/T1))

                    params.TI = obj.Prot.IRData.Mat';
                    params.TR = obj.Prot.TimingTable.Mat;
                    
                    if strcmp(obj.options.method, 'Magnitude')
                        % Make sure data vector is a column vector
                        data = data(:);

                        % Find the min of the data (which is nearest to
                        % signal null to flip
                        [~, minInd] = min(data);
                        
                        % Signal inversion algorithm to fir the T1 curve
                        for ii = 1:2
                            % Fit the data by inverting the sign of the
                            % datapoints up until the TI where signal is
                            % null, then also without that point. The
                            % fit with the smallest residual is our best
                            % guess for up to where to flip the sign of the
                            % signal.
                            if ii == 1
                                % First, we set all elements up to and including
                                % the smallest element to minus
                                dataTmp = data.*[-ones(minInd,1); ones(length(data) - minInd,1)];
                            elseif ii == 2
                                % Second, we set all elements up to (not including)
                                % the smallest element to minus
                                dataTmp = data.*[-ones(minInd-1,1); ones(length(data) - (minInd-1),1)];
                            end
                            [fitVals{ii}, resnorm(ii)] = inversion_recovery.fit_lm(dataTmp, params, approxFlag);
                        end
                        [~,ind] = min(resnorm); % Index of the minimum residual will be which signal fit results to choose.
                        FitResults.T1 = fitVals{ind}.T1;
                        FitResults.ra = fitVals{ind}.ra;
                        FitResults.rb = fitVals{ind}.rb;
                        FitResults.res = resnorm(ind);
                        FitResults.idx = ind;
                    elseif strcmp(obj.options.method, 'Complex')
                        params.dataType = 'complex';
                        [fitVals, resnorm] = inversion_recovery.fit_lm(data(:), params, 3);
                        FitResults.T1 = fitVals.T1;
                        FitResults.ra = fitVals.ra;
                        FitResults.rb = fitVals.rb;
                        FitResults.res = resnorm;
                    end
            end
        end

        function plotModel(obj, FitResults, data)
            % Plots the fit
            %
            % :param FitResults: [struct] Fitting parameters
            % :param data: [struct] input data
            if nargin<2 || isempty(FitResults), FitResults = obj.st; end
            if exist('data','var')
                data = data.IRData;
                % plot
                plot(obj.Prot.IRData.Mat,data,'.','MarkerSize',15)
                hold on
                if (strcmp(obj.options.method, 'Magnitude'))
                    % plot the polarity restored data points
                    data_rest = -1.*data(1:FitResults.idx);
                    plot(obj.Prot.IRData.Mat(1:FitResults.idx),data_rest,'o','MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor',[1 0 0])
                end
            end

            % compute model
            obj.Prot.IRData.Mat = linspace(min(obj.Prot.IRData.Mat),max(obj.Prot.IRData.Mat),100);
            Smodel = equation(obj, FitResults);

            % plot fitting curve
            plot(obj.Prot.IRData.Mat,Smodel,'Linewidth',3)
            hold off
            xlabel('Inversion Time [ms]','FontSize',15);
            ylabel('Signal','FontSize',15);
            legend('data', 'polarity restored', 'fit','Location','best')
            set(gca,'FontSize',15)
        end

        function [FitResults, data] = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            % Simulates Single Voxel
            %
            % :param x: [struct] fit parameters
            % :param Opt.SNR: [struct] signal to noise ratio to use
            % :param display: 1=display, 0=nodisplay
            % :returns: [struct] FitResults, data (noisy dataset)

            if ~exist('display','var'), display = 1; end

            Smodel = equation(obj, x);
            sigma = max(abs(Smodel))/Opt.SNR;
            if (strcmp(obj.options.method, 'Magnitude'))
                data.IRData = ricernd(Smodel,sigma);
            else
                data.IRData = random('normal',Smodel,sigma);
            end
            FitResults = fit(obj,data);
            if display
                plotModel(obj, FitResults, data);
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

%         function schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,Opt)
%             % schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,nV,popSize,migrations)
%             % schemeLEADER = Sim_Optimize_Protocol(obj,obj.st,30,100,100)
%             % Optimize Inversion times
%             nV         = Opt.Nofvolumes;
%             popSize    = Opt.Populationsize;
%             migrations = Opt.Nofmigrations;
%
%             sigma  = .05;
%             TImax = 5000;
%             TImin = 50;
%             GenerateRandFunction = @() rand(nV,1)*(TImax-TImin)+TImin; % do not sort TI values... or you might fall in a local minima
%             CheckProtInBoundFunc = @(Prot) min(max(50,Prot),TImax);
%             % Optimize Protocol
%             [retVal] = soma_all_to_one(@(Prot) mean(SimCRLB(obj,Prot,xvalues,sigma)), GenerateRandFunction, CheckProtInBoundFunc, migrations, popSize, nV, obj.Prot.IRData.Mat(:,1));
%
%             % Generate Rest
%             schemeLEADER = retVal.schemeLEADER;
%
%             fprintf('SOMA HAS FINISHED \n')
%
%         end

    end

    % CLI-only implemented static methods. Can be called directly from
    % class - no object needed.
    methods(Static)
        function Mz = analytical_solution(params, seqFlag, approxFlag)
            %ANALYTICAL_SOLUTION  Analytical equations for the longitudinal magnetization of
            %steady-state inversion recovery experiments with either a gradient echo
            %(GRE-IR) or spin-echo (SE-IR) readouts.
            %   Reference: Barral, J. K., Gudmundson, E. , Stikov, N. , Etezadi?Amoli,
            %   M. , Stoica, P. and Nishimura, D. G. (2010), A robust methodology for
            %   in vivo T1 mapping. Magn. Reson. Med., 64: 1057-1067.
            %   doi:10.1002/mrm.22497
            %
            %   params: struct with the required parameters for the sequence and
            %   approximation. See below for list.
            %
            %   seqFlag: String. Either 'GRE-IR' or 'SE-IR'
            %   approxFlag: Integer between 1 and 4.
            %       1: General equation (no approximation).
            %       2: Ideal 180 degree pulse approximation of case 1.
            %       3: Ideal 90 degree pulse approximation of case 2, and readout term
            %          absorbed into constant.
            %       4: Long TR (TR >> T1) approximation of case 3.
            %
            %   **PARAMS PROPERTIES**
            %   All times in ms, all angles in degrees.
            %  'GRE-IR'
            %       case 1: T1, TR, TI, EXC_FA, INV_FA, constant (optional)
            %       case 2: T1, TR, TI, EXC_FA, constant (optional)
            %       case 3: T1, TR, TI, constant (optional)
            %       case 4: T1, TI, constant (optional)
            %
            %  'SE-IR'
            %       case 1: Same as 'GRE-IR' case + SE_FA, TE
            %       case 2: Same as 'GRE-IR' case + TE
            %       case 3: Same as 'GRE-IR' case + TE
            %       case 4: Same as 'GRE-IR' case
            %

            Mz = ir_equations(params, seqFlag, approxFlag);

        end

        function [Mz, Msig] = bloch_sim(params)
            %BLOCH_SIM Bloch simulations of the GRE-IR pulse sequence.
            % Simulates 100 spins params.Nex repetitions of the IR pulse
            % sequences.
            %
            % params: Struct with the following fields:
            %   INV_FA: Inversion pulse flip angle in degrees.
            %   EXC_FA: Excitation pulse flip angle in degrees.
            %   TI: Inversion time (ms).
            %   TR: Repetition time (ms).
            %   TE: Echo time (ms).
            %   T1: Longitudinal relaxation time (ms).
            %   T2: Transverse relaxation time (ms).
            %   Nex: Number of excitations
            %
            %   (optional
            %       df: Off-resonance frequency of spins relative to excitation pulse (in Hz)
            %       crushFlag: Numeric flag for perfect spoiling (1) or partial spoiling (2).
            %       partialDephasing: Partial dephasing fraction (between [0, 1]). 1 = no dephasing, 0 = complete dephasing (sele
            %       inc: Phase spoiling increment in degrees.
            %
            % Outputs:
            %   Mz: Longitudinal magnetization at time TI (prior to excitation pulse).
            %   Msig: Complex signal produced by the transverse magnetization at time TE after excitation.
            %

            %% Setup parameters
            %

            alpha = deg2rad(params.INV_FA);
            beta  = deg2rad(params.EXC_FA);
            TI = params.TI;
            TR = params.TR;
            T1 = params.T1;

            TE = params.TE;
            T2 = params.T2;

            Nex = params.Nex;

            %% Optional parameers

            if isfield(params, 'df')
                df = params.df;
            else
                df = 0;
            end

            if isfield(params, 'crushFlag')
                crushFlag = params.crushFlag;
            else
                crushFlag = 1;
            end

            if isfield(params, 'partialDephasing')
                partialDephasing = params.partialDephasing;
            else
                partialDephasing = 1;
            end

            if isfield(params, 'inc')
                inc = deg2rad(params.inc);
            else
                inc = 0;
            end

            %% Simulate for every TI's
            %

            for ii = 1:length(TI)

                [Msig(ii), Mz(ii)] = ir_blochsim(                  ...
                                                 alpha,            ...
                                                 beta,             ...
                                                 TI(ii),           ...
                                                 T1,               ...
                                                 T2,               ...
                                                 TE,               ...
                                                 TR,               ...
                                                 crushFlag,        ...
                                                 partialDephasing, ...
                                                 df,               ...
                                                 Nex,              ...
                                                 inc               ...
                                                 );

            end

        end

        function [fitVals, resnorm] = fit_lm(data, params, approxFlag)
            % FIT_LM Levenberg-Marquardt fitting of GRE-IR data.
            %
            % data: Array for a single voxel (length = #TI)
            % params: Properties TI and TR (except for approxFlag = 4,
            %         where only TI is needed)
            % approxFlag: Same flags numbering & equations as for the
            %             analytical_solution class method.

            switch approxFlag
                case 1
                    TI = params.TI;
                    TR = params.TR;

                    %    [constant, T1, EXC_FA, INV_FA]
                    x0 = [1, 1000, 90, 180];

                    options.Algorithm = 'levenberg-marquardt';
                    options.Display = 'off';

                    [x, resnorm] = lsqnonlin(@(x)ir_loss_func_1(x, TR, TI, data), x0, [], [], options);

                    fitVals.INV_FA = x(4);
                    fitVals.EXC_FA = x(3);
                    fitVals.T1 = x(2);
                    fitVals.c = x(1);
                case 2
                    TI = params.TI;
                    TR = params.TR;

                    %    [constant, T1, EXC_FA]
                    x0 = [1, 1000, 90];

                    options.Algorithm = 'levenberg-marquardt';
                    options.Display = 'off';

                    [x, resnorm] = lsqnonlin(@(x)ir_loss_func_2(x, TR, TI, data), x0, [], [], options);

                    fitVals.EXC_FA = x(3);
                    fitVals.T1 = x(2);
                    fitVals.c = x(1);

                case 3
                    TI = params.TI;
                    TR = params.TR;

                    % Find the min of the data
                    [~, minInd] = min(abs(data));

                    T1est = -TI(minInd)/log(1/2); % Estimate from null (or min) of data and the equation in Case 4. Used as the first guess for the fitting point.

                    if isfield(params, 'dataType') && strcmp(params.dataType,'complex')
                        % Fit comlex data
                        %    [constant, T1]
                        if max(abs(data)) > 0
                            dataNorm = data/max(abs(data)); % Normalize the data to fit with the initial constant guess of 1.
                        else
                            dataNorm = data;
                        end
                        
                        % Initial fit estimates
                        %    [Re(constant), Im(constant), T1)]
                        x0 = [1, 0, T1est];

                        options.Algorithm = 'trust-region-reflective';
                        options.Display = 'off';
                        
                        % Bound the fitting variables to -2 to 2
                        % (constant) and 0 to 5000 (T1 in ms).
                        [x, resnorm] = lsqnonlin(@(x)ir_loss_func_3(x, TR, TI, dataNorm(:)', params.dataType), x0, [-2, -2, 0], [2, 2, 5000], options);
                        
                        fitVals.T1 = x(3);
                        
                        % ra and rb calculation from Equation 3
                        if max(abs(data)) > 0
                            fitVals.ra = (x(1)+1i*x(2))*max(abs(data)) * (1 + exp(-TR/fitVals.T1));
                            fitVals.rb = -2*(x(1)+1i*x(2))*max(abs(data));
                        else
                            fitVals.ra = (x(1)+1i*x(2)) * (1 + exp(-TR/fitVals.T1));
                            fitVals.rb = -2*(x(1)+1i*x(2));
                        end
                    else
                        % Fit magnitude data
                        %    [constant, T1]
                        x0 = [1, T1est];
                        if max(abs(data)) > 0
                            dataNorm = data/max(abs(data)); % Normalize the data to fit with the initial constant guess of 1.
                        else
                            dataNorm = data;
                        end

                        options.Algorithm = 'trust-region-reflective';
                        options.Display = 'off';

                        % Bound the fitting variables to -2 to 2
                        % (constant) and 0 to 5000 (T1 in ms).
                        [x, resnorm] = lsqnonlin(@(x)ir_loss_func_3(x, TR, TI, dataNorm(:)'), x0, [0, 0], [2, 5000], options);

                        fitVals.T1 = x(2);
                        
                        % ra and rb calculation from Equation 3
                        if max(abs(data)) > 0
                            fitVals.ra = x(1)*max(abs(data)) * (1 + exp(-TR/fitVals.T1));
                            fitVals.rb = -2*x(1)*max(abs(data));
                        else
                            fitVals.ra = x(2) * (1 + exp(-TR/fitVals.T1));
                            fitVals.rb = -2*x(2);
                        end

                    end


                case 4
                    TI = params.TI;
                    %    [constant, T1]
                    x0 = [1, 1000];

                    options.Algorithm = 'levenberg-marquardt';
                    options.Display = 'off';

                    [x, resnorm] = lsqnonlin(@(x)ir_loss_func_4(x, TI, data), x0, [], [], options);

                    fitVals.T1 = x(2);
                    fitVals.c = x(1);
            end

        end

    end

    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            % 2.0.10
            if checkanteriorver(version,[2 0 10])
                % Update buttons for simulation
                snrValue = obj.Sim_Single_Voxel_Curve_buttons{2};
                obj.Sim_Single_Voxel_Curve_buttons = {'SNR' snrValue 'T1' 600 'M0' 1000 'TR' 3000 'FAinv' 180 'FAexcite' 90 'Update input variables' 'pushbutton'};
            end
             if checkanteriorver(version,[2 4 1])
                % Update buttons for simulation
                obj.Prot = struct('IRData', struct('Format',{'TI(ms)'},'Mat',[350 500 650 800 950 1100 1250 1400 1700]'),...
                                  'TimingTable', struct('Format',{{'TR(ms)'}},'Mat',2500)); %default protocol
                % Model options
                obj.buttons = {'method',{'Magnitude','Complex'}, 'fitModel',{'Barral','General'}}; %selection buttons
                obj.options = button2opts(obj.buttons);
            end
        end
    end

end
