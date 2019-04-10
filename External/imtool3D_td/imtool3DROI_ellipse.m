classdef imtool3DROI_ellipse < imtool3DROI_rect
    
    properties (SetAccess = protected, GetAccess = protected)
        nPoints = 20;   %number of points to use to define the polygon that makes the elliptical mask 
    end
    
   
    
    methods
        %constructor
        function ROI = imtool3DROI_ellipse(varargin)
            
            switch nargin
                case 0  %use the current figure
                    
                    %let the user draw the ROI
                    h = imellipse;
                    
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
                    h = imellipse(parent);
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
                        h = imellipse(parent);
                        pos = getPosition(h);
                        position = [pos(1)+pos(3)/2 pos(2)+pos(4)/2 pos(3) pos(4)];
                        delete(h);
                    end
                    tool = varargin{3};

            end
            
            %contruct the rect ROI
            if ~exist('tool','var'), tool=[]; end
            ROI@imtool3DROI_rect(imageHandle,position, tool)
            
            %make the rectangle an ellipse
            set(ROI.graphicsHandles(1),'Curvature',[1 1]);
            
            %update the position
            newPosition(ROI,position)
            
            %Set the button down functions of the graphics
            for i=1:length(ROI.graphicsHandles)
                fun = @(hObject,evnt) ButtonDownFunction(hObject,evnt,ROI,i); set(ROI.graphicsHandles(i),'ButtonDownFcn',fun);
            end
            
        end
        
        function newPosition(ROI,position)
            
            %set the position property of the ROI
            ROI.position = position;
            
            %find the top left corner of the box
            pos = [position(1)-position(3)/2 position(2)-position(4)/2 position(3) position(4)];
            
            %get the graphics handles
            graphicsHandles = ROI.graphicsHandles;
            
            %get the corner positions
            t = pi/4:pi/2:2*pi-pi/4;
            [x,y] = getEllipsePoints(position,t,'');
            
            %set the new position of the rectangle and other graphics
            %objects
            set(graphicsHandles(1),'Position',pos);
            set(graphicsHandles(2),'Xdata',position(1),'Ydata',position(2));
            set(graphicsHandles(3),'Xdata',x(3),'Ydata',y(3));
            set(graphicsHandles(4),'Xdata',x(4),'Ydata',y(4));
            set(graphicsHandles(5),'Xdata',x(2),'Ydata',y(2));
            set(graphicsHandles(6),'Xdata',x(1),'Ydata',y(1));
            set(graphicsHandles(7),'Xdata',pos(1),'Ydata',position(2));
            set(graphicsHandles(8),'Xdata',pos(1)+pos(3),'Ydata',position(2));
            set(graphicsHandles(9),'Xdata',position(1),'Ydata',pos(2));
            set(graphicsHandles(10),'Xdata',position(1),'Ydata',pos(2)+pos(4));
            
            %get the ROI measurements
            stats = getMeasurements(ROI);
            
            %set the textbox
            V = get(gca,'View');
            if V(1)==-90
                x = pos(1) + pos(3) + ROI.tbuff;
            else
                x = pos(1);
            end
            y = pos(2)-ROI.tbuff;
            
            str = {['Mean: ' num2str(stats.mean,'%+.2f')], ['STD:     ' num2str(stats.STD,'%.2f')]};
            set(ROI.textHandle,'String',str,'Position',[x y]);
            
            %notify a new position
            notify(ROI,'newROIPosition');
        end
        
        function [x, y] = getPoly(ROI)
            %get the position
            position = ROI.position;
            
            %find the top left corner of the box
            pos = [position(1)-position(3)/2 position(2)-position(3)/2 position(3) position(4)];
            
            %make the polygon
            [x,y] = getEllipsePoints(position,ROI.nPoints,'nPoints');
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
        
        function varargout = autoCenterROI(ROI,varargin)
            Tforeground = .2;
            Tbackground = .8;
            pos=ROI.position(1:2);
            switch nargin
                case 1
                    weighting = 'pixels';
                    mode = 'normal';
                case 2
                    weighting = varargin{1}; %Weighting can be 'pixels' or 'mask'
                    mode ='normal'; %can be 'normal' or 'force positive contrast';
                case 3
                    weighting = varargin{1};
                    mode = varargin{2};
            end
                
            
            %Get the image
            im = double(get(ROI.imageHandle,'CData'));
            %Get coordinate system
            [X, Y]=meshgrid((1:size(im,2))-pos(1),(1:size(im,1))-pos(2));
            R=sqrt((X).^2 +(Y.^2));
            %get the mask
            stats = getMeasurements(ROI);
            mask=stats.mask;
            
            amin=min(im(mask));
            amax=max(im(mask));
            sim=mat2gray(im,[amin amax]);
            t=graythresh(sim(mask)); %Otsu threshold
            bw=im2bw(sim,t);
            bw=bw & mask;
            %bw=bwareaopen(bw,100);
            
            switch mode
                case 'force positive contrast'
                    obj=mean(im(bw));
                    bkg=mean(im(~bw & mask));
                case 'normal'
                    bkg=mean(im(mask & R>quantile(R(mask),Tbackground)));
                    obj=mean(im(mask & R<quantile(R(mask),Tforeground)));
                otherwise
                    bkg=mean(im(mask & R>quantile(R(mask),Tbackground)));
                    obj=mean(im(mask & R<quantile(R(mask),Tforeground)));
            end
            contrast=obj-bkg;
            if contrast<0
                bw=~bw & mask;
            end
            
            if any(bw(:))
                success = true;
                %compute the centroid of the rod
                center=zeros(1,2);
                switch weighting
                    case 'pixels'
                        center(1) = sum(X(bw).*im(bw))/sum(im(bw));
                        center(2) = sum(Y(bw).*im(bw))/sum(im(bw));
                    case 'mask'
                        center(1) = sum(X(bw).*bw(bw))/sum(bw(bw));
                        center(2) = sum(Y(bw).*bw(bw))/sum(bw(bw));
                    otherwise
                        center(1) = sum(X(bw).*im(bw))/sum(im(bw));
                        center(2) = sum(Y(bw).*im(bw))/sum(im(bw));
                end
                
                position = [center 0 0];
                position=position+ROI.position;
                newPosition(ROI,position);
            else
                success = false;
            end
            
            switch nargout
                case 1
                    varargout{1} = success;
            end
            
        end
        
        function success = autoCenterROIFindCircleMethod(ROI,circleRange)
            rescale=4;
            %Get the image
            im = double(get(ROI.imageHandle,'CData'));
            stats = getMeasurements(ROI);
            mask=stats.mask;
            
            %Crop the image
            [Yind Xind]=ind2sub(size(im),find(mask(:)));
            im=im(min(Yind):max(Yind),min(Xind):max(Xind));
            
            %Upsample the image
            im=imresize(im,rescale);
            
            %Find the circles
            warning('off','images:imfindcircles:warnForLargeRadiusRange')
            center = imfindcircles(im, round(rescale*circleRange),'Sensitivity',.95);
            warning('on','images:imfindcircles:warnForLargeRadiusRange')
            
            %move the ROI
            if ~isempty(center)
                center=center(1,:);
                success=true;
                center=center/rescale;
                center=center + [min(Xind) min(Yind)];
                position = [center ROI.position(3:4)];
                newPosition(ROI,position);
            else
                success=false;
            end
                
            
        end
       
        
    end
    
    
