function [hScrollPanel, hPanel] = attachScrollPanelTo(hObject)
% attachScrollPanelTo Places the input control/panel in a scrollpanel
%
% Syntax:
%    [hScrollPanel, hPanel] = attachScrollPanelTo(hObject);
%
% Description:
%    attachScrollPanelTo places the specified control/uipanel handle in
%    a scroll-panel (a Java JScrollPanel object). If the specified handle
%    is not a uipanel, then it is placed inside a tightly-fitting borderless
%    uipanel, which is then placed within the new scroll-panel.
%
%    The new scroll-panel automatically resizes with its containing figure/
%    uipanel or other container (the specified handle's original parent).
%    Scrollbars automatically appear as needed, when the container shrinks
%    or expands.
%
%    The returned hScrollPanel can be seperately customized (for example, 
%    programmatically setting the viewport's ViewPosition): see examples below
%
%    The returned hPanel is the Matlab panel containing the input hObject.
%    When hObject is a uipanel, hPanel==hObject; otherwise, hPanel is the
%    tightly-fitting borderless panel that is created for the scroll-panel.
%
%    Calling attachScrollPanelTo with no input handle displays a demo.
%
% Examples:
%    attachScrollPanelTo()        %display the demo
%    attachScrollPanelTo(hPanel)  %place the specified panel in a scroll-panel
%
%    hScroll = attachScrollPanelTo(hPanel);
%    hScroll.ViewOffset = [30,50];  %set viewport offset (30px right, 50px down)
%    set(hScroll, 'ViewOffset',[30,50]);  %equivalent alternative
%
% Limitations:
%    - HG2 figures created with GUIDE or the figure command - works ok
%    - HG2 figures created with AppDesigner or uifigure command - does NOT work
%    - HG1 figures created on R2014a or older - does NOT work
%
% Technical details:
%    https://UndocumentedMatlab.com/blog/scrollable-gui-panels
%
% Bugs and suggestions:
%    Please send to Yair Altman (altmany at gmail dot com)
%
% Change log:
%    2018-07-25: First version posted on <a href="https://www.mathworks.com/matlabcentral/profile/authors/642467-yair-altman">MathWorks File Exchange</a>

% Programmed by Yair M. Altman: altmany(at)gmail.com

    % Display the demo if no inputs were specified
    if nargin < 1,  [hScrollPanel, hPanel] = displayDemo;  return,  end

    % Bail out if empty handle(s) specified
    if isempty(hObject),  if nargout, hScrollPanel=[]; hPanel=[]; end,  return,  end

    % Ensure we use a supported figure
    hFig = ancestor(hObject,'figure');
    if hObject==hFig
        % TODO - place the figure's content-pane in the JScrollPane
        error('YMA:attachScrollPanelTo:BadFigure','Cannot place a figure in scroll-panel')
    elseif isnumeric(hFig)
        error('YMA:attachScrollPanelTo:BadFigure','attachScrollPanelTo only supports HG2 figures (R2014b or newer)')
    elseif ~isa(hFig,'matlab.ui.Figure')
        error('YMA:attachScrollPanelTo:BadFigure','GUI figure type not supported by attachScrollPanelTo')
    elseif ~ishandle(hObject) || ~isvalid(hObject)
        error('YMA:attachScrollPanelTo:BadObject','Invalid or deleted input handle specified')
    elseif ~isscalar(hObject)
        error('YMA:attachScrollPanelTo:BadObject','More than one input handles were specified')
    end

    % Get the handle's pixel position
    pixelpos = getpixelposition(hObject);

    % If the specified handle is not a panel, then encase it in a borderless panel
    hParent = hObject.Parent;
    if ~isa(hObject,'matlab.ui.container.Panel')  % not a uipanel
        try
            bgColor = get(hParent,'Background');  % panels etc.
        catch
            bgColor = get(hParent,'Color');  % figure
        end
        hPanel = uipanel(hParent, 'BorderType','none', 'Background',bgColor, ...
                                  'Units','pixel',     'Position',pixelpos);
        set(hObject, 'Parent',hPanel, 'Units','norm', 'Position',[0,0,1,1]);
        set(hObject, 'Units','pixel');
    else  % a standard uipanel
        hPanel = hObject;
    end

    % Ensure that everything is fully-rendered before we proceed 
    drawnow

    % Place the panel's underlying Java peer in a new dedicated JScrollPanel
    jPanel = hPanel.JavaFrame.getGUIDEView;
    jParent = jPanel.getParent;
    jScrollPanel = javaObjectEDT(javax.swing.JScrollPane(jParent));
    jScrollPanel.setBorder([]);
    jScrollPanel.getViewport.setBackground(jPanel.getBackground);
    [hjScrollPanel, hScrollPanel_] = javacomponent(jScrollPanel, pixelpos, hParent);
    hjScrollPanel.repaint;
    hScrollPanel_.Units = 'norm';
    drawnow

    %{
    % Set the scroll-panel to be transparent, so that the background will show
    % if/when hPanel is made non-visible
    jScrollPanel.setOpaque(0);
    jScrollPanel.getViewport.setOpaque(0);
    jScrollPanel.getParent.setOpaque(0);
    jScrollPanel.getParent.getParent.setOpaque(0);
    %}
    % Link the visibility of the scroll-panel and internal panel, so that both
    % become visible/non-visible together
    hLink = linkprop([hPanel,hScrollPanel_],'Visible');
    setappdata(hPanel,'attachScrollPanelToLink',hLink);

    % Add a Viewport property to the returned hScrollPanel object
    addprop(hScrollPanel_, 'Viewport');
    hScrollPanel_.Viewport = jScrollPanel.getViewport;

    % Add a ViewOffset property to the returned hScrollPanel object
    hProp = addprop(hScrollPanel_, 'ViewOffset');
    %hProp = findprop(hScrollPanel_, 'ViewOffset');
    hProp.GetMethod = @getViewOffset; %viewOffset = getViewOffset(hScrollPanel)
    hProp.SetMethod = @setViewOffset; %setViewOffset(hScrollPanel, viewOffset)

    % Set the callback function to repaint the scroll-pane when needed
    hScrollPanel_.SizeChangedFcn = @repaintScrollPane;

    if nargout
        hScrollPanel = hScrollPanel_;
    end
end

% Demo example to showcase this utility
function [hScrollPanel, hPanel] = displayDemo()
    hFig = figure('Color','w', 'MenuBar','none','Toolbar','none');
    %surf(peaks);  % background axes

    hPanel = uipanel(hFig, 'Background','y', 'Units','pixel', 'Pos',[50,50,200,200]);

    hAxes = axes(hPanel);
    surf(hAxes, peaks);  % in-panel axes

    uicontrol(hPanel, 'String','Button #1', 'Pos',[ 20, 20,100,20]);
    uicontrol(hPanel, 'String','Button #2', 'Pos',[ 50, 50,100,20]);
    uicontrol(hPanel, 'String','Button #3', 'Pos',[ 90, 90,100,20]);
    uicontrol(hPanel, 'String','Button #4', 'Pos',[150,150,100,20]);

    hScrollPanel = attachScrollPanelTo(hPanel);
end

% Repaint function whenever the panel resizes
function repaintScrollPane(hScrollPanel, varargin)
    drawnow
    jScrollPanel = hScrollPanel.JavaPeer;
    offsetX = jScrollPanel.getHorizontalScrollBar.getValue;
    offsetY = jScrollPanel.getVerticalScrollBar.getValue;
    jOffsetPoint = java.awt.Point(offsetX, offsetY);
    jViewport = jScrollPanel.getViewport;
    jViewport.setViewPosition(jOffsetPoint);
    jScrollPanel.repaint;
end

% Getter method for the dynamic hScroll.ViewOffset property
function viewOffset = getViewOffset(hScrollPanel, varargin)
    jPoint = hScrollPanel.Viewport.getViewPosition;
    viewOffset = [jPoint.getX, jPoint.getY];
end

% Setter method for the dynamic hScroll.ViewOffset property
function setViewOffset(hScrollPanel, viewOffset)
    if ~isnumeric(viewOffset) || numel(viewOffset)~=2 || any(isnan(viewOffset) | isinf(viewOffset) | viewOffset<0)
        error('YMA:attachScrollPanelTo:ViewOffset','ViewOffset must be a 2-element array of positive integers');
    end
    jPoint = java.awt.Point(viewOffset(1), viewOffset(2));
    hScrollPanel.Viewport.setViewPosition(jPoint);
    hScrollPanel.JavaPeer.repaint;
end
