classdef imtool3DROI_rect < imtool3DROI
    
    properties
        fixedAspectRatio = false;
    end
    
    properties (SetAccess = protected, GetAccess = protected)
        position        %defines the center of the box and its width/height [cx cy width height]
        tbuff           %amount of space (in pixels) to place the text above the ROI
    end
    
    properties (Dependent = true, Access = public)
        aspectRatio
    end
    
    methods
        
        %constructor
        function ROI = imtool3DROI_rect(varargin)
            
            switch nargin
                case 0  %use the current figure
                    
                    %let the user draw the ROI
                    h = imrect;
                    
                    %get the parent axes
                    ha = get(h,'Parent');
                    
                    %get the handle of the image
                    hi = imhandles(ha);
                    if length(hi)>1
                        for i=1:length(hi)
                            if ndims(get(hi(i),'CData'))<3
                                imageHandle = hi(i);
                            end
                        end
                    else
                        imageHandle = hi;
                    end
                    
                    %get the position
                    pos = getPosition(h);
                    position = [pos(1)+pos(3)/2 pos(2)+pos(4)/2 pos(3) pos(4)];
                    
                    %delete the imroi object
                    delete(h);
                case 1 %user inputs only the handle to the image
                    imageHandle = varargin{1};
                    parent = get(imageHandle,'Parent');
                    h = imrect(parent);
                    pos = getPosition(h);
                    position = [pos(1)+pos(3)/2 pos(2)+pos(4)/2 pos(3) pos(4)];
                    delete(h);
                case 2 %user inputs both the parent handle and a position
                    imageHandle = varargin{1};
                    position = varargin{2};
                case 3
                    imageHandle = varargin{1};
                    position = varargin{2};
                    if isempty(position)
                        parent = get(imageHandle,'Parent');
                        h = imrect(parent);
                        pos = getPosition(h);
                        position = [pos(1)+pos(3)/2 pos(2)+pos(4)/2 pos(3) pos(4)];
                        delete(h);
                    end
                    tool = varargin{3};
            end
            
            %get the parent axis handle
            parent = get(imageHandle,'Parent');
            
            %find the top left corner of the box
            pos = [position(1)-position(3)/2 position(2)-position(4)/2 position(3) position(4)];
            
            %Draw the rectangle at the desired spot
            graphicsHandles(1) = rectangle('Position',pos,'Parent',parent,'EdgeColor','r','LineWidth',1.5,'Curvature',[0 0]);
            
            %Draw a cross at the center of the box and sqaures on the sides
            nextPlot = get(parent,'NextPlot');  %make sure the new graphics don't delete the old ones
            set(parent,'NextPlot','add');
            graphicsHandles(2) = plot(position(1),position(2),'+r','MarkerSize',12,'Parent',parent); %middle cross
            graphicsHandles(3) = plot(pos(1),pos(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %top left corner
            graphicsHandles(4) = plot(pos(1)+pos(3),pos(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %top right corner
            graphicsHandles(5) = plot(pos(1),pos(2)+pos(4),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %bottom left corner
            graphicsHandles(6) = plot(pos(1)+pos(3),pos(2)+pos(4),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %bottom right corner
            graphicsHandles(7) = plot(pos(1),position(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %left
            graphicsHandles(8) = plot(pos(1)+pos(3),position(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %right
            graphicsHandles(9) = plot(position(1),pos(2),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %top
            graphicsHandles(10) = plot(position(1),pos(2)+pos(4),'sr','MarkerSize',8,'Parent',parent,'MarkerFaceColor','r'); %bottom
            set(graphicsHandles,'Clipping','off')
            set(parent,'NextPlot',nextPlot);
            
            %Define the context menu options (i.e., what happens when you
            %right click on the ROI)
            menuLabels = {'Export stats','Fix Aspect Ratio','Hide Text','Delete','poly2mask'};
            if ~exist('tool','var') || isempty(tool), menuLabels(end) = []; tool = []; end
            menuFunction = @contextMenuCallback;
            
            %create the ROI object from the superclass
            ROI@imtool3DROI(imageHandle,graphicsHandles,menuLabels,menuFunction, tool);
            
            %Create the text box
            I = get(ROI.imageHandle,'CData');
            ROI.tbuff = .02*size(I,1);
            ROI.textHandle = text(pos(1),pos(2)-ROI.tbuff,'text','Parent',parent,'Color','w','FontSize',10,'EdgeColor','w','BackgroundColor','k','HorizontalAlignment','Left','VerticalAlignment','bottom','Clipping','on');
            
            %Set the position property of the ROI
            ROI.position = position;
            
            %Set the button down functions of the graphics
            for i=1:length(graphicsHandles)
                fun = @(hObject,evnt) ButtonDownFunction(hObject,evnt,ROI,i); set(graphicsHandles(i),'ButtonDownFcn',fun);
            end
            
            %add a listener for changes in the image. This automatically
            %updates the ROI text when the image changes
            ROI.listenerHandle = addlistener(ROI.imageHandle,'CData','PostSet',@ROI.handlePropEvents);
            
            %update the text
            newPosition(ROI,position)
            
        end
        
        function position = getPosition(ROI)
            position = ROI.position;
        end
        
        function newPosition(ROI,position, notifoff)
            
            %Adjust the position if the aspect ratio should be fixed
            if ROI.fixedAspectRatio
                
            end
            
            %set the position property of the ROI
            ROI.position = position;
            
            %find the top left corner of the box
            pos = [position(1)-position(3)/2 position(2)-position(4)/2 position(3) position(4)];
            
            %get the graphics handles
            graphicsHandles = ROI.graphicsHandles;
            
            %set the new position of the rectangle and other graphics
            %objects
            set(graphicsHandles(1),'Position',pos);
            set(graphicsHandles(2),'Xdata',position(1),'Ydata',position(2));
            set(graphicsHandles(3),'Xdata',pos(1),'Ydata',pos(2));
            set(graphicsHandles(4),'Xdata',pos(1)+pos(3),'Ydata',pos(2));
            set(graphicsHandles(5),'Xdata',pos(1),'Ydata',pos(2)+pos(4));
            set(graphicsHandles(6),'Xdata',pos(1)+pos(3),'Ydata',pos(2)+pos(4));
            set(graphicsHandles(7),'Xdata',pos(1),'Ydata',position(2));
            set(graphicsHandles(8),'Xdata',pos(1)+pos(3),'Ydata',position(2));
            set(graphicsHandles(9),'Xdata',position(1),'Ydata',pos(2));
            set(graphicsHandles(10),'Xdata',position(1),'Ydata',pos(2)+pos(4));
            
            %get the ROI measurements
            stats = getMeasurements(ROI);
            
            %set the textbox
            str = {['Mean: ' num2str(stats.mean,'%+.2f')], ['STD:     ' num2str(stats.STD,'%.2f')]};
            set(ROI.textHandle,'String',str,'Position',[pos(1) pos(2)-ROI.tbuff]);
            
            %notify a new position
            if ~exist('notifoff','var') || ~notifoff
                notify(ROI,'newROIPosition');
            end
            
            
        end
        
        function newPositionSameSize(ROI,pos)
            position = ROI.position;
            position(1:2)=pos;
            newPosition(ROI,position);
        end
        
        function [x, y] = getPoly(ROI)
            %get the position
            position = ROI.position;
            
            %find the top left corner of the box
            pos = [position(1)-position(3)/2 position(2)-position(4)/2 position(3) position(4)];
            
            %make the polygon
            x = [pos(1) pos(1)+pos(3) pos(1)+pos(3) pos(1) pos(1)];
            y = [pos(2) pos(2) pos(2)+pos(4) pos(2)+pos(4) pos(2)];
        end
        
        function stats = getMeasurements(ROI)
            [x, y] = getPoly(ROI);
            im = double(get(ROI.imageHandle,'CData'));
            
            m = size(im,1);
            n = size(im,2);
            %Scale the polygon to match the size of the displayed image (in
            %the case that the displayed image is being upsampled to match
            %the screen resolution).
            x = x*n/ROI.imageHandle.XData(2);
            y = y*m/ROI.imageHandle.YData(2);
            
            mask = poly2mask(x,y,m,n);
            
            im = im(mask);
            
            stats.mean = mean(im);
            stats.STD = std(im);
            stats.min = min(im);
            stats.max = max(im);
            stats.mask = mask;
            stats.position = ROI.position;
            
        end
        
        function handlePropEvents(ROI,src,evnt)
            position = getPosition(ROI);
            newPosition(ROI,position);
        end
        
        function set.fixedAspectRatio(ROI,fixedAspectRatio)
            %Set the fixed aspect ratio property
            ROI.fixedAspectRatio = fixedAspectRatio;
            %update the context menu
            for i=1:length(ROI.menuHandles)
                if strcmp(get(ROI.menuHandles(i),'Label'),'Fix Aspect Ratio')
                    if fixedAspectRatio
                        set(ROI.menuHandles(i),'Check','on')
                    else
                        set(ROI.menuHandles(i),'Check','off')
                    end
                end
            end
        end
        
        function aspectRatio = get.aspectRatio(ROI)
            position = ROI.position;
            aspectRatio = position(3)/position(4);
        end
        
        function BB = getBoundingBox(ROI)
            %BB = [rowMin rowMax; colMin ColMax];
            lims = size(get(ROI.imageHandle,'CData'));
            
            BB=zeros(2);
            
            rowMin = floor(ROI.position(2) - ROI.position(4)/2);
            if rowMin < 1 
                rowMin = 1;
            end
            colMin = floor(ROI.position(1) - ROI.position(3)/2);
            if colMin < 1 
                colMin = 1;
            end
            rowMax = floor(ROI.position(2) + ROI.position(4)/2 - 1);
            if rowMax > lims(1)
                rowMax = lims(1);
            end
            colMax = floor(ROI.position(1) + ROI.position(3)/2 - 1);
            if colMax > lims(2)
                colMax = lims(2);
            end
            BB = [rowMin rowMax; colMin colMax];
            
            
            
            
        end
        
    end
        
end

function ButtonDownFunction(hObject,evnt,ROI,n)

%get the parent figure handle
fig = ROI.figureHandle;

%get the type of click
click = get(fig,'SelectionType');

if strcmp(click,'normal')
    %get the current button motion and button up functions of the figure
    WBMF_old = get(fig,'WindowButtonMotionFcn');
    WBUF_old = get(fig,'WindowButtonUpFcn');
    
    %set the new window button motion function and button up function of the figure
    fun = @(src,evnt) ButtonMotionFunction(src,evnt,ROI,n);
    fun2=@(src,evnt)  ButtonUpFunction(src,evnt,ROI,WBMF_old,WBUF_old);
    set(fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2);
end
end

function ButtonMotionFunction(src,evnt,ROI,n)
cp = get(ROI.axesHandle,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];

position = getPosition(ROI);

switch n
    case 2                                          %middle cross
        position(1) = cp(1); position(2) = cp(2);
        
    case 3                                          %top left corner
        
        %find the bottom edge
        bottom = position(2)+position(4)/2;
        %get the new height
        height = bottom - cp(2);
        if height>1
            cy = cp(2)+height/2;
            position(2) = cy;
            position(4) = height;
            %Adjust cp(1) if you want to fix the aspect ratio
            if ROI.fixedAspectRatio
                cp(1) = position(1)+position(3)/2-height*ROI.aspectRatio;
            end
        end
        
        %find the right edge
        right = position(1)+position(3)/2;
        %find the new width
        width = right-cp(1);
        if width>1
            %find the new center
            cx = cp(1)+width/2;
            position(1) = cx;
            position(3) = width;
        end
        
        
    case 4                                          %top right corner
        %find the bottom edge
        bottom = position(2)+position(4)/2;
        %get the new height
        height = bottom - cp(2);
        if height>1
            cy = cp(2)+height/2;
            position(2) = cy;
            position(4) = height;
            %Adjust cp(1) if you want to fix the aspect ratio
            if ROI.fixedAspectRatio
                cp(1) = position(1)-position(3)/2+height*ROI.aspectRatio;
            end
        end
        
        %find the left edge
        left = position(1)-position(3)/2;
        %find the new width
        width = cp(1) - left;
        if width>1
            cx = cp(1)-width/2;
            position(1) = cx;
            position(3) = width;
        end
       
        
    case 5                                          %bottom left corner
        %find the top edge
        top = position(2)-position(4)/2;
        %get the new height
        height = cp(2) - top;
        if height>1
            cy = cp(2)-height/2;
            position(2) = cy;
            position(4) = height;
            %Adjust cp(1) if you want to fix the aspect ratio
            if ROI.fixedAspectRatio
                cp(1) = position(1)+position(3)/2+-height*ROI.aspectRatio;
            end
        end
        
        %find the right edge
        right = position(1)+position(3)/2;
        %find the new width
        width = right-cp(1);
        if width>1
            %find the new center
            cx = cp(1)+width/2;
            position(1) = cx;
            position(3) = width;
        end
        
        
    case 6                                          %bottom right corner
        %find the top edge
        top = position(2)-position(4)/2;
        %get the new height
        height = cp(2) - top;
        if height>1
            cy = cp(2)-height/2;
            position(2) = cy;
            position(4) = height;
            %Adjust cp(1) if you want to fix the aspect ratio
            if ROI.fixedAspectRatio
                cp(1) = position(1)-position(3)/2+height*ROI.aspectRatio;
            end
        end
        
        %find the left edge
        left = position(1)-position(3)/2;
        %find the new width
        width = cp(1) - left;
        if width>1
            cx = cp(1)-width/2;
            position(1) = cx;
            position(3) = width;
        end
        
        
    case 7                                          %left
        %find the right edge
        right = position(1)+position(3)/2;
        %find the new width
        width = right-cp(1);
        if width>1
            %find the new center
            cx = cp(1)+width/2;
            position(1) = cx;
            position(3) = width;
        end
        
        if ROI.fixedAspectRatio
            position(4) = width/ROI.aspectRatio;
        end
        
    case 8                                          %right
        %find the left edge
        left = position(1)-position(3)/2;
        %find the new width
        width = cp(1) - left;
        if width>1
            cx = cp(1)-width/2;
            position(1) = cx;
            position(3) = width;
        end
        
        if ROI.fixedAspectRatio
            position(4) = width/ROI.aspectRatio;
        end
        
    case 9                                          %top
        %find the bottom edge
        bottom = position(2)+position(4)/2;
        %get the new height
        height = bottom - cp(2);
        if height>1
            cy = cp(2)+height/2;
            position(2) = cy;
            position(4) = height;
        end
        
        if ROI.fixedAspectRatio
            position(3) = height*ROI.aspectRatio;
        end
        
    case 10                                         %bottom
        %find the top edge
        top = position(2)-position(4)/2;
        %get the new height
        height = cp(2) - top;
        if height>1
            cy = cp(2)-height/2;
            position(2) = cy;
            position(4) = height;
        end
        
        if ROI.fixedAspectRatio
            position(3) = height*ROI.aspectRatio;
        end
        
end

newPosition(ROI,position);

end

function ButtonUpFunction(src,evnt,ROI,WBMF_old,WBUF_old)
fig = ROI.figureHandle;
set(fig,'WindowButtonMotionFcn',WBMF_old,'WindowButtonUpFcn',WBUF_old);
end

function contextMenuCallback(source,callbackdata,ROI, tool)

switch get(source,'Label')
    case 'Delete'
        delete(ROI);
    case 'Export stats'
        stats = getMeasurements(ROI);
        name = inputdlg('Enter variable name');
        if isempty(name); return; end
        name=name{1};
        assignin('base', name, stats)
    case 'Fix Aspect Ratio'
        switch get(source,'Checked')
            case 'off'
                ROI.fixedAspectRatio=true;
            case 'on'
                ROI.fixedAspectRatio=false;
        end
    case 'Hide Text'
        switch get(source,'Checked')
            case 'off'
                set(source,'Checked','on');
                ROI.textVisible = false;
            case 'on'
                set(source,'Checked','off');
                ROI.textVisible = true;
        end
    case 'poly2mask'
        mask = tool.getCurrentMaskSlice;
        
        [x, y] = getPoly(ROI);
        
        m = size(mask,1);
        n = size(mask,2);
        %Scale the polygon to match the size of the displayed image (in
        %the case that the displayed image is being upsampled to match
        %the screen resolution).
        x = x*n/ROI.imageHandle.XData(2);
        y = y*m/ROI.imageHandle.YData(2);
        
        masknew = poly2mask(x,y,m,n);
        combine = true;
        tool.setCurrentMaskSlice(masknew,combine);
        notify(tool,'maskChanged')
end


end