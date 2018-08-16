classdef mt_ratio < AbstractModel
% mt_ratio :  Magnetization transfer ratio (MTR)
%
% Assumptions:
%   MTR is a semi-quantitative measure. It is not an absolute measure of
%   magnetization transfer contrast and highly depended on the shape,
%   bandwidth and frequency offset of the MT pulse.
%
% Inputs:
%   MTon     MT-weighted data. Spoiled Gradient Echo (or FLASH) with MT
%   MToff    Data before MT pulse. Spoiled Gradient Echo (or FLASH) without MT
%  (Mask)    Binary mask.
%
% Outputs:
%	  MTR        Magnetization transfer ratio map (%)
%
% Example of command line usage (see also <a href="matlab: showdemo Custom_batch">showdemo Custom_batch</a>):
%   For more examples: <a href="matlab: qMRusage(Custom);">qMRusage(Custom)</a>
%
% Author: Agah Karakuzu
%
% References:
%   Please cite the following if you use this module:
%     FILL
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
    
    properties (Hidden=true)
        onlineData_url = 'https://osf.io/erm2s/download/';
    end
    
    properties
        
        
        voxelwise = 0;
        
        MRIinputs = {'MTon','MToff', 'Mask'};
        
        
        xnames = {'MTR'}; 
        
        Prot = struct();
        buttons  = {};
        options  = struct();
        
    end
    
    methods
        
        function obj = mt_ratio
            
            obj.options = button2opts(obj.buttons);
            
        end
        
        
        
        function FitResults = fit(obj, data)
            
            FitResults.MTR = 100 * (data.MToff - data.MTon)./data.MToff;
            
            if isfield(data,'Mask')
                FitResults.MTR = FitResults.MTR.*data.Mask;
            end
            
        end
        
        
        
        
    end
end