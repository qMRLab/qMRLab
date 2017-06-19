% qMT using Spoiled Gradient Echo (or FLASH)

classdef SPGR_modulaire
    % ----------------------------------------------------------------------------------------------------
    % CHARMED :  Composite Hindered and Restricted Model for Diffusion
    % ----------------------------------------------------------------------------------------------------
    % Assumptions :
    % (1) Diffusion gradients are applied perpendicularly to the neuronal fibers
    % (2) Neuronal fibers are parallel (orientational dispersion is negligible)
    % (3) The intra-axonal diffusion coefficient (Dr) is fixed. this assumption
    % should have little impact if the average propagator is larger than axonal diameter (sqrt(2*Dr*Delta)>8µm).
    % (4) permeability of the neuronal fibers is negligible
    % ----------------------------------------------------------------------------------------------------
    %
    %  Fitted Parameters:
    %    * fr :     fraction of water in the restricted compartment
    %    * Dh :    Apparent diffusion coefficient of the hindered compartment
    %    * axon diameter index : Mean axonal diameter
    %                                           (weighted by the axonal area --> biased toward the larger axons).
    %                                            fixed to 0 --> stick model (recommended if Gmax < 300mT/m)
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
    %   Sigma of the noise : Standard deviation of the noise, assuming Rician.
    %                        Use scd_noise_std_estimation to measure noise level
    %                        Not used if "Compute sigma noise per pixel" is checked. Instead, STD across >5 repetitions is used.
    %   S0 normalization :
    %     * 'Use b=0': Use b=0 images. In case of variable TE, your dataset requires a b=0 for each TE.
    %     * 'Single T2 compartment': in case of variable TE acquisition. fit T2 assuming Gaussian diffusion for data acquired at b<1000s/mm2
    % ----------------------------------------------------------------------------------------------------
    % Written by: Tanguy Duval, 2016
    % Reference: Assaf, Y., Basser, P.J., 2005. Composite hindered and restricted
    % model of diffusion (CHARMED) MR imaging of the human brain. Neuroimage 27, 48?58.
    % ----------------------------------------------------------------------------------------------------
    
    properties
        MRIinputs = {'MTdata','B1','T1'}; % input data required
        xnames = {'F','kr','R1f','R1r','T2f','T2r'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [0.5     0.7        6           0         0    3  ]; % starting point
        lb            = [0       0.3        3          0         0    1   ]; % lower bound
        ub           = [1       3         10           1        8    4    ]; % upper bound
        fx            = [0      0           0          1         1    1   ]; % fix parameters
        
        % Protocol
        Prot = struct('MTdata',...
                               struct('Format',{{'Angle' 'Offset'}},...
                                      'Mat',  cat(1,[ones(100,1) zeros(100,1)])),...
                      'TimingTable',...
                               struct('Format',{{'Tmt (s)'; 'Ts (s)'; 'Tp (s)'; 'Tr (s)'; 'TR (s)'}},...
                                      'Mat',[1; 1; 1; 1; 1])); % You can define a default protocol here.

        % Model options
        buttons = {'Read pulse alpha',10,'MT pulse',{'Gausshann', 'sinc'},'Model',{'SledPikeRP','Yarnick'},'R1r = R1f',1};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = SPGR_modulaire
            obj = button2opts(obj);
        end
        
        function obj = UpdateFields(obj)
            Protocol = Prot2Protocol(obj);
            obj.options.Sf = CacheSf(Protocol);
        end
        
        function Smodel = equation(obj, x)
        end
        
        
        function FitResults = fit(obj,data)
            FitOpt.fx = obj.fx;
            FitOpt.st = obj.st;
            FitOpt.names = obj.xnames;
            if isfield(data,'R1map'), 
                FitOpt.R1map = 1;
            end
            FitOpt.model = obj.options.Model;
            
            Protocol.Sf = obj.Sf;
            Protocol = Prot2Protocol(obj);
            
            FitResults = SPGR_fit(data.MTdata,obj.Prot.MTdata,FitOpt);       
            
        end
        
        function plotmodel(obj, x, data)
          
        end
        
        function plotProt(obj)
            subplot(1,1,2)
            plot(obj.Prot.MTdata(:,1),obj.Prot.MTdata(:,2))
            subplot(2,1,2)
            title('MTpulse')
            angles = Prot.Angles(1);
            offsets = Prot.Offsets(1);
            shape = Prot.MTpulse.shape;
            Trf = Prot.Tm;
            PulseOpt = Prot.MTpulse.opt;
            Pulse = GetPulse(angles, offsets, Trf, shape, PulseOpt);
            figure();
            ViewPulse(Pulse,'b1');
        end
        


    end
end

% function Protocol = Prot2Protocol(obj);