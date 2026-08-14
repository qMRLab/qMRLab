classdef BrowserSet < handle
    % BrowserSet - App Designer version of BrowserSet
    %   Manages file browser interface in App Designer
    
    properties
        NameID;         % Method name
        FullFile;       % Full file path
    end
    
    properties(Access = private)
        % App Designer components
        NameText;
        BrowseBtn;
        ClearBtn;
        InfoBtn;
        FileBox;
        ViewBtn;
        Parent;
        
        IsOptional;
        InfoText;
    end
    
    methods
        %------------------------------------------------------------------
        % CONSTRUCTOR
        function obj = BrowserSet(Parent, InputName, InputOptional, info)
            % Parent is the one-row uigridlayout MethodBrowser builds for this
            % input. Stage E2: it used to be the Datasets panel itself, with every
            % widget placed at a pixel offset computed from the panel's size at
            % construction time -- which is why the panel could not reflow and why
            % the 'large' text size had to be withheld.
            obj.Parent = Parent;
            obj.NameID = InputName;
            obj.IsOptional = InputOptional;
            obj.InfoText = info;

            obj.createComponents();
            obj.setupCallbacks();
        end
        
        %------------------------------------------------------------------
        % CREATE COMPONENTS
        %------------------------------------------------------------------
        function createComponents(obj)
            % One row of the Datasets grid: [? | name | + | - | file | View].
            %
            % Column widths, not pixel offsets. The file box takes '1x' so it is the
            % part that absorbs a wider window -- which is the whole point of E2: the
            % row now reflows, and larger text grows the cells that hold it instead of
            % overflowing boxes frozen at their design size.
            hasInfo = ~isempty(obj.InfoText);
            hasView = ~strcmp(obj.NameID, 'Mask');   % a mask has nothing to plot

            % 'fit' where text decides the width, so the row survives a larger text
            % size; the +/- buttons are icons and keep a fixed square.
            obj.Parent.ColumnWidth   = {'fit', 'fit', 28, 28, '1x', 'fit'};
            obj.Parent.RowHeight     = {'fit'};
            obj.Parent.Padding       = [0 0 0 0];
            obj.Parent.ColumnSpacing = 4;

            if hasInfo
                obj.InfoBtn = uibutton(obj.Parent, 'push');
                obj.InfoBtn.Layout.Row = 1; obj.InfoBtn.Layout.Column = 1;
                obj.InfoBtn.Text = '?';
                obj.InfoBtn.FontWeight = 'bold';
                obj.InfoBtn.Tooltip = obj.InfoText;
                obj.InfoBtn.ButtonPushedFcn = @(src,event) helpdlg(obj.InfoText);
            end

            obj.NameText = uilabel(obj.Parent);
            obj.NameText.Layout.Row = 1; obj.NameText.Layout.Column = 2;
            obj.NameText.Text = obj.NameID;
            obj.NameText.FontWeight = 'bold';
            obj.NameText.HorizontalAlignment = 'left';
            if obj.IsOptional
                obj.NameText.FontColor = qmrlabUIColor('muted');
            end
            if obj.IsOptional == 2
                obj.NameText.FontWeight = 'normal';
                obj.NameText.Text = ['(' obj.NameID ')'];
            end

            obj.BrowseBtn = uibutton(obj.Parent, 'push');
            obj.BrowseBtn.Layout.Row = 1; obj.BrowseBtn.Layout.Column = 3;
            obj.BrowseBtn.Text = '';
            obj.BrowseBtn.Icon = obj.getPlusIcon();
            obj.BrowseBtn.Tooltip = ['Choose a file for ' obj.NameID];

            obj.ClearBtn = uibutton(obj.Parent, 'push');
            obj.ClearBtn.Layout.Row = 1; obj.ClearBtn.Layout.Column = 4;
            obj.ClearBtn.Text = '';
            obj.ClearBtn.Icon = obj.getMinusIcon();
            obj.ClearBtn.Tooltip = ['Clear ' obj.NameID];

            obj.FileBox = uieditfield(obj.Parent, 'text');
            obj.FileBox.Layout.Row = 1; obj.FileBox.Layout.Column = 5;
            obj.FileBox.HorizontalAlignment = 'left';

            % The placeholder doubles as the input's documentation, and
            % Test/GUI/tControls.m finds the row by it. Keep the wording.
            if obj.IsOptional && hasInfo
                obj.FileBox.Value = obj.InfoText;
                obj.FileBox.FontColor = qmrlabUIColor('muted');
            elseif obj.IsOptional
                obj.FileBox.Value = 'OPTIONAL';
                obj.FileBox.FontColor = qmrlabUIColor('muted');
            else
                obj.FileBox.Value = ['REQUIRED ' obj.InfoText];
            end

            if hasView
                obj.ViewBtn = uibutton(obj.Parent, 'push');
                obj.ViewBtn.Layout.Row = 1; obj.ViewBtn.Layout.Column = 6;
                obj.ViewBtn.Text = 'View';
            end
        end

        %------------------------------------------------------------------
        % SETUP CALLBACKS
        function setupCallbacks(obj)
            obj.BrowseBtn.ButtonPushedFcn = @(src,event) obj.BrowseBtn_callback();
            obj.ClearBtn.ButtonPushedFcn = @(src,event) obj.ClearBtn_callback();
            
            if ~strcmp(obj.NameID, 'Mask')
                obj.ViewBtn.ButtonPushedFcn = @(src,event) obj.ViewBtn_callback();
            end
            
            % Add click callback to FileBox for browsing
            % Was obj.FileBox_callback(), a method that has never existed on this
            % class -- typing a path into the box threw noSuchMethodOrField.
            % SetFileName is what it meant: it stores the path and loads the file.
            obj.FileBox.ValueChangedFcn = @(src,event) obj.SetFileName(src.Value);
        end
        
        %------------------------------------------------------------------
        % GET PLUS ICON
        function icon = getPlusIcon(obj)
            % Create a simple plus icon programmatically
            icon = ones(16, 16, 3);
            icon(8:9, 3:14, :) = 0;  % Horizontal line
            icon(3:14, 8:9, :) = 0;  % Vertical line
        end
        
        %------------------------------------------------------------------
        % GET MINUS ICON
        function icon = getMinusIcon(obj)
            % Create a simple minus icon programmatically
            icon = ones(16, 16, 3);
            icon(8:9, 3:14, :) = 0;  % Horizontal line
        end
        
        %------------------------------------------------------------------
        % VISIBILITY CONTROL
        function Visible(obj, Visibility)
            obj.NameText.Visible = Visibility;
            obj.BrowseBtn.Visible = Visibility;
            obj.ClearBtn.Visible = Visibility;
            obj.FileBox.Visible = Visibility;
            
            if ~isempty(obj.InfoBtn)
                obj.InfoBtn.Visible = Visibility;
            end
            
            if ~strcmp(obj.NameID, 'Mask') && ~isempty(obj.ViewBtn)
                obj.ViewBtn.Visible = Visibility;
            end
        end
        
        %------------------------------------------------------------------
        % GET FILE NAME
        function FileName = GetFileName(obj)
            FileName = obj.FileBox.Value;
            if ~(exist(FileName, 'file') == 2 || exist(FileName, 'dir') == 7)
                FileName = char.empty;
            end
        end
        
        %------------------------------------------------------------------
        % GET FIELD NAME
        function fieldName = GetFieldName(obj)
            fieldName = obj.NameID;
        end
        
        %------------------------------------------------------------------
        % SET FILE NAME
        function SetFileName(obj, fileName)
            obj.FileBox.Value = fileName;
            obj.FullFile = fileName;
            obj.DataLoad();
        end
        
        %------------------------------------------------------------------
        % DATA LOAD
        function DataLoad(obj, warnmissing)
            if ~exist('warnmissing', 'var')
                warnmissing = true;
            end
            
            % Set cursor to watch. onCleanup guarantees the pointer is restored
            % even if loading throws (#536).
            set(findobj('Name', 'qMRLab'), 'pointer', 'watch');
            pointer_restore = onCleanup(@() set(findobj('Name', 'qMRLab'), 'pointer', 'arrow')); %#ok<NASGU>
            drawnow;
            
            obj.FullFile = obj.FileBox.Value;
            tmp = [];
            
            if ~isempty(obj.FullFile)
                [~, ~, ext] = fileparts(obj.FullFile);

                if strcmp(ext, '.gz')
                    [~, ~, ext] = fileparts(obj.FullFile(1:end-3)); % real extension under the .gz (#506)
                end

                if strcmp(ext, '.mat')
                    mat = load(obj.FullFile);
                    mapName = fieldnames(mat);
                    tmp = mat.(mapName{1});
                elseif strcmp(ext, '.mnc')
                    [hdr, tmp] = minc_read(obj.FullFile);
                elseif strcmp(ext, '.nii') || strcmp(ext, '.img')
                    intrp = 'linear';
                    [tmp, hdr] = nii_load(obj.FullFile, 0, intrp);
                elseif strcmp(ext, '.tiff') || strcmp(ext, '.tif')
                    TiffInfo = imfinfo(obj.FullFile);
                    NbIm = numel(TiffInfo);
                    if NbIm == 1
                        File = imread(obj.FullFile);
                    else
                        for ImNo = 1:NbIm
                            File(:,:,ImNo) = imread(obj.FullFile, ImNo);
                        end
                    end
                    tmp = File;
                else
                    if exist(obj.FullFile, 'file') == 2
                        warndlg(['File extension ' ext ' is not supported. Choose .mat, .nii, .nii.gz, .mnc, .mnc.gz, .img, .tiff or .tif files']);
                    end
                end
            end
            
            Data = getappdata(0, 'Data');
            Model = getappdata(0, 'Model');
            Data.(class(Model)).(obj.NameID) = double(tmp);
            
            if exist('hdr', 'var')
                Data.([class(Model) '_hdr']) = hdr;
            elseif isfield(Data, [class(Model) '_hdr'])
                Data = rmfield(Data, [class(Model) '_hdr']);
            end
            
            setappdata(0, 'Data', Data);
            set(findobj('Name', 'qMRLab'), 'pointer', 'arrow');
            drawnow;
            
            if warnmissing
                % This block threw for the whole life of the migrated app:
                % "Property assignment is not allowed when the object is empty."
                %
                % Two faults, either of which is fatal. MethodBrowser creates the
                % warning label without ever setting a Tag, so the findobj matched
                % nothing and hWarnBut was an empty handle; and the property is
                % Text, not Value, because the label is a uilabel and not the GUIDE
                % uicontrol this line was written against.
                %
                % It was invisible because the only routine caller passes
                % warnmissing = 0 (MethodBrowser.setFullPath, which is what the
                % "Browse" folder button and "Download example" use, and which
                % reports consistency itself). Everything that loads ONE file --
                % the per-input "+" button, Clear, setFileName, and therefore the
                % documented qMRLab(Model, data) API -- came through here and died.
                % char(): sanityCheck returns a message when the data is WRONG and
                % 0x0 double [] when it is RIGHT, and uilabel.Text rejects [] with
                % MATLAB:ui:Label:invalidMultilineTextValue. Without this the label
                % throws on the success path -- the common one.
                ErrMsg = char(Model.sanityCheck(Data.(class(Model))));
                % Search from the figure: the label belongs to MethodBrowser and
                % sits on the Datasets panel, while obj.Parent is now only this
                % input's row.
                hWarnBut = findall(ancestor(obj.Parent,'figure'), 'Tag', ['WarnBut_DataConsistency_' class(Model)]);
                if ~isempty(hWarnBut)
                    set(hWarnBut, 'Text', ErrMsg, 'Tooltip', ErrMsg, ...
                                  'Visible', matlab.lang.OnOffSwitchState(~isempty(ErrMsg)));
                end
            end
        end
        
        %------------------------------------------------------------------
        % SET PATH
        function setPath(obj, Path, fileList, warnmissing)
            if ~exist('warnmissing', 'var')
                warnmissing = true;
            end
            
            % Clear previous file paths
            obj.FileBox.Value = '';
            
            % Check for files and set fields automatically
            for ii = 1:length(fileList)
                if contains(fileList{ii}(1:end-4), obj.NameID)
                    obj.FullFile = fullfile(Path, fileList{ii});
                    obj.FileBox.Value = obj.FullFile;
                    warning('off', 'MATLAB:mat2cell:TrailingUnityVectorArgRemoved');
                    obj.DataLoad(warnmissing);
                end
            end
        end
        
        %------------------------------------------------------------------
        % BROWSE BUTTON CALLBACK
        function BrowseBtn_callback(obj, FileName)
            origdir = pwd;
            
            if ~exist('FileName', 'var')
                obj.FullFile = obj.FileBox.Value;
                W = evalin('base', 'whos');
                pathExist = ismember('DataPath', {W(:).name});
                
                if pathExist && ~(isnumeric(evalin('base', 'DataPath')))
                    dataDir = evalin('base', 'DataPath');
                    if exist(dataDir, 'dir') == 7
                        cd(dataDir);
                    end
                end
                
                if isequal(obj.FullFile, 0) || isempty(obj.FullFile)
                    [FileName, PathName] = uigetfile({'*.nii;*.nii.gz;*.mnc;*.mnc.gz;*.gz;*.mat'; '*.img'}, 'Select file');
                else
                    [FileName, PathName] = uigetfile({'*.nii;*.nii.gz;*.mnc;*.mnc.gz;*.gz;*.mat'; '*.img'}, 'Select file', obj.FullFile);
                end
                
                cd(origdir);
            else
                PathName = '';
            end
            
            if FileName
                obj.FullFile = fullfile(PathName, FileName);
            else
                if obj.IsOptional && ~isempty(obj.InfoText)
                    obj.FullFile = obj.InfoText;
                elseif obj.IsOptional && isempty(obj.InfoText)
                    obj.FullFile = 'OPTIONAL';
                elseif ~obj.IsOptional
                    obj.FullFile = ['REQUIRED ' obj.InfoText];
                end
            end
            
            obj.FileBox.Value = obj.FullFile;
            obj.DataLoad();
        end
        
        %------------------------------------------------------------------
        % CLEAR BUTTON CALLBACK
        function ClearBtn_callback(obj)
            obj.FileBox.Value = '';
            obj.DataLoad();
            
            if obj.IsOptional && ~isempty(obj.InfoText)
                obj.FileBox.Value = obj.InfoText;
            elseif obj.IsOptional && isempty(obj.InfoText)
                obj.FileBox.Value = 'OPTIONAL';
            elseif ~obj.IsOptional
                obj.FileBox.Value = ['REQUIRED ' obj.InfoText];
            end
        end
        
        %------------------------------------------------------------------
        % VIEW BUTTON CALLBACK
        function ViewBtn_callback(obj)
            dat = getappdata(0, 'Data');
            Model = getappdata(0, 'Model');
            Data = dat.(class(Model));
            
            if isempty(Data.(obj.NameID))
                errordlg('"Browse" for your own MRI data or click on "download example" data.', 'empty data');
                return;
            end
            
            fieldstmp = fieldnames(Data);
            for ff = 1:length(fieldstmp)
                if isempty(Data.(fieldstmp{ff}))
                    Data = rmfield(Data, fieldstmp{ff});
                end
            end
            Data.fields = fieldnames(Data);
            
            try
                Data.hdr = dat.([class(Model) '_hdr']);
            catch
                % No header data
            end
            
            handles = guidata(findobj('Name', 'qMRLab'));
            handles.CurrentData = Data;
            DrawPlot(handles, obj.NameID);
        end
    end
end