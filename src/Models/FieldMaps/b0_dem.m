classdef b0_dem < AbstractModel
% b0_dem map :  Dual Echo Method for B0 mapping
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
%   Magn thresh     relative threshold for the magnitude (phase is undefined in the background
%
% Example of command line usage:
%   Model = b0_dem;  % Create class from model
%   Model.Prot.TimingTable.Mat = 1.92e-3; % deltaTE [s]
%   data.Phase = double(load_nii_data('Phase.nii.gz'));%Load 4D data, 2 frames with different TE
%   data.Magn  = double(load_nii_data('Magn.nii.gz'));
%   FitResults       = FitData(data,Model);
%   FitResultsSave_nii(FitResults,'Phase.nii.gz'); %save nii file using Phase.nii.gz as template
%
%   For more examples: <a href="matlab: qMRusage(b0_dem);">qMRusage(b0_dem)</a>
%
% Author: Ian Gagnon, 2017
%
% References:
%   Please cite the following if you use this module:
%     Maier, F., Fuentes, D., Weinberg, J.S., Hazle, J.D., Stafford, R.J.,
%     2015. Robust phase unwrapping for MR temperature imaging using a
%     magnitude-sorted list, multi-clustering algorithm. Magn. Reson. Med.
%     73, 1662?1668. Schofield, M.A., Zhu, Y., 2003. Fast phase unwrapping
%     algorithm for interferometric applications. Opt. Lett. 28, 1194?1196
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
    onlineData_url = 'https://osf.io/zkefh/download?version=5';
end

    properties
        MRIinputs = {'Phase','Magn'};
        xnames = {'B0 (Hz)'};
        voxelwise = 0; % 0, if the analysis is done matricially
                       % 1, if the analysis is done voxel per voxel

        % Protocol
        % You can define a default protocol here.
        Prot = struct('TimingTable',struct('Format',{'deltaTE'},'Mat', 1.92e-3));

        % Model options
        buttons = {'Magn thresh',.05};
        options = struct(); % structure filled by the buttons. Leave empty in the code

    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods
        function obj = b0_dem
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end

        function obj = UpdateFields(obj)
            obj.options.Magnthresh = max(obj.options.Magnthresh,0);
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
%             FitResult.B0map = (B0.img(:,:,:,2) - B0.img(:,:,:,1))/(obj.Prot.TimingTable.Mat*2*pi);


            % 2D or 3D data ?
            if any(size(Phase) == 1)
                TwoD  = true;
            else
                TwoD = false;
            end

            % MATLAB "sunwrap" for 2D data
            Phase_uw = Phase;
            if TwoD
                Complex = Magn.*exp(Phase*1i);
                for iEcho = 1:size(Magn,4)
                    Phase_uw(:,:,:,iEcho) = sunwrap(Complex(:,:,:,iEcho));
                end
            % MATLAB "laplacianUnwrap" for 3D data
            else
                for iEcho = 1:size(Phase,4)
                    Phase_uw(:,:,:,iEcho) = laplacianUnwrap(Phase(:,:,:,iEcho), Magn>obj.options.Magnthresh);
                end
            end
            FitResult.B0map = (Phase_uw(:,:,:,2) - Phase_uw(:,:,:,1))/(obj.Prot.TimingTable.Mat*2*pi);
            
            % Save unwrapped phase
            FitResult.Phase_uw = Phase_uw;
        end
    end
end
