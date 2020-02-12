classdef (CaseInsensitiveProperties) dndcontrol < handle
%DNDCONTROL Class for Drag & Drop functionality.
%   obj = DNDCONTROL(javaobj) creates a dndcontrol object for the specified
%   Java object, such as 'javax.swing.JTextArea' or 'javax.swing.JList'. Two
%   callback functions are available: obj.DropFileFcn and obj.DropStringFcn, 
%   that listen to drop actions of respectively system files or plain text.
%
%   The Drag & Drop control class relies on a Java class that need to be
%   visible on the Java classpath. To initialize, call the static method
%   dndcontrol.initJava(). The Java class can be adjusted and recompiled if
%   desired.
%
%   DNDCONTROL Properties:
%       Parent            - The associated Java object.
%       DropFileFcn       - Callback function for system files.
%       DropStringFcn     - Callback function for plain text.
%
%   DNDCONTROL Methods:
%       dndcontrol        - Constructs the DNDCONTROL object.
%
%   DNDCONTROL Static Methods:
%       defaultDropFcn    - Default callback function for drop events.
%       demo              - Runs the demonstration script.
%       initJava          - Initializes the Java class.
%       isInitialized     - Checks if the Java class is visible.
%
%   A demonstration is available from the static method dndcontrol.demo().
%
%   Example:
%       dndcontrol.initJava();
%       dndcontrol.demo();
%
%   See also:
%       uicontrol, javaObjectEDT.    
%
%   Written by: Maarten van der Seijs, 2015.
%   Version: 1.0, 13 October 2015.

        
    properties (Hidden)
        dropTarget;                
    end
    
    properties (Dependent)
        %PARENT The associated Java object.
        Parent;
    end
    
    properties
        %DROPFILEFCN Callback function executed upon dropping of system files.
        DropFileFcn;        
        %DROPSTRINGFCN Callback function executed upon dropping of plain text.
        DropStringFcn;        
    end
       
    methods (Static)
        function initJava()
        %INITJAVA Initializes the required Java class.
        
            %Add java folder to javaclasspath if necessary
            if ~dndcontrol.isInitialized();
                classpath = fileparts(mfilename('fullpath'));                
                javaclasspath(classpath);                
            end 
        end
        
        function TF = isInitialized()            
        %ISINITIALIZED Returns true if the Java class is initialized.
        
            TF = (exist('MLDropTarget','class') == 8);
        end                           
    end
    
    methods
        function obj = dndcontrol(Parent,DropFileFcn,DropStringFcn)
        %DNDCONTROL Drag & Drop control constructor.
        %   obj = DNDCONTROL(javaobj) contstructs a DNDCONTROL object for 
        %   the given parent control javaobj. The parent control should be a 
        %   subclass of java.awt.Component, such as most Java Swing widgets.
        %
        %   obj = DNDCONTROL(javaobj,DropFileFcn,DropStringFcn) sets the
        %   callback functions for dropping of files and text.
            
            % Check for Java class
            assert(dndcontrol.isInitialized(),'Javaclass MLDropTarget not found. Call dndcontrol.initJava() for initialization.')
             
            % Construct DropTarget            
            obj.dropTarget = handle(javaObjectEDT('MLDropTarget'),'CallbackProperties');
            set(obj.dropTarget,'DropCallback',{@dndcontrol.DndCallback,obj});
            set(obj.dropTarget,'DragEnterCallback',{@dndcontrol.DndCallback,obj});
            
            % Set DropTarget to Parent
            if nargin >=1, Parent.setDropTarget(obj.dropTarget); end
            
            % Set callback functions
            if nargin >=2, obj.DropFileFcn = DropFileFcn; end 
            if nargin >=3, obj.DropStringFcn = DropStringFcn; end
        end
        
        function set.Parent(obj, Parent)
            if isempty(Parent)
                obj.dropTarget.setComponent([]);
                return
            end
            if isa(Parent,'handle') && ismethod(Parent,'java')
                Parent = Parent.java;
            end
            assert(isa(Parent,'java.awt.Component'),'Parent is not a subclass of java.awt.Component.')
            assert(ismethod(Parent,'setDropTarget'),'DropTarget cannot be set on this object.')
            
            obj.dropTarget.setComponent(Parent);
        end
        
        function Parent = get.Parent(obj)
            Parent = obj.dropTarget.getComponent();
        end
    end
    
    methods (Static, Hidden = true)
        %% Callback functions
        function DndCallback(jSource,jEvent,obj)
            
            if jEvent.isa('java.awt.dnd.DropTargetDropEvent')
                % Drop event     
                try
                    switch jSource.getDropType()
                        case 0
                            % No success.
                        case 1
                            % String dropped.
                            string = char(jSource.getTransferData());
                            if ~isempty(obj.DropStringFcn)
                                evt = struct();
                                evt.DropType = 'string';
                                evt.Data = string;                                
                                feval(obj.DropStringFcn,obj,evt);
                            end
                        case 2
                            % File dropped.
                            files = cell(jSource.getTransferData());                            
                            if ~isempty(obj.DropFileFcn)
                                evt = struct();
                                evt.DropType = 'file';
                                evt.Data = files;                                
                                feval(obj.DropFileFcn,obj,evt);
                            end
                    end
                    
                    % Set dropComplete
                    jEvent.dropComplete(true);  
                catch ME
                    % Set dropComplete
                    jEvent.dropComplete(true);  
                    rethrow(ME)
                end                              
                
            elseif jEvent.isa('java.awt.dnd.DropTargetDragEvent')
                 % Drag event                               
                 action = java.awt.dnd.DnDConstants.ACTION_COPY;
                 jEvent.acceptDrag(action);
            end            
        end
    end
    
    methods (Static)
        function defaultDropFcn(src,evt)
        %DEFAULTDROPFCN Default drop callback.
        %   DEFAULTDROPFCN(src,evt) accepts the following arguments:
        %       src   - The dndcontrol object.
        %       evt   - A structure with fields 'DropType' and 'Data'.
        
            fprintf('Drop event from %s component:\n',char(src.Parent.class()));
            switch evt.DropType
                case 'file'
                    fprintf('Dropped files:\n');
                    for n = 1:numel(evt.Data)
                        fprintf('%d %s\n',n,evt.Data{n});
                    end
                case 'string'
                    fprintf('Dropped text:\n%s\n',evt.Data);
            end
        end            
        
        function [dndobj,hFig] = demo()
        %DEMO Demonstration of the dndcontrol class functionality.
        %   dndcontrol.demo() runs the demonstration. Make sure that the
        %   Java class is visible in the Java classpath.
            
            % Initialize Java class
            dndcontrol.initJava();
        
            % Create figure
            hFig = figure();
            
            % Create Java Swing JTextArea
            jTextArea = javaObjectEDT('javax.swing.JTextArea', ...
                sprintf('Drop some files or text content here.\n\n'));
            
            % Create Java Swing JScrollPane
            jScrollPane = javaObjectEDT('javax.swing.JScrollPane', jTextArea);
            jScrollPane.setVerticalScrollBarPolicy(jScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
                        
            % Add Scrollpane to figure
            [~,hContainer] = javacomponent(jScrollPane,[],hFig);
            set(hContainer,'Units','normalized','Position',[0 0 1 1]);
            
            % Create dndcontrol for the JTextArea object
            dndobj = dndcontrol(jTextArea);
            
            % Set Drop callback functions
            dndobj.DropFileFcn = @demoDropFcn;
            dndobj.DropStringFcn = @demoDropFcn;
            
            % Callback function
            function demoDropFcn(~,evt)
                switch evt.DropType
                    case 'file'
                        jTextArea.append(sprintf('Dropped files:\n'));
                        for n = 1:numel(evt.Data)
                            jTextArea.append(sprintf('%d %s\n',n,evt.Data{n}));
                        end
                    case 'string'
                        jTextArea.append(sprintf('Dropped text:\n%s\n',evt.Data));
                end
                jTextArea.append(sprintf('\n'));
            end
        end
    end    
end