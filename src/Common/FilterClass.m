
classdef (Abstract) FilterClass
    % FilterClass:  Methods for filtering data which can be inherited by
    % models
    %
    %   *Methods*
    %   gaussFilt: gaussian filtering (2D or 3D)
    %   medianFilt: median filtering (2D or 3D)
    %
    
    properties (Access = private)
        MRIinputs = {'Raw','Mask'};
        xnames = {};
        voxelwise = 0; % 0, if the analysis is done matricially
        % 1, if the analysis is done voxel per voxel
        
        % Protocol
        %Prot = ();
    end
    properties
        % Model options
        buttons ={'PANEL','Smoothing filter',5,...
            'Type',{'gaussian','median','spline'},...
            'Dimension',{'3D','2D'},...
            'size x',3,...
            'size y',3,...
            'size z',3};
        options = struct(); % structure filled by the buttons. Leave empty in the code
    end
    
    methods
        % Constructor
        function obj = FilterClass()
            obj.version = qMRLabVer();
            obj.ModelName = class(obj);
        end
        function obj = UpdateFields(obj)
          
            % Disable/enable some options --> Add ### to the button
            % Name you want to disable
            disablelist = {'size x','size y','size z'};
            switch  obj.options.Smoothingfilter_Dimension
                case {'2D'}
                    disable = [false false true]; 
                    obj.options.Smoothingfilter_sizez=0;
                otherwise
                   disable = [false false false]; 
            end
            % for spline, only 1 value for the amount of smoothness and 3D
            if strcmp(obj.options.Smoothingfilter_Type,{'spline'})
                disable = [false true true]; 
            end
            
            for ll = 1:length(disablelist)
                indtodisable = find(strcmp(obj.buttons,disablelist{ll}) | strcmp(obj.buttons,['##' disablelist{ll}]));
                if disable(ll)
                    obj.buttons{indtodisable} = ['##' disablelist{ll}];
                else
                    obj.buttons{indtodisable} = [disablelist{ll}];
                end
            end
        end
        
        function FitResult = fit(obj,data,size)
            switch obj.options.Smoothingfilter_Type
                case {'gaussian'}
                    FitResult.Filtered=obj.gaussFilt(data,size); %smoothed
                case {'median'}
                    FitResult.Filtered=obj.medianFilt(data,size); %smoothed
                case {'spline'}
                    FitResult.Filtered=obj.splineFilt(data,size); %smoothed
            end
        end
        % Gaussian filter
        function filtered = gaussFilt(obj,data,fwhm)
            % Apply a Gaussian filter (2D or 3D)
            % fwhm is a 2 or 3-element vector of positive numbers
            sigmaPixels = fwhm2sigma(fwhm); %Full width half max of desired gaussian kernel (in #voxels) converted to sigma of Gaussian
            if(sigmaPixels(3)==0 || strcmp(obj.options.Smoothingfilter_Dimension,'{2D}')) %for the 2D case
                filtered = imgaussfilt(data,sigmaPixels(1:2));
            else
                filtered = imgaussfilt3(data,sigmaPixels);
            end
        end
        
        %Median filter
        function filtered =medianFilt(obj,data,s)
            % Apply a median filter (2D or 3D)
            % s is a 3-element vector of positive numbers (voxels)
            if(s(3)==0 || strcmp(obj.options.Smoothingfilter_Dimension,'{2D}')) %for the 2D case, if the volume is 3D, have to do each slice separately
                if(ndims(data)==2)
                    filtered = medfilt2(data,s(1:2));
                else
                    filtered=zeros(size(data));
                    for i=1:size(data,3)
                        filtered(:,:,i)=medfilt2(data(:,:,i),s(1:2));
                    end
                end
            else
                filtered = medfilt3(data,s);
            end
        end
        
        %Spline filter
        function filtered =splineFilt(obj,data,S)
            % Apply a spline filter (2D or 3D)
            s=S(1); %just 1 values for the smoothness
            if(strcmp(obj.options.Smoothingfilter_Dimension,'{2D}')) %if want 2D smoothing
                if(ndims(data)==2) %if a 2D volume
                    filtered = smoothn(data,s);
                else %if a 3D volume, do each slice separately
                    filtered=zeros(size(data));
                    for i=1:size(data,3)
                        filtered(:,:,i)=smoothn(data(:,:,i),s);
                    end
                end
            else
                filtered = smoothn(data,s);
            end
                
            %filtered = smoothn(data,'robust');            
        end
    end
    
    
    
end

