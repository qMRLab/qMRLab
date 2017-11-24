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
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
    
properties (Hidden=true)
% Hidden proprties goes here.    
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
            
            [N, eta, sigma_g] = scd_noise_fit_histo(dat,'fig',obj.options.figure,'distrib',obj.options.NoiseDistribution);
            init=ones(size(data.Data4D,1),size(data.Data4D,2),size(data.Data4D,3));
            FitResults.sigma_g = sigma_g*init;
            if strcmp(obj.options.NoiseDistribution,'Non-central Chi')
                FitResults.eta = eta*init;
                FitResults.N = N*init;
            end
        end
        
    end
end
