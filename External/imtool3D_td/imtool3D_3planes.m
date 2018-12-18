function tool = imtool3D_3planes(dat,mask)
if ~exist('mask','var'), mask=[]; end

dat = setviewplane(dat,'axial');
mask = setviewplane(mask,'axial');
tool = imtool3D(dat,[],[],[],[],mask,[]);
range = tool.getClimits;
datsag = setviewplane(dat,'sagittal');
masksag = setviewplane(mask,'sagittal');
tool(2) = imtool3D(datsag,[],tool(1).getHandles.fig,range,[],masksag,[]);
datcor = setviewplane(dat,'coronal');
maskcor = setviewplane(mask,'coronal');
tool(3) = imtool3D(datcor,[],tool(1).getHandles.fig,range,[],maskcor,[]);

tool(1).setPosition([0 0 0.33 1])
tool(2).setPosition([0.33 0 0.33 1])
tool(3).setPosition([0.66 0 0.33 1])

for ii=1:3
set(tool(ii).getHandles.Panels.ROItools,'Visible','off')
set(tool(ii).getHandles.Tools.Save,'Visible','off')
set(tool(ii).getHandles.Tools.SaveOptions,'Visible','off')
end

h = tool(1).getHandles.fig;
set(h,'WindowScrollWheelFcn',@(src, evnt) scrollWheel(src, evnt, tool) )
set(h,'Windowkeypressfcn', @(hobject, event) shortcutCallback(hobject, event,tool))

% Make 3 times larger
set(h,'Units','Pixels');
pos = get(tool(1).getHandles.fig,'Position');
pos(3)=3*pos(3);
screensize = get(0,'ScreenSize');
pos(3) = min(pos(3),screensize(3));
pos(1) = ceil((screensize(3)-pos(3))/2);
pos(2) = ceil((screensize(4)-pos(4))/2);
set(h,'Position',pos)
set(h,'Units','normalized');

% add help
H = tool(3).getHandles;
pos = get(H.Tools.ViewRestore,'Position'); w = pos(3); buff = pos(2);
pos = get(H.Panels.Tools,'Position');
H.Tools.Help             =   uicontrol(H.Panels.Tools,'Style','pushbutton','String','?','Position',[pos(3)-w-buff buff w w],'TooltipString','Help with imtool3D');
fun=@(hObject,evnt) displayHelp;
set(H.Tools.Help,'Callback',fun)

function displayHelp
msg = {'imtool3D, written by Justin Solomon',...
       'justin.solomon@duke.edu',...
       'adapted by Tanguy Duval',...
       'https://github.com/tanguyduval/imtool3D_td',...
       '------------------------------------------',...
       '',...
       'KEYBOARD SHORTCUTS:',...
       'X:                      Set slices based on current mouse location (hold X and move the mouse to navigate in the volume)',...
       'Left/right arrows:      navigate through time (4th dimension)',...
       'Top/bottom arrows:      navigate through volumes (5th dimension)',...
       'Middle Click and drag:  Zoom in/out',...
       'Left Click and drag:    Contrast/Brightness',...
       'Right Click and drag:   Pan',...
       '...'};msgbox(msg)




function scrollWheel(src, evnt, tool)
currentobj = hittest;
for ii=1:length(tool)
    if isequal(currentobj,tool(ii).getHandles.mask)
        newSlice=tool(ii).getCurrentSlice-evnt.VerticalScrollCount;
        dim = tool(ii).getImageSize;
        if newSlice>=1 && newSlice <=dim(3)
            tool(ii).setCurrentSlice(newSlice);
        end
        
    end
end


function shortcutCallback(hobject, event,tool)
switch event.Key
    case 'x'
        currentobj = hittest;
        for ii=1:length(tool)
            if isequal(currentobj,tool(ii).getHandles.mask)
                movetools = setdiff(1:length(tool),ii);
                [xi,yi,zi] = tool(ii).getCurrentMouseLocation;
                if ii==1
                    tool(movetools(1)).setCurrentSlice(yi);
                    tool(movetools(2)).setCurrentSlice(xi);
                else
                    tool(movetools(1)).setCurrentSlice(xi);
                    tool(movetools(2)).setCurrentSlice(yi);
                end
            end
        end
    case {'leftarrow', 'rightarrow', 'uparrow', 'downarrow', 'space'}
        for ii=1:length(tool)
            tool(ii).shortcutCallback(event)
        end
        
    otherwise
        tool(end).shortcutCallback(event)
end


