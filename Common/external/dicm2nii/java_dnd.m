classdef (CaseInsensitiveProperties) java_dnd < handle
% JAVA_DND Class for Drag & Drop functionality.
%   obj = JAVA_DND(javaobj) creates a java_dnd object for the specified Java
%   object, such as 'javax.swing.JTextArea' or 'javax.swing.JList'. Callback
%   function obj.DropFcn listen to drop actions of system files or plain text.
%
%   JAVA_DND Properties:
%       Parent            - The associated Java object.
%       DropFcn           - Callback function for files or plain txt.
%
%   JAVA_DND Methods:
%       java_dnd        - Constructs the java_dnd object.
%
%   See also:
%       uicontrol, javaObjectEDT.    
%
%   dndcontrol Written by: Maarten van der Seijs, 2015.
%   Version: 1.0, 13 October 2015.
%   Modified by Xiangrui Li for nii_viewer and dicm2nii:
%    1. Combine two callback into one
%    2. Allow extra input arguments
%    3. Remove initJava, and do it automatically
%    4. Remove demo etc to make it simple
%    5. Rename file to avoid problem in case original dndcontrol on path

    properties (Hidden)
        dropTarget;                
    end
    
    properties (Dependent)
        %PARENT The associated Java object.
        Parent;
    end
    
    properties
        DropFcn;        
    end
       
    methods
        function obj = java_dnd(Parent, DropFcn)
        %java_dnd Drag & Drop control constructor.
        %   obj = java_dnd(javaobj) contstructs a java_dnd object for 
        %   the given parent control javaobj. The parent control should be a 
        %   subclass of java.awt.Component, such as most Java Swing widgets.
        %
        %   obj = java_dnd(javaobj,DropFcn) sets the callback functions for
        %   dropping of files and text.
            
            if (exist('MLDropTarget','class') ~= 8)
                classpath = fileparts(mfilename('fullpath'));                
                javaclasspath(classpath);                
            end 
             
            % Construct DropTarget            
            obj.dropTarget = handle(javaObjectEDT('MLDropTarget'),'CallbackProperties');
            set(obj.dropTarget,'DropCallback',{@java_dnd.DndCallback,obj});
            set(obj.dropTarget,'DragEnterCallback',{@java_dnd.DndCallback,obj});
            
            % Set DropTarget to Parent
            if nargin >=1, Parent.setDropTarget(obj.dropTarget); end
            
            % Set callback functions
            if nargin >=2, obj.DropFcn = DropFcn; end 
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
        function DndCallback(jSource, jEvent, obj)
            
            if jEvent.isa('java.awt.dnd.DropTargetDropEvent') % Drop event     
                try
                    dropType = jSource.getDropType();
                    if dropType<1 || dropType>2 % No success.
                        jEvent.dropComplete(true);  
                        return;
                    end
                    
                    if dropType==1 % String dropped.
                        evt.DropType = 'string';
                        evt.Data = char(jSource.getTransferData());
                    else % file(s) dropped.
                        evt.DropType = 'file';
                        evt.Data = cell(jSource.getTransferData());
                    end
                    
                    if iscell(obj.DropFcn)
                        feval(obj.DropFcn{1}, obj, evt, obj.DropFcn{2:end});
                    else
                        feval(obj.DropFcn, obj, evt);
                    end
                    
                    % Set dropComplete
                    jEvent.dropComplete(true);  
                catch ME
                    % Set dropComplete
                    jEvent.dropComplete(true);  
                    rethrow(ME)
                end                              
                
            elseif jEvent.isa('java.awt.dnd.DropTargetDragEvent') % Drag event                               
                 action = java.awt.dnd.DnDConstants.ACTION_COPY;
                 jEvent.acceptDrag(action);
            end            
        end
    end
end