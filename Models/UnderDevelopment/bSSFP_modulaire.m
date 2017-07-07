classdef bSSFP_modulaire
% ----------------------------------------------------------------------------------------------------
% bSSFP : qMT using Balanced Steady State Free Precession acquisition
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% (1) FILL
% (2) 
% (3) 
% (4) 
% ----------------------------------------------------------------------------------------------------
%
%  Fitted Parameters:
%    * fr :     fraction of water in the restricted compartment
%    * Dh :    Apparent diffusion coefficient of the hindered compartment
%    
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
%   FILL
%
%
% ----------------------------------------------------------------------------------------------------
% Written by: Ian Gagnon, 2017
% Reference: FILL
% ----------------------------------------------------------------------------------------------------
    
    properties
        MRIinputs = {'MTdata','R1map','Mask'}; % input data required
        xnames = {'F','kr','R1f','R1r','T2f','M0f'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [ 0.1    30      1        1        0.04    1 ]; % starting point
        lb           = [ 0       0      0.2      0.2      0.01    0 ]; % lower bound
        ub           = [ 0.3   100      3        3        0.2     2 ]; % upper bound
        fx           = [ 0       0      1        1        0       0 ]; % fix parameters
        
        % Protocol
        % You can define a default protocol here.
        Prot = struct('MTdata',...
                               struct('Format',{{'Alpha' 'Trf'}},...
                                      'Mat', [5 2.7e-4; 10 2.7e-4; 15 2.7e-4; 20 2.7e-4; 25 2.7e-4 
                                              30 2.7e-4; 35 2.7e-4; 40 2.7e-4; 35 2.3e-4; 35 3.0e-4
                                              35 4.0e-4; 35 5.8e-4; 35 8.4e-4; 35 0.0012; 35 0.0012 
                                              35 0.0021]));
                                      
        % Model options
        buttons = {'G(0)',1.2524e-05,...
                   'Use R1map to constrain R1f',false,...
                   'Fix R1r = R1f',true,...
                   'Fix TR',false,...
                   'TR Value', 0.00519,...
                   'PANEL','Inversion_Pulse',2,...
                   'Shape',{'hard','gaussian','gausshann','sinc','sinchann','sincgauss','fermi'},'# of RF pulses', 500,...
                   'Fix TR - Trf',true,...
                   'TR - Trf Value', 0.00269,...
                   'Prepulse',true}; % (Alpha/2 - TR/2 )
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = bSSFP_modulaire
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            if obj.options.FixTRTrf
                obj.options.FixTR = false;
            end
            if obj.options.UseR1maptoconstrainR1f
                obj.fx(3)=true;
            end
        end
        
        function FitResults = fit(obj,data)
            Protocol = GetProt(obj); 
            FitOpt = GetFitOpt(obj,data);
            FitResults = bSSFP_fit(data.MTdata,Protocol,FitOpt);                  
        end
        
        function plotmodel(obj, x, data)
            Protocol = GetProt(obj);
            FitOpt = GetFitOpt(obj,data);
            SimCurveResults = bSSFP_SimCurve(x, Protocol, FitOpt );
            Sim.Opt.AddNoise = 0;
            axe(1) = subplot(2,1,1);
            axe(2) = subplot(2,1,2);
            bSSFP_PlotSimCurve(data.MTdata, data.MTdata, Protocol, Sim, SimCurveResults, axe);
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
        function Prot = GetProt(obj)  
            Prot.alpha = obj.Prot.MTdata.Mat(:,1);
            Prot.Trf = obj.Prot.MTdata.Mat(:,2);
            Prot.FixTR = obj.options.FixTR;
            Prot.TR = obj.options.TRValue;
            Prot.Td = obj.options.TRTrfValue;
            Prot.PulseShape = obj.options.Inversion_Pulse_Shape;
        end
                
        function FitOpt = GetFitOpt(obj,data)
            if isfield(data,'R1map'), FitOpt.R1 = data.R1map; end
            FitOpt.R1map = obj.options.UseR1maptoconstrainR1f;
            FitOpt.names = obj.xnames;
            FitOpt.fx = obj.fx;
            FitOpt.st = obj.st;
            FitOpt.lb = obj.lb;
            FitOpt.ub = obj.ub;
            FitOpt.R1reqR1f = obj.options.FixR1rR1f;
            FitOpt.G = obj.options.G0;
        end

    end
end