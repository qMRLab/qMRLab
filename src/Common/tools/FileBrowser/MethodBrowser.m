classdef MethodBrowser < handle
    % MethodBrowser  - App Designer version of MethodBrowser
    %   Manages file browser fields per method in App Designer
    
    properties
        Grid;   % the per-model uigridlayout that fills the Datasets panel
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
    
    properties (Constant)
        ROWHEIGHT = 22;   % px, one input row
        ROWGAP    = 6;    % px between rows
        PADDING   = 8;    % px around the whole block
    end

    methods (Static)
        function h = heightFor(nItems)
            % Pixel height this browser needs: a header row plus one row per input,
            % plus the warning line. MainApp sizes the Datasets row of its grid from
            % this, so the panel fits the ACTIVE model rather than the tallest one --
            % every model's browser is built once and kept, so a 'fit' row would
            % otherwise size to whichever model has the most inputs.
            % Named directly, not through a local alias: MethodBrowser is a handle
            % class whose constructor takes (Parent, Model), so `C = MethodBrowser`
            % is a constructor call, not a way to reach the constants.
            % Rows are 'fit', so they grow with the text size; scale the estimate the
            % same way or the panel track stays sized for medium text and the browser
            % scrolls when it did not need to.
            g = 1;
            try, g = qmrlab.gui.TypeScale.geomFactor(); catch, end
            h = 2*MethodBrowser.PADDING ...
                + (nItems + 1) * MethodBrowser.ROWHEIGHT * g ...
                + (nItems + 1) * MethodBrowser.ROWGAP + 18*g;
        end
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
            
            obj.NbItems = length(InputsName);
            obj.ItemsList = BrowserSet.empty(0, obj.NbItems);  % Pre-allocate empty array

            % Stage E2. One grid per model, filling the Datasets panel; only the
            % active model's grid is Visible. Several such grids coexist as siblings
            % in the panel and overlap rather than sharing space, so hiding the others
            % costs nothing -- measured on R2026b.
            %
            % This replaces a block of normalized arithmetic (ROWPITCH / HEADERNORM /
            % MINBOTTOM / contentTopFor) that existed only to keep the last input row
            % from landing at a negative y. Rows cannot collide with a grid, so that
            % whole computation is gone rather than ported.
            obj.Grid = uigridlayout(Parent, [obj.NbItems + 2, 1]);
            % 'fit' rows too: a row is as tall as its text needs. ROWHEIGHT survives
            % only as the estimate heightFor() gives MainApp for the panel track.
            obj.Grid.RowHeight     = [repmat({'fit'}, 1, obj.NbItems + 1), {'fit'}];
            obj.Grid.ColumnWidth   = {'1x'};
            obj.Grid.Padding       = repmat(MethodBrowser.PADDING, 1, 4);
            obj.Grid.RowSpacing    = MethodBrowser.ROWGAP;
            obj.Grid.Scrollable    = 'on';   % backstop: a short window scrolls, never clips

            obj.createCommonComponents(Model, header);

            for ii = 1:obj.NbItems
                headerii = strcmp(header.input(:,1), InputsName{ii}) | ...
                          strcmp(header.input(:,1), ['(' InputsName{ii} ')']) | ...
                          strcmp(header.input(:,1), ['((' InputsName{ii} '))']);
                if any(headerii)
                    headerii = header.input{find(headerii,1,'first'),2};
                else
                    headerii = '';
                end
                row = uigridlayout(obj.Grid, [1 6]);
                row.Layout.Row = ii + 1;
                row.Layout.Column = 1;
                obj.ItemsList(ii) = BrowserSet(row, InputsName{ii}, InputsOptional(ii), headerii);
            end
            
            % Create warning label.
            %
            % The Tag is load-bearing, not decoration: BrowserSet.DataLoad reaches
            % this label by findobj on exactly this name, and one label exists per
            % model in the shared Datasets panel, so the model class is what makes
            % it unique. Without it every single-file load threw.
            obj.WarnBut_DataConsistency = uilabel(obj.Grid);
            obj.WarnBut_DataConsistency.Layout.Row = obj.NbItems + 2;
            obj.WarnBut_DataConsistency.Layout.Column = 1;
            obj.WarnBut_DataConsistency.Tag = ['WarnBut_DataConsistency_' class(Model)];
            obj.WarnBut_DataConsistency.FontColor = qmrlabUIColor('warning');
            obj.WarnBut_DataConsistency.FontSize = 10;
            obj.WarnBut_DataConsistency.Visible = 'off';
            obj.WarnBut_DataConsistency.Text = '';
        end
        
        %------------------------------------------------------------------
        % Create common components (Work Dir, Study ID, etc.)
        function createCommonComponents(obj, Model, header)
            % The header row: work directory, study ID, and the example download.
            % Widths, not offsets -- the path box is the '1x' that absorbs a wider
            % window. The old version measured the panel and placed each control at a
            % fixed x, so "Browse" and "Download example" clipped as soon as the text
            % size went up. That clipping is what gated TypeScale's 'large' step.
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

            head = uigridlayout(obj.Grid, [1 7]);
            head.Layout.Row = 1;
            head.Layout.Column = 1;
            % 'fit' rather than fixed widths: a fit column sizes itself to the text
            % it holds, so it grows with the text size instead of clipping it. Fixed
            % 60/90/130 columns were what truncated "Study ID:" to "Study ..." and
            % "Download example" to "Download exampl" at the 1.25 step. The path box
            % keeps '1x' and absorbs whatever is left.
            head.ColumnWidth   = {'fit', 'fit', 'fit', '1x', 'fit', 'fit', 'fit'};
            head.RowHeight     = {22};
            head.Padding       = [0 0 0 0];
            head.ColumnSpacing = 4;

            obj.InfoBtnWD = uibutton(head, 'push');
            obj.InfoBtnWD.Layout.Column = 1;
            obj.InfoBtnWD.Text = '?';
            obj.InfoBtnWD.FontWeight = 'bold';
            obj.InfoBtnWD.Tooltip = InfoText;
            obj.InfoBtnWD.ButtonPushedFcn = @(src,event) helpdlg(InfoText);

            obj.WorkDir_TextArea = uilabel(head);
            obj.WorkDir_TextArea.Layout.Column = 2;
            obj.WorkDir_TextArea.Text = 'Path data:';
            obj.WorkDir_TextArea.HorizontalAlignment = 'left';

            obj.WorkDir_BrowseBtn = uibutton(head, 'push');
            obj.WorkDir_BrowseBtn.Layout.Column = 3;
            obj.WorkDir_BrowseBtn.Text = 'Browse';
            obj.WorkDir_BrowseBtn.ButtonPushedFcn = @(src,event) obj.WD_BrowseBtn_callback();

            obj.WorkDir_FileNameArea = uieditfield(head, 'text');
            obj.WorkDir_FileNameArea.Layout.Column = 4;
            obj.WorkDir_FileNameArea.Value = '';

            obj.StudyID_TextArea = uilabel(head);
            obj.StudyID_TextArea.Layout.Column = 5;
            obj.StudyID_TextArea.Text = 'Study ID:';
            obj.StudyID_TextArea.HorizontalAlignment = 'left';

            obj.StudyID_TextID = uieditfield(head, 'text');
            obj.StudyID_TextID.Layout.Column = 6;
            obj.StudyID_TextID.Value = '';

            obj.DownloadBtn = uibutton(head, 'push');
            obj.DownloadBtn.Layout.Column = 7;
            obj.DownloadBtn.Text = 'Download example';
            obj.DownloadBtn.BackgroundColor = qmrlabUIColor('accent');
            obj.DownloadBtn.FontColor = qmrlabUIColor('onTheAccent');
            obj.DownloadBtn.ButtonPushedFcn = @(src,event) obj.DownloadBtn_callback();
        end

        %------------------------------------------------------------------
        % Visibility control
        function Visible(obj, Visibility)
            % One property on the container. Every widget is inside obj.Grid now, so
            % the fourteen individual Visible assignments this used to make -- which
            % had to be kept in step with the component list by hand -- are gone.
            obj.Grid.Visible = Visibility;

            % The warning is a child of the grid but has its own reason to be hidden:
            % it only shows when there is something to warn about.
            if isempty(obj.WarnBut_DataConsistency.Text)
                obj.WarnBut_DataConsistency.Visible = 'off';
            else
                obj.WarnBut_DataConsistency.Visible = Visibility;
            end
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
                    qmrlab.gui.OptionsWindow(Model, gcf);
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
            ErrMsg = char(Model.sanityCheck(Data.(class(Model))));
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
            % Set cursor to watch. onCleanup guarantees the pointer is restored
            % even if the download throws (#536).
            set(findobj('Name','qMRLab'),'pointer', 'watch');
            pointer_restore = onCleanup(@() set(findobj('Name','qMRLab'),'pointer', 'arrow')); %#ok<NASGU>
            
            Model = getappdata(0,'Model');
            qMRgenBatch(Model);
            obj.WD_BrowseBtn_callback([pwd filesep Model.ModelName '_data']);
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