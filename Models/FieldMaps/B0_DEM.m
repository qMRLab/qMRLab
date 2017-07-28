classdef B0_DEM
% ----------------------------------------------------------------------------------------------------
% B0_DEM map :  Dual-Echo Method for B0 mapping
% ----------------------------------------------------------------------------------------------------
% Assumptions :
% FILL
% ----------------------------------------------------------------------------------------------------
%
%  Output Parameters:
%    * B0
%
%
%  Non-Fitted Parameters:
%    * Phase
%    * Magnitude
%
%
% Options:
%   None
% ----------------------------------------------------------------------------------------------------
% Written by: I. Gagnon, 2017
% Reference: FILL
% ----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'Phase','Magn'};
        xnames = {'B0 (Hz)'};
        voxelwise = 0; % 0, if the analysis is done matricially
                       % 1, if the analysis is done voxel per voxel
        
        % Protocol
        % You can define a default protocol here.
        Prot = struct('Time',struct('Format',{'deltaTE'},'Mat', 1.92e-3));
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = B0_DEM
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
        end
        
        function FitResult = fit(obj,data)
            Phase = data.Phase;
            Magn = data.Magn;
            Complex = Magn.*exp(Phase*1i);
            Phase_uw = Phase;
            for it = 1:size(Magn,4)
                Phase_uw(:,:,:,it) = sunwrap(Complex(:,:,:,it));
            end
            FitResult.B0map = (Phase_uw(:,:,:,2) - Phase_uw(:,:,:,1))/(obj.Prot.Time.Mat*2*pi);           
        end        
    end
end
