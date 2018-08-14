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
        InfoBtn;
        FileBox;
        ViewBtn;
        parent;
    end
    
    methods
        %------------------------------------------------------------------
        % -- CONSTRUCTOR
        function obj = BrowserSet(varargin)
            % BrowserSet(parentPanel,Name,InputOptional,Location)
            % handles: used for the view button
            % Name: Name of the field
            if nargin>0
                % parse the input arguments
                obj.parent = varargin{1};
                InputName = varargin{2};
                InputOptional = varargin{3};
                Location = varargin{4};
                info = varargin{5};
                
                obj.NameID = {InputName};
                
                Position = [Location, 0.02, 0.1];
                % add Info button
                if ~isempty(info)
                    obj.InfoBtn = uicontrol(obj.parent, 'Style', 'pushbutton', 'units', 'normalized','BackgroundColor',[0.94 0.94 0.94], ...
                        'String', '?','FontWeight','bold','TooltipString',info,'Position',Position,'Callback',@(hObj,eventdata,handles) helpdlg(info));
                end
                
                % add Input Name
                Position = [[Location+[0.03 0]], 0.10, 0.1];
                obj.NameText = uicontrol(obj.parent, 'Style', 'Text', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', obj.NameID, 'HorizontalAlignment', 'left', 'Position', Position,'FontSize', 0.6,'FontWeight','bold');
                
                % Set color to gray if optional
                if InputOptional, set(obj.NameText,'ForegroundColor',[.5 .5 .5]); end
                if InputOptional==2 
                    set(obj.NameText,'FontWeight','normal');
                    set(obj.NameText,'String',['(' obj.NameID{:} ')']);
                end
                    
                % add Browse button
                Position = [Location + [0.14, 0], 0.1, 0.1];
                obj.BrowseBtn = uicontrol(obj.parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', 'Browse', 'Position', Position, 'FontSize', 0.6,'Interruptible','off');

                % add Browse button
                Position = [Location + [0.27, 0], 0.58, 0.1];
                obj.FileBox = uicontrol(obj.parent, 'Style', 'text','units', 'normalized', 'fontunits', 'normalized', 'Position', Position,'FontSize', 0.6,...
                    'BackgroundColor', [1 1 1]);
                
                % add View button
                Position = [Location + [0.87, 0], 0.10, 0.1];
                obj.ViewBtn = uicontrol(obj.parent, 'style', 'pushbutton','units', 'normalized', 'fontunits', 'normalized', ...
                    'String', 'View', 'Position', Position, 'FontSize', 0.6,'Interruptible','off');
                
                % Set Callbacks
                set(obj.FileBox,'Callback', {@(src, event)BrowserSet.BrowseBtn_callback(obj)});
                set(obj.BrowseBtn,'Callback', {@(src, event)BrowserSet.BrowseBtn_callback(obj)});
                set(obj.ViewBtn,'Callback', {@(src, event)BrowserSet.ViewBtn_callback(obj, src, event)});

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
            set(obj.InfoBtn, 'Visible', Visibility);
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
        function DataLoad(obj,warnmissing)
            if ~exist('warnmissing','var'), warnmissing=true; end
            set(findobj('Name','qMRLab'),'pointer', 'watch'); drawnow;
            obj.FullFile = get(obj.FileBox, 'String');
            tmp = [];
            if ~isempty(obj.FullFile)
                [~,~,ext] = fileparts(obj.FullFile);
                if strcmp(ext,'.mat')
                    mat = load(obj.FullFile);
                    mapName = fieldnames(mat);
                    tmp = mat.(mapName{1});
                elseif strcmp(ext,'.nii') || strcmp(ext,'.gz') || strcmp(ext,'.img')
                    [tmp, hdr] = load_nii_data(obj.FullFile);
                elseif strcmp(ext,'.tiff') || strcmp(ext,'.tif')
                    TiffInfo = imfinfo(obj.FullFile);
                    NbIm = numel(TiffInfo);
                    if NbIm == 1
                        File = imread(obj.FullFile);
                    else
                        for ImNo = 1:NbIm
                            File(:,:,ImNo) = imread(obj.FullFile, ImNo);%, 'Info', info);
                        end
                    end
                    tmp = File;
                else
                    warndlg(['file extension ' ext ' is not supported. Choose .mat, .nii, .nii.gz, .img, .tiff or .tif files'])
                end
            end
            
            Data = getappdata(0, 'Data');
            Model = getappdata(0,'Model');
            Data.(class(Model)).(obj.NameID{1}) = double(tmp);
            
            if exist('hdr','var')
                Data.([class(Model) '_hdr']) = hdr; 
            elseif isfield(Data,[class(Model) '_hdr'])
                Data = rmfield(Data,[class(Model) '_hdr']);
            end

            setappdata(0, 'Data', Data); 
            set(findobj('Name','qMRLab'),'pointer', 'arrow'); drawnow;
            
            if warnmissing
                ErrMsg = Model.sanityCheck(Data.(class(Model)));
                hWarnBut = findobj(obj.parent,'Tag',['WarnBut_DataConsistency_' class(Model)]);
                if ~isempty(ErrMsg)
                    set(hWarnBut,'String',ErrMsg)
                    set(hWarnBut,'TooltipString',ErrMsg)
                    set(hWarnBut,'Visible','on')
                else
                    set(hWarnBut,'String','')
                    set(hWarnBut,'TooltipString','')
                    set(hWarnBut,'Visible','off')
                end
            end
        end
        
        %------------------------------------------------------------------
        % -- setPath
        % search for filenames that match the NameText
        function setPath(obj, Path, fileList,warnmissing)    
            if ~exist('warnmissing','var'), warnmissing=true; end
            % clear previous file paths
            set(obj.FileBox, 'String', '');
            DataName = get(obj.NameText, 'String');
            %Check for files and set fields automatically
            for ii = 1:length(fileList)
                if strfind(fileList{ii}(1:end-4), DataName{1})
                    obj.FullFile = fullfile(Path,fileList{ii});                    
                    set(obj.FileBox, 'String', obj.FullFile);
                    obj.DataLoad(warnmissing);
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
            if FileName
                obj.FullFile = fullfile(PathName,FileName);
            else
                obj.FullFile = '';
            end
            set(obj.FileBox,'String',obj.FullFile);
            
            DataLoad(obj);            
        end
        
        %------------------------------------------------------------------
        % -- VIEW BUTTONS
        %------------------------------------------------------------------
        function ViewBtn_callback(obj,src, event)
            dat = getappdata(0, 'Data');
            dat=dat.(class(getappdata(0,'Model'))).(obj.NameID{1,1});
            if isempty(dat), errordlg('"Browse" for your own MRI data or click on "download example" data.','empty data'); return; end
            
            n = ndims(dat);
            Data.(obj.NameID{1,1}) = dat;
            
            Data.fields = {obj.NameID{1,1}};
            handles = guidata(findobj('Name','qMRLab'));
            handles.CurrentData = Data;
            DrawPlot(handles);
            
            set(handles.RoiAnalysis,'Enable','on');
        end
        
        
    end
    
end

