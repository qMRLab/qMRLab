classdef vfa_t1 < AbstractModel
% vfa_t1: Compute a T1 map using Variable Flip Angle
%
% Assumptions:
%
% Inputs:
%   VFAData         Spoiled Gradient echo data, 4D volume with different flip angles in time dimension
%   (B1map)         Normalized transmit excitation field map (B1+). B1+ is defined 
%                   as a  normalized multiplicative factor such that:
%                   FA_actual = B1+ * FA_nominal. (OPTIONAL).
%   (Mask)          Binary mask to accelerate the fitting. (OPTIONAL)
%
% Outputs:
%   T1              Longitudinal relaxation time [s]
%   M0              Equilibrium magnetization
%
% Protocol:
%   VFAData Array [nbFA x 2]:
%       [FA1 TR1; FA2 TR2;...]      flip angle [degrees] TR [s]
%
% Options:
%   None
%
% Example of command line usage:
%   Model = vfa_t1;  % Create class from model
%   Model.Prot.VFAData.Mat=[3 0.015; 20 0.015]; %Protocol: 2 different FAs
%   data = struct;  % Create data structure
%   data.VFAData = load_nii_data('VFAData.nii.gz');
%   data.B1map = load_nii_data('B1map.nii.gz');
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_mat(FitResults);
%
%   For more examples: <a href="matlab: qMRusage(vfa_t1);">qMRusage(vfa_t1)</a>
%
%
% Author: Ian Gagnon, 2017
%
% References:
%   Please cite the following if you use this module:
%     Fram, E.K., Herfkens, R.J., Johnson, G.A., Glover, G.H., Karis, J.P.,
%     Shimakawa, A., Perkins, T.G., Pelc, N.J., 1987. Rapid calculation of
%     T1 using variable flip angle gradient refocused imaging. Magn. Reson.
%     Imaging 5, 201?208
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
 onlineData_url = 'https://osf.io/7wcvh/download?version=3';  
end

    properties
        MRIinputs = {'VFAData','B1map','Mask'};
        xnames = {'M0','T1'};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct('VFAData',struct('Format',{{'FlipAngle' 'TR'}},...
                                         'Mat', [3 0.015; 20 0.015])); % You can define a default protocol here.

        % fitting options
        st           = [2000 0.7]; % starting point
        lb           = [0   0.00001]; % lower bound
        ub           = [6000   5]; % upper bound
        fx           = [0     0]; % fix parameters

        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code

        % Simulation Options
        Sim_Single_Voxel_Curve_buttons = {'SNR',50};
        Sim_Optimize_Protocol_buttons = {'# of volumes',5,'Population size',100,'# of migrations',100};
    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods

        function obj = vfa_t1()
            obj.options = button2opts(obj.buttons);
        end

        function Smodel = equation(obj,x)
            % Generates a VFA signal based on input parameters
            x = mat2struct(x,obj.xnames); % if x is a structure, convert to vector

            % Equation: S=M0sin(a)*(1-E)/(1-E)cos(a); E=exp(-TR/T1)
            flipAngles = (obj.Prot.VFAData.Mat(:,1))';
            TR = obj.Prot.VFAData.Mat(1,2);
            E = exp(-TR/x.T1);
            Smodel = x.M0*sin(flipAngles/180*pi)*(1-E)./(1-E*cos(flipAngles/180*pi));
        end

       function FitResult = fit(obj,data)
            % T1 and M0
            flipAngles = (obj.Prot.VFAData.Mat(:,1))';
            TR = obj.Prot.VFAData.Mat(:,2);
            if obj.voxelwise == 0
                if (length(unique(TR))~=1), error('VFA data must have same TR'); end
                if ~isfield(data, 'B1map'), data.B1map = []; end
                if ~isfield(data, 'Mask'), data.Mask = []; end
                [FitResult.T1, FitResult.M0] = Compute_M0_T1_OnSPGR(double(data.VFAData), flipAngles, TR(1), data.B1map, data.Mask);
            elseif obj.voxelwise == 1
                if ~isfield(data,'B1map'), data.B1map=1; end
                [m0, t1] = mtv_compute_m0_t1(double(data.VFAData), flipAngles, TR(1), data.B1map);
                FitResult.T1 = t1;
                FitResult.M0 = m0;
            end
       end

       function plotModel(obj,x,data)
           if nargin<2 || isempty(x), x = obj.st; end
           x = mat2struct(x,obj.xnames);
           disp(x)
           flipAngles = obj.Prot.VFAData.Mat(:,1)';
           TR = obj.Prot.VFAData.Mat(1,2)';
           subplot(2,1,1)
           if exist('data','var')
               if isfield(data,'B1map')
                  if ~isempty(data.B1map)
                   B1map=data.B1map;
                  end
               else
                   B1map=1;
               end
                % Plot data and fitted signal
                plot(flipAngles,data.VFAData,'.','MarkerSize',16)
            else
                B1map=1;
            end
            E = exp(-TR/x.T1);
            Smodel = x.M0*sin(flipAngles/180*pi*B1map)*(1-E)./(1-E*cos(flipAngles/180*pi*B1map));
            hold on
            plot(flipAngles,Smodel,'x','MarkerSize',16)
            hold off
            title('Data points','FontSize',14);
            xlabel('Flip Angle [deg]','FontSize',12);
            ylabel('Signal','FontSize',12);
            legend('data', 'fitted','Location','best')
            set(gca,'FontSize',12)


            % Plot linear fit
            subplot(2,1,2)
            if exist('data','var')
                ydata = data.VFAData./sin(flipAngles/180*pi*B1map)';
                xdata = data.VFAData./tan(flipAngles/180*pi*B1map)';
                plot(xdata,ydata,'xb','MarkerSize',16)
                hold on
            end
            slope = exp(-TR/x.T1);
            intercept = x.M0*(1-slope);
            X=Smodel./tan(flipAngles/180*pi*B1map);
            mval = min(X);
            Mval = max(X);
            plot([mval Mval],intercept+slope*[mval Mval],'-r');
            hold off
            title(sprintf('Linear Fit: T1=%0.4f s; M0=%0.0f;',x.T1,x.M0),'FontSize',14);
            xlabel('[au]','FontSize',12);
            ylabel('[au]','FontSize',12);
            legend('linearized data', 'linear fit','Location','best')
            %txt=strcat('T1=',num2str(x.T1),'s M0=',num2str(x.M0));
            set(gca,'FontSize',12)

