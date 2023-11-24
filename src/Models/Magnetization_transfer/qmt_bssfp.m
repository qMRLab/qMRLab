classdef qmt_bssfp < AbstractModel
% qmt_bssfp : qMT using Balanced Steady State Free Precession acquisition
%-----------------------------------------------------------------------------------------------------
% Assumptions:
%
% Inputs:
%   MTdata        4D Magnetization Transfer data
%   (R1map)       1/T1map (OPTIONAL)
%   (Mask)        Binary mask to accelerate the fitting (OPTIONAL)
%
% Outputs:
%     F         Ratio of number of restricted pool to free pool, defined
%               as F = M0r/M0f = kf/kr.
%     kr        Exchange rate from the free to the restricted pool
%               (note that kf and kr are related to one another via the
%               definition of F. Changing the value of kf will change kr
%               accordingly, and vice versa).
%     R1f       Longitudinal relaxation rate of the free pool
%               (R1f = 1/T1f).
%     R1r       Longitudinal relaxation rate of the restricted pool
%               (R1r = 1/T1r).
%     T2f       Tranverse relaxation time of the free pool (T2f = 1/R2f).
%     M0f       Equilibrium value of the free pool longitudinal
%               magnetization.
%
%   Additional Outputs
%     M0r       Equilibrium value of the restricted pool longitudinal
%                  magnetization.
%     kf        Exchange rate from the restricted to the free pool.
%     resnorm   Fitting residual.
%
% Protocol:
%   MTdata      Array [nbVols x 2]:
%       Alpha   Flip angle of the RF pulses (degrees)
%       Trf     Duration of the RF pulses (s)
%
% Options:
%   RF Pulse
%       Shape           Shape of the RF pulses.
%                          Available shapes are:
%                          - hard
%                          - gaussian
%                          - gausshann (gaussian pulse with Hanning window)
%                          - sinc
%                          - sinchann (sinc pulse with Hanning window)
%                          - singauss (sinc pulse with gaussian window)
%                          - fermi
%       Nb of RF pulses Number of RF pulses applied before readout.
%
%   Protocol Timing
%       Fix TR          Select this option and enter a value in the text
%                         box below to set a fixed repetition time.
%       Fix TR - Trf	Select this option and enter a value in the text
%                         box below to set a fixed free precession time
%                         (TR - Trf).
%       Prepulse      Perform an Alpha/2 - TR/2 prepulse before each
%                         series of RF pulses.
%
%   R1
%       Use R1map to      By checking this box, you tell the fitting
%         constrain R1f   algorithm to check for an observed R1map and use
%                         its value to constrain R1f. Checking this box
%                         will automatically set the R1f fix box to true in
%                         the Fit parameters table.
%       Fix R1r = R1f     By checking this box, you tell the fitting
%                         algorithm to fix R1r equal to R1f. Checking this
%                         box will automatically set the R1r fix box to
%                         true in the Fit parameters table.
%
%   Global
%       G(0)              The assumed value of the absorption lineshape of
%                         the restricted pool.
%
% References:
%   Please cite the following if you use this module:
%
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
    onlineData_url = 'https://osf.io/r64tk/download?version=3';
