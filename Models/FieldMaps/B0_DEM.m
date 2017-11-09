classdef B0_DEM
% B0_DEM map :  Dual Echo Method for B0 mapping
%
% Assumptions:
%   Compute B0 map based on 2 phase images with different TEs
%
% Inputs:
%   Phase       4D phase image, 2 different TEs in time dimension
%   Magn        3D magnitude image
%
% Outputs:
%	B0map       B0 field map [Hz]
%
% Protocol:
%   TimingTable
%       deltaTE     Difference in TE between 2 images [ms]            
%
% Options:
%   Magn thresh lb  Lower bound to threshold the magnitude image for use as a mask
%
% Example of command line usage (see also <a href="matlab: showdemo B0_DEM_batch">showdemo B0_DEM_batch</a>):
%   Model = B0_DEM;  % Create class from model 
%   Model.Prot.Time.Mat = 1.92e-3; % deltaTE [s]
%   data.Phase = double(load_nii_data('Phase.nii.gz'));%Load 4D data, 2 frames with different TE
%   data.Magn  = double(load_nii_data('Magn.nii.gz'));
%   FitResults       = FitData(data,Model);
%   FitResultsSave_nii(FitResults,'Phase.nii.gz'); %save nii file using Phase.nii.gz as template
%    
%   For more examples: <a href="matlab: qMRusage(B0_DEM);">qMRusage(B0_DEM)</a>
%
% Author: Ian Gagnon, 2017
%
% References:
%   Please cite the following if you use this module:
%     FILL
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

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
