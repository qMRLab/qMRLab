classdef imtool3DROI_line < imtool3DROI
    
    properties

    end
    
    properties (SetAccess = protected, GetAccess = protected)
        position     %nx2 matrix that defines the vertices of the polygon [x y] 
        tbuff = 10;  %amount of space (in pixels) to place the text above the line
        pbuff = 10;  %amount of space (in pixels) to place the line profile above the line
        pheight      %height of the line profile drawn above the ROI line. Default sets it to a percentage of the size of the image
    end
    
    methods
        
        %Contstructor
        function ROI = imtool3DROI_line(varargin)
            
            switch nargin
                case 0  %use the current figure
                    
                    %let the user draw the line
                    h = imline;
                    
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
                    %make sure the second point is different than the first
                    if position(1,1) == position(1,2) && position(2,1) == position(2,2)
                        position(2,:) = position(2,:)+5;
                    end
                    
                    %delete the imroi object
                    delete(h);
                case 1 %user inputs only the handle to the image
                    imageHandle = varargin{1};
                    parent = get(imageHandle,'Parent');
                    h = imline(parent);
                    position = getPosition(h);
                    if position(1,1) == position(1,2) && position(2,1) == position(2,2)
                       position(2,:) = position(2,:)+5;
                    end
                    delete(h);
                case 2 %user inputs both the parent handle and a position
                    imageHandle = varargin{1};
                    position = varargin{2};
            end
           
            %get the parent axis handle
            parent = get(imageHandle,'Parent');
            
            %compute the pheight
            pheight = min(size(get(imageHandle,'CData')));
            pheight = pheight/10;
            
            %Draw the graphics
            nextPlot = get(parent,'NextPlot');  %make sure the new graphics don't delete the old ones
            set(parent,'NextPlot','add');
            graphicsHandles(1) = plot(position(:,1),position(:,2),'-r','LineWidth',1.5,'Parent',parent);
            graphicsHandles(2) = plot(position(:,1),position(:,2),'sr','LineWidth',1.5,'MarkerSize',8,'Parent',parent,'MarkerFaceColor','r');
            set(graphicsHandles,'Clipping','off')
            set(parent,'NextPlot',nextPlot);
            
            %Define the context menu options (i.e., what happens when you
            %right click on the ROI)
            menuLabels = {'Export stats','Plot profile','Hide Text','Delete'};
            menuFunction = @contextMenuCallback;
            
            %create the ROI object from the superclass
            ROI@imtool3DROI(imageHandle,graphicsHandles,menuLabels,menuFunction);
            
            %create the text object and line profile object
            [x,y] = findTextPosition(position,ROI.tbuff);
            ROI.textHandle = text(x,y,'text','Parent',parent,'Color','w','FontSize',10,'EdgeColor','w','BackgroundColor','k','HorizontalAlignment','Left','VerticalAlignment','top','Clipping','on');
            graphicsHandles(3) = plot(position(:,1),position(:,2)-ROI.pbuff,'-r','LineWidth',1.5,'Parent',parent);
            set(parent,'NextPlot',nextPlot);
            ROI.graphicsHandles = graphicsHandles;
            
            %Set the position and pheight properties of the ROI
            ROI.position = position;
            ROI.pheight = pheight;
            
            %add a listener for changes in the image. This automatically
            %updates the ROI text when the image changes
            ROI.listenerHandle = addlistener(ROI.imageHandle,'CData','PostSet',@ROI.handlePropEvents);
            
            %Set the button down functions of the graphics
            for i=1:length(graphicsHandles)
                fun = @(hObject,evnt) ButtonDownFunction(hObject,evnt,ROI,i); set(graphicsHandles(i),'ButtonDownFcn',fun);
            end
            
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
            
            %set the new position of the line
            set(graphicsHandles(1),'XData',position(:,1),'YData',position(:,2));
            set(graphicsHandles(2),'XData',position(:,1),'YData',position(:,2));
            
            %get the ROI measurements
            [stats, x , y] = getMeasurements(ROI);
            
            %Set position of the line profile
            set(graphicsHandles(3),'XData',x,'YData',y);
            
            %set the textbox
            [x,y] = findTextPosition(position,ROI.tbuff);
            str = ['Length: '  num2str(stats.distance,'%+.2f')];
            set(ROI.textHandle,'String',str,'Position',[x y]);
             
        end
        
        function [stats, x ,y] = getMeasurements(ROI)
            %get the position
            position = ROI.position;
            
            %get the image data
            im = get(ROI.imageHandle,'CData');
            
            %get the distance
            stats.distance = norm(position(1,:)-position(2,:));
            
            %get the line profile data
            [cx,cy,pv] = improfile(ROI.imageHandle.XData,ROI.imageHandle.YData,im,position(:,1),position(:,2));
            
            %get the stats
            stats.mean = mean(pv);
            stats.STD = std(pv);
            stats.min = min(pv);
            stats.max = max(pv);
            stats.profile = pv;
            stats.cx = cx;
            stats.cy = cy;
            stats.position = position;
            
            %find the positions of the line profile
            %get the vector pointing in the direction of the profile
            dir = (position(2,:)-position(1,:))./stats.distance;
            %get a normal vector
            perp = [dir(2) -dir(1)];
            %move the line profile by pbuff in the direction of perp
            x = cx + ROI.pbuff*perp(1);
            y = cy + ROI.pbuff*perp(2);
            %get a vector of distances away from this line
            d = mat2gray(pv); d = d*ROI.pheight;
            %adjust the x and y values
            x = x + d.*perp(1);
            y = y + d.*perp(2);
            
        end
        
        function handlePropEvents(ROI,src,evnt)
            position = getPosition(ROI);
            newPosition(ROI,position);
        end
    end
    
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

%get the point that was clicked
dist = sqrt((position_old(:,1)-op(1)).^2 + (position_old(:,2)-op(2)).^2 );
[~, ind] = min(dist);

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
    case 1   %User clicked on the line. Entire ROI will move
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

function [x,y] = findTextPosition(position,tbuff)
%This finds the postion of the text box given the polygon vertices

x = min(position(:,1)); y = max(position(:,2))+tbuff;


end

function contextMenuCallback(source,callbackdata,ROI)
switch get(source,'Label')
    case 'Delete'
        delete(ROI);
    case 'Export stats'
        [stats, ~,~] = getMeasurements(ROI);
        name = inputdlg('Enter variable name');
        name=name{1};
        assignin('base', name, stats)
    case 'Plot profile'
        [stats, ~,~] = getMeasurements(ROI);
        %get distance from the first point
        x = stats.cx(1); y = stats.cy(1);
        d = sqrt((stats.cx-x).^2+(stats.cy-y).^2);
        %make plot
        figure;
        plot(d,stats.profile);
        xlabel('Distance (px)');
        ylabel('Pixel Value');
    case 'Hide Text'
        switch get(source,'Checked')
            case 'off'
                set(source,'Checked','on');
                ROI.textVisible = false;
            case 'on'
                set(source,'Checked','off');
                ROI.textVisible = true;
        end
        
end


end