
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
                objStruct = objProps2struct(obj);
                
                save([regexprep(regexprep(suffix,'.qmrlab.mat','','ignorecase'),'.mat','','ignorecase') '.qmrlab.mat'], '-struct', 'objStruct');
                
                if moxunit_util_platform_is_octave
          
                 save('-mat7-binary', [regexprep(regexprep(suffix,'.qmrlab.mat','','ignorecase'),'.mat','','ignorecase') '.qmrlab.mat'], '-struct' ,'objStruct');
                end
                
                
            catch ME
                error(ME.identifier, [class(obj) ':' ME.message])
            end
        end
        
        function obj = loadObj(obj, fileName)
            try
                if isstruct(fileName) % load a structure
                    loadedStruct = fileName;
                else % load from a file
                    loadedStruct = load(fileName);
                end
                % parse structure to object
                obj = qMRpatch(obj,loadedStruct,loadedStruct.version);
                
            catch ME
                error(ME.identifier, [class(obj) ':' ME.message])
            end
        end
        
        % Do some error checking
        function sanityCheck(obj,data)
           % check if all necessary inputs are present
           
           % check if all input data is sampled the same way
           MRIinputs = fieldnames(data);
           MRIinputs(structfun(@isempty,data))=[];
           MRIinputs(strcmp(MRIinputs,'hdr'))=[];
           qData = double(data.(MRIinputs{1}));
           x = 1; y = 1; z = 1;
           [x,y,z,nT] = size(qData);
           
           % check if protocol matched data
        end
    end
    

    
    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            objStruct = objProps2struct(obj);
            objectProperties = fieldnames(objStruct);
            %Loop through all object properties
            for propIndex = 1:length(objectProperties)
                
                % Assign object property value to identically named struct field.
                obj.(objectProperties{propIndex}) = loadedStruct.(objectProperties{propIndex});
            end
            
        end
    end
    
end
