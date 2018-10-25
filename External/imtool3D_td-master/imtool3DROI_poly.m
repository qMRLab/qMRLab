classdef imtool3DROI_poly < imtool3DROI
    
    properties

    end
    
    properties (SetAccess = protected, GetAccess = protected)
        position        %nx2 matrix that defines the vertices of the polygon [x y] 
        tbuff           %amount of space (in pixels) to place the text above the ROI
    end
    
    methods
        %Contructor
        function ROI = imtool3DROI_poly(varargin)
            
            switch nargin
                case 0  %use the current figure
                    
                    %let the user draw the ROI
                    h = impoly;
                    
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
                    position = getPosition(h);
                    %close the polygon
                    position(end+1,:) = position(1,:);
                    
                    %delete the imroi object
                    delete(h);
                case 1 %user inputs only the handle to the image
                    imageHandle = varargin{1};
                    parent = get(imageHandle,'Parent');
                    h = impoly(parent);
                    position = getPosition(h);
                    position(end+1,:) = position(1,:);
                    delete(h);
                case 2 %user inputs both the parent handle and a position
                    imageHandle = varargin{1};
                    position = varargin{2};
                case 3
                    imageHandle = varargin{1};
                    position = varargin{2};
                    if isempty(position)
                        parent = get(imageHandle,'Parent');
                        h = impoly(parent);
                        position = getPosition(h);
                        position(end+1,:) = position(1,:);
                        delete(h);
                    end
                    tool = varargin{3};
            end
            
            %get the parent axis handle
            parent = get(imageHandle,'Parent');
            
            %Draw the graphics
            nextPlot = get(parent,'NextPlot');  %make sure the new graphics don't delete the old ones
            set(parent,'NextPlot','add');
            graphicsHandles(1) = plot(position(:,1),position(:,2),'-r','LineWidth',1.5,'Parent',parent);
            graphicsHandles(2) = plot(position(:,1),position(:,2),'sr','LineWidth',1.5,'MarkerSize',8,'Parent',parent,'MarkerFaceColor','r');
            graphicsHandles(3) = plot(position(1,1),position(1,2),'+r','MarkerSize',12,'Parent',parent); %centroid cross
            set(graphicsHandles,'Clipping','off')
            set(parent,'NextPlot',nextPlot);
            
            %Define the context menu options (i.e., what happens when you
            %right click on the ROI)
            menuLabels = {'Export stats','Hide Text','Delete','poly2mask'};
            if ~exist('tool','var'), menuLabels(end) = []; tool = []; end
            menuFunction = @contextMenuCallback;
            
            %create the ROI object from the superclass
            ROI@imtool3DROI(imageHandle,graphicsHandles,menuLabels,menuFunction,tool);
            
            %create the text object
            I = get(ROI.imageHandle,'CData');
            ROI.tbuff = .02*size(I,1);
            [x,y] = findTextPosition(position,ROI.tbuff);
            ROI.textHandle = text(x,y,'text','Parent',parent,'Color','w','FontSize',10,'EdgeColor','w','BackgroundColor','k','HorizontalAlignment','Left','VerticalAlignment','bottom','Clipping','on');
            
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
        
        function newPosition(ROI,position)
            
            %set the position property of the ROI
            ROI.position = position;
            
            %get the graphics handles
            graphicsHandles = ROI.graphicsHandles;
            
            %set the new position of the polygon and other graphics
            %objects
            set(graphicsHandles(1),'XData',position(:,1),'YData',position(:,2));
            set(graphicsHandles(2),'XData',position(:,1),'YData',position(:,2));
            
            %get the ROI measurements
            stats = getMeasurements(ROI);
            
            %Set position of centroid
            set(graphicsHandles(3),'XData',stats.centroid(1),'YData',stats.centroid(2));
            
            %set the textbox
            [x,y] = findTextPosition(position,ROI.tbuff);
            str = {['Mean: ' num2str(stats.mean,'%+.2f')], ['STD:     ' num2str(stats.STD,'%.2f')]};
            set(ROI.textHandle,'String',str,'Position',[x y]);
            
            
        end
        
        function stats = getMeasurements(ROI)
            %get the position
            position = ROI.position;
            x=position(:,1);
            y=position(:,2);
            
            im = double(get(ROI.imageHandle,'CData'));
            
            m = size(im,1);
            n = size(im,2);
            %Scale the polygon to match the size of the displayed image (in
            %the case that the displayed image is being upsampled to match
            %the screen resolution).
            x = x*n/ROI.imageHandle.XData(2);
            y = y*m/ROI.imageHandle.YData(2);
            
            mask = poly2mask(x,y,m,n);
            cent = regionprops(double(mask),'Centroid');
            [x,y] = getPolygonCentroid(position);
            
            
            im = im(mask);
            
            stats.mean = mean(im);
            stats.STD = std(im);
            stats.min = min(im);
            stats.max = max(im);
            stats.mask = mask;
            stats.position = position;
            stats.centroid = [x y];
            
        end
        
        function handlePropEvents(ROI,src,evnt)
            position = getPosition(ROI);
            newPosition(ROI,position);
        end
        
    end
    
end