end

function [x,y] = getEllipsePoints(position,t,mode)
%This function returns a list of vertices of an elliptical polygon with
%nPoints number of vertices;
if strcmp(mode,'nPoints')
    t=linspace(0,2*pi,t); %elliptical equation is parameterized by t
end
a = position(3)/2;
b = position(4)/2;
x = a*cos(t); x = x+position(1);
y = b*sin(t); y = y+position(2);
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
        %find the x and y for the current position
        [x,y] = getEllipsePoints(position,5*pi/4,'');
        dx = x-cp(1); dy = y-cp(2);
        cp(1) = position(1)-(position(3)/2+dx); cp(2) = position(2)-(position(4)/2+dy);
        
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
        %find the x and y for the current position
        [x,y] = getEllipsePoints(position,7*pi/4,'');
        dx = cp(1)-x; dy = y-cp(2);
        cp(1) = position(1)+(position(3)/2+dx); cp(2) = position(2)-(position(4)/2+dy);
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
        %find the x and y for the current position
        [x,y] = getEllipsePoints(position,3*pi/4,'');
        dx = x-cp(1); dy = cp(2)-y;
        cp(1) = position(1)-(position(3)/2+dx); cp(2) = position(2)+(position(4)/2+dy);
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
        %find the x and y for the current position
        [x,y] = getEllipsePoints(position,pi/4,'');
        dx = cp(1)-x; dy = cp(2)-y;
        cp(1) = position(1)+(position(3)/2+dx); cp(2) = position(2)+(position(4)/2+dy);
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