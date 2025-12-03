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
        function obj = BrowserSet(Parent, InputName, InputOptional, Location, info)
            obj.Parent = Parent;
            obj.NameID = InputName;
            obj.IsOptional = InputOptional;
            obj.InfoText = info;
            
            % Create components
            obj.createComponents(Location);
            
            % Set up callbacks
            obj.setupCallbacks();
        end
        
        %------------------------------------------------------------------
        % CREATE COMPONENTS
        %------------------------------------------------------------------
        function createComponents(obj, Location)
            % Get parent container size for proper positioning
            parentPos = obj.Parent.Position; % [x, y, width, height] in pixels
            
            % Convert normalized coordinates to pixels relative to parent
            posX = Location(1) * parentPos(3);
            posY = Location(2) * parentPos(4);
            
            % Adjust Y position to account for panel title bar and layout
            posY = posY - 20; % Adjust this value as needed
            
            % Info button
            if ~isempty(obj.InfoText)
                obj.InfoBtn = uibutton(obj.Parent, 'push');
                obj.InfoBtn.Position = [posX, posY, 20, 25];
                obj.InfoBtn.Text = '?';
                obj.InfoBtn.FontWeight = 'bold';
                obj.InfoBtn.Tooltip = obj.InfoText;
                obj.InfoBtn.ButtonPushedFcn = @(src,event) helpdlg(obj.InfoText);
            end
            
            % Input Name label
            labelX = posX + 25;
            obj.NameText = uilabel(obj.Parent);
            obj.NameText.Position = [labelX, posY, 80, 25];
            obj.NameText.Text = obj.NameID;
            obj.NameText.FontWeight = 'bold';
            obj.NameText.HorizontalAlignment = 'left';
            
            % Set color and style based on optional status
            if obj.IsOptional
                obj.NameText.FontColor = [0.5, 0.5, 0.5];
            end
            if obj.IsOptional == 2
                obj.NameText.FontWeight = 'normal';
                obj.NameText.Text = ['(' obj.NameID ')'];
            end
            
            % Browse button (plus icon)
            browseX = labelX + 85;
            obj.BrowseBtn = uibutton(obj.Parent, 'push');
            obj.BrowseBtn.Position = [browseX, posY, 25, 25];
            obj.BrowseBtn.Text = '';
            obj.BrowseBtn.Icon = obj.getPlusIcon();
            
            % Clear button (minus icon)
            clearX = browseX + 30;
            obj.ClearBtn = uibutton(obj.Parent, 'push');
            obj.ClearBtn.Position = [clearX, posY, 25, 25];
            obj.ClearBtn.Text = '';
            obj.ClearBtn.Icon = obj.getMinusIcon();
            
            % File box - make sure this is visible
            fileX = clearX + 30;
            obj.FileBox = uieditfield(obj.Parent, 'text');
            obj.FileBox.Position = [fileX, posY, 350, 25];
            obj.FileBox.BackgroundColor = [1, 1, 1]; % White background
            obj.FileBox.Value = '';
            obj.FileBox.HorizontalAlignment = 'left';
            obj.FileBox.FontColor = [0, 0, 0]; % Black text
            obj.FileBox.Visible = 'on'; % Explicitly set to visible
            
            % Set initial text based on optional status
            if obj.IsOptional && ~isempty(obj.InfoText)
                obj.FileBox.Value = obj.InfoText;
                obj.FileBox.FontColor = [0.5, 0.5, 0.5]; % Gray for optional
            elseif obj.IsOptional && isempty(obj.InfoText)
                obj.FileBox.Value = 'OPTIONAL';
                obj.FileBox.FontColor = [0.5, 0.5, 0.5];
            elseif ~obj.IsOptional
                obj.FileBox.Value = ['REQUIRED ' obj.InfoText];
                obj.FileBox.FontColor = [0, 0, 0]; % Black for required
            end
            
            % View button (skip for Mask)
            if ~strcmp(obj.NameID, 'Mask')
                viewX = fileX + 355;
                obj.ViewBtn = uibutton(obj.Parent, 'push');
                obj.ViewBtn.Position = [viewX, posY, 40, 25];
                obj.ViewBtn.Text = 'View';
                obj.ViewBtn.Visible = 'on';
            end
            
            % Debug: Force all components to be visible
            obj.NameText.Visible = 'on';
            obj.BrowseBtn.Visible = 'on';
            obj.ClearBtn.Visible = 'on';
            obj.FileBox.Visible = 'on';
            if ~isempty(obj.InfoBtn)
                obj.InfoBtn.Visible = 'on';
            end
            if ~strcmp(obj.NameID, 'Mask') && ~isempty(obj.ViewBtn)
                obj.ViewBtn.Visible = 'on';
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
            obj.FileBox.ValueChangedFcn = @(src,event) obj.FileBox_callback();
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
            
            % Set cursor to watch
            set(findobj('Name', 'qMRLab'), 'pointer', 'watch');
            drawnow;
            
            obj.FullFile = obj.FileBox.Value;
            tmp = [];
            
            if ~isempty(obj.FullFile)
                [~, ~, ext] = fileparts(obj.FullFile);
                if strcmp(ext, '.mat')
                    mat = load(obj.FullFile);
                    mapName = fieldnames(mat);
                    tmp = mat.(mapName{1});
                elseif strcmp(ext, '.nii') || strcmp(ext, '.gz') || strcmp(ext, '.img')
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
                        warndlg(['File extension ' ext ' is not supported. Choose .mat, .nii, .nii.gz, .img, .tiff or .tif files']);
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
                ErrMsg = Model.sanityCheck(Data.(class(Model)));
                hWarnBut = findobj(obj.Parent, 'Tag', ['WarnBut_DataConsistency_' class(Model)]);
                if ~isempty(ErrMsg)
                    hWarnBut.Value = ErrMsg;
                    hWarnBut.Tooltip = ErrMsg;
                    hWarnBut.Visible = 'on';
                else
                    hWarnBut.Value = '';
                    hWarnBut.Tooltip = '';
                    hWarnBut.Visible = 'off';
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
                    [FileName, PathName] = uigetfile({'*.nii;*.nii.gz;*.mat'; '*.img'}, 'Select file');
                else
                    [FileName, PathName] = uigetfile({'*.nii;*.nii.gz;*.mat'; '*.img'}, 'Select file', obj.FullFile);
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