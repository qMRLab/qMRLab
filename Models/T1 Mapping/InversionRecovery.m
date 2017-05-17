classdef InversionRecovery
% ----------------------------------------------------------------------------------------------------
% InversionRecovery :  T1 map using Inversion Recovery 
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% ----------------------------------------------------------------------------------------------------
%
%  Fitted Parameters:
%               (1) T1 
%               (2) 'b' or 'rb' parameter 
%               (3) 'a' or 'ra' parameter
%               (4) residual from the fit%    
%
%  Non-Fitted Parameters:
%    * fr = 1 - fh - fcsf : fraction of water in the restricted compartment (intra-axonal)
%    * residue : Fitting residue.
%
%
% Options:
%   Sigma of the noise : Standard deviation of the noise, assuming Rician.
%                                       Use scd_noise_std_estimation to
%                                       measure noise level
%                                       If "Compute sigma noise per pixel" is checked, STD across >5 repetitions is used.
% ----------------------------------------------------------------------------------------------------
% Written by: Tanguy Duval, 2016
% Reference: Assaf, Y., Basser, P.J., 2005. Composite hindered and restricted 
% model of diffusion (CHARMED) MR imaging of the human brain. Neuroimage 27, 48?58.
% ----------------------------------------------------------------------------------------------------

properties
        MRIinputs = {'IRdata','Mask'}; % input data required
        xnames = {'T1','rb','ra'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [1      0.7        6     ]; % starting point
        lb            = [0     0.3        3       ]; % lower bound
        ub           = [3       3         10       ]; % upper bound
        fx            = [0      0           0    ]; % fix parameters
        
        % Protocol
        ProtFormat = {'TI'}; % columns of the Protocol matrix. 
        Prot  = [];
        
        % Model options
        buttons = {'method',{'Complex','Magnitude'}};
        options= struct(); % structure filled by the buttons. Leave empty in the code

    end
    
    methods
        function obj = CHARMED
            obj = button2opts(obj);
        end
        
        function Smodel = equation(obj, x)
        end
        
        
        function FitResults = fit(obj,data)
            mtv_fitT1_IR(data,obj.Prot,obj.options.method);
            FitResults.T1 = T1;
            FitResults.rb = rb;
        end
        
        function plotmodel(obj, x, data)
        end
           
    end
end

