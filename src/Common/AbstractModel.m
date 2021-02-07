
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

    properties (Hidden=true)
        EnvDetails
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

                save([strrep(regexprep(suffix,'.qmrlab.mat','','ignorecase'),'.mat','') '.qmrlab.mat'], '-struct', 'objStruct');

                if moxunit_util_platform_is_octave

                 save('-mat7-binary', [strrep(regexprep(suffix,'.qmrlab.mat','','ignorecase'),'.mat','') '.qmrlab.mat'], '-struct' ,'objStruct');
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

           for brkloop=1:1 % allow break
           %if data is empty
           if isempty(MRIinputs)
               txt=strcat('No input data provided');
               ErrMsg = txt; break
           end
           %if required number of inputs
           optionalInputs = obj.get_MRIinputs_optional;
           for ii=1:length(optionalInputs)
               if ~optionalInputs(ii) %if it's required input
                   if(~any(strcmp(obj.MRIinputs{ii},MRIinputs')) || ~isfield(data,obj.MRIinputs{ii}) || isempty(data.(obj.MRIinputs{ii})))
                       txt=['Cannot find required input called '  obj.MRIinputs{ii}];
                       ErrMsg = txt; break
                   end
               end
           end
           if ~isempty(ErrMsg), break; end
           
           if ~optionalInputs(1)
           % For some models e.g. MP2RAGE, first input can be optional
           % as well. This error should not be thrown in such cases.
           % check if all input data is sampled the same as qData input
           qDataIdx=find((strcmp(obj.MRIinputs{1},MRIinputs')));
           qData = double(data.(MRIinputs{qDataIdx}));
           x = 1; y = 1; z = 1;
           [x,y,z,nT] = size(qData);
           for ii=1:length(MRIinputs)
               if (~isempty(data.(MRIinputs{ii})) && ii ~= qDataIdx) %not empty and not the qData
                   [x_,y_,z_,t_]=size(data.(MRIinputs{ii}));
                   if(x_~=x || z_~=z || z_~=z)
                       txt=['Inputs not sampled the same way:' sprintf('\n') MRIinputs{qDataIdx} ' is ' num2str(x)  'x'  num2str(y)  'x'  num2str(z)  'x'  num2str(nT)  '.' sprintf('\n')  MRIinputs{ii}   ' input is  '  num2str(x_)  'x'  num2str(y_)  'x'  num2str(z_)];
                       ErrMsg = txt; break
                   end
               end
           end
           end
           
           if ~isempty(ErrMsg), break; end

           % check if protocol matches data
           if ~isempty(obj.Prot)
               if isfield(obj.Prot,obj.MRIinputs{1})
                   nR = size(obj.Prot.(obj.MRIinputs{1}).Mat,1);
                   if (nT ~= size(obj.Prot.(obj.MRIinputs{1}).Mat,1) && ~isempty(obj.Prot))
                       txt=['Protocol has: ' num2str(nR) ' rows. And input volume ' obj.MRIinputs{1} ' has ' num2str(nT)  ' frames'];
                       ErrMsg = txt; break
                   end
               end
           end
           end
           % error if no output
           if nargout==0 && ~isempty(ErrMsg)
               if moxunit_util_platform_is_octave
                   errordlg(ErrMsg,'Input Error');
               else
                   Mode = struct('WindowStyle','modal','Interpreter','tex');
                   errordlg(ErrMsg,'Input Error', Mode);
                   error(ErrMsg);
               end
           end
        end
        function optionalInputs = get_MRIinputs_optional(obj)
            % Optional input? Search in help
            optionalInputs = zeros(1,length(obj.MRIinputs));
            hlptxt = qMRinfo(obj.ModelName);
            for ii = 1:length(obj.MRIinputs)
                if ~isempty(strfind(hlptxt,char(['(' obj.MRIinputs{ii} ')'])))
                    optionalInputs(ii)=1;
                end
                if ~isempty(strfind(hlptxt,char(['((' obj.MRIinputs{ii} '))'])))
                    optionalInputs(ii)=2;
                end
            end
        end
           
    end

    methods(Access = protected)

        function obj = qMRpatch(obj,loadedStruct, version)
        % This function is to xxx
            objStruct = objProps2struct(obj);
            objectProperties = fieldnames(objStruct);
            %Loop through all object properties
            for propIndex = 1:length(objectProperties)
                  
                % Assign object property value to identically named struct field.
                if ismember(objectProperties{propIndex},fieldnames(loadedStruct))
                obj.(objectProperties{propIndex}) = loadedStruct.(objectProperties{propIndex});
                end
           
            end

        end

        function idx = getButtonIdx(obj,buttonName)
        % This function returns obj.buttons index of the buttonName.
        % All prepended jokers must be included to this list.
        % Jokers should also be added to the src/Common/tools/genvarname_v2.m

            idx = find(strcmp(obj.buttons,buttonName) | strcmp(obj.buttons,['##' buttonName]) | ...
                strcmp(obj.buttons,['**' buttonName]));


        end

        function obj = setButtonInvisible(obj,buttonName,state)
        % This function is to show/hide an UIObject associated with buttonName.
        %
        % Hiding a UIObject that is not scoped by a frame is performed by
        % prepending *** joker to its corresponding buttonName. For details,
        % please see src/Common/tools/GenerateButtonsWithPanels.m.
        %
        % Hide UIObject: Assign state variable with true
        % Show UIObject: Assign state variable with false

            idx = getButtonIdx(obj,buttonName);

            if state

                % There may be an attempt to sth
                obj.buttons{idx} = ['**' buttonName];

            elseif not(state) && strcmp(obj.buttons{idx}(1:2),'**')

                obj.buttons{idx} = buttonName;

            end

        end

        function obj = setButtonDisabled(obj,buttonName,state)
          % This function is to disable/enable an UIObject associated with buttonName.
          %
          % Disabling a UIObject that is not scoped by a frame is performed by
          % prepending ### joker to its corresponding buttonName. For details,
          % please see src/Common/tools/GenerateButtonsWithPanels.m.
          %
          % Disable UIObject: Assign state variable with true
          % Enable UIObject: Assign state variable with false

            idx = getButtonIdx(obj,buttonName);

            if state && not(strcmp(obj.buttons{idx}(1:2),'##'))

                obj.buttons{idx} = ['##' buttonName];

            elseif not(state) && strcmp(obj.buttons{idx}(1:2),'##')

                obj.buttons{idx} = buttonName;

            end

        end

        function obj = setPanelInvisible(obj,panelName,state)
        % This function is to disable/enable a panel that contians multiple UIObjects.
        %
        % Disabling a panel is performed by prepending ### joker to panelName
        % For details, please see src/Common/tools/GenerateButtonsWithPanels.m.
        %
        % Hide panel: Assign state variable with true
        % Show panel: Assign state variable with false

            idx = getButtonIdx(obj,panelName);

            if not(strcmp(obj.buttons{idx-1},'PANEL'))
                error(['panelName passed to the setPanelInvisible function' ...
                    ' does not correspond to a panel']);
            end

            if state

                obj.buttons{idx} = ['##' panelName];

            elseif not(state) && strcmp(obj.buttons{idx}(1:2),'##')

                obj.buttons{idx} = panelName;

            end

        end

        function obj = linkGUIState(obj, checkBoxName, targetObject, eventType, activeState, setVal)
        % This function to link behaviour of a target UIObject to a checkbox state.
        % checkBoxName and the targetObject vars must use respective buttonNames.
        % targetObject can be any button. checkBoxName: only chechboxes.
        %
        % eventType is one of the following:
        %   enable_disable_button
        %   show_hide_button
        %   show_hide_panel
        %
        % Set activeState to 'active_0' if you'd like to trigger disable/hide
        % on checking checkbox. Set it to 'active_1' if you'd like to trigger enable/show
        % for the targetObject on checking checkbox event.
        % Inverting the checkbox state will invert target behaviour.
        % Pay attention to the order of linkGUIState functions to ensure desired
        % dynamic behaviour persists.
        %
        % setVal is to assign an UIObject with a desired value before disabling it.
        % For example, a target may needed to be checked before being disabled:
        % obj = linkGUIState(obj, 'Split-Bregman', 'L1 Regularized', 'enable_disable_button', 'active_0', true);
        % Note that targetObject is a checkbox in this example.

            switch activeState

                case 'active_1'
                    x = false;
                    y = true;
                case 'active_0'
                    x = true;
                    y = false;
            end

            [opNameCheckbox, typeCheckBox] = getOptionsFieldName(obj,checkBoxName);
            [opNameTarget, typeTarget] = getOptionsFieldName(obj,targetObject);

            if not(strcmp(typeCheckBox,'checkbox'))
                error('LinkGUIState: Second argument must be a checkbox');
            end

            switch eventType

                case 'enable_disable_button'

                    if obj.options.(opNameCheckbox)

                      if nargin == 6

                          obj = setValAssign(obj,opNameTarget,typeTarget,setVal);

                      end

                      obj =  setButtonDisabled(obj,targetObject,x);

                    else

                        obj =  setButtonDisabled(obj,targetObject,y);

                    end

                case 'show_hide_button'

                    if obj.options.(opNameCheckbox)

                        obj =  setButtonInvisible(obj,targetObject,x);

                    else

                        obj =  setButtonInvisible(obj,targetObject,y);

                    end

                case 'show_hide_panel'

                    if obj.options.(opNameCheckbox)

                        obj =  setPanelInvisible(obj,targetObject,x);

                    else

                        obj =  setPanelInvisible(obj,targetObject,y);

                    end
            end

        end

        function [opName, type] = getOptionsFieldName(obj,buttonName)
        % buttonNames are changed to obtain option field names that lives
        % obj.options.(here). This function is to get corresponding options
        % name for a given buttonName.

            varName = genvarname_v2(buttonName);

            opts = button2opts(obj.buttons);
            opNames = fieldnames(opts);

            varIdx = find(cellfun(@(x)~isempty(strfind(x,varName)), opNames));
            opName = opNames{varIdx};

            idx = getButtonIdx(obj,buttonName);
            val = obj.buttons{idx+1};
            ln = length(val);

            if islogical(val)

                type = 'checkbox';

            elseif isnumeric(val) && ln == 1

                type = 'singleNum';

            elseif isnumeric(val) && ln > 1

                type = 'table';

            elseif iscell(val)

                type = 'popupmenu';

            end

        end

        function obj = setValAssign(obj,opNameTarget,typeTarget,setVal)
        % Subfunction of LinkGUIState to assign a targetObject value.

                try

                    obj.options.(opNameTarget) = setVal;

                catch

                if strcmp(typeTarget,'checkbox') && not(islogical(setVal))
                    error('setVal to a checkbox targetObject must be logical');
                end

                if strcmp(typeTarget,'singleNum') && length(setVal)>1
                    error('Target object expects a single value.');
                end

                if strcmp(typeTarget,'popupmenu') && not(iscell(setVal))
                    error('Target object expects type cell.');
                end

                if strcmp(typeTarget,'table') && length(setVal) == 1
                    error('Target object expects an array.');
                end

                end

        end

        function state = getCheckBoxState(obj,checkBoxName)

        [opName, type] = getOptionsFieldName(obj,checkBoxName);
        state = obj.options.(opName);

        if not(strcmp(type,'checkbox'))
          error('Pass checknoxname please.');
        end

        end

    end

    methods(Static)

        function FitProvenance = getProvenance(varargin)
            
            FitProvenance = struct();
            FitProvenance.EstimationSoftwareName = 'qMRLab';
            FitProvenance.EstimationSoftwareVer  = qMRLabVer;
            % Add extra fields
            if nargin>0
                if any(cellfun(@isequal,varargin,repmat({'extra'},size(varargin))))
                    idx = find(cellfun(@isequal,varargin,repmat({'extra'},size(varargin)))==1);
                    if isstruct(varargin{idx+1})
                        tmp = varargin{idx+1};
                        names = fieldnames(tmp);
                        for ii=1:length(names) 
                            FitProvenance.(names{ii}) = tmp.(names{ii});
                        end
                    end    
                end
            end 

            if moxunit_util_platform_is_octave
                
                FitProvenance.EstimationDate = strftime('%Y-%m-%d %H:%M:%S', localtime (time ()));
                [FitProvenance.EstimationSoftwareEnv, FitProvenance.MaxSize, FitProvenance.Endian] = computer;
                FitProvenance.EstimationSoftwareEnvDetails = GetOSDetails();
                FitProvenance.EstimationSoftwareLang = ['Octave ' OCTAVE_VERSION()];
                Fitprovenance.EstimationSoftwareLangDetails = pkg('list');

            else 

                FitProvenance.EstimationDate = datetime(now,'ConvertFrom','datenum');
                [FitProvenance.EstimationSoftwareEnv, FitProvenance.MaxSize, FitProvenance.Endian] = computer; 
                FitProvenance.EstimationSoftwareEnvDetails = GetOSDetails();
                FitProvenance.EstimationSoftwareLang = ['Matlab ' version('-release')];
                FitProvenance.EstimationSoftwareLangDetails = ver;

            end
            
        end    

        function URL = getLink(urlFull,urlPartial,docException)
              
             if ~isempty(getenv('ISCITEST')) && str2double(getenv('ISCITEST'))
                URL = urlPartial;
              else
                URL  = urlFull;
            end

            if exist('docException','var') &&  ~isempty(str2double(getenv('ISDOC')))
                try
                    URL = docException;
                catch
                    URL = urlPartial;
                end
            end

        end

    end

end
