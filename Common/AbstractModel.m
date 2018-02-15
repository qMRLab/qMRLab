
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
           mode = struct('WindowStyle','modal','Interpreter','tex');
           % check if all necessary inputs are present 
           MRIinputs = fieldnames(data);
           %if data is empty
           if isempty(MRIinputs)
               txt=strcat('No input data provided');
               h = errordlg(txt,'Input Error', mode);
               uiwait(h)
               error('There is no input data')
           end
           %if required number of inputs
           for i=1:length(obj.reqInputs)
               if obj.reqInputs(i) %if it's required input
                   if(~any(strcmp(obj.MRIinputs{i},MRIinputs')))
                       txt=strcat('Cannot find required input called ',cellstr(obj.MRIinputs{i}),'. Your input is ',cellstr(MRIinputs{i}));
                       h = errordlg(txt,'Input Error', mode);
                       uiwait(h)
                       error('The input data is incorrect')
                   end
               end
           end
           % check if all input data is sampled the same as qData input
           qDataIdx=find((strcmp(obj.MRIinputs{1},MRIinputs')));
           qData = double(data.(MRIinputs{qDataIdx}));
           x = 1; y = 1; z = 1;
           [x,y,z,nT] = size(qData);
           for ii=1:length(obj.reqInputs)
               if (ii ~= qDataIdx) %not the qData
                   [x_,y_,z_]=size(data.(MRIinputs{ii}));
                   if(x_~=x || z_~=z || z_~=z)
                       txt=convertStringsToChars("Inputs not sampled the same way:"+newline+cellstr(MRIinputs{qDataIdx})+" is "+num2str(x)+ "x" +num2str(y)+ "x"+ num2str(z)+ "x"+ num2str(nT) +"."+ cellstr(MRIinputs{ii}) + " input is  "+ num2str(x_)+ "x"+ num2str(y_)+ "x" +num2str(z_));
                       h = errordlg(txt,'Input Error', mode);
                       uiwait(h)
                       error('The input data is sampled incorrectly')
                   end
               end
           end
           % check if protocol matches data
           
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
