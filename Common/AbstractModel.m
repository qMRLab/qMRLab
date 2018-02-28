
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
        function [ErrMsg]=sanityCheck(obj,data)
           [ErrMsg]=[];
           % check if all necessary inputs are present 
           MRIinputs = fieldnames(data);
           %if data is empty
           if isempty(MRIinputs)
               txt=strcat('No input data provided');
               ErrMsg = txt;
               return
           end
           %if required number of inputs
           optionalInputs = obj.get_MRIinputs_optional;
           for i=1:length(optionalInputs)
               if ~optionalInputs(i) %if it's required input
                   if(~any(strcmp(obj.MRIinputs{i},MRIinputs')) || isempty(data.(MRIinputs{i})))
                       txt=['Cannot find required input called '  obj.MRIinputs{i}];
                       ErrMsg = txt;
                       return
                   end
               end
           end
           % check if all input data is sampled the same as qData input
           qDataIdx=find((strcmp(obj.MRIinputs{1},MRIinputs')));
           qData = double(data.(MRIinputs{qDataIdx}));
           x = 1; y = 1; z = 1;
           [x,y,z,nT] = size(qData);
           for ii=1:length(MRIinputs)
               if (~isempty(data.(MRIinputs{ii})) && ii ~= qDataIdx) %not empty and not the qData
                   [x_,y_,z_]=size(data.(MRIinputs{ii}));
                   if(x_~=x || z_~=z || z_~=z)
                       txt=['Inputs not sampled the same way:' sprintf('\n') MRIinputs{qDataIdx} ' is ' num2str(x)  'x'  num2str(y)  'x'  num2str(z)  'x'  num2str(nT)  '.' sprintf('\n')  MRIinputs{ii}   ' input is  '  num2str(x_)  'x'  num2str(y_)  'x'  num2str(z_)];
                       ErrMsg = txt;
                       return
                   end
               end
           end
           % check if protocol matches data
           if ~isempty(obj.Prot)
               nR = size(obj.Prot.(obj.MRIinputs{1}).Mat,1);
               if (nT ~= size(obj.Prot.(obj.MRIinputs{1}).Mat,1) && ~isempty(obj.Prot))
                   txt=['Protocol has:' num2str(nR) ' rows. And input volume ' obj.MRIinputs{1} ' has ' num2str(nT)  ' frames'];
                   ErrMsg = txt;
                   return
               end
           end
        end
        
        function optionalInputs = get_MRIinputs_optional(obj)
            % Optional input? Search in help
            optionalInputs = false(1,length(obj.MRIinputs));
            hlptxt = qMRinfo(obj.ModelName);
            for ii = 1:length(obj.MRIinputs)
                if ~isempty(strfind(hlptxt,['(' obj.MRIinputs{ii} ')']))
                    optionalInputs(ii)=true;
                end
            end
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
