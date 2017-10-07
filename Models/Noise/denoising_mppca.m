classdef denoising_mppca
    % ----------------------------------------------------------------------------------------------------
    % denoising_mppca :  Denoise 4D data using adaptative pca
    % ----------------------------------------------------------------------------------------------------
    % Assumptions :
    %   * Noise follows a rician distribution
    % ----------------------------------------------------------------------------------------------------
    %
    %  Fitted Parameters:
    %    * Sigma: standard deviation of the rician noise
    %
    % Options:
    %
    %
    % ----------------------------------------------------------------------------------------------------
    % Written by: Tanguy Duval, 2017
    % Reference: 
    %      Veraart, J.; Fieremans, E. & Novikov, D.S. Diffusion MRI noise mapping
    %      using random matrix theory Magn. Res. Med., 2016, early view, doi:
    %      10.1002/mrm.26059
    % ----------------------------------------------------------------------------------------------------
    
    properties
        MRIinputs = {'Data4D'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct(); % You can define a default protocol here.
        
        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = denoising_mppca
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
        end
        
        function FitResults = fit(obj,data)
            dims=size(data.Data4D);
            kernel = min(dims(1:3),[5 5 5]);
            if min(kernel)<2, FitResults.Sigma=zeros(dims(1:3)); helpdlg('your dataset need at least 2 slices'); return; end
            [FitResults.Data4D, FitResults.Sigma] = MPdenoising(data.Data4D,[],kernel);
        end
        
    end
end