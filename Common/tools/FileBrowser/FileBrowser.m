classdef FileBrowser < handle
    %FILEBROWSER parent class for file browsers specific to METHODs
    %   Detailed explanation goes here
    
    properties
        WorkDir_TextArea;
        WorkDir_BrowseBtn;
        WorkDir_FileNameArea;
        WorkDir_FullFile;
        
        StudyID_TextArea;
        StudyID_TextID;
    end
    
    methods
        % -- FileBrowser constructor
        % Input: 
        %           handles     parent panel for buttons
        function obj = FileBrowser(parent)            
            WorkDir_TextArea = uicontrol(parent, 'Style', 'Text', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Work Dir:', 'HorizontalAlignment', 'left', 'Position', [0.02,0.85,0.1,0.1],'FontSize', 0.6);
            WorkDir_BrowseBtn = uicontrol(parent, 'Style', 'pushbutton', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Browse', 'Position', [0.11,0.85,0.1,0.1], 'FontSize', 0.6);
            WorkDir_FileNameArea = uicontrol(parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized', 'Position', [0.22,0.85,0.3,0.1],'FontSize', 0.6);
                        
            StudyID_TextArea = uicontrol(parent, 'Style', 'text', 'units', 'normalized', 'fontunits', 'normalized', ...
                'String', 'Study ID:', 'Position', [0.55,0.85,0.1,0.1], 'FontSize', 0.6);
            StudyID_TextID = uicontrol(parent, 'Style', 'edit','units', 'normalized', 'fontunits', 'normalized', 'Position', [0.65,0.85,0.3,0.1],'FontSize', 0.6);
            
        end % end constructor
        
    end
    
end

