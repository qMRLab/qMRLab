function [newpos,centerpos] = func_flyA(pos,flight,th_xy,th_z)

% 壁など気にせず, 単純にスタート地点から一定の方向に一定方向進めたときの座標を返す.
% 【入力系】
%   pos -> x,y,z座標. size(pos) = [1,3]
%   flight -> 飛距離. 定数.
%   th_xy, th_z -> X軸からの回転角, XY平面からの仰角. 定数. 後者は-0.5pi～0.5pi.

% 【出力系】
%   newpos -> x,y,z座標. size(pos) = [1,3]
%   centerpos -> x,y,z座標. size(pos) = [1,3]. 飛程の中間点

fl_z = flight * sin(th_z);
fl_x = (flight * cos(th_z)) * cos(th_xy);
fl_y = (flight * cos(th_z)) * sin(th_xy);

newpos = pos + [fl_x, fl_y, fl_z];
centerpos = pos + [fl_x, fl_y, fl_z]*0.5;

