classdef B1_DAM
%-----------------------------------------------------------------------------------------------------
% B1_DAM map :  Double-Angle Method for B1+ mapping
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
%   1) SF60  : SPGR data at a flip angle of 60 degree
%   2) SF120 : SPGR data at a flip angle of 120 degree
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%	* B1map : Excitation (B1+) field map
%
%-----------------------------------------------------------------------------------------------------
%----------%
% PROTOCOL %
%----------%
%	NONE
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OPTIONS %
%---------%
%   NONE
%
%-----------------------------------------------------------------------------------------------------
% Written by: Ian Gagnon, 2017
% Reference: FILL
%-----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'SF60','SF120'};
        xnames = {};
        voxelwise = 0; % 0, if the analysis is done matricially
                       % 1, if the analysis is done voxel per voxel
        
        % Protocol
        ProtFormat ={};
        Prot  = []; % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options = struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = B1_DAM
            obj.options = button2opts(obj.buttons);
        end
        
        function FitResult = fit(obj,data)
            FitResult.B1map = abs(acos(data.SF120./(2*data.SF60))./(60*pi/180));
        end
        
    end
end
