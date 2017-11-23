classdef VFA_T1
% VFA_T1: Compute a T1 map using Variable Flip Angle
%<a href="matlab: figure, imshow qMT_SPGR.png ;">Pulse Sequence Diagram</a>
%
% Assumptions:
% 
% Inputs:
%   SPGR            spoiled Gradient echo data, 4D volume with different flip angles in time dimension
%   B1map           excitation (B1+) fieldmap. Used to correct flip angles.
%
% Outputs:
%   T1              Longitudinal relaxation time
%   M0              Equilibrium magnetization
%
% Protocol:
%   Array [nbFA x 2]:
%       [FA1 TR1; FA2 TR2;...]      flip angle [degrees] TR [s]
%
% Options:
%   None
%
% Example of command line usage (see also <a href="matlab: showdemo VFA_T1_batch">showdemo VFA_T1_batch</a>):
%   Model = VFA_T1;  % Create class from model 
%   Model.Prot.SPGR.Mat=[4 0.025; 10 0.025; 20 0.025]; %Protocol: 3 different FAs
%   data = struct;  % Create data structure 
%   data.SPGR = load_nii_data('SPGR.nii.gz');
%   data.B1map = load_nii_data('B1map.nii.gz');
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_mat(FitResults);
%
%   For more examples: <a href="matlab: qMRusage(VFA_T1);">qMRusage(VFA_T1)</a>
%
% 
% Author: Ian Gagnon, 2017
%
% References:
%   Please cite the following if you use this module:
%     Fram, E.K., Herfkens, R.J., Johnson, G.A., Glover, G.H., Karis, J.P.,
%     Shimakawa, A., Perkins, T.G., Pelc, N.J., 1987. Rapid calculation of
%     T1 using variable flip angle gradient refocused imaging. Magn. Reson.
%     Imaging 5, 201?208
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG,
%     Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and
%     Stikov N. (2016), Quantitative magnetization transfer imaging made
%     easy with qMTLab: Software for data simulation, analysis, and
%     visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

properties (Hidden=true)
% Hidden proprties goes here.    
end

    properties
        MRIinputs = {'SPGR','B1map'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct('SPGR',struct('Format',{{'FlipAngle' 'TR'}},...
                                         'Mat', [4 0.025; 10 0.025; 20 0.025])); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
methods (Hidden=true)
% Hidden methods goes here.    
end
    
    methods
        
        function obj = VFA_T1()
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
