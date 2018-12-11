classdef b1_dam < AbstractModel
% b1_dam map:  Double-Angle Method for B1+ mapping
%
% Assumptions:
%   Compute a B1map using 2 SPGR images with 2 different flip angles (60, 120deg)
%
% Inputs:
%   SFalpha            SPGR data at a flip angle of Alpha degree
%   SF2alpha           SPGR data at a flip angle of AlphaX2 degree
%
% Outputs:
%	B1map           Excitation (B1+) field map
%
% Protocol:
%	NONE
%
% Options
%   NONE
%
% Example of command line usage:
%   Model = b1_dam;% Create class from model
%   data.SF60 = double(load_nii_data('SFalpha.nii.gz')); %load data
%   data.SF120  = double(load_nii_data('SFalpha.nii.gz'));
%   FitResults       = FitData(data,Model); % fit data
%   FitResultsSave_nii(FitResults,'SFalpha.nii.gz'); %save nii file using SFalpha.nii.gz as template
%
%   For more examples: <a href="matlab: qMRusage(b1_dam);">qMRusage(b1_dam)</a>
%
% Author: Ian Gagnon, 2017
%
% References:
%   Please cite the following if you use this module:
%     Insko, E.K., Bolinger, L., 1993. Mapping of the Radiofrequency Field.
%     J. Magn. Reson. A 103, 82?85.
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG,
%     Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and
%     Stikov N. (2016), Quantitative magnetization transfer imaging made
%     easy with qMTLab: Software for data simulation, analysis, and
%     visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

properties (Hidden=true)
    onlineData_url = 'https://osf.io/mw3sq/download?version=1';
end

    properties
        MRIinputs = {'SFalpha','SF2alpha'};
        xnames = {};
        voxelwise = 0; % 0, if the analysis is done matricially
                       % 1, if the analysis is done voxel per voxel

        % Protocol
        Prot = struct('Alpha',struct('Format',{'FlipAngle'},'Mat',60));

        % Model options
        buttons = {};
        options = struct(); % structure filled by the buttons. Leave empty in the code

    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods

        function obj = b1_dam
            obj.options = button2opts(obj.buttons);
        end

        function FitResult = fit(obj,data)
            FitResult.B1map = abs(acos(data.SF2alpha./(2*data.SFalpha))./(deg2rad(obj.Prot.Alpha.Mat)));
        end

    end


    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);

            % 2.0.12
            if checkanteriorver(version,[2 0 12])
                % add B1factor
                obj.Prot = struct('Alpha',struct('Format',{'FlipAngle'},'Mat',60));
                obj.MRIinputs = {'SFalpha','SF2alpha'};

            end

        end
    end



end
