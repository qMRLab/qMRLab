classdef CSFMask
% ----------------------------------------------------------------------------------------------------
% CSFMask :  CerebroSpinal Fluid (CSF) mask using T1 values
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% FILL
% ----------------------------------------------------------------------------------------------------
%
%  Fitted Parameters:
%    * CSFMask
%
%
%  Non-Fitted Parameters:
%    * None
%
%
% Options:
%    * Set T1 bounds to obtain the best CSFMask
%     
%
% ----------------------------------------------------------------------------------------------------
% Written by: I. Gagnon, 2017
% Reference: FILL (ASK TANGUY/TUNG who wrote: "sct_create_mask_bg")
% ----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'SPGR','T1'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct(); % You can define a default protocol here.
        
        % Model options
        buttons = {'T1min',1.7,'T1max',2.5};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = CSFMask
            obj = button2opts(obj);
        end
        
        function FitResult = fit(obj,data)           
            % CSFMask
            FitResult.CSFMask = double (...
               data.T1 > obj.options.T1min &... % Lower limit (usually between 1.5 and 1.8)
               data.T1 < obj.options.T1max &... % Upper limit
               sct_create_mask_bg(data.SPGR(:,:,1)));
       
        end
        
    end
end
