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
%   (Mask)             Binary mask to exclude non-brain voxels (OPTIONAL) (better when smoothing)
%
% Outputs:
%	B1map_raw          Excitation (B1+) field map
%   B1map_filtered     Smoothed B1+ field map using Gaussian, Median, Spline or polynomial filter (see FilterClass.m for more info)
%   Spurious           Map of datapoints that were set to 1 prior to smoothing
%
% Protocol:
%	NONE
%
% Options:
%   (inherited from FilterClass)
%
% Example of command line usage:
%   Model = b1_dam;% Create class from model
%   data.SFalpha = double(load_nii_data('SFalpha.nii.gz')); %load data
%   data.SF2alpha  = double(load_nii_data('SF2alpha.nii.gz'));
%   Model.Smoothingfilter_Dimension = 'gaussian'; %apply gaussian smoothing in 3D with fwhm=3
%   Model.Smoothingfilter_Type = '3D';
%   Model.Smoothingfilter_sizex = 3;
%   Model.Smoothingfilter_sizey = 3;
%   Model.Smoothingfilter_sizez = 3;
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
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
    onlineData_url = 'https://osf.io/mw3sq/download?version=3';
    %additional multi-slice dataset available here: https://osf.io/kytxw/
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
            obj = UpdateFields(obj);
        end
        
        function FitResult = fit(obj,data)
            FitResult.B1map_raw = abs(acos(data.SF2alpha./(2*data.SFalpha))./(deg2rad(obj.Prot.Alpha.Mat)));
            %remove 'spurious' points to reduce edge effects
            FitResult.Spurious = double(FitResult.B1map_raw<0.5);
            B1map_nospur = FitResult.B1map_raw;
            B1map_nospur(B1map_nospur<0.6 | isnan(B1map_nospur))=0.6; %set 'spurious' values to 0.6
            
            % call the superclass (FilterClass) fit function
            data.Raw = B1map_nospur;
            FitResult.B1map_filtered=cell2mat(struct2cell(fit@FilterClass(obj,data,[obj.options.Smoothingfilter_sizex,obj.options.Smoothingfilter_sizey,obj.options.Smoothingfilter_sizez])));
            % note: can't use struct2array because dne for octave...
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
            % 2.0.13
            if checkanteriorver(version,[2 0 13])
                % add mask and add options/buttons for smoothing
                obj.MRIinputs = {'SFalpha','SF2alpha','Mask'};
                obj.options.Smoothingfilter_Type='polynomial';
                obj.options.Smoothingfilter_Dimension='3D';
                obj.options.Smoothingfilter_sizex='3';
                obj.options.Smoothingfilter_sizex='3';
                obj.options.Smoothingfilter_sizey='3';
                obj.options.Smoothingfilter_sizez='3';
                obj.options.Smoothingfilter_order='5';
                obj.buttons ={'PANEL','Smoothing filter',6,...
                    'Type',{'polynomial','gaussian','median','spline'},...
                    'Dimension',{'3D','2D'},...
                    'size x',3,...
                    'size y',3,...
                    'size z',3,...
                    'order',6};
            end
            
        end
    end


end
