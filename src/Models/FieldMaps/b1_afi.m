classdef b1_afi < AbstractModel & FilterClass
% b1_afi map:  Actual Flip-Angle Imaging for B1+ mapping
%
% Assumptions:
%   Compute a B1map
%   Smoothing can be done with different filters and optional size
%   Spurious B1 values and those outside the mask (optional) are set to a constant before smoothing
%   
%
% Inputs:
%   AFIData1     3D Actual Flip Imaging (AFI) data 1
%   AFIData2     3D Actual Flip Imaging (AFI) data 2
%  (Mask)    Binary mask to exclude non-brain voxels
%
% Outputs:
%	B1map_raw          Actual/Nominal FA field map (B1+) 
%   B1map_filtered     Smoothed B1+ field map using Gaussian, Median, Spline or polynomial filter (see FilterClass.m for more info)
%   Spurious           Map of datapoints that were set to 1 prior to smoothing


% Protocol:
%   Sequence    [nomFA; TR1; TR2]  nominal Flip Angle [deg]; TR1 [s]; TR2 [s]
%
% Options:
%
%
%
% Example of command line usage:
%   Model = b1_afi;  % Create class from model
%   Model.Prot.Sequence.Mat = txt2mat('seq.txt');  % Load protocol
%   data = struct;  % Create data structure
%   data.AFIData1 = load_nii_data('AFIData1.nii');
%   data.AFIData2 = load_nii_data('AFIData2.nii');
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_nii(FitResults,'AFIData1.nii'); % Save in local folder: FitResults/
%
%   For more examples: <a href="matlab: qMRusage(b1_afi);">qMRusage(b1_afi)</a>
%
% Authors: Juan Velazquez
%
% References:
%   Please cite the following if you use this module:
%     Yarnykh, VL., 2007. Actual Flip-Angle Imaging in the Pulsed Steady State: A Method for Rapid Three Dimensional Mapping of the Transmitted Radiofrequency Field. Magn. Reson. Med. 57, 192?200.
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357


    properties (Hidden=true)
        onlineData_url = 'https://osf.io/csjgx/download/';
    end

    properties
        MRIinputs = {'AFIData1','AFIData2', 'Mask'};
        xnames = {};
        voxelwise = 0;

        % Protocol
        Prot  = struct('Sequence',struct('Format',{{'nomFA';'TR1';'TR2'}},...
            'Mat',[60;20;100]));
    end

    methods
        function obj = b1_afi
            obj.options = button2opts(obj.buttons);
        end

        function FitResult = fit(obj,data)
            nomFA = obj.Prot.Sequence.Mat(1); %nominal Flip Angle
            n = obj.Prot.Sequence.Mat(3)/obj.Prot.Sequence.Mat(2); %TR2/TR1

            r = abs(data.AFIData2./data.AFIData1); %Signal AFI2/Signal AFI1
            cos_arg = (r*n-1)./(n-r);
            % filter out cases where r > 1:
            % r should not be greater than one, so must be noise
            cos_arg = double(cos_arg).*(r<=1) + ones(size(r)).*(r>1);
            AFImap = acos(cos_arg); %AFImap is in radians
            AFImap = AFImap*180/pi;
            FitResult.B1map_raw = AFImap/nomFA;
                
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

end
