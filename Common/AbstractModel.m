classdef (Abstract) AbstractModel
    % AbstractModel:  Properties/Methods shared between all models.
    %
    %   *Methods*
    %   save: save model object properties to a file as an struct.
    %   load: load model properties from a struct-file into the object.
    %
    
    properties
        version
        ModelName
    end
    
    methods
        % Constructor
        function obj = AbstractModel()
            obj.version = qMRLabVer();
            obj.ModelName = class(obj);
        end
        
        function saveObj(obj, suffix)
            if ~exist('suffix','var'), suffix = class(obj); end
            try
                objectProperties = fieldnames(obj);
                objStruct = struct();
                %Loop through all object properties
                for propIndex = 1:length(objectProperties)
                    
                    % Assign object property value to identically named struct field.
                    objStruct.(objectProperties{propIndex}) = obj.(objectProperties{propIndex});
                end
                % Add Model Name
                objStruct.ModelName = class(obj);
                
                save([strrep(strrep(suffix,'.qmrlab.mat',''),'.mat','') '.qmrlab.mat'], '-struct', 'objStruct');
            catch ME
                error(ME.identifier, ME.message)
            end
        end
        
        function obj = loadObj(obj, fileName)
            try
                loadedStruct = load(fileName);
                
                % parse structure to object
                obj = qMRpatch(obj,loadedStruct,loadedStruct.version);
                
            catch ME
                error(ME.identifier, ME.message)
            end
        end
    end
    
    methods(Access = private)
        function obj = qMRpatch(obj,loadedStruct, version)
            objectProperties = fieldnames(obj);
            
            %Loop through all object properties
            for propIndex = 1:length(objectProperties)
                
                % Assign object property value to identically named struct field.
                obj.(objectProperties{propIndex}) = loadedStruct.(objectProperties{propIndex});
            end
            
        end
    end
    
end
