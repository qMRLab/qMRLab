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
%  (Mask)    Binary mask. (OPTIONAL)
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
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

    properties (Hidden=true)
        onlineData_url = 'https://osf.io/erm2s/download?version=2';
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

            FitResults.MTR(isnan(FitResults.MTR)) = 0;
            FitResults.MTR(isinf(FitResults.MTR)) = 0;

            if isfield(data,'Mask') && not(isempty(data.Mask))

                data.Mask(isnan(data.Mask)) = 0;

                data.Mask = logical(data.Mask);
                FitResults.MTR = FitResults.MTR.*data.Mask;

            end

        end




    end
end
