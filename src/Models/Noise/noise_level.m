classdef noise_level < AbstractModel
% noise_level :  Noise histogram fitting within a noise mask
% ASSUMPTIONS:
%   (1)Uniform noise distribution. Outputs are scalar : all voxels have
%       the same value
%
% Fitted Parameters:
%   Non-central Chi Parameters
%       Sigma
%       eta
%       N
%
% Options:
%    figure             plot noise histogram fit
% Noise Distribution
%    Rician             valid if using one coil OR adaptive combine
%    Non-central Chi    valid for multi-coil and parallel imaging (parameter N reprensent the effective number of coils)
%
% Author: Ian Gagnon, 2017
%
% References:
%   Please cite the following if you use this module:
%     FILL
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
    onlineData_url = 'https://osf.io/ve3xy/download?version=4';
end

    properties
        MRIinputs = {'Data4D','NoiseMask'};
        xnames = {};
        voxelwise = 0;

        % Protocol
        Prot  = struct(); % You can define a default protocol here.

        % Model options
        buttons = {'figure',true,'Noise Distribution',{'Rician','Non-central Chi'}};
        options= struct(); % structure filled by the buttons. Leave empty in the code

    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods

        function obj = noise_level
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end

        function obj = UpdateFields(obj)
        end

        function FitResults = fit(obj,data)
            if any(strcmp('NoiseMask',fieldnames(data)))
                dat = reshape2D(data.Data4D,4)';
                dat = dat(logical(data.NoiseMask(:)),:);
            else
                dat = data.Data4D;
            end

            [N, eta, sigma_g] = scd_noise_fit_histo(dat,'fig',double(obj.options.figure),'distrib',obj.options.NoiseDistribution);
            init=ones(size(data.Data4D,1),size(data.Data4D,2),size(data.Data4D,3));
            FitResults.sigma_g = sigma_g*init;
            if strcmp(obj.options.NoiseDistribution,'Non-central Chi')
                FitResults.eta = eta*init;
                FitResults.N = N*init;
            end
        end

    end
end
