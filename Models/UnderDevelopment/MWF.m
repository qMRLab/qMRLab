classdef MWF
% ----------------------------------------------------------------------------------------------------
% MWF :  Myelin Water Fraction
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% FILL
% ----------------------------------------------------------------------------------------------------
%
%  Output Parameters:
%    * MWF
%
%
%  Non-Fitted Parameters:
%    *     
%    * FILL
%
%
% Options:
%   FILL:
%     *
%     *
%   FILL:
%     * 
%     * 
% ----------------------------------------------------------------------------------------------------
% Written by: I. Gagnon, 2017
% Reference: FILL
% ----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'MET2','Mask'};
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
        end
        
        function FitResult = fit(obj,data)            
            multi_comp_fit(data.MET2, 'T2', data.Mask);   
        end
        
    end
end