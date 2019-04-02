function imtool3D_3planes_crop(tool)
% imtool3D_3planes_crop(tool) adds a synchronized rectangle to the imtool
% object created by imtool3D_3planes
%
% WIP
% todo: add button to crop

S = tool(1).getImageSize;

RECT1 = imtool3DROI_rect(tool(1).getHandles.I,round([S(2) S(1) S(2) S(1)]/2));
RECT2 = imtool3DROI_rect(tool(2).getHandles.I,round([S(3) S(2) S(3) S(2)]/2));
RECT3 = imtool3DROI_rect(tool(3).getHandles.I,round([S(3) S(1) S(3) S(1)]/2));
syncPos(RECT1,RECT2,RECT3,1)

% Hide text
RECT1.textVisible = false;
RECT2.textVisible = false;
RECT3.textVisible = false;

% Sync Positions
addlistener(RECT1,'newROIPosition',@(src,evnt) syncPos(RECT1,RECT2,RECT3,1));
addlistener(RECT2,'newROIPosition',@(src,evnt) syncPos(RECT1,RECT2,RECT3,2));
addlistener(RECT3,'newROIPosition',@(src,evnt) syncPos(RECT1,RECT2,RECT3,3));

tool(1).getHandles.fig



