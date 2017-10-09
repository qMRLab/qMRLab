classdef SPGR
%-----------------------------------------------------------------------------------------------------
% SPGR :  qMT using Spoiled Gradient Echo (or FLASH)
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
%   1) MTdata : Magnetization Transfert data
%   2) R1map  : 1/T1map (OPTIONAL but RECOMMANDED Boudreau 2017 MRM)
%   3) B1map  : B1 field map (OPTIONAL)
%   4) B0map  : B0 field map (OPTIONAL)
%   5) Mask   : Binary mask to accelerate the fitting (OPTIONAL)
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%   Fitting Parameters
%       * F   : Ratio of number of restricted pool to free pool, defined 
%               as F = M0r/M0f = kf/kr.
%       * kr  : Exchange rate from the free to the restricted pool 
%               (note that kf and kr are related to one another via the 
%               definition of F. Changing the value of kf will change kr 
%               accordingly, and vice versa).
%       * R1f : Longitudinal relaxation rate of the free pool 
%               (R1f = 1/T1f).
%       * R1r : Longitudinal relaxation rate of the restricted pool 
%               (R1r = 1/T1r).
%       * T2f : Tranverse relaxation time of the free pool (T2f = 1/R2f).
%       * T2r : Tranverse relaxation time of the restricted pool (T2r = 1/R2r).
%
%   Additional Outputs
%       * kf     : Exchange rate from the restricted to the free pool.
%       * resnorm: Fitting residual.
%
%-----------------------------------------------------------------------------------------------------
%----------%
% PROTOCOL %
%----------%
%   1) MTdata
%       * Angle  : MT pulses angles (degree)
%       * Offset : Offset frequencies (Hz)
%
%   2) TimingTable
%       * Tmt : Duration of the MT pulses (s)
%       * Ts  : Free precession delay between the MT and excitation pulses (s)
%       * Tp  : Duration of the excitation pulse (s)
%       * Tr  : Free precession delay after tje excitation pulse, before 
%               the next MT pulse (s)
%       * TR  : Repetition time of the whole sequence (TR = Tmt + Ts + Tp + Tr)
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OPTIONS %
%---------%
%   MT Pulse
%       * Shape          : Shape of the MT pulse.
%                          Available shapes are:
%                          - hard
%                          - gaussian
%                          - gausshann (gaussian pulse with Hanning window)
%                          - sinc
%                          - sinchann (sinc pulse with Hanning window)
%                          - singauss (sinc pulse with gaussian window)
%                          - fermi
%       * Sinc TBW       : Time-bandwidth product for the sinc MT pulses 
%                          (applicable to sinc, sincgauss, sinchann MT 
%                          pulses).
%       * Bandwidth      : Bandwidth of the gaussian MT pulse (applicable 
%                          to gaussian, gausshann and sincgauss MT pulses).
%       * Fermi 
%         transition (a) : 'a' parameter (related to the transition width) 
%                           of the Fermi pulse (applicable to fermi MT 
%                           pulse).
%       * # of MT pulses : Number of pulses used to achieve steady-state
%                          before a readout is made.
%   Fitting constraints
%       * Use R1map to  : By checking this box, you tell the fitting 
%         constrain R1f   algorithm to check for an observed R1map and use
%                         its value to constrain R1f. Checking this box 
%                         will automatically set the R1f fix box to true             
%                         in the Fit parameters table.  
%       * Fix R1r = R1f : By checking this box, you tell the fitting
%                         algorithm to fix R1r equal to R1f. Checking this 
%                         box will automatically set the R1r fix box to 
%                         true in the Fit parameters table.
%       * Fix R1f*T2f   : By checking this box, you tell the fitting
%                         algorithm to compute T2f from R1f value. R1f*T2f
%                         value is set in the next box.
%       * R1f*T2f =     : Value of R1f*T2f (no units)
%
%   Global
%       * Model         : Model you want to use for fitting. 
%                         Available models are: 
%                         - SledPikeRP (Sled & Pike rectangular pulse), 
%                         - SledPikeCW (Sled & Pike continuous wave), 
%                         - Yarkykh (Yarnykh & Yuan)
%                         - Ramani
%                         Note: Sled & Pike models will show different  
%                               options than Yarnykh or Ramani.
%       * Lineshape     : The absorption lineshape of the restricted pool. 
%                         Available lineshapes are:
%                         - Gaussian
%                         - Lorentzian
%                         - SuperLorentzian
%       * Read pulse    : Flip angle of the excitation pulse.
%         alpha          
%       * Compute       : By checking this box, you compute a new SfTable
%         SfTable           
%
%-----------------------------------------------------------------------------------------------------
% Written by: Ian Gagnon, 2017
% Reference: FILL
%-----------------------------------------------------------------------------------------------------
    
    properties
        MRIinputs = {'MTdata','R1map','B1map','B0map','Mask'}; % input data required
        xnames = {'F','kr','R1f','R1r','T2f','T2r'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [ 0.16    25     1        1       0.03     1.3e-05 ]; % starting point
        lb           = [ 0        0     0.05     0.05    0.003    3e-6    ]; % lower bound
        ub           = [ 0.5     30     5        5       0.5      5.0e-05 ]; % upper bound
        fx           = [ 0        0     1        1       0        0       ]; % fix parameters
        
        % Protocol
        % You can define a default protocol here.
        Prot = struct('MTdata',...
            struct('Format',{{'Angle' 'Offset'}},...
            'Mat', [142 443; 426 443; 142 1088; 426 1088; 142 2732
            426 2732; 142 6862; 426 6862; 142 17235; 426 17235]),...
            'TimingTable',...
            struct('Format',{{'Tmt (s)'; 'Ts (s)'; 'Tp (s)'; 'Tr (s)'; 'TR (s)'}},...
            'Mat',[0.0102; 0.0030; 0.0018; 0.0100; 0.0250]));
        
        ProtSfTable = load('DefaultSFTable.mat'); % SfTable declaration
        
        % Model options
        buttons = {'PANEL','MT_Pulse', 5,...
            'Shape',{'gausshann','gaussian','hard','sinc','sinchann','sincgauss','fermi'},...
            'Sinc TBW',nan,...
            'Bandwidth',200,...
            'Fermi transition (a)',nan,...
            '# of MT pulses',100,...
            'Model',{'SledPikeRP','SledPikeCW','Yarnykh','Ramani'},...
            'Lineshape',{'SuperLorentzian','Lorentzian','Gaussian'},...
            'PANEL','fitting constraints',4,...
            'Use R1map to constrain R1f',true,...
            'Fix R1r = R1f',false,...
            'Fix R1f*T2f',false,...
            'R1f*T2f =',0.055,...
            'Read pulse alpha',7,...
            'Compute SfTable','pushbutton'};
        options = struct(); % structure filled by the buttons. Leave empty in the code
        
        % Simulations Default options
        Sim_Single_Voxel_Curve_buttons = {'SNR',50,'Method',{'Analytical equation','Block equation'},'Reset Mz',false};
        Sim_Sensitivity_Analysis_buttons = {'# of run',5};
    end
    
    methods
        function obj = SPGR
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            if obj.options.ComputeSfTable
                obj.ProtSfTable = CacheSf(GetProt(obj));
            end
            % TR must be the sum of Tmt, Ts, Tp and Tr
            obj.Prot.TimingTable.Mat(5) = obj.Prot.TimingTable.Mat(1)+...
                                          obj.Prot.TimingTable.Mat(2)+...
                                          obj.Prot.TimingTable.Mat(3)+...
                                          obj.Prot.TimingTable.Mat(4); 
            % Fix R1f if the option is chosen
            if obj.options.fittingconstraints_UseR1maptoconstrainR1f
                obj.fx(3)=true;
            end
        end
        
        function obj = Precompute(obj)
            if isempty(fieldnames(obj.ProtSfTable))
                obj.ProtSfTable = CacheSf(GetProt(obj));
            else
                obj.ProtSfTable = CacheSf(GetProt(obj),obj.ProtSfTable);
            end         
        end
        
        function FitResults = fit(obj,data)
            Protocol = GetProt(obj);
            FitOpt   = GetFitOpt(obj,data);
            % normalize data
            NoMT = Protocol.Angles<1;
            if ~any(NoMT)
                warning('No MToff. MTData cannot be normalized.');  
            else
                data.MTdata = data.MTdata/median(data.MTdata(NoMT));
                data.MTdata = data.MTdata(~NoMT);
                Protocol.Angles  = Protocol.Angles(~NoMT);
                Protocol.Offsets = Protocol.Offsets(~NoMT);
            end
            % fit data
            FitResults = SPGR_fit(data.MTdata,Protocol,FitOpt);
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            % Example: obj.Sim_Single_Voxel_Curve(obj.st,button2opts(obj.Sim_Single_Voxel_Curve_buttons))
            if ~exist('display','var'), display = 1; end      
            Smodel = equation(obj, x, Opt);
            data.MTdata = addNoise(Smodel, Opt.SNR, 'mt');
            FitResults = fit(obj,data);
            delete(findall(0,'Tag','Msgbox_Lookup Table empty'))
            if display
                plotmodel(obj, FitResults, data);
                drawnow;
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
        
        function mz = equation(obj, x, Opt)
            if nargin<3, Opt=button2opts(obj.Sim_Single_Voxel_Curve_buttons); end
            x = x+eps;
            for ix = 1:length(x)
                Sim.Param.(obj.xnames{ix}) = x(ix);
            end
            Protocol = GetProt(obj);
            switch Opt.Method
                case 'Block equation'
                    Sim.Param.lineshape = obj.options.Lineshape;
                    Sim.Param.M0f       = 1;
                    Sim.Opt.Reset       = Opt.ResetMz;
                    Sim.Opt.SScheck     = 1;
                    Sim.Opt.SStol       = 1e-4;
                    Protocol.Npulse = Protocol.MTpulse.Npulse;
                    if isempty(getenv('ISDISPLAY')) || str2double(getenv('ISDISPLAY')), ISDISPLAY=1; else ISDISPLAY=0; end
                    mz = SPGR_sim(Sim, Protocol, ISDISPLAY);
                case 'Analytical equation'
                    SimCurveResults = SPGR_SimCurve(Sim.Param, Protocol, obj.GetFitOpt, 1);
                    mz = SimCurveResults.curve;
            end
        end
        
        
        function plotmodel(obj, x, data)
            if nargin<2, x = obj.st; data.MTdata = []; end
            if isnumeric(x)
                x=mat2struct(x,obj.xnames); 
            end
            Protocol = GetProt(obj);
            FitOpt   = GetFitOpt(obj,data);
            % normalize data
            NoMT = Protocol.Angles<1;
            if ~any(NoMT)
                warning('No MToff. MTData cannot be normalized.');               
            else
                data.MTdata = data.MTdata/median(data.MTdata(NoMT));
                data.MTdata = data.MTdata(~NoMT);
                Protocol.Angles  = Protocol.Angles(~NoMT);
                Protocol.Offsets = Protocol.Offsets(~NoMT);
            end
            SimCurveResults  = SPGR_SimCurve(x, Protocol, FitOpt );
            Sim.Opt.AddNoise = 0;
            SPGR_PlotSimCurve(data.MTdata, data.MTdata, Protocol, Sim, SimCurveResults);
            title(sprintf('F=%0.2f; kf=%0.2f; R1f=%0.2f; R1r=%0.2f; T2f=%0.2f; T2r=%f; Residuals=%f', ...
                x.F,x.R1f,x.R1r,x.T2f,x.T2r),...
                'FontSize',10);
        end
        
        function plotProt(obj)
            Prot = GetProt(obj);
            subplot(2,1,1)
            plot(obj.Prot.MTdata.Mat(:,2),obj.Prot.MTdata.Mat(:,1),'+')
            ylabel('Angle (°)')
            xlabel('offset (Hz)')
            subplot(2,1,2)
            title('MTpulse')
            angles = Prot.Angles(1);
            offsets = Prot.Offsets(1);
            shape = Prot.MTpulse.shape;
            Trf = Prot.Tm;
            PulseOpt = Prot.MTpulse.opt;
            Pulse = GetPulse(angles, offsets, Trf, shape, PulseOpt);
            ViewPulse(Pulse,'b1');
        end
        
        function Prot = GetProt(obj)
            Prot.Angles        = obj.Prot.MTdata.Mat(:,1);
            Prot.Offsets       = obj.Prot.MTdata.Mat(:,2);
            Prot.Alpha         = obj.options.Readpulsealpha;
            Prot.MTpulse.shape = obj.options.MT_Pulse_Shape;
            switch  obj.options.MT_Pulse_Shape    
                case {'sinc','sinchann'}
                    Prot.MTpulse.opt.TBW = obj.options.MT_Pulse_SincTBW;    
                case {'gausshann','gaussian'}
                    Prot.MTpulse.opt.bw = obj.options.MT_Pulse_Bandwidth;
                case 'sincgauss'
                    Prot.MTpulse.opt.TBW = obj.options.MT_Pulse_SincTBW;
                    Prot.MTpulse.opt.bw  = obj.options.MT_Pulse_Bandwidth;
                case 'fermi'                    
                    Prot.MTpulse.opt.slope = obj.options.MT_Pulse_Fermitransitiona;
                otherwise
                    Prot.MTpulse.opt = [];
            end
           	Prot.MTpulse.Npulse = obj.options.MT_Pulse_NofMTpulses;             
            Prot.Tm = obj.Prot.TimingTable.Mat(1);
            Prot.Ts = obj.Prot.TimingTable.Mat(2);
            Prot.Tp = obj.Prot.TimingTable.Mat(3);
            Prot.Tr = obj.Prot.TimingTable.Mat(4);
            Prot.TR = obj.Prot.TimingTable.Mat(5);
            % Check is the Sf table had already been compute and
            % corresponds to the current Protocol
            if ~isempty(obj.ProtSfTable)
                Sf = CacheSf(Prot,obj.ProtSfTable,0);
                if ~isempty(Sf), Prot.Sf=Sf; end
            end
        end
        
        function FitOpt = GetFitOpt(obj,data)
            if exist('data','var')
                if isfield(data,'R1map'), FitOpt.R1 = data.R1map; end
                if isfield(data,'B1map'), FitOpt.B1 = data.B1map; end
                if isfield(data,'B0map'), FitOpt.B0 = data.B0map; end
            end
            FitOpt.R1map = obj.options.fittingconstraints_UseR1maptoconstrainR1f;
            FitOpt.fx = obj.fx;
            FitOpt.st = obj.st;
            FitOpt.lb = obj.lb;
            FitOpt.ub = obj.ub;
            FitOpt.names     = obj.xnames;
            FitOpt.lineshape = obj.options.Lineshape;
            FitOpt.R1reqR1f  = obj.options.fittingconstraints_FixR1rR1f;
            FitOpt.model     = obj.options.Model;
            FitOpt.FixR1fT2f = obj.options.fittingconstraints_FixR1fT2f;
            FitOpt.FixR1fT2fValue = obj.options.fittingconstraints_R1fT2f;
        end
        
    end
end
