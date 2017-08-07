classdef MWF
% ----------------------------------------------------------------------------------------------------
% MWF :  Myelin Water Fraction
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% FILL
% ----------------------------------------------------------------------------------------------------
%
%  Fitted Parameters:
%    * MWF : Myelin Water Fraction
%    * T2  : Spin relaxation time
%
%
%  Non-Fitted Parameters:
%    * None    
%
%
%  Options:
%    * 
%    * 
%    * 
% ----------------------------------------------------------------------------------------------------
% Written by: Ian Gagnon, 2017
% Reference: FILL
% ----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'MET2data','Mask'};
        xnames = {};
        voxelwise = 1;
        
        % Protocol
        Prot  = struct('Echo',struct('Format',{{'First (ms)'; 'Spacing (ms)'}},...
                                     'Mat', [10; 10])); % You can define a default protocol here.
        
        % Model options
        buttons = {'Cutoff (ms)',50, 'Sigma', 28};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = MWF
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
        end

        
        function FitResults = fit(obj,data)
            Echo.First   = obj.Prot.Echo.Mat(1);
            Echo.Spacing = obj.Prot.Echo.Mat(2);
            Cutoff  = obj.options.Cutoffms;
            Sigma = obj.options.Sigma;
            MET2 = data.MET2data;
            Mask = data.Mask;            
            FitResults = multi_comp_fit_v2(reshape(MET2,[1 1 1 length(MET2)]), 'T2', Echo, Cutoff, Sigma, 'tissue', Mask);
        end
        
    end
end