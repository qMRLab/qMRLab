classdef BrowserSet
% BrowserSet - manages file browser interface items
%
%   Properties:
%       uicontrols:
%           - NameText
%           - BrowserButton
%           - FileBox
%           - ViewButton
%       vars:
%           - NameID: identifies the method
%           - FullFile(*): filepath(s) chosen by the user
%
%   (*) FullFile is a dependent property that sets/gets the path from
%       FileBox.String.
%
%   P.Beliveau 2017 - setup
%   M.Herrerias 2025 - support for multiple files

    properties
        NameID;         % Method
    end
    properties (Dependent)
        FullFile;      % gets/sets FileBox
    end

    properties (Constant, Hidden=true)
      SupportedExtensions = {'*.mat', '*.nii', '*.nii.gz', '*.img', '*.tiff', '*.tif'}
    end

    properties(Hidden = true)
        NameText;
        BrowseBtn;
        ClearBtn;
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
                Position = [Location + [0.14, 0], 0.05, 0.11];
                obj.BrowseBtn = uicontrol(obj.parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', '', 'Position', Position, 'FontSize', 0.6,'Interruptible','off');
                cur_m = mfilename('fullpath');
                cur_loc = strfind(cur_m,[filesep 'src' filesep 'Common']);
                im = imread([cur_m(1:cur_loc-1) filesep 'src' filesep 'Common' filesep 'icons' filesep 'plus.png']);
                obj.BrowseBtn.CData = im;

                Position = [Location + [0.19, 0], 0.05, 0.11];
                obj.ClearBtn = uicontrol(obj.parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', '', 'Position', Position, 'FontSize', 0.6,'Interruptible','off');
                im = imread([cur_m(1:cur_loc-1) filesep 'src' filesep 'Common' filesep 'icons' filesep 'minus.png']);
                obj.ClearBtn.CData = im;

                % add Browse button
                Position = [Location + [0.25, 0], 0.58, 0.1];
                obj.FileBox = uicontrol(obj.parent, 'Style', 'text','units', 'normalized', 'fontunits', 'normalized', 'Position', Position,'FontSize', 0.6,...
                    'BackgroundColor', [1 1 1]);
                obj.ResetFileBox(info, InputOptional);

                % add View button
                Position = [Location + [0.87, 0], 0.10, 0.1];
                obj.ViewBtn = uicontrol(obj.parent, 'style', 'pushbutton','units', 'normalized', 'fontunits', 'normalized', ...
                    'String', 'View', 'Position', Position, 'FontSize', 0.6,'Interruptible','off');

                % Set Callbacks
                set(obj.FileBox,'Callback', {@(src, event)BrowserSet.BrowseBtn_callback(obj,info,InputOptional)});
                set(obj.FileBox,'Callback', {@(src, event)BrowserSet.ClearBtn_callback(obj,info,InputOptional)});
                set(obj.BrowseBtn,'Callback', {@(src, event)BrowserSet.BrowseBtn_callback(obj,info,InputOptional)});
                set(obj.ClearBtn,'Callback', {@(src, event)BrowserSet.ClearBtn_callback(obj,info,InputOptional)});
                set(obj.ViewBtn,'Callback', {@(src, event)BrowserSet.ViewBtn_callback(obj, src, event)});

                if strcmp(InputName,'Mask')
                    delete(obj.ViewBtn);
                end
            end % testing varargin

            if isempty(obj.FileBox)
                % required to store FullFile
                obj.FileBox = uicontrol();
            end
        end % constructor end

        function ResetFileBox(obj, info, InputOptional)
            set(obj.FileBox,'string',info)
            if InputOptional && ~isempty(info), set(obj.FileBox,'string',info); end
            if InputOptional && isempty(info), set(obj.FileBox,'string','OPTIONAL'); end
            if ~InputOptional, set(obj.FileBox,'string',['REQUIRED ' info]); end
        end

        %------------------------------------------------------------------
        % -- VISIBLE
        %       Visibility should be set to 'on' or 'off'
        function Visible(obj, Visibility)
            set(obj.NameText, 'Visible', Visibility);
            set(obj.BrowseBtn, 'Visible', Visibility);
            set(obj.ClearBtn, 'Visible', Visibility);
            set(obj.FileBox, 'Visible', Visibility);
            if ~strcmp(obj.NameID{1},'Mask')
                set(obj.ViewBtn, 'Visible', Visibility);
            end
            set(obj.InfoBtn, 'Visible', Visibility);
        end

        %------------------------------------------------------------------
        % -- get/set FullFile
        %   FullFile works just as an interface to parse FileBox

        function obj = set.FullFile(obj,val)
            if iscellstr(val) || isstring(val)
                val = strjoin(val,';');
            end
            set(obj.FileBox, 'String', val);
        end

        function paths = get.FullFile(obj)

            text = get(obj.FileBox, 'String');
            if isempty(text)
                paths = char.empty;
                return
            end

            % expand lists of files / patterns separated by ';'
            % expand patterns, e.g. /some/file_*.ext
            glob = @(p) arrayfun(@(d) fullfile(d.folder, d.name), dir(p),'unif',0);
            expanded = cellfun(glob, strsplit(text,';'), 'unif',0);
            paths = cat(1,expanded{:})';

            if isempty(paths)
                paths = char.empty;
            elseif isscalar(paths)
                paths = paths{1};
            end
        end

        %------------------------------------------------------------------
        % -- DATA LOAD
        %   load data from file and make accessible to qMRLab fct
        function DataLoad(obj,warnmissing)
            if ~exist('warnmissing','var'), warnmissing=true; end
            set(findobj('Name','qMRLab'),'pointer', 'watch'); drawnow;

            paths = obj.FullFile;

            tmp = [];
            hdr = struct.empty;
            if ~isempty(paths) && ~isequal(paths,0)

                % try
                    if ischar(paths)
                        [tmp, hdr] = BrowserSet.LoadImage(paths);
                    else
                        [tmp, hdr] = LoadComplex(paths{:});
                    end
                % catch err
                %     errordlg(err.message,'Failed to load data')
                % end
            end

            Data = getappdata(0, 'Data');
            Model = getappdata(0,'Model');
            Data.(class(Model)).(obj.NameID{1}) = double(tmp);

            if ~isempty(hdr)
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

            % match all files that contain NameText
            candidates = {};
            for ii = 1:length(fileList)
                % TODO: confirm whether we want to match on the
                %   full path, or only on the basename
                [relpath, basename, ~] = obj.fileparts2(fileList{ii});
                if strfind(fullfile(relpath, basename), DataName{1})
                    candidates{end+1} = fullfile(Path, fileList{ii}); %#ok<AGROW>
                end
            end
            if isempty(candidates), return; end

            % this will trigger set.FullFile
            obj.FullFile = candidates;

            warning('off','MATLAB:mat2cell:TrailingUnityVectorArgRemoved');
            obj.DataLoad(warnmissing);
        end
    end

    methods(Static)
        %------------------------------------------------------------------
        % -- BROWSE BUTTONS
        %------------------------------------------------------------------
        function BrowseBtn_callback(obj,info,InputOptional,FileName)

            if ~exist('FileName','var')
                defPath = '';
                if evalin('base','exist(''DataPath'', ''var'')')
                    defPath = evalin('base','DataPath');
                    if isnumeric(defPath) || exist(defPath,'dir') ~= 7
                        defPath = '';
                    end
                end

                files = obj.FullFile;
                if ~isempty(files)
                    if iscell(files)
                        defPath = fileparts(files{1});
                    else
                        defPath = files;
                    end
                end
                [FileName, PathName] = uigetfile( ...
                    strjoin(BrowserSet.SupportedExtensions,';'), ...
                    'Select file', defPath, 'MultiSelect','on');
            else
                PathName = '';
            end
            if ischar(FileName)
                obj.FullFile = fullfile(PathName,FileName);
            elseif iscell(FileName)
                obj.FullFile = cellfun(@(f) fullfile(PathName,f), FileName, 'unif', 0);
            elseif isequal(FileName, 0)
                obj.ResetFileBox(info, InputOptional);
            else
                error('You really should not be here')
            end
            obj.DataLoad();
        end

        function ClearBtn_callback(obj,info,InputOptional)
            obj.ResetFileBox(info, InputOptional);
            obj.DataLoad();
        end

        %------------------------------------------------------------------
        % -- VIEW BUTTONS
        %------------------------------------------------------------------
        function ViewBtn_callback(obj,src, event)
            dat  = getappdata(0, 'Data');
            Data = dat.(class(getappdata(0,'Model')));
            if isempty(Data.(obj.NameID{1,1})), errordlg('"Browse" for your own MRI data or click on "download example" data.','empty data'); return; end
            fieldstmp = fieldnames(Data);
            for ff = 1:length(fieldstmp)
                if isempty(Data.(fieldstmp{ff}))
                    Data = rmfield(Data,fieldstmp{ff});
                    continue
                end
                if ~isreal(Data.(fieldstmp{ff}))
                    Data.([fieldstmp{ff} 'Phase']) = angle(Data.(fieldstmp{ff}))*180/pi;
                    Data.(fieldstmp{ff}) = abs(Data.(fieldstmp{ff}));
                end
            end
            Data.fields = fieldnames(Data);

            try
                Data.hdr=dat.([class(getappdata(0,'Model')) '_hdr']);
            end
            handles = guidata(findobj('Name','qMRLab'));
            handles.CurrentData = Data;
            DrawPlot(handles,obj.NameID{1,1});
        end

        function [filepath, name, ext] = fileparts2(filename)
        % Tweaked fileparts to recognize compound extensions e.g. '.nii.gz'

            knownCompoundEndings = {'.gz'};

            [filepath, name, ext] = fileparts(filename);
            if ismember(ext, knownCompoundEndings)
                [~, name, extSuffix] = fileparts(name);
                ext = [extSuffix, ext];
            end
        end

        function [data, hdr] = LoadImage(file)
        % Read individual files of known types
        %   Return a numeric array DATA and/or a metadata structure HDR
        %   For composite datasets (e.g. magnitude + phase) see DataLoad
        %
        % TODO: Should this be merged with/replaced by tools/LoadImage?
        % See also: LoadComplex

            assert(ischar(file) && ~isempty(file))
            if exist(file,'file')~=2
                error(['File not found: ', file])
            end

            hdr = struct.empty;

            [~,~,ext] = BrowserSet.fileparts2(file);
            switch ext
            case '.mat'
                mat = load(file);
                mapName = fieldnames(mat);
                data = mat.(mapName{1});
            case {'.nii','.nii.gz', '.img'}
                intrp = 'linear';
                [data, hdr] = nii_load(file,0,intrp);
            case {'.tiff', '.tif'}
                TiffInfo = imfinfo(file);
                NbIm = numel(TiffInfo);
                if NbIm == 1
                    File = imread(file);
                else
                    for ImNo = NbIm:-1:1
                        File(:,:,ImNo) = imread(file, ImNo);
                    end
                end
                data = File;
            otherwise
                if ismember(['*' ext], BrowserSet.SupportedExtensions)
                    error([ext, ' should not be on BrowserSet.SupportedExtensions, ' ...
                        'please report this to the developers'])
                end
                error('qMRLab:BrowserSet:extension', ...
                    ['File extension ' ext ' is not supported. Choose one of: ' ...
                    strjoin(BrowserSet.SupportedExtensions)])
            end
        end
    end

end
