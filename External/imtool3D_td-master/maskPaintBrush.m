classdef maskPaintBrush < handle
    
    properties
        handles
        position                    %[x y radius]
        Visible = 'on';
        color = [206 82 65]./256;
        nPoints = 20;
        oldWBMF
        oldPTR
    end
    
    events
    end
    
    methods
        %Contructor
        function brush = maskPaintBrush(tool)
            
            %get the parent axes handle
            h = getHandles(tool);
            brush.handles.parent = h.Axes;
            brush.handles.fig = h.fig;
            brush.handles.tool=tool;
            
            %get the mouse location
            cp = get(brush.handles.parent,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
            position = [cp(1,1) cp(1,2) 5];
             
            %Create the circle object
            pos = [position(1)-position(3) position(2)-position(3) 2*position(3) 2*position(3)];
            brush.handles.circle = rectangle('Position',pos,'Parent',brush.handles.parent,'EdgeColor',brush.color,'LineWidth',1.5,'Curvature',[1 1],'PickableParts','all');
            
            %Get the old window button motion function
            brush.oldWBMF = get(brush.handles.fig,'WindowButtonMotionFcn');
            
            %Get the old pointer style
            brush.oldPTR.ptr = get(brush.handles.fig,'Pointer');
            brush.oldPTR.CData = get(brush.handles.fig,'PointerShapeCData');
            
            %Make the pointer invisible
            set(brush.handles.fig,'Pointer','custom','PointerShapeCData',nan(16))
            
            %Set the new window button motion function
            fun = @(src,evnt) ButtonMotionFunction(src,evnt,brush,'No Click',[]);
            set(brush.handles.fig,'WindowButtonMotionFcn',fun)
            
            %Set the mouse click function
            fun=@(hObject,eventdata) buttonDownFunction(hObject,eventdata,brush);
            set(brush.handles.circle,'ButtonDownFcn',fun)
            
            
            %set the position property of the brush
            brush.position=position;
            
            
        end
        
        function delete(brush)  %destructor
            try
                delete(brush.handles.circle);
                set(brush.handles.fig,'Pointer',brush.oldPTR.ptr,'PointerShapeCData',brush.oldPTR.CData,'WindowButtonMotionFcn',brush.oldWBMF);
            end
        end
        
        function set.position(brush,position)
            brush.position=position;
            pos = [position(1)-position(3) position(2)-position(3) 2*position(3) 2*position(3)];
            set(brush.handles.circle,'Position',pos);
        end
        
        function set.Visible(brush,visible)
            set(brush.handles.cirlce,'Visible',visible);
        end
        
        function mask = getBrushMask(brush)
            %This function creates a binary mask based on the current
            %position of the mask
            
            t=linspace(0,2*pi,brush.nPoints); %elliptical equation is parameterized by t
            x = brush.position(3)*cos(t)+brush.position(1);
            y= brush.position(3)*sin(t)+brush.position(2);
            S = getImageSize(brush.handles.tool);
            mask = poly2mask(x,y,S(1),S(2));
            
   
        end
        
        function answer = isInAxis(brush)
           
            xlim=get(brush.handles.parent,'Xlim');
            ylim=get(brush.handles.parent,'Ylim');
            
            if brush.position(1)>=xlim(1) && brush.position(1)<=xlim(2) && brush.position(2)>=ylim(1) && brush.position(2)<=ylim(2)
                answer = true;
            else
                answer = false;
            end
            
        end
    end
    
end

function buttonUpFunction(hObject,eventdata,WBMF_old,WBUF_old,brush)
set(hObject,'WindowButtonMotionFcn',WBMF_old,'WindowButtonUpFcn',WBUF_old);
notify(brush.handles.tool,'maskChanged')

end

function buttonDownFunction(hObject,eventdata,brush)

WBMF_old = get(brush.handles.fig,'WindowButtonMotionFcn');
WBUF_old = get(brush.handles.fig,'WindowButtonUpFcn');
switch get(brush.handles.fig,'SelectionType')
    case 'normal'   %left click (paint on the mask)
        fun = @(src,evnt) ButtonMotionFunction(src,evnt,brush,'Left Click',[]);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,WBMF_old,WBUF_old,brush);
        set(brush.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
        fun([],[]);     
        
    case 'alt'      %right click
        fun = @(src,evnt) ButtonMotionFunction(src,evnt,brush,'Right Click',[]);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,WBMF_old,WBUF_old,brush);
        set(brush.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
        fun([],[]);     
    case 'extend'   %center click
        data.bp=get(0,'PointerLocation');
        data.r = brush.position(3);
        fun = @(src,evnt) ButtonMotionFunction(src,evnt,brush,'Middle Click',data);
        fun2=@(src,evnt) buttonUpFunction(src,evnt,WBMF_old,WBUF_old,brush);
        set(brush.handles.fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2)
        fun([],[]);
end

end

function ButtonMotionFunction(src,evnt,brush,tag,data)

switch tag
    case 'No Click'
        cp = get(brush.handles.parent,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
        brush.position = [cp(1) cp(2) brush.position(3)];
        
        %Check if the cursor is within the axis
        if isInAxis(brush)
             set(brush.handles.fig,'Pointer','custom','PointerShapeCData',nan(16))
        else
            set(brush.handles.fig,'Pointer',brush.oldPTR.ptr,'PointerShapeCData',brush.oldPTR.CData)
            
        end
        
    case 'Left Click'
        %moves the circle
        cp = get(brush.handles.parent,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
        brush.position = [cp(1) cp(2) brush.position(3)];
        
        %get the mask for the new brush position
        mask = getBrushMask(brush);
        
        %get the current mask of the imtool3D object
        maskOld = getCurrentMaskSlice(brush.handles.tool);
        
        %Combine the two masks
        mask = mask | maskOld;
        
        %Update the mask of the tool
        setCurrentMaskSlice(brush.handles.tool,mask)
        
    case 'Right Click'
        %moves the circle
        cp = get(brush.handles.parent,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];
        brush.position = [cp(1) cp(2) brush.position(3)];
        
        %get the mask for the new brush position
        mask = getBrushMask(brush);
        
        %get the current mask of the imtool3D object
        maskOld = getCurrentMaskSlice(brush.handles.tool);
        
        %Combine the two masks
        mask = maskOld   &   ~(mask & maskOld);
        
        %Update the mask of the tool
        setCurrentMaskSlice(brush.handles.tool,mask)
        
    case 'Middle Click'
        %get the current mouse position 
        cp = get(0,'PointerLocation');
       
        %get the difference in the y direction
        d = .25*(data.bp(2)-cp(2));
        
        rnew = data.r+d;
        if rnew<1
            rnew=1;
        end
        
        brush.position(3)=rnew;
        
end

end