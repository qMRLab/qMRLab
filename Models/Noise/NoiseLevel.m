classdef NoiseLevel
    % ----------------------------------------------------------------------------------------------------
    % NoiseLevel :  Noise histogram fitting within a noise mask
    % ----------------------------------------------------------------------------------------------------
    % Assumptions :
    %   * Uniform noise distribution. Outputs are scalar : all voxels have
    %     the same value
    % ----------------------------------------------------------------------------------------------------
    %
    %  Fitted Parameters:
    % Non-central Chi Parameters:
    %    * Sigma
    %    * eta
    %    * N
    %
    % Options:
    %    * figure : plot noise histogram fit
    % Noise Distribution
    %    * Rician          : valid if using one coil OR adaptive combine
    %    * Non-central Chi : valid for multi-coil and parallel imaging (parameter N reprensent the effective number of coils)
    %
    %
    % ----------------------------------------------------------------------------------------------------
    % Written by: Ian Gagnon, 2017
    % Reference: 
    % ----------------------------------------------------------------------------------------------------
    
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
    
    methods
        
        function obj = NoiseLevel
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
        end
        
        function FitResults = fit(obj,data)
            if any(strcmp('NoiseMask',fieldnames(data)))
                dat = reshape2D(data.Data4D,4)';
                dat = dat(logical(data.NoiseMask(:)),:);
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