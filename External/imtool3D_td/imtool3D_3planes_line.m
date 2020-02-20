function LINES = imtool3D_3planes_line(tool)
% imtool3D_3planes_crop(tool) adds a synchronized rectangle to the imtool
% object created by imtool3D_3planes
%
% WIP
% todo: add button to crop

S = tool(1).getImageSize;

LINES(1) = imtool3DROI_line(tool(1).getHandles.I,round([2*S(1) S(2); S(1) S(2)]/3));
LINES(2) = imtool3DROI_line(tool(3).getHandles.I,round([2*S(3) S(2); S(3) S(2)]/3));

addlistener(LINES(2),'newROIPosition',@(src,evnt) syncPos(LINES(1),tool(1).getCurrentSlice,LINES(2),tool(2).getCurrentSlice))
%addlistener(LINES(1),'newROIPosition',@(src,evnt) syncPos(LINES(2),tool(2).getCurrentSlice,LINES(1),tool(1).getCurrentSlice))


%Masknew = getsymmetrical(tool(1).getMask(1), LINES);


function syncPos(LINE1,y1,LINE2,y2)

Pos = LINE2.getPosition;
Dy = y1-Pos(2,1);
PosIntersect1 = Pos(2,:)+Dy*(Pos(1,:)-Pos(2,:))/norm(Pos(1,:)-Pos(2,:));

Pos = LINE1.getPosition;
Dy = y2-Pos(2,1);
PosIntersect2 = Pos(2,:)+Dy*(Pos(1,:)-Pos(2,:))/norm(Pos(1,:)-Pos(2,:));
Pos(:,2) = Pos(:,2)+(PosIntersect1(2)-PosIntersect2(2));
LINE1.newPosition(Pos)

function getsymmetrical(Mask, LINES)
Pos1 = LINES(1).getPosition;
Pos2 = LINES(2).getPosition;

Pos(2,:)-Pos(1,:);
%Vnormal = 



