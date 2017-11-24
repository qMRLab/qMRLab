classdef (Abstract) AbstractModel
% AbstractModel:  Properties/Methods shared between all models.
%
%   *Methods*
%   save: save model to a file as an object variable.
%   load: load model from a file as an object variable.
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
            save(fileName, 'obj', '-mat');
        catch ME
            error(ME.identifier, ME.message)
        end
    end
    
    function loadObj(obj, fileName)
        try
            tmp = load(fileName, '-mat');
            obj = tmp.obj;
        catch ME
        	error(ME.identifier, ME.message)
        end
    end
end

end
