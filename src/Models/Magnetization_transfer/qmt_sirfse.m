classdef qmt_sirfse < AbstractModel
% qmt_sirfse:  qMT using Inversion Recovery Fast Spin Echo acquisition
%<a href="matlab: figure, imshow qmt_sirfse.png ;">Pulse Sequence Diagram</a>
%
% ASSUMPTIONS:
% (1) FILL
% (2)
% (3)
% (4)
%
% Inputs:
%   MTdata              Magnetization Transfert data
%   (R1map)             1/T1map (OPTIONAL but recommended)
%   (Mask)              Binary mask to accelerate the fitting (OPTIONAL)
%
% Outputs:
%   F                   Ratio of number of restricted pool to free pool, defined
%                         as F = M0r/M0f = kf/kr.
%   kr                  Exchange rate from the free to the restricted pool
%                         (note that kf and kr are related to one another via the
%                         definition of F. Changing the value of kf will change kr
%                         accordingly, and vice versa).
%   R1f                 Longitudinal relaxation rate of the free pool
%                         (R1f = 1/T1f).
%   R1r                 Longitudinal relaxation rate of the restricted pool
%                         (R1r = 1/T1r).
%   Sf                  Instantaneous fraction of magnetization after vs. before
%                         the pulse in the free pool. Starting point is computed using Bloch
%                         simulation.
%   Sr                  Instantaneous fraction of magnetization after vs. before
%                         the pulse in the restricted pool. Starting point is computed using Bloch
%                         simulation.
%   M0f                 Equilibrium value of the free pool longitudinal
%                         magnetization.
%   (M0r)               Equilibrium value of the restricted pool longitudinal
%                         magnetization. Computed using M0f = M0r * F.
%   (kf)                Exchange rate from the restricted to the free pool.
%                         Computed using kf = kr * F.
%   (resnorm)           Fitting residual.
%
% Protocol:
%   MTdata
%     Ti                Inversion times (s)
%     Td                Delay times (s)
%
%   FSEsequence
%     Trf               Duration of the pulses in the FSE sequence (s)
%     Tr                Delay between the pulses in the FSE sequnece (s)
%     Npulse            Number of refocusing pulses in the FSE sequence
%
% Options:
%   Inversion Pulse
%     Shape             Shape of the inversion pulse.
%                          Available shapes are:
%                          - hard
%                          - gaussian
%                          - gausshann (gaussian pulse with Hanning window)
%                          - sinc
%                          - sinchann (sinc pulse with Hanning window)
%                          - singauss (sinc pulse with gaussian window)
%                          - fermi
%     Duration          Duration of the inversion pulse (s)
%
%   Fitting
%     Use R1map to      By checking this box, you tell the fitting
%     constrain R1f       algorithm to check for an observed R1map and use
%                         its value to constrain R1f. Checking this box
%                         will automatically set the R1f fix box to true in
%                         the Fit parameters table.
%     Fix R1r = R1f     By checking this box, you tell the fitting
%                         algorithm to fix R1r equal to R1f. Checking this
%                         box will automatically set the R1r fix box to
%                         true in the Fit parameters table.
%
%   Sr Calculation
%     Lineshape         The absorption lineshape of the restricted pool. Available lineshapes are: Gaussian, Lorentzian and SuperLorentzian.
%     T2r               Transverse relaxation time of the restricted pool (T2r = 1/R2r)
%
% Example of command line usage:
%   For more examples: <a href="matlab: qMRusage(qmt_sirfse);">qMRusage(qmt_sirfse)</a>
%
% Author: Ian Gagnon, 2017

% References:
%   Please cite the following if you use this module:
%     Li, K., Zu, Z., Xu, J., Janve, V. A., Gore, J. C., Does, M. D., & Gochberg, D. F. (2010).
%       Optimized inversion recovery sequences for quantitative T1 and magnetization transfer imaging.
%       Magn Reson Med, 64(2), 491500.
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
    onlineData_url = 'https://osf.io/fk2nd/download?version=2';

