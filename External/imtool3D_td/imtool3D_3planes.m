function tool = imtool3D_3planes(dat,mask)
if ~exist('mask','var'), mask=[]; end
if ~exist('dat','var'), dat=[]; end

tool = imtool3D(dat,[],[],[],[],mask,[]);
range = tool.getClimits;
CB_Motion1 = get(gcf,'WindowButtonMotionFcn');
tool(2) = imtool3D(dat,[],tool(1).getHandles.fig,range,[],mask,[]);
CB_Motion2 = get(gcf,'WindowButtonMotionFcn');
tool(3) = imtool3D(dat,[],tool(1).getHandles.fig,range,[],mask,[]);
CB_Motion3 = get(gcf,'WindowButtonMotionFcn');

setviewplane(tool(2),'sagittal');
setviewplane(tool(3),'coronal');

% Set each plane position
  % horizontal config
tool(1).setPosition([0 0 0.33 1])
tool(2).setPosition([0.33 0 0.33 1])
tool(3).setPosition([0.66 0 0.33 1])
  % square config
% tool(1).setPosition([0 0.5 0.5 0.5])
% tool(2).setPosition([0.5 0.5 0.5 0.5])
% tool(3).setPosition([0 0 0.5 0.5])

% Make figure 3 times larger
h = tool(1).getHandles.fig;
set(h,'Units','Pixels');
pos = get(tool(1).getHandles.fig,'Position');
pos(3)=3*pos(3);
screensize = get(0,'ScreenSize');
pos(3) = min(pos(3),screensize(3)-100);
pos(4) = min(pos(4),screensize(4)-100);
pos(1) = ceil((screensize(3)-pos(3))/2);
pos(2) = ceil((screensize(4)-pos(4))/2);
set(h,'Position',pos)
set(h,'Units','normalized');


for ii=2:3
set(tool(ii).getHandles.Tools.Save,'Visible','off')
% hide pixel info
set(tool(ii).getHandles.Panels.Tools,'Visible','off')
end
set(tool(1).getHandles.Tools.ViewPlane,'Visible','off')

% Synchronize masks
for ii=1:3
    addlistener(tool(ii),'maskChanged',@(x,y) syncMasks(tool,ii));
    addlistener(tool(ii),'maskUndone',@(x,y) syncMasks(tool,ii));
end

