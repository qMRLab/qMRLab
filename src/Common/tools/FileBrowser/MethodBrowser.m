classdef MethodBrowser < handle
    % MethodBrowser  - App Designer version of MethodBrowser
    %   Manages file browser fields per method in App Designer
    
    properties
        Parent; % App Designer panel
        ItemsList; % List of BrowserSetAD objects
        NbItems;
        MethodID = 'unassigned';
    end
    
    properties(Access = private)
        % App Designer components
        InfoBtnWD;
        WorkDir_TextArea;
        WorkDir_BrowseBtn;
        WorkDir_FileNameArea;
        StudyID_TextArea;
        StudyID_TextID;
        DownloadBtn;
        WarnBut_DataConsistency;
        
        WorkDir_FullPath = '';
    end
    
    methods
        %------------------------------------------------------------------
        % constructor
        function obj = MethodBrowser(Parent, Model)
            obj.Parent = Parent;
            obj.MethodID = Model.ModelName;
            InputsName = Model.MRIinputs;
            InputsOptional = Model.get_MRIinputs_optional;
            
            % Parse header information
            header = iqmr_header.header_parse(which(Model.ModelName));
            if isempty(header.input), header.input = {''}; end
            
            % Create components
            obj.createCommonComponents(Model, header);
            
            % Create input items
            obj.NbItems = length(InputsName);
            obj.ItemsList = BrowserSet.empty(0, obj.NbItems);  % Pre-allocate empty array
            
            Location = [0.02, 0.7];
            for ii = 1:obj.NbItems
                headerii = strcmp(header.input(:,1), InputsName{ii}) | ...
                          strcmp(header.input(:,1), ['(' InputsName{ii} ')']) | ...
                          strcmp(header.input(:,1), ['((' InputsName{ii} '))']);
                if any(headerii)
                    headerii = header.input{find(headerii,1,'first'),2};
                else
                    headerii = '';
                end
                obj.ItemsList(ii) = BrowserSet(obj.Parent, InputsName{ii}, InputsOptional(ii), Location, headerii);
                Location = Location + [0.0, -0.15];
            end
            
            % Create warning label
            obj.WarnBut_DataConsistency = uilabel(obj.Parent);
            obj.WarnBut_DataConsistency.Position = [10, 10, 500, 30];
            obj.WarnBut_DataConsistency.FontColor = [1, 0, 0];
            obj.WarnBut_DataConsistency.FontSize = 10;
            obj.WarnBut_DataConsistency.Visible = 'off';
            obj.WarnBut_DataConsistency.Text = '';
        end
        
        %------------------------------------------------------------------
        % Create common components (Work Dir, Study ID, etc.)
        function createCommonComponents(obj, Model, header)
            % Get parent container size for proper positioning
            parentPos = obj.Parent.Position; % [x, y, width, height] in pixels
            
            % Calculate positions relative to parent size
            topMargin = parentPos(4) - 60; % Position from top with margin
            
            % Info button for Work Directory
            Info = {'1. Path to data (Optional): ',...
                '    FitResults will be saved to this directory',...
                ['    Default: ' pwd],...
                '',...
                '    The files (.nii, .nii.gz, .mat) containing the following pattern in their name will be loaded automatically (Case Sensitive):',...
                sprintf('    -  *%s*\n',Model.MRIinputs{:}),...
                '',...
                '2. Study ID (Optional):',...
                '    Suffix for the FitResults file'};
            InfoText = sprintf('%s\n',Info{:});
            
            obj.InfoBtnWD = uibutton(obj.Parent, 'push');
            obj.InfoBtnWD.Position = [20, topMargin, 20, 25];
            obj.InfoBtnWD.Text = '?';
            obj.InfoBtnWD.FontWeight = 'bold';
            obj.InfoBtnWD.Tooltip = InfoText;
            obj.InfoBtnWD.ButtonPushedFcn = @(src,event) helpdlg(InfoText);
            obj.InfoBtnWD.Visible = 'on';
            
            % Work Directory components
            obj.WorkDir_TextArea = uilabel(obj.Parent);
            obj.WorkDir_TextArea.Position = [50, topMargin, 80, 25];
            obj.WorkDir_TextArea.Text = 'Path data:';
            obj.WorkDir_TextArea.HorizontalAlignment = 'left';
            obj.WorkDir_TextArea.Visible = 'on';
            
            obj.WorkDir_BrowseBtn = uibutton(obj.Parent, 'push');
            obj.WorkDir_BrowseBtn.Position = [140, topMargin, 60, 25];
            obj.WorkDir_BrowseBtn.Text = 'Browse';
            obj.WorkDir_BrowseBtn.ButtonPushedFcn = @(src,event) obj.WD_BrowseBtn_callback();
            obj.WorkDir_BrowseBtn.Visible = 'on';
            
            obj.WorkDir_FileNameArea = uieditfield(obj.Parent, 'text');
            obj.WorkDir_FileNameArea.Position = [210, topMargin, 200, 25];
            obj.WorkDir_FileNameArea.Value = '';
            obj.WorkDir_FileNameArea.BackgroundColor = [1, 1, 1];
            obj.WorkDir_FileNameArea.FontColor = [0, 0, 0];
            obj.WorkDir_FileNameArea.Visible = 'on';
            
            % Study ID components
            obj.StudyID_TextArea = uilabel(obj.Parent);
            obj.StudyID_TextArea.Position = [420, topMargin, 60, 25];
            obj.StudyID_TextArea.Text = 'Study ID:';
            obj.StudyID_TextArea.HorizontalAlignment = 'left';
            obj.StudyID_TextArea.Visible = 'on';
            
            obj.StudyID_TextID = uieditfield(obj.Parent, 'text');
            obj.StudyID_TextID.Position = [490, topMargin, 80, 25];
            obj.StudyID_TextID.Value = '';
            obj.StudyID_TextID.BackgroundColor = [1, 1, 1];
            obj.StudyID_TextID.FontColor = [0, 0, 0];
            obj.StudyID_TextID.Visible = 'on';
            
            % Download button
            obj.DownloadBtn = uibutton(obj.Parent, 'push');
            obj.DownloadBtn.Position = [580, topMargin, 120, 25];
            obj.DownloadBtn.Text = 'Download example';
            obj.DownloadBtn.BackgroundColor = [0, 0.65, 1];
            obj.DownloadBtn.FontColor = [1, 1, 1];
            obj.DownloadBtn.ButtonPushedFcn = @(src,event) obj.DownloadBtn_callback();
            obj.DownloadBtn.Visible = 'on';
            
            % Force immediate update
            drawnow;
        end
        
        %------------------------------------------------------------------
        % Visibility control
        function Visible(obj, Visibility)
            for i = 1:obj.NbItems
                obj.ItemsList(i).Visible(Visibility);
            end
            
            obj.InfoBtnWD.Visible = Visibility;
            obj.WorkDir_BrowseBtn.Visible = Visibility;
            obj.WorkDir_TextArea.Visible = Visibility;
            obj.WorkDir_FileNameArea.Visible = Visibility;
            obj.StudyID_TextArea.Visible = Visibility;
            obj.StudyID_TextID.Visible = Visibility;
            obj.DownloadBtn.Visible = Visibility;
            
            % Warning label only visible if there's a warning
            if isempty(obj.WarnBut_DataConsistency.Text)
                obj.WarnBut_DataConsistency.Visible = 'off';
            else
                obj.WarnBut_DataConsistency.Visible = Visibility;
            end
            
            % Force refresh
            drawnow;
        end
        
        %------------------------------------------------------------------
        % Check if this browser matches a method ID
        function Res = IsMethodID(obj, NameID)
            Res = strcmp(obj.MethodID, NameID);
        end
        
        %------------------------------------------------------------------
        % Get method ID
        function Res = GetMethod(obj)
            Res = obj.MethodID;
        end
        
        %------------------------------------------------------------------
        % Load data
        function DataLoad(obj)
            for i = 1:obj.NbItems
                obj.ItemsList(i).DataLoad;
            end
        end
        
        %------------------------------------------------------------------
        % Set full path and load files
        function setFullPath(obj)
            Path = obj.WorkDir_FullPath;
            if isequal(Path, 0)
                errordlg('Invalid path');
                Path = '';
                return;
            end
            
            dirData = dir(Path);
            dirIndex = [dirData.isdir];
            fileList = {dirData(~dirIndex).name}';
            
            % Manage protocol and fit options
            Method = getappdata(0,'Method');
            for ii = 1:length(fileList)
                if contains(fileList{ii}, 'Protocol')
                    ProtLoad(fullfile(Path, fileList{ii}));
                    Model = getappdata(0,'Model');
                    Custom_OptionsGUI(Model, gcf);
                end
            end
            
            % Clear previous data
            Data = getappdata(0,'Data');
            if isfield(Data, Method)
                fields = fieldnames(Data.(Method));
                for ff = 1:length(fields)
                    Data.(Method).(fields{ff}) = [];
                end
            end
            if isfield(Data, [Method '_hdr'])
                Data = rmfield(Data, [Method '_hdr']);
            end
            setappdata(0,'Data',Data);
            
            Model = getappdata(0,'Model');
            
            % Manage each data item
            for ii = 1:obj.NbItems
                obj.ItemsList(ii).setPath(Path, fileList, 0);
            end
            
            % Check for warnings
            Data = getappdata(0, 'Data');
            ErrMsg = Model.sanityCheck(Data.(class(Model)));
            if ~isempty(ErrMsg)
                obj.WarnBut_DataConsistency.Text = ErrMsg;
                obj.WarnBut_DataConsistency.Tooltip = ErrMsg;
                obj.WarnBut_DataConsistency.Visible = 'on';
            else
                obj.WarnBut_DataConsistency.Text = '';
                obj.WarnBut_DataConsistency.Tooltip = '';
                obj.WarnBut_DataConsistency.Visible = 'off';
            end
        end
        
        %------------------------------------------------------------------
        % Get working directory
        function WD = getWD(obj)
            WD = obj.WorkDir_FileNameArea.Value;
        end
        
        %------------------------------------------------------------------
        % Set working directory
        function setWD(obj, WD)
            obj.WorkDir_FileNameArea.Value = WD;
            obj.WorkDir_FullPath = WD;
            obj.setFullPath();
        end
        
        %------------------------------------------------------------------
        % Get study ID
        function StudyID = getStudyID(obj)
            StudyID = obj.StudyID_TextID.Value;
        end
        
        %------------------------------------------------------------------
        % Set study ID
        function setStudyID(obj, StudyID)
            obj.StudyID_TextID.Value = StudyID;
        end
        
        %------------------------------------------------------------------
        % Get file names
        function FileName = getFileName(obj)
            for i = 1:obj.NbItems
                fN = obj.ItemsList(i).GetFieldName();
                FileName.(fN) = obj.ItemsList(i).GetFileName();
            end
        end
        
        %------------------------------------------------------------------
        % Set file name
        function setFileName(obj, fieldName, FileName)
            for i = 1:obj.NbItems
                if strcmp(obj.ItemsList(i).GetFieldName(), fieldName)
                    obj.ItemsList(i).SetFileName(FileName);
                    break;
                end
            end
        end
        
        %------------------------------------------------------------------
        % Work Directory Browse callback
        function WD_BrowseBtn_callback(obj, WorkDir_FullPath)
            if ~exist('WorkDir_FullPath','var')
                WorkDir_FullPath = uigetdir;
                assignin('base','DataPath',WorkDir_FullPath);
            end
            
            if WorkDir_FullPath == 0
                obj.WorkDir_FileNameArea.Value = '';
                warndlg(['Current folder is set to: ' pwd]);
                return;
            end
            
            obj.WorkDir_FullPath = WorkDir_FullPath;
            obj.WorkDir_FileNameArea.Value = obj.WorkDir_FullPath;
            obj.setFullPath();
        end
        
        %------------------------------------------------------------------
        % Download example callback
        function DownloadBtn_callback(obj)
            % Set cursor to watch
            set(findobj('Name','qMRLab'),'pointer', 'watch');
            
            Model = getappdata(0,'Model');
            qMRgenBatch(Model);
            obj.WD_BrowseBtn_callback([pwd filesep Model.ModelName '_data']);
            
            % Restore cursor
            set(findobj('Name','qMRLab'),'pointer', 'arrow');
        end
        
        %------------------------------------------------------------------
        % DEBUG: Check component visibility and positions
        function debugComponents(obj)
            fprintf('MethodBrowser debug for %s:\n', obj.MethodID);
            fprintf('Parent panel size: [%d, %d, %d, %d]\n', obj.Parent.Position);
            
            fprintf('WorkDir_FileNameArea - Visible: %s, Position: [%d, %d, %d, %d]\n', ...
                obj.WorkDir_FileNameArea.Visible, obj.WorkDir_FileNameArea.Position);
            fprintf('StudyID_TextID - Visible: %s, Position: [%d, %d, %d, %d]\n', ...
                obj.StudyID_TextID.Visible, obj.StudyID_TextID.Position);
            fprintf('DownloadBtn - Visible: %s, Position: [%d, %d, %d, %d]\n', ...
                obj.DownloadBtn.Visible, obj.DownloadBtn.Position);
            
            for i = 1:obj.NbItems
                fprintf('Item %d (%s):\n', i, obj.ItemsList(i).NameID);
                obj.ItemsList(i).debugVisibility();
            end
        end
    end
end