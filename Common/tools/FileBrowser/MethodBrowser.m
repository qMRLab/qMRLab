classdef MethodBrowser < handle
        % MethodBrowser  - Manage fields in the file Browser per methods
        %   P.Beliveau 2017 - setup
        %   * All Methods have in common the WorkDir Button and File Box and
        %       the StudyID file Box
        %   * All other file managements uicontrols are contained in the
        %       ItemsList
    
    properties
        Parent;
        % common to all methods, work directory and studyID
        WorkDir_TextArea;
        WorkDir_BrowseBtn;
        WorkDir_FileNameArea;
        WorkDir_FullPath;
        StudyID_TextArea;
        StudyID_TextID;
        
        ItemsList; % is a list of the class BrowserSet objects
        NbItems;
        MethodID;        
    end
    
    methods
        % constructor
        function obj = MethodBrowser(varargin)
            obj.Parent = varargin{1};
            if nargin > 2            
                obj.Parent = varargin{1};
                handles = varargin(2);
                Params = varargin{3}; 
                
                obj.MethodID = Params(1);
                Location = [0.02, 0.7];
                
                TheSize = size(Params);
                if strcmp(Params(TheSize(2)), '') 
                    obj.NbItems = TheSize(2)-2;
                else
                    obj.NbItems = TheSize(2)-1;
                end
                
                obj.ItemsList = repmat(BrowserSet(),1,obj.NbItems);
                
                for i=1:obj.NbItems
                    obj.ItemsList(i) = BrowserSet(obj.Parent, handles, Params(i+1), Location, 1, 1);
                    Location = Location + [0.0, -0.15];
                end
                
                % setup work directory and study ID display
                obj.WorkDir_TextArea = uicontrol(obj.Parent, 'Style', 'Text', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Work Dir:', 'HorizontalAlignment', 'left', 'Position', [0.02,0.85,0.1,0.1],'FontSize', 0.6);
                obj.WorkDir_BrowseBtn = uicontrol(obj.Parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', 'Browse', 'Position', [0.11,0.85,0.1,0.1], 'FontSize', 0.6, ...
                    'Callback', {@(src, event)MethodBrowser.BrowseBtn_callback(obj, src, event, handles{1,1})});
                obj.WorkDir_FileNameArea = uicontrol(obj.Parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized', 'Position', [0.22,0.85,0.3,0.1],'FontSize', 0.6);
                obj.WorkDir_FullPath = '';
                obj.StudyID_TextArea = uicontrol(obj.Parent, 'Style', 'text', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', 'Study ID:', 'Position', [0.55,0.85,0.1,0.1], 'FontSize', 0.6);
                obj.StudyID_TextID = uicontrol(obj.Parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized', 'Position', [0.65,0.85,0.3,0.1],'FontSize', 0.6);
            end
        end % end constructor      
        
        % destructor
        function delete(obj)
            delete(setdiff(findobj(obj.Parent),obj.Parent))
        end % destructir end
                
        %---
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
        
        %---
        % IsMethod
        function Res = IsMethod(obj, NameID)
            if strcmp(obj.MethodID, NameID)
                Res = 0;
            else
                Res = 1;
            end
        end
        
        %---
        % DataLoad - save the images using setappdata
        function DataLoad(obj, handles)
            for i=1:obj.NbItems
                obj.ItemsList(i).DataLoad(handles);
            end
        end
        
        %---
        % SetFullPath
        function setFullPath(obj, handles)
            Path = obj.WorkDir_FullPath;
            
            dirData = dir(Path);
            dirIndex = [dirData.isdir];
            fileList = {dirData(~dirIndex).name}';
            
            % manage protocol and fit options
            for i = 1:length(fileList)
                if strcmp(fileList{i}, 'Protocol.mat')
                    Prot = load(fullfile(Path,'Protocol.mat'));
                    SetAppData(Prot);
                    strcmp(fileList{i}, 'FitOpt.mat')        
                    FitOpt = load(fullfile(Path,'FitOpt.mat'));
                    SetAppData(FitOpt);
                end
            end            
            
            % Manage each data items
            for i=1:obj.NbItems
                obj.ItemsList(i).setPath(Path, fileList, handles);
            end
        end % end SetFullPath
        
        function WD = getWD(obj)
            WD = obj.WorkDir_FullPath;
        end
        
    end
    
    methods(Static)
        
        %------------------------------------------------------------------
        % -- BrowseBtn_callback
        %   Callback function for the working directory
        function BrowseBtn_callback(obj,src, event, handles)
            obj.WorkDir_FullPath = uigetdir;
            set(obj.WorkDir_FileNameArea,'String',obj.WorkDir_FullPath);
            obj.setFullPath(handles);
            
            
            % clear previous file paths
            
        end
    end
    
end