% tool of first block transfert to all
controls1 = findobj(tool(1).getHandles.Panels.Tools,'Type','uicontrol');
controls2 = findobj(tool(2).getHandles.Panels.Tools,'Type','uicontrol');
controls3 = findobj(tool(3).getHandles.Panels.Tools,'Type','uicontrol');
controls1 = cat(1,controls1,tool(3).getHandles.Tools.maskSelected',tool(3).getHandles.Tools.maskLock);
controls2 = cat(1,controls2,tool(1).getHandles.Tools.maskSelected',tool(1).getHandles.Tools.maskLock);
controls3 = cat(1,controls3,tool(2).getHandles.Tools.maskSelected',tool(2).getHandles.Tools.maskLock);

for ic = 1:length(controls1)
    if ~isempty(controls1(ic).Callback) && ~isempty(strfind(func2str(controls1(ic).Callback),'saveImage')), continue; end % save Mask only once!
    if ~isempty(controls1(ic).Callback) && ~isempty(strfind(func2str(controls1(ic).Callback),'displayHelp')), continue; end % Display Help only once!

    CB = get(controls1(ic),'Callback');
    CB2 = get(controls2(ic),'Callback');
    CB3 = get(controls3(ic),'Callback');
    if ~isempty(CB)
        switch nargin(CB)
            case 1
                set(controls1(ic),'Callback', @(a) Callback3(CB,CB2,CB3,a))
            case 2
                set(controls1(ic),'Callback', @(a,b) Callback3(CB,CB2,CB3,a,b))
            case 3
                set(controls1(ic),'Callback', @(a,b,c) Callback3(CB,CB2,CB3,a,b,c))
        end
    end
end

% hide buttons with repeated functionalities
set(tool(1).getHandles.Tools.maskSelected,'Visible','off')
set(tool(2).getHandles.Tools.maskSelected,'Visible','off')
set(tool(1).getHandles.Tools.maskLock,'Visible','off')
set(tool(2).getHandles.Tools.maskLock,'Visible','off')
set(tool(1).getHandles.Tools.maskStats,'Visible','off')
set(tool(2).getHandles.Tools.maskStats,'Visible','off')
set(tool(1).getHandles.Tools.maskSave,'Visible','off')
set(tool(2).getHandles.Tools.maskSave,'Visible','off')
set(tool(1).getHandles.Tools.maskLoad,'Visible','off')
set(tool(2).getHandles.Tools.maskLoad,'Visible','off')

% Add crosses
H = tool(1).getHandles;
S = tool(1).getImageSize;
y1 = tool(2).getCurrentSlice;
x1 = tool(3).getCurrentSlice;
crossX1 = plot(H.Axes,[x1 x1],[0 S(1)],'r-');
crossY1 = plot(H.Axes,[0 S(2)],[y1 y1],'r-');

H = tool(2).getHandles;
S = tool(2).getImageSize;
y2 = tool(3).getCurrentSlice;
x2 = tool(1).getCurrentSlice;
crossX2 = plot(H.Axes,[x2 x2],[0 S(1)],'r-');
crossY2 = plot(H.Axes,[0 S(2)],[y2 y2],'r-');

H = tool(3).getHandles;
S = tool(3).getImageSize;
y3 = tool(2).getCurrentSlice;
x3 = tool(1).getCurrentSlice;
crossX3 = plot(H.Axes,[x3 x3],[0 S(1)],'r-');
crossY3 = plot(H.Axes,[0 S(2)],[y3 y3],'r-');

hidecross(crossX1,crossY1,crossX2,crossY2,crossX3,crossY3)
% add tooltip
for ii=1:3
    set(tool(ii).getHandles.Slider,'TooltipString',sprintf('Change Slice (use the scroll wheel)\nAlso, use and hold the [X] key to navigate in the volume based on mouse location)'));
end


% Add mouse/keyboard interactions
h = tool(1).getHandles.fig;
set(h,'WindowScrollWheelFcn',@(src, evnt) scrollWheel(src, evnt, tool) )
set(h,'Windowkeypressfcn', @(hobject, event) shortcutCallback(hobject, event,tool,crossX1,crossY1,crossX2,crossY2,crossX3,crossY3))
set(h,'WindowButtonMotionFcn',@(src,evnt) Callback3(CB_Motion1,CB_Motion2,CB_Motion3,src,evnt))
set(h,'WindowKeyReleaseFcn',@(hobject,key) setappdata(hobject,'HoldX',0))
setappdata(h,'HoldX',1)

addlistener(tool(1).getHandles.Tools.L,'String','PostSet',@(x,y) setWL(tool));
addlistener(tool(1).getHandles.Tools.U,'String','PostSet',@(x,y) setWL(tool));

% add help
H = tool(1).getHandles;
fun=@(hObject,evnt) displayHelp;
set(H.Tools.Help,'Callback',fun)


function setWL(tool)
L=str2num(get(tool(1).getHandles.Tools.L,'String'));
U=str2num(get(tool(1).getHandles.Tools.U,'String'));
for ii=1:3
    tool(ii).setDisplayRange([L U]);
end

function displayHelp
%%
msg = {'imtool3D, written by Justin Solomon',...
       'justin.solomon@duke.edu',...
       'adapted by Tanguy Duval',...
       'https://github.com/tanguyduval/imtool3D_td',...
       '------------------------------------------',...
       '',...
       'KEYBOARD SHORTCUTS:',...
       '[X]                      Set slices based on current mouse location',... 
       '                           (hold X and move the mouse to navigate',...
       '                            in the volume)',...
       'Left/right arrows        Navigate through time (4th dimension)',...
       'Top/bottom arrows        Navigate through volumes (5th dimension)',...
       'Middle Click and drag    Zoom in/out',...
       'Left   Click and drag    Contrast/Brightness',...
       'Right  Click and drag    Pan',...
              '',...
       'Spacebar                 Show/hide mask',...
       '[B]                      Toolbrush ',...
       '                           Middle click and drag to change diameter',...
       '                           Right click to erase',...
       '[S]                      Smart Toolbrush',...
       '[Z]                      Undo mask',...
       '[1]                      Select mask label 1',...
       '[2]                      Select mask label 2',...
       '[...]'};
   h = msgbox(msg);
   set(findall(h,'Type','Text'),'FontName','FixedWidth');
   Pos = get(h,'Position'); Pos(3) = 450;
   set(h,'Position',Pos)





function scrollWheel(src, evnt, tool)
currentobj = hittest;
for ii=1:length(tool)
    try
    if ismember(currentobj,findobj(tool(ii).getHandles.Axes))
        newSlice=tool(ii).getCurrentSlice-evnt.VerticalScrollCount;
        dim = tool(ii).getImageSize;
        if newSlice>=1 && newSlice <=dim(4-ii)
            tool(ii).setCurrentSlice(newSlice);
        end
        
    end
    end
end


function shortcutCallback(hobject, event,tool,crossX1,crossY1,crossX2,crossY2,crossX3,crossY3)
switch event.Key
    case 'x'
        if getappdata(hobject,'HoldX'), return; end
        setappdata(hobject,'HoldX',1)
        while getappdata(hobject,'HoldX')
            syncSlices(tool,crossX1,crossY1,crossX2,crossY2,crossX3,crossY3)
            pause(.1)
        end
        hidecross(crossX1,crossY1,crossX2,crossY2,crossX3,crossY3)
    case 'z'
        tool(1).shortcutCallback(event)
        
    otherwise
        fig = tool(1).getHandles.fig;
        oldWBMF = get(fig,'WindowButtonMotionFcn');
        oldPTR  = get(fig,'Pointer');
        for ii=length(tool):-1:1
            set(fig,'WindowButtonMotionFcn',oldWBMF);
            set(fig,'Pointer',oldPTR);
            tool(ii).shortcutCallback(event)
            CB_Motion_mod{ii} = get(fig,'WindowButtonMotionFcn');
        end
        if ~isequal(CB_Motion_mod{1},CB_Motion_mod{2})
            set(fig,'WindowButtonMotionFcn',@(src,evnt) Callback3(CB_Motion_mod{1},CB_Motion_mod{2},CB_Motion_mod{3},src,evnt));
        end
end

function Callback3(CB1,CB2,CB3,varargin)
CB3(varargin{:})
CB1(varargin{:})
CB2(varargin{:})


function syncMasks(tool,ic)
persistent timer
if isempty(timer), timer=tic; end
if toc(timer)<1, return; end
timer=tic;

for ii=setdiff(1:3,ic)
    tool(ii).setMask(tool(ic).getMask(1));
end

function syncSlices(tool,crossX1,crossY1,crossX2,crossY2,crossX3,crossY3)
persistent timer
if isempty(timer), timer=tic; end
if toc(timer)<0.1
    return;
end

currentobj = hittest;
for ii=1:length(tool)
    if ismember(currentobj,findobj(tool(ii).getHandles.Axes))
        movetools = setdiff(1:length(tool),ii);
        [xi,yi,~] = tool(ii).getCurrentMouseLocation;
        if ii==1
            tool(movetools(1)).setCurrentSlice(yi);
            tool(movetools(2)).setCurrentSlice(xi);
        else
            tool(movetools(1)).setCurrentSlice(xi);
            tool(movetools(2)).setCurrentSlice(yi);
        end
    end
end
showcross(tool,crossX1,crossY1,crossX2,crossY2,crossX3,crossY3)
timer=tic;


function showcross(tool,crossX1,crossY1,crossX2,crossY2,crossX3,crossY3)
set(crossX1,'XData',[tool(3).getCurrentSlice tool(3).getCurrentSlice])
set(crossY1,'YData',[tool(2).getCurrentSlice tool(2).getCurrentSlice])
set(crossX2,'XData',[tool(1).getCurrentSlice tool(1).getCurrentSlice])
set(crossY2,'YData',[tool(3).getCurrentSlice tool(3).getCurrentSlice])
set(crossX3,'XData',[tool(1).getCurrentSlice tool(1).getCurrentSlice])
set(crossY3,'YData',[tool(2).getCurrentSlice tool(2).getCurrentSlice])

set(crossX1,'Visible','on')
set(crossY1,'Visible','on')
set(crossX2,'Visible','on')
set(crossY2,'Visible','on')
set(crossX3,'Visible','on')
set(crossY3,'Visible','on')

function hidecross(crossX1,crossY1,crossX2,crossY2,crossX3,crossY3)
set(crossX1,'Visible','off')
set(crossY1,'Visible','off')
set(crossX2,'Visible','off')
set(crossY2,'Visible','off')
set(crossX3,'Visible','off')
set(crossY3,'Visible','off')
