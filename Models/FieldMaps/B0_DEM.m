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
        Prot = struct('Time',struct('Format',{'TE2'},'Mat', 1.92e-3));
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = B0_DEM
            obj.options = button2opts(obj.buttons);
        end
        
        function FitResult = fit(obj,data)
            Phase = data.Phase;
            Magn = data.Magn;
            mkdir('tmp')
            save_nii(make_nii(Phase),'tmp/Phase.nii');
            save_nii(make_nii(Magn),'tmp/Magn.nii');
            unix('prelude -p tmp/Phase.nii -a tmp/Magn.nii -o tmp/Ph_uw -f');
            b0 = load_untouch_nii('tmp/Ph_uw.nii.gz');
            cd ..
            rmdir('tmp','s')
            b0.img = unwrap(b0.img,[],4);
            FitResult.b0map = (b0.img(:,:,:,2) - b0.img(:,:,:,1))/(obj.Prot.Time.Mat*2*pi);           
        end        
    end
end
