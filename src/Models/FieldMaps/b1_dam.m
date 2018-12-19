classdef b1_dam < AbstractModel & FilterClass
% b1_dam map:  Double-Angle Method for B1+ mapping
%
% Assumptions:
%   Compute a B1map using 2 SPGR images with 2 different flip angles (alpha, 2xalpha)
%   Smoothing can be done with different filters and optional size
%   Spurious B1 values and those outside the mask (optional) are set to a constant before smoothing
%
% Inputs:
%   SFalpha            SPGR data at a flip angle of Alpha degree
%   SF2alpha           SPGR data at a flip angle of AlphaX2 degree
%   (Mask)             Binary mask to exclude non-brain voxels (better when smoothing)
%
% Outputs:
%	B1map_raw          Excitation (B1+) field map
%   B1map              Smoothed B1+ field map using Gaussian or Median filter
%   Spurious           Map of datapoints that were set to 1 prior to smoothing
%
% Protocol:
%	NONE
%
% Options:
%   Smoothing Filter
%     Type                 Type of filter
%                              - gaussian
%                              - median
%     Dimension            In which dimensions to apply the filter
%                               -2D
%                               -3D
%     size(x,y,z)          Extent of filter in # of voxels
%                               For gaussian, it's FWHM
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
    onlineData_url = 'https://osf.io/mw3sq/download?version=3';
end

    properties
        MRIinputs = {'SFalpha','SF2alpha','Mask'};
        xnames = {};
        voxelwise = 0; % 0, if the analysis is done matricially
                       % 1, if the analysis is done voxel per voxel

        % Protocol
        Prot = struct('Alpha',struct('Format',{'FlipAngle'},'Mat',60));

        % Inherit these from public properties of FilterClass 
%         % Model options
%         buttons ={};
%         options = struct(); % structure filled by the buttons. Leave empty in the code

    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods

        function obj = b1_dam
            obj.options = button2opts(obj.buttons);
        end
       
        
        function FitResult = fit(obj,data)
            FitResult.B1map_raw = abs(acos(data.SF2alpha./(2*data.SFalpha))./(deg2rad(obj.Prot.Alpha.Mat)));
            %remove 'spurious' points to reduce edge effects
            if isfield(data,'Mask') && ~isempty(data.Mask)
                FitResult.B1map_raw = data.Mask .* FitResult.B1map_raw;
            end
            FitResult.Spurious = double(FitResult.B1map_raw<0.5);
            B1map_nospur = FitResult.B1map_raw;
            B1map_nospur(B1map_nospur<0.6 | isnan(B1map_nospur))=0.6; %set 'spurious' values to 0.6
            
            % call the superclass (FilterClass) fit function
            FitResult.B1map=struct2array(fit@FilterClass(obj,B1map_nospur,[obj.options.Smoothingfilter_sizex,obj.options.Smoothingfilter_sizey,obj.options.Smoothingfilter_sizez]));
            % re-apply the mask
            if isfield(data,'Mask') && ~isempty(data.Mask)
                FitResult.B1map = data.Mask .* FitResult.B1map;
            end
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
