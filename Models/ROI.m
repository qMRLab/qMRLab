classdef ROI
% ----------------------------------------------------------------------------------------------------
% Mask :  ROI drawing over a map
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% FILL
% ----------------------------------------------------------------------------------------------------
%
%  Fitted Parameters:
%    * ROI
%    * NewMap
%
%  Non-Fitted Parameters:
%    * None
%
% Options:
%    Drawing Method
%       * Ellipse: Maintain left click while you draw your ellipse
%       * Polygone: Selected all the vertices of your polygone one after the other
%       * Rectangle: Maintain left click while you draw your rectangle
%       * FreeHand: Maintain left click while you draw your shape (make sure it is well closed)
%      
% ----------------------------------------------------------------------------------------------------
% Written by: I. Gagnon, 2017
% Reference: FILL
% ----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'Map'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct(); % You can define a default protocol here.
        
        % Model options
        buttons = {'Drawing',{'Ellipse','Polygone','Rectangle','FreeHand'}};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = ROI
            obj = button2opts(obj);
        end
        
 
        function FitResult = fit(obj,data)  
            
            % Drawing the mask with the choosen method
            switch obj.options.Drawing
                case 'Ellipse'
                    draw = imellipse();
                case 'Polygone'
                    draw = impoly();
                case 'Rectangle'
                    draw = imrect();
                case 'FreeHand'
                    draw = imfreehand();
                otherwise
                    warning('Choose a Drawing Method');
            end
            
            FitResult.ROI = double(rot90(draw.createMask(),-1));
            FitResult.NewMap = (data.Map(:,:,1,1)).*(FitResult.ROI);
   
        end
        
    end
end
