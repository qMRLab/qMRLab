classdef BrowserSet < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    
    properties
        NameText;
        BrowseBtn;
        FileBox;
        ViewBtn;
        
        BrowseBtnOn;
        ViewBtnOn;
        
        NameID;
        FullFile;
    end
    
    methods
        % constructor
        function obj = BrowserSet(varargin)
            
            if nargin>0
                % parse the input arguments
                parent = varargin{1};
                handles = varargin{2};
                Name = varargin{3};
                Location = varargin{4};
                obj.BrowseBtnOn = varargin{5};
                obj.ViewBtnOn = varargin{6};

                
                obj.NameID = Name;

                Position = [Location, 0.1, 0.1];
                obj.NameText = uicontrol(parent, 'Style', 'Text', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', Name, 'HorizontalAlignment', 'left', 'Position', Position,'FontSize', 0.6);

                if obj.BrowseBtnOn == 1
                    Location = Location + [0.1, 0];
                    Position = [Location, 0.1, 0.1];
                    obj.BrowseBtn = uicontrol(parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                    'String', 'Browse', 'Position', Position, 'FontSize', 0.6, ...
                    'Callback', {@(src, event)BrowserSet.BrowseBtn_callback(obj, src, event, handles)});
                end 

                Location = Location + [0.11, 0];
                Position = [Location, 0.65, 0.1];
                obj.FileBox = uicontrol(parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized', 'Position', Position,'FontSize', 0.6);

                if obj.ViewBtnOn == 1 
                    Location = Location + [0.66, 0];
                    Position = [Location, 0.1, 0.1];
                    obj.ViewBtn = uicontrol(parent, 'style', 'pushbutton','units', 'normalized', 'fontunits', 'normalized', ...
                        'String', 'View', 'Position', Position, 'FontSize', 0.6, ...
                        'Callback', {@(src, event)BrowserSet.ViewBtn_callback(obj, src, event, handles)});            end
            end % testing varargin
        end % constructor end
    end
    
    methods
        function VisibleOn(obj)
            set(obj.NameText, 'Visible', 'on');
            set(obj.BrowseBtn, 'Visible', 'on');
            set(obj.FileBox, 'Visible', 'on');
            set(obj.ViewBtn, 'Visible', 'on');
        end
        
        function VisibleOff(obj)
            set(obj.NameText, 'Visible', 'off');
            set(obj.BrowseBtn, 'Visible', 'off');
            set(obj.FileBox, 'Visible', 'off');
            set(obj.ViewBtn, 'Visible', 'off');
        end
    end
    
    methods(Static)
        %------------------------------------------------------------------
        % -- BROWSE BUTTONS
        %------------------------------------------------------------------
        function BrowseBtn_callback(obj,src, event, handles)
            FullFile = ManageTextArea(obj, obj.FileBox);
            if FullFile == 0 
                return;
            end
            data = [];
            data = LoadImage(FullFile);
            setappdata(0, Name, data);
            % define internal variables
            Data.(NameID) = double(data);
            Data.fields = {NameID};
            handles.CurrentData = Data;  
        end
        
        function ViewBtn_callback(obj,src, event, handles)
        end
    end
    
end

