classdef B0_DEM
%-----------------------------------------------------------------------------------------------------
% B0_DEM map :  Dual Echo Method for B0 mapping
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
%   1) Phase : 
%   2) Magn  : 
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%	* B0map : B0 field map
%
%-----------------------------------------------------------------------------------------------------
%----------%
% PROTOCOL %
%----------%
%	* deltaTE : 
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OPTIONS %
%---------%
%   * Magn thresh lb : 
%
%-----------------------------------------------------------------------------------------------------
% Written by: Ian Gagnon, 2017
% Reference: FILL
%-----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'Phase','Magn'};
        xnames = {'B0 (Hz)'};
        voxelwise = 0; % 0, if the analysis is done matricially
                       % 1, if the analysis is done voxel per voxel
        
        % Protocol
        % You can define a default protocol here.
        Prot = struct('Time',struct('Format',{'deltaTE'},'Mat', 1.92e-3));
        
        % Model options
        buttons = {'Magn thresh lb',0};
        options = struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = B0_DEM
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            if obj.options.Magnthreshlb == 0
                obj.options.Magnthreshlb = '';
            end
        end
        
        function FitResult = fit(obj,data)
            Phase = data.Phase;
            Magn = data.Magn;
            
%             % FSL "prelude"
%             mkdir('tmp')
%             save_nii(make_nii(Phase),'tmp/Phase.nii');
%             save_nii(make_nii(Magn),'tmp/Magn.nii');
%             unix('prelude -p tmp/Phase.nii -a tmp/Magn.nii -o tmp/Ph_uw -f');
%             B0 = load_untouch_nii('tmp/Ph_uw.nii.gz');
%             rmdir('tmp','s')
%             B0.img = unwrap(B0.img,[],4);
%             FitResult.B0map = (B0.img(:,:,:,2) - B0.img(:,:,:,1))/(obj.Prot.Time.Mat*2*pi);
            
            
            % 2D or 3D data ?
            if any(size(Phase) == 1)
                TwoD  = true;
            else
                TwoD = false;
            end
            
            % MATLAB "sunwrap" for 2D data
            if TwoD
                Complex = Magn.*exp(Phase*1i);
                Phase_uw = Phase;
                for it = 1:size(Magn,4)
                    Phase_uw(:,:,:,it) = sunwrap(Complex(:,:,:,it));
                end
                FitResult.B0map = (Phase_uw(:,:,:,2) - Phase_uw(:,:,:,1))/(obj.Prot.Time.Mat*2*pi); 
                     
            % MATLAB "laplacianUnwrap" for 3D data
            else
                if isempty(obj.options.Magnthreshlb)
                    msgbox('Enter a Lower Bound relative to the Magn','Create a Mask');
                end
                Phase_uw = laplacianUnwrap(Phase, magn>.05);
                FitResult.B0map = (Phase_uw(:,:,:,2) - Phase_uw(:,:,:,1))/(obj.Prot.Time.Mat*2*pi);                 
            end
            
            
        end        
    end
end
