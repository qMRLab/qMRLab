classdef BrowserSet
    % BrowserSet - manage the file browser interface
    %   P.Beliveau 2017 - setup
    %   * manage the standard set of interface items in the browser
    %   * Properties: 
    %       uicontrols:     - NameText 
    %                       - BrowserButton 
    %                       - FileBox 
    %                       - ViewButton
    %       vars: - NameID: identifies the method
    %             - FullFile: the path and file name displayed 
    %                           and chosen by user

    
    properties
        
        NameID;         % Method
        FullFile;       
        

    end
    
    properties(Hidden = true)
        NameText;
        BrowseBtn;
        FileBox;
        ViewBtn;
        BrowseBtnOn;
        ViewBtnOn;

    end
    
    methods
        %------------------------------------------------------------------
        % -- CONSTRUCTOR
        function obj = BrowserSet(varargin)
            % BrowserSet(parentPanel,handles,Name)
            % handles: used for the view button
            % Name: Name of the field
            if nargin>0
                % parse the input arguments
                parent = varargin{1};
                handles = varargin{2};
                InputName = varargin{3};
                InputOptional = varargin{4};
                Location = varargin{5};
                obj.BrowseBtnOn = varargin{6};
                obj.ViewBtnOn = varargin{7};
                
                obj.NameID = InputName;

                Position = [Location, 0.1, 0.1];
                obj.NameText = uicontrol(parent, 'Style', 'Text', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', obj.NameID, 'HorizontalAlignment', 'left', 'Position', Position,'FontSize', 0.6);
                
                % Set color to gray if optional
                if InputOptional, set(obj.NameText,'ForegroundColor',[.5 .5 .5]); end
                    
                if obj.BrowseBtnOn == 1
                    Location = Location + [0.1, 0];
                    LocationBrowse = Location;
                end
                
                Location = Location + [0.11, 0];
                Position = [Location, 0.65, 0.1];
                obj.FileBox = uicontrol(parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized', 'Position', Position,'FontSize', 0.6,...
                    'Callback', {@(src, event)BrowserSet.BrowseBtn_callback(obj)});
                
                if obj.BrowseBtnOn == 1
                    Position = [LocationBrowse, 0.1, 0.1];
                    obj.BrowseBtn = uicontrol(parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                        'String', 'Browse', 'Position', Position, 'FontSize', 0.6, ...
                        'Callback', {@(src, event)BrowserSet.BrowseBtn_callback(obj)});
                end

                if obj.ViewBtnOn == 1 
                    Location = Location + [0.66, 0];
                    Position = [Location, 0.1, 0.1];
                    obj.ViewBtn = uicontrol(parent, 'style', 'pushbutton','units', 'normalized', 'fontunits', 'normalized', ...
                        'String', 'View', 'Position', Position, 'FontSize', 0.6, ...
                        'Callback', {@(src, event)BrowserSet.ViewBtn_callback(obj, src, event, handles{1,1})});           
                end
            end % testing varargin
        end % constructor end
        
    end
    
    methods
        %------------------------------------------------------------------
        % -- VISIBLE
        %       Visibility should be set to 'on' or 'off'
        function Visible(obj, Visibility)
            set(obj.NameText, 'Visible', Visibility);
            set(obj.BrowseBtn, 'Visible', Visibility);
            set(obj.FileBox, 'Visible', Visibility);
            set(obj.ViewBtn, 'Visible', Visibility);
        end
        
        %------------------------------------------------------------------
        % -- GetFileName
        function FileName = GetFileName(obj)
            FileName = get(obj.FileBox, 'string');
        end
        
        
    end
    
    methods
        
        %------------------------------------------------------------------
        % -- DATA LOAD
        %   load data from file and make accessible to qMRLab fct
        function DataLoad(obj)
            obj.FullFile = get(obj.FileBox, 'String');
            tmp = [];
            if ~isempty(obj.FullFile)
                [pathstr,name,ext] = fileparts(obj.FullFile);
                Data = getappdata(0,'Data');
                if strcmp(ext,'.mat');
                    mat = load(obj.FullFile);
                    mapName = fieldnames(mat);
                    tmp = mat.(mapName{1});
                elseif strcmp(ext,'.nii') || strcmp(ext,'.gz') || strcmp(ext,'.img');
                    tmp = load_nii_data(obj.FullFile);
                elseif strcmp(ext,'.tiff') || strcmp(ext,'.tif');
                    TiffInfo = imfinfo(obj.FullFile);
                    NbIm = numel(TiffInfo);
                    if NbIm == 1
                        File = imread(obj.FullFile);
                    else
                        for ImNo = 1:NbIm;
                            File(:,:,ImNo) = imread(obj.FullFile, ImNo);%, 'Info', info);
                        end
                    end
                    tmp = File;
                end
            end
            Data = getappdata(0, 'Data'); 
            Data.(class(getappdata(0,'Model'))).(obj.NameID) = double(tmp);
            if exist('nii','var'),	Data.hdr = nii.hdr; end
            setappdata(0, 'Data', Data);            
        end
        
        %------------------------------------------------------------------
        % -- setPath
        % search for filenames that match the NameText
        function setPath(obj, Path, fileList)       
            % clear previous file paths
            set(obj.FileBox, 'String', '');
            DataName = get(obj.NameText, 'String');
            %Check for files and set fields automatically
            for i = 1:length(fileList)
                if strfind(fileList{i}(1:end-4), DataName)
                    obj.FullFile = fullfile(Path,fileList{i});                    
                    set(obj.FileBox, 'String', obj.FullFile);
                    obj.DataLoad();
                end
            end
            
        end
    end
    
    methods(Static)
        %------------------------------------------------------------------
        % -- BROWSE BUTTONS
        %------------------------------------------------------------------
        function BrowseBtn_callback(obj,FileName)
            if ~exist('FileName','var')
                obj.FullFile = get(obj.FileBox, 'String');
                if isequal(obj.FullFile, 0) || (isempty(obj.FullFile))
                    [FileName,PathName] = uigetfile({'*.nii;*.nii.gz';'*.mat';'*.img'},'Select file');
                else
                    [FileName,PathName] = uigetfile({'*.nii;*.nii.gz';'*.mat';'*.img'},'Select file',obj.FullFile);
                end
            else
                PathName = '';
            end
            obj.FullFile = fullfile(PathName,FileName);
            set(obj.FileBox,'String',obj.FullFile);
            
            DataLoad(obj);            
        end
        
        %------------------------------------------------------------------
        % -- VIEW BUTTONS
        %------------------------------------------------------------------
        function ViewBtn_callback(obj,src, event, handles)
            obj.DataLoad();
            dat = getappdata(0, 'Data');
            dat=dat.(class(getappdata(0,'Model'))).(obj.NameID);
            if isempty(dat), errordlg('empty data'); return; end
            
            n = ndims(dat);
            Data.(obj.NameID) = dat;
            
            Data.fields = {obj.NameID};
            handles.CurrentData = Data;
            DrawPlot(handles);
        end
        
        
    end
    
end

