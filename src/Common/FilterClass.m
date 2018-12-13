
classdef (Abstract) FilterClass
    % FilterClass:  Methods for filtering data which can be inherited by
    % models
    %
    %   *Methods*
    %   gaussFilt: gaussian filtering (2D or 3D)
    %   medianFilt: median filtering (2D or 3D)
    %
    
    properties

    end
    
    methods
        % Constructor
        function obj = FilterClass()
            obj.version = qMRLabVer();
            obj.ModelName = class(obj);
        end
        
        function obj = gaussFilt(obj,data,fwhm)
            % Apply a Gaussian filter (2D or 3D)
            % fwhm is a 3-element vector of positive numbers
            sigmaPixels = fwhm2sigma(fwhm); %Full width half max of desired gaussian kernel (in #voxels) converted to sigma of Gaussian
            B = imgaussfilt3(data,sigmaPixels);
        end
        
        
        
        
        
    end
end
