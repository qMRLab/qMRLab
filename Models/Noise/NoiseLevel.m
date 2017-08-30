classdef NoiseLevel
% ----------------------------------------------------------------------------------------------------
% NoiseLevel :  Noise histogram fitting to find sigma
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% FILL
% ----------------------------------------------------------------------------------------------------
%
%  Fitted Parameters:
%    * Sigma
%
%
%  Non-Fitted Parameters:
%    * None    
%
%
% Options:
%    * None
%  
%
% ----------------------------------------------------------------------------------------------------
% Written by: Ian Gagnon, 2017
% Reference: FILL
% ----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'Data4D','NoiseMask'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct(); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = NoiseLevel
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
        end
        
        function FitResults = fit(obj,data)
            if any(strcmp('NoiseMask',fieldnames(data)))
               data.Data4D(data.NoiseMask==0) = 0;
            end 
            [N, eta, sigma_g] = histfit_noncentralchi(data.Data4D);
            init=ones(size(data.Data4D,1),size(data.Data4D,2),size(data.Data4D,3));
            FitResults.N = N*init;
            FitResults.eta = eta*init;
            FitResults.sigma_g = sigma_g*init;
        end
        
    end
end