%             h = plot( fitresult, xData, yData,'+');
%             set(h,'MarkerSize',30)
%             legend( h, 'y vs. x', 'untitled fit 1', 'Location', 'NorthEast' );
%             p11 = predint(fitresult,x,0.95,'observation','off');
%             hold on
%             plot(x,p11,'m--'); drawnow;
%             hold off
%             % Label axes
%             xlabel( 'x' );
%             ylabel( 'y' );
%             grid on
%             saveas(gcf,['temp.jpg']);
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
           data.VFAData = ricernd(Smodel,sigma)';
           data.B1map = 1;

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
           % SimVaryGUI
           SimRndResults = SimRnd(obj, RndParam, Opt);
       end


    end
    
    % CLI-only implemented static methods. Can be called directly from
    % class - no object needed.
    methods(Static)
        function Mz = analytical_solution(params)
            %ANALYTICAL_SOLUTION  Analytical equations for the longitudinal magnetization of
            %steady-state gradient echo experiments.
            %
            %   Reference: Stikov, N. , Boudreau, M. , Levesque, I. R.,
            %   Tardif, C. L., Barral, J. K. and Pike, G. B. (2015), On the
            %   accuracy of T1 mapping: Searching for common ground. Magn.
            %   Reson. Med., 73: 514-522. doi:10.1002/mrm.25135
            %
            %   params: Struct.
            %           Properties: T1, TR, EXC_FA, constant (optional)
            %
            
            Mz = vfa_equation(params);
            
        end
        
        function signMaxAngle = ernst_angle(params)
            %ERNST_ANGLE  Analytical equations for the longitudinal magnetization of
            %steady-state gradient echo experiments.
            %
            %   Reference: Ernst, R. R. (1966). "Application of Fourier 
            %   transform spectroscopy to magnetic resonance". Review of 
            %   Scientific Instruments. 37: 93. doi:10.1063/1.171996
            %
            %   params: Struct.
            %           Properties: T1, TR
            %
            
            try
                T1 = params.T1;
                TR = params.TR;
            catch
                error('vfa_t1.ernst_equation: Incorrect parameters.  Run `help vfa_t1.ernst_angle` for more info.')
            end

            signMaxAngle = acosd(exp(-TR./T1));
            
        end
        
        function [Mz, Msig] = bloch_sim(params)
            %BLOCH_SIM Bloch simulations of the GRE-IR pulse sequence.
            % Simulates 100 spins params. Nex repetitions of the IR pulse
            % sequences.
            %
            % params: Struct with the following fields:
            %   EXC_FA: Excitation pulse flip angle in degrees.
            %   TI: Inversion time (ms).
            %   TR: Repetition time (ms).
            %   TE: Echo time (ms).
            %   T1: Longitudinal relaxation time (ms).
            %   T2: Transverse relaxation time (ms).
            %   Nex: Number of excitations
            %
            %   (optional)
            %       df: Off-resonance frequency of spins relative to excitation pulse (in Hz)
            %       crushFlag: Numeric flag for perfect spoiling (1) or partial spoiling (2).
            %       partialDephasingFlag: do partialDephasing (see below)
            %       partialDephasing: Partial dephasing fraction (between [0, 1]). 1 = no dephasing, 0 = complete dephasing (sele
            %       inc: Phase spoiling increment in degrees.
            %
            % Outputs:
            %   Mz: Longitudinal magnetization at just prior to excitation pulse.
            %   Msig: Complex signal produced by the transverse magnetization at time TE after excitation.
            %
            
            %% Setup parameters
            %
            
            alpha = deg2rad(params.EXC_FA);
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
            
            if isfield(params, 'partialDephasingFlag')
                partialDephasingFlag = params.partialDephasingFlag;
            else
                partialDephasingFlag = 0;
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
            
            %% Simulate for every flip angless
            %
            
            for ii = 1:length(alpha)
                
                [Msig(ii), Mz(ii)] = vfa_blochsim(                  ...
                    alpha(ii),            ...
                    T1,                   ...
                    T2,                   ...
                    TE,                   ...
                    TR,                   ...
                    crushFlag,            ...
                    partialDephasingFlag, ...
                    partialDephasing,     ...
                    df,                   ...
                    Nex,                  ...
                    inc                   ...
                    );
                
            end
        end
        
        function EXC_FA = find_two_optimal_flip_angles(params, sigFigs)
            %FIND_TWO_OPTIMAL_FLIP_ANGLES Calculate the two optimal flip
            %angles (having signals 71% of the signal at the Ernst angle).
            %
            % Simulates 100 spins params. Nex repetitions of the IR pulse
            % sequences.
            %
            % References:
            %
            % Deoni, S. C., Rutt, B. K. and Peters, T. M. (2003), Rapid 
            % combined T1 and T2 mapping using gradient recalled 
            % acquisition in the steady state. Magn. Reson. Med., 49: 
            % 515-526. 
            %
            % Schabel, M.C. & Morrell, G.R., 2009. Uncertainty in T(1) 
            % mapping using the variable flip angle method with two flip 
            % angles. Physics in medicine and biology, 54(1), pp.N1?8.
            
            
            if ~exist('sigFigs','var')
                sigFigs = 0;
            end
            
            % Set up search space of flip angle and signal values
            flipAngleSearchSpace = 0:1*10^(-sigFigs):90;
            
            params.EXC_FA = flipAngleSearchSpace;
            signals = vfa_t1.analytical_solution(params);
            
            % Get the Angle, find index in search space
            maxAngle = vfa_t1.ernst_angle(params);
            [~,maxRangeIndex] = min(abs(flipAngleSearchSpace-maxAngle));
            
            % Calculate signal at optimal flip angle values
            optAngleSignal= 0.71*signals(maxRangeIndex);
            
            % Calculate indices of optimal flip angles (smaller and larger
            % than the Ernst angle)
            [~,optRangeIndex_small] = min(abs(signals(1:maxRangeIndex)-optAngleSignal));
            [~,optRangeIndex_large_rel] = min(abs(signals(maxRangeIndex+1:end)-optAngleSignal));
            optRangeIndex_large = maxRangeIndex+optRangeIndex_large_rel;
            
            % Output optimal flip angle values
            EXC_FA = [flipAngleSearchSpace(optRangeIndex_small), flipAngleSearchSpace(optRangeIndex_large)];
            
        end
    end
end
