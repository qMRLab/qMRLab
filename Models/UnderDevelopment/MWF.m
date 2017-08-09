classdef MWF
%-----------------------------------------------------------------------------------------------------
% MWF :  Myelin Water Fraction
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
%   1) MET2data : Multi-Exponential T2 data
%   2) Mask     : Binary mask to accelerate the fitting (OPTIONAL)
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%	* MWF : Myelin Water Fraction
%	* T2  : Spin relaxation time
%
%-----------------------------------------------------------------------------------------------------
%----------%
% PROTOCOL %
%----------%
%	* First   : Time of the first echo (s) 
%	* Spacing : Time interval between each echo (s)
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OPTIONS %
%---------%
%   * Cutoff : Time cutoff (s) 
%   * Sigma  : Noise's sigma ?????
%
%-----------------------------------------------------------------------------------------------------
% Written by: Ian Gagnon, 2017
% Reference: FILL
%-----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'MET2data','Mask'};
        xnames = {};
        voxelwise = 1;
        
        % Protocol
        Prot  = struct('Echo',struct('Format',{{'First (s)'; 'Spacing (s)'}},...
                                     'Mat', [0.01; 0.01])); % You can define a default protocol here.
        
        % Model options
        buttons = {'Cutoff (s)',0.05, 'Sigma', 28};
        options = struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = MWF
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
        end

        
        function FitResults = fit(obj,data)
            Echo.First   = 1000*obj.Prot.Echo.Mat(1);
            Echo.Spacing = 1000*obj.Prot.Echo.Mat(2);
            Cutoff  = 1000*obj.options.Cutoffs;
            Sigma = obj.options.Sigma;
            MET2 = data.MET2data;
            Mask = data.Mask;            
            FitResults = multi_comp_fit_v2(reshape(MET2,[1 1 1 length(MET2)]), 'T2', Echo, Cutoff, Sigma, 'tissue', Mask);
        end
        
    end
end