function [x,y] = getPolygonCentroid(position)
%get the vectors I need
xi = position(1:end-1,1); xip1 = position(2:end,1);
yi = position(1:end-1,2); yip1 = position(2:end,2);
xiyip1 = xi.*yip1;
xip1yi = xip1.*yi;
diff = xiyip1-xip1yi;

%Get area
A = .5 .* sum(xiyip1 - xip1yi);
A = 1./(6*A);

%Find the center
x = A .* sum((xi + xip1).*diff);
y = A .* sum((yi + yip1).*diff);

end

function [x,y] = findTextPosition(position,tbuff)
%This finds the postion of the text box given the polygon vertices

x = min(position(:,1)); y = min(position(:,2))-tbuff;


end

function ind = findLineSegment(position,cp)
%This finds the line segment that was clicked by the user

%first find distance from point to each line segment,see
%http://en.wikipedia.org/wiki/Distance_from_a_point_to_a_line
x=position(:,1); y = position(:,2);
dx = diff(x); dy = diff(y);
x0=cp(1); y0 = cp(2);
x2y1 = x(2:end).*y(1:end-1);
y2x1 = y(2:end).*x(1:end-1);
dist = abs (dy.*x0 - dx.*y0 + x2y1 - y2x1) ./ sqrt(dx.^2 + dy.^2);

%get the index of the min distance
[~, ind] = min(dist);



end

function ButtonDownFunction(hObject,evnt,ROI,n)

%get the parent figure handle
fig = ROI.figureHandle;

%get the current button motion and button up functions of the figure
WBMF_old = get(fig,'WindowButtonMotionFcn');
WBUF_old = get(fig,'WindowButtonUpFcn');

%get the original point that was clicked
op = get(ROI.axesHandle,'CurrentPoint'); op=[op(1,1) op(1,2)];

%get the original position of the ROI
position_old = getPosition(ROI);

%get the type of click
click = get(ROI.figureHandle,'SelectionType');

%set the default ind
ind=0;
if n == 2   %User clicked on a vertice to move it (or delete it)
    %find closest vertice to click
    dist = sqrt((position_old(:,1)-op(1)).^2 + (position_old(:,2)-op(2)).^2 );
    [~, ind] = min(dist);
    if ind == length(dist)
        ind = 1;
    end
    if strcmp(click,'extend') && size(position_old,1)>4 %user wants to delete the vertice
        
        switch ind
            case 1
                %remove first and last points
                position = position_old(2:end-1,:);
                %close the new polygon
                position(end+1,:) = position(1,:);
            otherwise
                position = [position_old(1:ind-1,:) ; position_old(ind+1:end,:)];
        end
        %set the new position of the ROI
        newPosition(ROI,position);
        
        %make the button motion function not do anything
        n = 0;
    end
    
end


if n ==1 && strcmp(click,'normal')    %The user clicked on a line and wants to add a vertice
    %get the point on the line to insert the new point
    try
        np = evnt.IntersectionPoint(1:2);
    catch
        np = op;
    end
    
    %get the index of the intersecting line segment
    ind = findLineSegment(position_old,np); %points will be ind to ind+1
    
    %insert the new point
    position = [position_old(1:ind,:); np ; position_old(ind+1:end,:)];
    
    %set the new position of the ROI
    newPosition(ROI,position);
    
    %set the parameters to allow the user to move the new vertice without
    %re-clicking
    position_old = position;
    ind = ind+1;
    n=2;
    op = np;
    
end

%set the new window button motion function and button up function of the figure
fun = @(src,evnt) ButtonMotionFunction(src,evnt,ROI,n,op,position_old,ind);
fun2=@(src,evnt)  ButtonUpFunction(src,evnt,ROI,WBMF_old,WBUF_old);
set(fig,'WindowButtonMotionFcn',fun,'WindowButtonUpFcn',fun2);

end

function ButtonMotionFunction(src,evnt,ROI,n,op,position_old,ind)
cp = get(ROI.axesHandle,'CurrentPoint'); cp=[cp(1,1) cp(1,2)];

switch n
    case 2      %user clicked on a vertice. Will move just that vertice
        position = getPosition(ROI);
        position(ind,1) = cp(1);
        position(ind,2) = cp(2);
        if ind ==1
            position(end,1) = cp(1);
            position(end,2) = cp(2);
        end
    case 3   %User clicked on the center mark. Entire ROI will pan
        d = cp - op;
        position(:,1) = position_old(:,1)+d(1);
        position(:,2) = position_old(:,2)+d(2);
    otherwise %location remains unchanged (happens when a vertice is removed and the user keeps the button pressed while moving the mouse)
        position = getPosition(ROI);
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
        name=name{1};
        assignin('base', name, stats)
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
         mask = tool.getMask;
         %get the position
         position = ROI.position;
         x=position(:,1);
         y=position(:,2);
         
         m = size(mask,1);
         n = size(mask,2);
         %Scale the polygon to match the size of the displayed image (in
         %the case that the displayed image is being upsampled to match
         %the screen resolution).
         x = x*n/ROI.imageHandle.XData(2);
         y = y*m/ROI.imageHandle.YData(2);
         
         masknew = poly2mask(x,y,m,n);
         mask(:,:,tool.getCurrentSlice) = mask(:,:,tool.getCurrentSlice) | masknew;
         tool.setMask(mask)
end


end