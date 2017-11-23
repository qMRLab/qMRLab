classdef (Abstract) AbstractModel
% AbstractModel:  Properties/Methods shared between all models.
%
%   *Methods*
%   save: save model object properties to a file as an struct.
%   load: load model properties from a struct-file into the object.
%

properties
    version
end

methods
    % Constructor
    function obj = AbstractModel()
        obj.version = qMRLabVer();
    end
    
    function saveObj(obj, fileName)
        try            
            objectProperties = properties(obj);
            
            %Loop through all object properties
            for propIndex = 1:length(objectProperties)
                
                % Assign object property value to identically named struct field.
                objStruct.(objectProperties{propIndex}) = obj.(objectProperties{propIndex});
            end

            save(fileName, '-struct', 'objStruct');
        catch ME
            error(ME.identifier, ME.message)
        end
    end
    
    function loadObj(obj, fileName)
        try
            loadedStruct = load(fileName);
            
            % Check version
            try
                currentVersion = obj.version;
                fileVersion = loadedStruct.version;
                
                assert(isequal(currentVersion, fileVersion), 'AbstractModel:VersionMismatch', 'Warning, loaded file is from a different qMRLab version. Abort.')
            catch ME
                error(ME.identifier, ME.message)
            end
            
            
            objectProperties = properties(obj);

            %Loop through all object properties
            for propIndex = 1:length(objectProperties)
                
                % Assign object property value to identically named struct field.
                obj.(objectProperties{propIndex}) = loadedStruct.(objectProperties{propIndex});
            end
            
        catch ME
        	error(ME.identifier, ME.message)
        end
    end
end

end
