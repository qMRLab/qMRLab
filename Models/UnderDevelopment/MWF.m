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
%    * T2  : spin relaxation time
%
%
%  Non-Fitted Parameters:
%    * None    
%
%
% Options:
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
        voxelwise = 0;
        
        % Protocol
        Prot  = struct('Echo',struct('Format',{{'First (ms)'; 'Spacing (ms)'; 'Cutoff (ms)'}},...
                                     'Mat', [10; 10; 50])); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = MWF
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
        end
        
        function FitResult = fit(obj,data)
            Echo.First   = obj.Prot.Echo.Mat(1);
            Echo.Spacing = obj.Prot.Echo.Mat(2);
            Cutoff  = obj.Prot.Echo.Mat(3);
            MET2 = data.MET2data;
            Mask = data.Mask;
            FitResult = multi_comp_fit_v2(MET2, 'T2', Echo, Cutoff, 'tissue',Mask);
        end
        
    end
end