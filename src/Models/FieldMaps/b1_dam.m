classdef b1_dam < AbstractModel
% b1_dam map:  Double-Angle Method for B1+ mapping
%
% Assumptions:
%   Compute a B1map using 2 SPGR images with 2 different flip angles (60, 120deg)
%
% Inputs:
%   SF60            SPGR data at a flip angle of 60 degree
%   SF120           SPGR data at a flip angle of 120 degree
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
%   data.SF60 = double(load_nii_data('SF60.nii.gz')); %load data
%   data.SF120  = double(load_nii_data('SF120.nii.gz'));
%   FitResults       = FitData(data,Model); % fit data
%   FitResultsSave_nii(FitResults,'SF60.nii.gz'); %save nii file using SF60.nii.gz as template
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
    onlineData_url = 'https://osf.io/8ypzw/download/';
end

    properties
        MRIinputs = {'SF60','SF120'};
        xnames = {};
        voxelwise = 0; % 0, if the analysis is done matricially
                       % 1, if the analysis is done voxel per voxel
        
        % Protocol
        ProtFormat ={};
        Prot  = []; % You can define a default protocol here.
        
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
            FitResult.B1map = abs(acos(data.SF120./(2*data.SF60))./(60*pi/180));
        end
        
    end
end
