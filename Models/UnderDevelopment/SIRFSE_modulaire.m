classdef SIRFSE_modulaire
% ----------------------------------------------------------------------------------------------------
% SIRFSE :  FILL
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
        xnames = {'F','kr','R1f','R1r','Sf','Sr','M0f'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [ 0.1    30      1        1      -0.9     0.6564    1 ]; % starting point
        lb           = [ 0       0      0.05     0.05   -1       0         0 ]; % lower bound
        ub           = [ 1     100     10       10       0       1         2 ]; % upper bound
        fx           = [ 0       0      0        1       0       1         0 ]; % fix parameters
        
        % Protocol
        Prot = struct('MTdata',...
                               struct('Format',{{'Ti' 'Td'}},...
                                      'Mat', [0.0030 3.5; 0.0037 3.5; 0.0047 3.5; 0.0058 3.5; 0.0072 3.5 
                                              0.0090 3.5; 0.0112 3.5; 0.0139 3.5; 0.0173 3.5; 0.0216 3.5
                                              0.0269 3.5; 0.0335 3.5; 0.0417 3.5; 0.0519 3.5; 0.0646 3.5 
                                              0.0805 3.5; 0.1002 3.5; 0.1248 3.5; 0.1554 3.5; 0.1935 3.5
                                              0.2409 3.5; 0.3000 3.5; 1.0000 3.5; 2.0000 3.5; 10.0000 3.5]),...
                      'FSEsequence',...
                               struct('Format',{{'Trf (s)'; 'Tr (s)'; 'Npulse'}},...
                                      'Mat',[0.001; 0.01; 16])); % You can define a default protocol here.
                                           
        % Model options
        buttons = {'Use R1map to constrain R1f',false,...
                   'Fix R1r = R1f',true,...
                   'PANEL',2,'Inversion pulse',1,...
                   'Shape',{'hard','gaussian','gausshann','sinc','sinchann','sincgauss','fermi'},'Duration (s)', 0.001};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = SIRFSE_modulaire
            obj = button2opts(obj);
        end
        
        function obj = UpdateFields(obj)
        end
        
        function Smodel = equation(obj, x)
        end
        
        function FitResults = fit(obj,data)
            if isfield(data,'R1map'), FitOpt.R1 = data.R1map; end
            FitOpt.names = obj.xnames;
            FitOpt.fx = obj.fx;
            FitOpt.st = obj.st;
            FitOpt.lb = obj.lb;
            FitOpt.ub = obj.ub;
            FitOpt.R1reqR1f = obj.options.FixR1r0x3DR1f;
            Protocol = Prot2Protocol(obj);                            
            FitResults = SIRFSE_fit(data.MTdata,Protocol,FitOpt);                  
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
            Protocol.ti = obj.Prot.MTdata.Mat(:,1);
            Protocol.td = obj.Prot.MTdata.Mat(:,2);
            Protocol.Trf = obj.Prot.FSEsequence.Mat(1);
            Protocol.Tr = obj.Prot.FSEsequence.Mat(2);
            Protocol.Npulse = obj.Prot.FSEsequence.Mat(3);  
        end

    end
end