end

    properties
        MRIinputs = {'MTdata','R1map','Mask'}; % input data required
        xnames = {'F','kr','R1f','R1r','Sf','Sr','M0f'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?

        % fitting options
        st           = [ 0.1    30      1        1     -0.9     0.6564    1  ]; % starting point
        lb           = [ 0.0001       0.0001      0.05     0.05   -1       0.0001         0.0001]; % lower bound
        ub           = [ 1     100     10       10       0       1         2 ]; % upper bound
        fx           = [ 0       0      0        1       0       1         0 ]; % fix parameters

        % Protocol
        % You can define a default protocol here.
        Prot = struct('MTdata',...
                               struct('Format',{{'Ti' 'Td'}},...
                                      'Mat', [0.0030 3.5; 0.0037 3.5; 0.0047 3.5; 0.0058 3.5; 0.0072 3.5
                                              0.0090 3.5; 0.0112 3.5; 0.0139 3.5; 0.0173 3.5; 0.0216 3.5
                                              0.0269 3.5; 0.0335 3.5; 0.0417 3.5; 0.0519 3.5; 0.0646 3.5
                                              0.0805 3.5; 0.1002 3.5; 0.1248 3.5; 0.1554 3.5; 0.1935 3.5
                                              0.2409 3.5; 0.3000 3.5; 1.0000 3.5; 2.0000 3.5; 10.0000 3.5]),...
                      'FSEsequence',...
                               struct('Format',{{'Trf (s)'; 'Tr (s)'; 'Npulse'}},...
                                      'Mat',[0.001; 0.01; 16]));

        % Model options
        buttons = {'PANEL','Inversion_Pulse',2,...
                   'Shape',{'hard','gaussian','gausshann','sinc','sinchann','sincgauss','fermi'},'Duration (s)',0.001,...
                   'PANEL','fitting constraints',2,...
                   'Use R1map to constrain R1f',false,...
                   'Fix R1r = R1f',true,...
                   'PANEL','Sr_Calculation',2,...
                   'T2r',1e-05,...
                   'Lineshape',{'SuperLorentzian','Lorentzian','Gaussian'}};
        options = struct(); % structure filled by the buttons. Leave empty in the code

        % Simulations Default options
        Sim_Single_Voxel_Curve_buttons = {'SNR',50,'Method',{'Analytical equation','Bloch sim assuming M=0 after Tr (full recovery) (slow)','Bloch sim with full FSE (very slow)'},'T2f (Used in Bloch sim)',0.040};
        Sim_Sensitivity_Analysis_buttons = {'# of run',5};
        Sim_Optimize_Protocol_buttons = {'# of volumes',30,'Population size',100,'# of migrations',100};

    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods
        function obj = qmt_sirfse
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end

        function obj = UpdateFields(obj)
            if obj.options.fittingconstraints_UseR1maptoconstrainR1f
                obj.fx(3) = true;
            end

            if obj.options.fittingconstraints_FixR1rR1f
                obj.fx(4) = true;
            end

            SrParam = GetSrParam(obj);
            SrProt = GetSrProt(obj);
            [obj.st(6),obj.st(5)] = computeSr(SrParam,SrProt);
        end

        function mz = equation(obj, x, Opt)
            if nargin<3, Opt=button2opts(obj.Sim_Single_Voxel_Curve_buttons); end
            Sim.Param = mat2struct(x,obj.xnames);
            Protocol = GetProt(obj);
            if strcmp(Opt.Method,'Bloch sim assuming M=0 after Tr (full recovery) (slow)')
                Sim.Opt.method = 'FastSim';
                Opt.Method = 'Bloch sim';
            elseif strcmp(Opt.Method,'Bloch sim with full FSE (very slow)')
                Sim.Opt.method = 'FullSim';
                Opt.Method = 'Bloch sim';
            end
            switch Opt.Method
                case 'Bloch sim'
                    Sim.Param.M0f = 1;
                    Sim.Param.R2f = 1/Opt.T2fUsedinBlochsim;
                    Sim.Param.G   = 1.4176e-5;
                    Protocol.FSE = Protocol;
                    Protocol.InvPulse.Trf = obj.options.Inversion_Pulse_Durations;
                    Protocol.InvPulse.shape = obj.options.Inversion_Pulse_Shape;
                    if isempty(getenv('ISDISPLAY')) || str2double(getenv('ISDISPLAY')), ISDISPLAY=1; else ISDISPLAY=0; end
                    mz = SIRFSE_sim(Sim, Protocol, ISDISPLAY);
                case 'Analytical equation'
                    Sim.Param.Sf = -Sim.Param.Sf;
                    SimCurveResults = SIRFSE_SimCurve(Sim.Param, Protocol, obj.GetFitOpt,0);
                    mz = SimCurveResults.curve;
            end
        end

        function FitResults = fit(obj,data)
            Protocol = GetProt(obj);
            FitOpt = GetFitOpt(obj,data);
            FitResults = SIRFSE_fit(data.MTdata/max(eps,max(data.MTdata)),Protocol,FitOpt);
            FitResults.M0f = FitResults.M0f*max(data.MTdata);
            FitResults.Sf = - FitResults.Sf;
        end

        function plotModel(obj, x, data)
            if nargin<2, x = obj.st; end
            if nargin<3, data.MTdata = []; end
            x=mat2struct(x,obj.xnames);

            Protocol = GetProt(obj);
            FitOpt = GetFitOpt(obj,data);
            x.Sf = - x.Sf;
            SimCurveResults = SIRFSE_SimCurve(x, Protocol, FitOpt );
            Sim.Opt.AddNoise = 0;
            SIRFSE_PlotSimCurve(data.MTdata, data.MTdata, Protocol, Sim, SimCurveResults);
            if ~isfield(x,'kf'), x.kf = x.kr/x.F; end;
            if ~isfield(x,'resnorm'), x.resnorm = 0; end;
            title(sprintf('F=%0.2f; kf=%0.2f; R1f=%0.2f; R1r=%0.2f; Sf=%0.2f; Sr=%f; M0f=%0.2f; Residuals=%f',...
                x.F,x.kf,x.R1f,x.R1r,-x.Sf,x.Sr,x.M0f,x.resnorm), ...
                'FontSize',10);
        end

        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            % Example: obj.Sim_Single_Voxel_Curve(obj.st,button2opts(obj.Sim_Single_Voxel_Curve_buttons))
            if ~exist('display','var'), display = 1; end
            x = struct2mat(x,obj.xnames);
            Smodel = equation(obj, x+eps, Opt);
            data.MTdata = addNoise(Smodel, Opt.SNR, 'mt');
            data.R1map = x(strcmp(obj.xnames,'R1f')); % set R1map to R1f
            FitResults = fit(obj,data);
            if display
                plotModel(obj, FitResults, data);
            end
        end

        function plotProt(obj)
            Prot = GetProt(obj);
            subplot(2,1,1)
            plot(Prot.ti(2:end),diff(Prot.ti))

            hold on
            minti = min(Prot.ti); maxti = max(Prot.ti);
            tilin=linspace(minti,maxti,length(Prot.ti));
            plot(tilin(2:end),diff(tilin),'--')
            tilog=logspace(log10(minti),log10(maxti),length(Prot.ti));
            plot(tilog(2:end),diff(tilog),'--')
            ylabel('\Delta ti')
            xlabel('ti')
            ylim([min(diff(Prot.ti)),max(diff(Prot.ti))])
            legend({'Experiment', 'Linear spacing','Log10 spacing'})
            title('Inversion time spacing (logspace?, linspace?)')
            subplot(2,1,2)
            imshow qmt_sirfse.png
            title('Pulse sequence diagram')
        end


        function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opts)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, Opts.Nofrun, OptTable, Opts);
        end

        function SimRndResults = Sim_Multi_Voxel_Distribution(obj, RndParam, Opt)
            % SimRndGUI
            SimRndResults = SimRnd(obj, RndParam, Opt);
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


        function schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,Opt)
            % schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,nV,popSize,migrations)
            % schemeLEADER = Sim_Optimize_Protocol(obj,obj.st,30,100,100)
            % Optimize Inversion times
            nV         = Opt.Nofvolumes;
            popSize    = Opt.Populationsize;
            migrations = Opt.Nofmigrations;

            sigma  = .05;
            TImax = 15;
            GenerateRandFunction = @() rand(nV,1)*TImax+1e-3; % do not sort TI values... or you might fall in a local minima
            CheckProtInBoundFunc = @(Prot) min(max(1e-3,Prot),TImax);
            % Optimize Protocol
            td = 3.5;
            [retVal] = soma_all_to_one(@(Prot) mean(SimCRLB(obj,[Prot ones(size(Prot,1),1)*td],xvalues,sigma)), GenerateRandFunction, CheckProtInBoundFunc, migrations, popSize, nV, obj.Prot.MTdata.Mat(:,1));

            % Generate Rest
            schemeLEADER = retVal.schemeLEADER;
            schemeLEADER = [schemeLEADER ones(size(schemeLEADER,1),1)*td];

            fprintf('SOMA HAS FINISHED \n')

        end

        function Prot = GetProt(obj)
            Prot.ti = obj.Prot.MTdata.Mat(:,1);
            Prot.td = obj.Prot.MTdata.Mat(:,2);
            Prot.Trf = obj.Prot.FSEsequence.Mat(1);
            Prot.Tr = obj.Prot.FSEsequence.Mat(2);
            Prot.Npulse = obj.Prot.FSEsequence.Mat(3);
        end

        function FitOpt = GetFitOpt(obj,data)
            if exist('data','var')
                if isfield(data,'R1map'), FitOpt.R1 = data.R1map; end
            end
            FitOpt.R1map = obj.options.fittingconstraints_UseR1maptoconstrainR1f;
            FitOpt.names = obj.xnames;
            FitOpt.fx = obj.fx;
            FitOpt.st = obj.st;
            FitOpt.lb = obj.lb;
            FitOpt.ub = obj.ub;
            FitOpt.R1reqR1f = obj.options.fittingconstraints_FixR1rR1f;
        end

        function SrParam = GetSrParam(obj)
            SrParam.F = 0.1;
            SrParam.kf = 3;
            SrParam.kr = SrParam.kf/SrParam.F;
            SrParam.R1f = 1;
            SrParam.R1r = 1;
            SrParam.T2f = 0.04;
            SrParam.T2r = obj.options.Sr_Calculation_T2r;
            SrParam.M0f = 1;
            SrParam.M0r = SrParam.F*SrParam.M0f;
            SrParam.lineshape = obj.options.Sr_Calculation_Lineshape;
        end

        function SrProt = GetSrProt(obj)
            SrProt.InvPulse.Trf = obj.options.Inversion_Pulse_Durations;
            SrProt.InvPulse.shape = obj.options.Inversion_Pulse_Shape;
        end

        function optionalInputs = get_MRIinputs_optional(obj)
            optionalInputs = get_MRIinputs_optional@AbstractModel(obj);
            if obj.options.fittingconstraints_UseR1maptoconstrainR1f
                optionalInputs(strcmp(obj.MRIinputs,'R1map')) = false;
            end
        end

    end

    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            % 2.0.6
            if checkanteriorver(version,[2 0 7])
                obj.options.fittingconstraints_UseR1maptoconstrainR1f = obj.options.Fitting_UseR1maptoconstrainR1f;
                obj.options = rmfield(obj.options,'Fitting_UseR1maptoconstrainR1f');
                obj.options.fittingconstraints_FixR1rR1f = obj.options.Fitting_FixR1rR1f;
                obj.options = rmfield(obj.options,'Fitting_FixR1rR1f');
                obj.buttons{strcmp(obj.buttons,'Fitting')} = 'fitting constraints';
            end
        end
    end

end
