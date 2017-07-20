classdef VFA_T1
% ----------------------------------------------------------------------------------------------------
% VFA_T1 :  T1 map using Macromolecular Tissue Volume
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% FILL
% ----------------------------------------------------------------------------------------------------
%  Inputs:
%    * SPGR  : spoiled Gradient echo. 4D volume with variable flip angles
%    * B1map : excitation (B1+) fieldmap. Used to correct flip angles.
%
%  Output maps:
%    * T1
%    * M0
%
%
%
% Options:
%     * None
%     
%
% ----------------------------------------------------------------------------------------------------
% Written by: I. Gagnon, 2017
% Reference: FILL
% ----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'SPGR','B1map'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct('SPGR',struct('Format',{{'Flip Angle' 'TR'}},...
                                         'Mat', [4 0.025; 10 0.025; 20 0.025])); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = VFA_T1
            obj.options = button2opts(obj.buttons);
        end
        
        function FitResult = fit(obj,data)           
            % T1 and M0
            flipAngles = (obj.Prot.SPGR.Mat(:,1))';
            TR = obj.Prot.SPGR.Mat(1,2);
            [FitResult.M0, FitResult.T1] = mtv_compute_m0_t1(double(data.SPGR(:,:,:,:)), flipAngles(1:length(flipAngles)), TR, data.B1map);
       
        end
        
    end
end
