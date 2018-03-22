classdef MethodBrowser
        % MethodBrowser  - Manage fields in the file Browser per methods
        %   P.Beliveau 2017 - setup
        %   * All Methods have in common the WorkDir Button and File Box and
        %       the StudyID file Box
        %   * All other file managements uicontrols are contained in the
        %       ItemsList
    
    properties
        Parent;        
        ItemsList; % is a list of the class BrowserSet objects
        NbItems;
        MethodID = 'unassigned';        
    end
    properties(Hidden = true)
        % common to all methods, work directory and studyID
        WorkDir_TextArea;
        WorkDir_BrowseBtn;
        WorkDir_FileNameArea;
        WorkDir_FullPath;
        StudyID_TextArea;
        StudyID_TextID;
    end
    
    methods
        %------------------------------------------------------------------
        % constructor
        function obj = MethodBrowser(Parent,Model)
            % example: figure(1); clf; MB = MethodBrowser(1,dti); 
            obj.Parent = Parent;
            obj.MethodID = Model.ModelName;
            InputsName = Model.MRIinputs;
            InputsOptional = Model.get_MRIinputs_optional;
            try
            header = iqmr_header.header_parse(which(Model.ModelName));
            catch
                header.input = {''};
            end
            if isempty(header.input), header.input = {''}; end
                
            Location = [0.02, 0.7];
            
            obj.NbItems = size(InputsName,2);
            
            obj.ItemsList = repmat(BrowserSet(),1,obj.NbItems);
            
            for ii=1:obj.NbItems
                headerii = strcmp(header.input(:,1),InputsName{ii}) | strcmp(header.input(:,1),['(' InputsName{ii} ')']);
                if max(headerii), headerii = header.input{find(headerii,1,'first'),2}; else, headerii=''; end
                obj.ItemsList(ii) = BrowserSet(obj.Parent, InputsName{ii}, InputsOptional(ii), Location, headerii);
                Location = Location + [0.0, -0.15];
            end
            
            % setup work directory and study ID display
            obj.WorkDir_FullPath = '';
            obj.WorkDir_TextArea = uicontrol(obj.Parent, 'Style', 'Text', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Work Dir:', 'HorizontalAlignment', 'left', 'Position', [0.02,0.85,0.1,0.1],'FontSize', 0.6);
            obj.WorkDir_FileNameArea = uicontrol(obj.Parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized', 'Position', [0.22,0.85,0.3,0.1],'FontSize', 0.6);
            obj.WorkDir_BrowseBtn = uicontrol(obj.Parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Browse', 'Position', [0.11,0.85,0.1,0.1], 'FontSize', 0.6, ...
                'Callback', {@(src, event)MethodBrowser.WD_BrowseBtn_callback(obj)});
            obj.StudyID_TextArea = uicontrol(obj.Parent, 'Style', 'text', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Study ID:', 'Position', [0.55,0.85,0.1,0.1], 'FontSize', 0.6);
            obj.StudyID_TextID = uicontrol(obj.Parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized', 'Position', [0.65,0.85,0.3,0.1],'FontSize', 0.6);
        end % end constructor
                  
        %------------------------------------------------------------------
        % Visible
        function Visible(obj, Visibility)
            for i=1:obj.NbItems
                obj.ItemsList(i).Visible(Visibility);
            end
            set(obj.WorkDir_BrowseBtn, 'Visible', Visibility); 
            set(obj.WorkDir_TextArea, 'Visible', Visibility);
            set(obj.WorkDir_BrowseBtn, 'Visible', Visibility);
            set(obj.WorkDir_FileNameArea, 'Visible', Visibility);
            set(obj.StudyID_TextArea, 'Visible', Visibility);
            set(obj.StudyID_TextID, 'Visible', Visibility);            
        end
        
        %------------------------------------------------------------------
        % IsMethod
        function Res = IsMethodID(obj, NameID)
            if strcmp(obj.MethodID, NameID)
                Res = 1;
            else
                Res = 0;
            end
        end
        
        %------------------------------------------------------------------
        % GetMethod
        function Res = GetMethod(obj)
            Res = obj.MethodID;
        end
        
        %------------------------------------------------------------------
        % DataLoad - load the images using setappdata
        function DataLoad(obj)
            for i=1:obj.NbItems
                obj.ItemsList(i).DataLoad;
            end
        end
        
        %------------------------------------------------------------------
        % SetFullPath
        function setFullPath(obj)
            Path = obj.WorkDir_FullPath;
            if Path == 0
                errordlg('Invalid path');
                Path = '';
                return;
            end
            dirData = dir(Path);
            dirIndex = [dirData.isdir];
            fileList = {dirData(~dirIndex).name}';
            
            % manage protocol and fit options
            Method = getappdata(0,'Method');
            for i = 1:length(fileList)
                if ~~strfind(fileList{i}, 'Protocol')
                    ProtLoad(fullfile(Path,fileList{i}));
                    Model = getappdata(0,'Model');
                    Custom_OptionsGUI(Model, gcf);
                end
            end
            
            % clear previous data
            if isappdata(0,'Data')
                rmappdata(0,'Data'); 
            end
            
            % Manage each data items
            for i=1:obj.NbItems
                obj.ItemsList(i).setPath(Path, fileList);
            end
        end % end SetFullPath
        
        
        %------------------------------------------------------------------
        % get working directory name
        function WD = getWD(obj)
            WD = get(obj.WorkDir_FileNameArea, 'String');
        end
        
        %------------------------------------------------------------------
        % get working directory name
        function WD = setWD(obj,WD)
            obj.WD_BrowseBtn_callback(obj,WD)
        end
        
        %------------------------------------------------------------------
        % get study ID name
        function StudyID = getStudyID(obj)
            StudyID = '';
            obj.StudyID_TextID = get(obj.StudyID_TextID, 'String');
            StudyID = obj.StudyID_TextID;
        end
        
                %------------------------------------------------------------------
        % get study ID name
        function setStudyID(obj,StudyID)
            set(obj.StudyID_TextID, 'String',StudyID);
        end

        %------------------------------------------------------------------
        % getFileName
        % get the filename for the specified ID data
        function FileName = getFileName(obj)
            for i=1:obj.NbItems
                fN = get(obj.ItemsList(i).NameText,'String');
                FileName.(fN{1}) = obj.ItemsList(i).GetFileName;
            end
        end
        
        %------------------------------------------------------------------
        % setFileName
        % set the filename
        function setFileName(obj,fieldName, FileName)
            % setFileName(obj,fieldName, FileName)
            list_file = get([obj.ItemsList.NameText]','String');
            if iscell(list_file{1}), list_file = cellfun(@(c) c{1}, list_file,'UniformOutput',0); end
            indexfieldName = strcmp(list_file,fieldName);
            if sum(indexfieldName)
                obj.ItemsList(indexfieldName).BrowseBtn_callback(obj.ItemsList(indexfieldName),FileName)
            end
        end

        
               
    end
    

    methods(Static)
        %------------------------------------------------------------------
        % -- WD_BrowseBtn_callback
        %   Callback function for the working directory
        function WD_BrowseBtn_callback(obj, WorkDir_FullPath)
            if ~exist('WorkDir_FullPath','var')
                WorkDir_FullPath = uigetdir;
            end
            
            if WorkDir_FullPath == 0
                errordlg('Invalid path');
                return;
            end
            
            obj.WorkDir_FullPath = WorkDir_FullPath;
            set(obj.WorkDir_FileNameArea,'String',obj.WorkDir_FullPath);
            obj.setFullPath();
            
        end
    end
    
end

