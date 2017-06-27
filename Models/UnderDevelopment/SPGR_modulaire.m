classdef SPGR_modulaire
% ----------------------------------------------------------------------------------------------------
% SPGR :  qMT using Spoiled Gradient Echo (or FLASH)
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
        MRIinputs = {'MTdata','R1map','B1map','B0map','Mask'}; % input data required
        xnames = {'F','kr','R1f','R1r','T2f','T2r'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [ 0.16    10      1        1       0.03     1.3e-05 ]; % starting point
        lb           = [ 0       0       0.05     0.05    0        0       ]; % lower bound
        ub           = [ 0.5     30      5        5       0.5      5.0e-05 ]; % upper bound
        fx           = [ 0       0       0        1       0        0       ]; % fix parameters
        
        % Protocol
        Prot = struct('MTdata',...
                               struct('Format',{{'Angle' 'Offset'}},...
                                      'Mat', [142 443; 142 1088; 142 2732; 142 6862; 142 17235 
                                              426 443; 426 1088; 426 2732; 426 6862; 426 17235]),...
                      'TimingTable',...
                               struct('Format',{{'Tmt (s)'; 'Ts (s)'; 'Tp (s)'; 'Tr (s)'; 'TR (s)'}},...
                                      'Mat',[0.0102; 0.0030; 0.0018; 0.0100; 0.0250])); % You can define a default protocol here.
                                           
        % Model options
        buttons = {'Model',{'SledPikeRP','SledPikeCW','Yarnykh','Ramani'},...
                   'Lineshape',{'SuperLorentzian','Lorentzian','Gaussian'},...
                   'Use R1map to constrain R1f',true,...
                   'Fix R1r = R1f',false,...
                   'Read pulse alpha',7,...
                   'PANEL',5,'MT pulse',1,...
                   'Shape',{'gausshann','gaussian','hard','sinc','sinchann','sincgauss','fermi'},...
                   'Sinc TBW', nan,...
                   'Gaussian bandwidth',200,...
                   'Fermi transition (a)', nan,...
                   '# of MT pulses',100,...
                   'Precompute SfTable',{'NO','YES'}};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = SPGR_modulaire
            obj = button2opts(obj);
        end
        
        function obj = UpdateFields(obj)
            if strcmp(obj.options.PrecomputeSfTable,'YES')
                Protocol = Prot2Protocol(obj);
                obj.options.Sf = CacheSf(Protocol);
                obj.options.PrecomputeSfTable = 'NO';
            end
            if obj.options.UseR1mapToConstrainR1f
                obj.fx(3)=true;
            end
        end
        
        function Smodel = equation(obj, x)
            Prot = Prot2Protocol(obj);
            mz = SPGR_sim(Sim, Prot, 1);
        end
        
        function FitResults = fit(obj,data)
            if isfield(data,'R1map'), FitOpt.R1 = data.R1map; end
            if isfield(data,'B1map'), FitOpt.B1 = data.B1map; end
            if isfield(data,'B0map'), FitOpt.B0 = data.B0map; end
            FitOpt.R1map = obj.options.UseR1mapToConstrainR1f;
            FitOpt.fx = obj.fx;
            FitOpt.st = obj.st;
            FitOpt.lb = obj.lb;
            FitOpt.ub = obj.ub;
            FitOpt.names = obj.xnames;
            FitOpt.lineshape = obj.options.Lineshape;
                
            Protocol = Prot2Protocol(obj);
            
            % Check is the Sf table had already been compute
            if any(strcmp('Sf',fieldnames(obj.options)))
                FitOpt.Sf = obj.options.Sf;
            else
                errordlg('Please compute Sf Table in the options panel to enable fitting...');
            end            
            FitOpt.R1reqR1f = obj.options.FixR1r0x3DR1f;
            FitOpt.model = obj.options.Model;                           
            FitResults = SPGR_fit(data.MTdata,Protocol,FitOpt);                  
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, SNR,display)
            if ~exist('display','var'), display=1; end
            
            Smodel = equation(obj, x);
            sigma = max(Smodel)/SNR;
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

        
%         function plotmodel(obj, x, data)
%           
%         end
        
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
    function Protocol = Prot2Protocol(obj)
            Protocol.Angles = obj.Prot.MTdata.Mat(:,1);
            Protocol.Offsets = obj.Prot.MTdata.Mat(:,2);
            Protocol.Alpha = obj.options.ReadPulseAlpha;
            Protocol.MTpulse.shape = obj.options.MTPulse;
            Protocol.MTpulse.opt = obj.options.x0x23OfMTPulses;
               
            Protocol.Tm = obj.Prot.TimingTable.Mat(1);
            Protocol.Ts = obj.Prot.TimingTable.Mat(2);
            Protocol.Tp = obj.Prot.TimingTable.Mat(3);
            Protocol.Tr = obj.Prot.TimingTable.Mat(4);
            Protocol.TR = obj.Prot.TimingTable.Mat(5);     
        end

    end
end