end

    properties
        MRIinputs = {'MTdata','R1map','Mask'}; % input data required
        xnames = {'F','kr','R1f','R1r','T2f','M0f'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?

        % fitting options
        st           = [ 0.1    30      1        1        0.04    1 ]; % starting point
        lb           = [ 0.0001        0.0001       0.2      0.2      0.01    0.0001]; % lower bound
        ub           = [ 0.3   100      3        3        0.2     2 ]; % upper bound
        fx           = [ 0       0      1        1        0       0 ]; % fix parameters

        % Protocol
        % You can define a default protocol here.
        Prot = struct('MTdata',...
                               struct('Format',{{'Alpha' 'Trf'}},...
                                      'Mat', [5 2.7e-4; 10 2.7e-4; 15 2.7e-4; 20 2.7e-4; 25 2.7e-4
                                              30 2.7e-4; 35 2.7e-4; 40 2.7e-4; 35 2.3e-4; 35 3.0e-4
                                              35 4.0e-4; 35 5.8e-4; 35 8.4e-4; 35 0.0012; 35 0.0016
                                              35 0.0021]));

        % Model options
        buttons = {'PANEL', 'RF_Pulse',2,...
                   'Shape',{'gaussian','hard','gausshann','sinc','sinchann','sincgauss','fermi'},'# of RF pulses',500,...
                   'PANEL','Protocol Timing',2,...
                   'Type',{'fix TR - Trf','fix TR'},...
                   'Value',0.00269,...
                   'Prepulse',true,...
                   'G(0)',1.2524e-05,...
                   'PANEL','R1',2,...
                   'Use R1map to constrain R1f',true,...
                   'Fix R1r = R1f',true};
        options = struct(); % structure filled by the buttons. Leave empty in the code

        Sim_Single_Voxel_Curve_buttons = {'SNR',50,'Method',{'Analytical equation','Bloch sim'},'Reset Mz',false};
        Sim_Sensitivity_Analysis_buttons = {'# of run',5};
    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods
        function obj = qmt_bssfp
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end

        function obj = UpdateFields(obj)
            if obj.options.R1_UseR1maptoconstrainR1f
                obj.fx(3)=true;
            end
            if obj.options.R1_FixR1rR1f
                obj.fx(4)=true;
            end
        end

        function mxy = equation(obj, x, Opt)
            if nargin<3, Opt=button2opts(obj.Sim_Single_Voxel_Curve_buttons); end
            x=struct2mat(x,obj.xnames);
            x = x+eps;
            for ix = 1:length(x)
                Sim.Param.(obj.xnames{ix}) = x(ix);
            end
            Sim.Param.G = obj.options.G0;
            Protocol = GetProt(obj);
            switch Opt.Method
                case 'Bloch sim'
                    Sim.Opt.Reset = Opt.ResetMz;
                    Sim.Opt.SScheck = 1;
                    Sim.Opt.SStol = 5e-5;
                    if isempty(getenv('ISDISPLAY')) || str2double(getenv('ISDISPLAY')), ISDISPLAY=1; else ISDISPLAY=0; end
                    mxy = bSSFP_sim(Sim, Protocol, ISDISPLAY);
                case 'Analytical equation'
                    FitOpt = obj.GetFitOpt;
                    [alpha1, Trf1, TR1, W1] = bSSFP_prepare(Protocol,FitOpt);
                    xdata = [alpha1, Trf1, TR1, W1];
                    mxy = bSSFP_fun( x, xdata, FitOpt );
            end
        end


        function FitResults = fit(obj,data)
            Protocol = GetProt(obj);
            FitOpt = GetFitOpt(obj,data);
            FitResults = bSSFP_fit(data.MTdata,Protocol,FitOpt);
        end

        function plotModel(obj, x, data)
            if nargin<2, x = obj.st; end
            if nargin<3, data.MTdata = []; end
            x=mat2struct(x,obj.xnames);

            Protocol = GetProt(obj);
            FitOpt = GetFitOpt(obj,data);
            SimCurveResults = bSSFP_SimCurve(x, Protocol, FitOpt );
            Sim.Opt.AddNoise = 0;
            axe(1) = subplot(2,1,1);
            axe(2) = subplot(2,1,2);
            bSSFP_PlotSimCurve(data.MTdata, data.MTdata, Protocol, Sim, SimCurveResults, axe);
            if ~isfield(x,'kf'), x.kf = x.kr/x.F; end;
            if ~isfield(x,'resnorm'), x.resnorm = 0; end;
            title(sprintf('F=%0.2f; kf=%0.2f; R1f=%0.2f; R1r=%0.2f; T2f=%0.2f; M0f=%0.2f; Residuals=%f', ...
                x.F,x.kf,x.R1f,x.R1r,x.T2f,x.M0f,x.resnorm), ...
                'FontSize',10);
        end

%         function plotProt(obj)
%             subplot(1,1,2)
%             plot(obj.Prot.MTdata(:,1),obj.Prot.MTdata(:,2))
%             subplot(2,1,2)
%             title('MTpulse')
%             angles = Prot.Angles(1);
%             offsets = Prot.Offsets(1);
%             shape = Prot.MTpulse.shape;
%             Trf = Prot.Tm;
%             PulseOpt = Prot.MTpulse.opt;
%             Pulse = GetPulse(angles, offsets, Trf, shape, PulseOpt);
%             figure();
%             ViewPulse(Pulse,'b1');
%         end
%

        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            % Example: obj.Sim_Single_Voxel_Curve(obj.st,button2opts(obj.Sim_Single_Voxel_Curve_buttons))
            if ~exist('display','var'), display = 1; end
            Smodel = equation(obj, x, Opt);
            data.MTdata = addNoise(Smodel, Opt.SNR, 'magnitude');
            FitResults = fit(obj,data);
            if display
                plotModel(obj, FitResults, data);
            end
        end

        function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opts)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, Opts.Nofrun, OptTable, Opts);
        end

        function SimRndResults = Sim_Multi_Voxel_Distribution(obj, RndParam, Opt)
            % SimRndGUI
            SimRndResults = SimRnd(obj, RndParam, Opt);
        end

%   INTERFACE VARIABLES WITH OLD VERSION OF qMTLAB:
        function Prot = GetProt(obj)
            Prot.alpha = obj.Prot.MTdata.Mat(:,1);
            Prot.Trf = obj.Prot.MTdata.Mat(:,2);
            Prot.FixTR = strcmp(obj.options.ProtocolTiming_Type,'fix TR');
            Prot.TR = obj.options.ProtocolTiming_Value;
            Prot.Td = obj.options.ProtocolTiming_Value;
            Prot.Pulse.shape = obj.options.RF_Pulse_Shape;
            Prot.Npulse = obj.options.RF_Pulse_NofRFpulses;
            Prot.prepulse = obj.options.Prepulse;
        end

        function FitOpt = GetFitOpt(obj,data)
            if exist('data','var') && isfield(data,'R1map'), FitOpt.R1 = data.R1map; end
            FitOpt.R1map = obj.options.R1_UseR1maptoconstrainR1f;
            FitOpt.names = obj.xnames;
            FitOpt.fx = obj.fx;
            FitOpt.st = obj.st;
            FitOpt.lb = obj.lb;
            FitOpt.ub = obj.ub;
            FitOpt.R1reqR1f = obj.options.R1_FixR1rR1f;
            FitOpt.G = obj.options.G0;
        end

    end
end
