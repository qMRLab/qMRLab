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
        InfoBtnWD;
        WorkDir_TextArea;
        WorkDir_BrowseBtn;
        WorkDir_FileNameArea;
        WorkDir_FullPath;
        StudyID_TextArea;
        StudyID_TextID;
        DownloadBtn;
        WarnBut_DataConsistensy;
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
            header = iqmr_header.header_parse(which(Model.ModelName));
            if isempty(header.input), header.input = {''}; end
            
            Location = [0.02, 0.7];
            
            obj.NbItems = size(InputsName,2);
            
            obj.ItemsList = repmat(BrowserSet(),1,obj.NbItems);
            
            for ii=1:obj.NbItems
                headerii = strcmp(header.input(:,1),InputsName{ii}) | strcmp(header.input(:,1),['(' InputsName{ii} ')']) | strcmp(header.input(:,1),['((' InputsName{ii} '))']);
                if max(headerii), headerii = header.input{find(headerii,1,'first'),2}; else, headerii=''; end
                obj.ItemsList(ii) = BrowserSet(obj.Parent, InputsName{ii}, InputsOptional(ii), Location, headerii);
                Location = Location + [0.0, -0.15];
            end
            
            % ADD WARNING BUTTON
            obj.WarnBut_DataConsistensy = uicontrol(obj.Parent, 'Style', 'Text','units', 'normalized','BackgroundColor',[0.94 0.94 0.94],'ForegroundColor',[1 0 0],'FontSize',10,...
                'Position', [0,0,1,0.08], 'Tag', ['WarnBut_DataConsistency_' class(Model)]);
            
            % setup work directory and study ID display
            Info = {'1. Path to data (Optional): ',...
                '    FitResults will be saved to this directory',...
                ['    Default: ' pwd],...
                '',...
                '    The files (.nii, .nii.gz, .mat) containing the following pattern in their name will be loaded automatically (Case Sensitive):',...
                sprintf('    -  *%s*\n',Model.MRIinputs{:}),...
                '',...
                '2. Study ID (Optional):',...
                '    Suffix for the FitResults file'};
            Info = sprintf('%s\n',Info{:});
            obj.InfoBtnWD = uicontrol(obj.Parent, 'Style', 'pushbutton', 'units', 'normalized','BackgroundColor',[0.94 0.94 0.94], ...
                'String', '?','FontWeight','bold','TooltipString',sprintf('%s\n',Info),'Position',[0.02,0.85,0.02,0.1],'Callback',@(hObj,eventdata,handles) helpdlg(Info));
            obj.WorkDir_FullPath = '';
            obj.WorkDir_TextArea = uicontrol(obj.Parent, 'Style', 'Text', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Path data:', 'HorizontalAlignment', 'left', 'Position', [0.05,0.85,0.1,0.1],'FontSize', 0.6);
            obj.WorkDir_FileNameArea = uicontrol(obj.Parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized',...
                'Position', [0.27,0.85,0.3,0.1],'FontSize', 0.6);
            obj.WorkDir_BrowseBtn = uicontrol(obj.Parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Browse', 'Position', [0.16,0.85,0.1,0.1], 'FontSize', 0.6, ...
                'Callback', {@(src, event) WD_BrowseBtn_callback(obj)});
            obj.StudyID_TextArea = uicontrol(obj.Parent, 'Style', 'text', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Study ID:', 'Position', [0.58,0.85,0.1,0.1], 'FontSize', 0.6);
            obj.StudyID_TextID = uicontrol(obj.Parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized',...
                'Position', [0.69,0.85,0.10,0.1],'FontSize', 0.6);
            obj.DownloadBtn = uicontrol(obj.Parent, 'Style', 'pushbutton','units', 'normalized', 'fontunits', 'normalized',...
                'Position', [0.80,0.85,0.19,0.10],'FontSize', 0.6, 'String', 'Download example', 'BackGroundColor', [0, 0.65, 1],  ...
                'Callback', {@(src, event) DownloadBtn_callback(obj)});
        end % end constructor
        
        %------------------------------------------------------------------
        % Visible
        function Visible(obj, Visibility)
            for i=1:obj.NbItems
                obj.ItemsList(i).Visible(Visibility);
            end
            set(obj.InfoBtnWD, 'Visible', Visibility);
            set(obj.WorkDir_BrowseBtn, 'Visible', Visibility);
            set(obj.WorkDir_TextArea, 'Visible', Visibility);
            set(obj.WorkDir_BrowseBtn, 'Visible', Visibility);
            set(obj.WorkDir_FileNameArea, 'Visible', Visibility);
            set(obj.StudyID_TextArea, 'Visible', Visibility);
            set(obj.StudyID_TextID, 'Visible', Visibility);
            set(obj.DownloadBtn, 'Visible', Visibility);
            % Warning button is unvisible if no warning
            if isempty(get(obj.WarnBut_DataConsistensy,'TooltipString')), Visibility = 'off'; end
            set(obj.WarnBut_DataConsistensy, 'Visible', Visibility);
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
            for ii = 1:length(fileList)
                if ~~strfind(fileList{ii}, 'Protocol')
                    ProtLoad(fullfile(Path,fileList{ii}));
                    Model = getappdata(0,'Model');
                    Custom_OptionsGUI(Model, gcf);
                end
            end
            
            % clear previous data
            Data = getappdata(0,'Data');
            if isfield(Data,Method)
                fields = fieldnames(Data.(Method));
                for ff=1:length(fields)
                    Data.(Method).(fields{ff})=[];
                end
            end
            if isfield(Data,[Method '_hdr'])
                Data = rmfield(Data,[Method '_hdr']);
            end
            setappdata(0,'Data',Data);
            
            Model = getappdata(0,'Model');
            
            % TODO:
            if not(isfield(Model.options,'BIDS'))
                % Manage each data items
                for ii=1:obj.NbItems
                    obj.ItemsList(ii).setPath(Path, fileList,0);
                end
                
            else
            
            if Model.options.BIDS    
              disp('Looking for BIDS');  
            else
              disp('Annoying function goes here');  
            end
            
            end
            
            % warning
            Data = getappdata(0, 'Data');
            ErrMsg = Model.sanityCheck(Data.(class(Model)));
            hWarnBut = findobj(obj.Parent,'Tag',['WarnBut_DataConsistency_' class(Model)]);
            if ~isempty(ErrMsg)
                set(hWarnBut,'String',ErrMsg)
                set(hWarnBut,'TooltipString',ErrMsg)
                set(hWarnBut,'Visible','on')
            else
                set(hWarnBut,'String','')
                set(hWarnBut,'TooltipString','')
                set(hWarnBut,'Visible','off')
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
            obj.WD_BrowseBtn_callback(WD)
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
        
        
        
        
        
        
        %------------------------------------------------------------------
        % -- WD_BrowseBtn_callback
        %   Callback function for the working directory
        function WD_BrowseBtn_callback(obj, WorkDir_FullPath)
            if ~exist('WorkDir_FullPath','var')
                WorkDir_FullPath = uigetdir;
                assignin('base','DataPath',WorkDir_FullPath);
            end
            
            if WorkDir_FullPath == 0
                set(obj.WorkDir_FileNameArea,'String','');
                warndlg(['Current folder is set to: ' pwd]);
                return;
            end
            
            obj.WorkDir_FullPath = WorkDir_FullPath;
            set(obj.WorkDir_FileNameArea,'String',obj.WorkDir_FullPath);
            obj.setFullPath();
            
        end
        
        function DownloadBtn_callback(obj)
            set(findobj('Name','qMRLab'),'pointer', 'watch')
            Model = getappdata(0,'Model');
            qMRgenBatch(Model);
            WD_BrowseBtn_callback(obj, [pwd filesep  Model.ModelName '_data']);
            set(findobj('Name','qMRLab'),'pointer', 'arrow')

        end
        
    end
    
    
end
