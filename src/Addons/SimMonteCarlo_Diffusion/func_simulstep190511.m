function [endpoint, new_th, new_th_z, new_phase] = func_simulstep190511(R,center,trans,startpoint,th_xy,th_z,totalflight,startphase,G,axis,time,mode3D,sn)

% ★func_simulstep190511
% func_simulstep190403より改変。MRathonのため。
% exceedsの廃止。床反射の廃止。また、Rやcenをセルではなくて行列で表現するように。行方向が要素の数に対応。(各列が個別のパラメータに対応)
% Heightも廃止。高さは無限にあることに。
% 3D切り替え（といっても、円柱を表示するかどうかと、th_zを0に固定するかどうかだけだが）

%★func_simulstep190403
% func190327より改変. func_hitobj190403に対応しphase計算でマリオ処理(exceeds)を反映できるように.

% 1stepの挙動を総合的に計算. MPGによる位相シフトも計算. func_endpoint190307を連続的に活用し,位相の情報を加える.

% 【入力系】
% R,center,height -> それぞれセル.　各要素が各構造物に対応. 対象のXY方向の半径(定数), 中心([x,y,z]), height(定数, Z方向の高さ(centerからの長さなので実際の高さはこの2倍))
% trans -> セル. 対象の壁の透過率 (定数)
% startpoint, th_xy, th_z -> スタート地点(x,y,z), XY方向の射出角(定数), Z方向の射出角(仰角)(定数). 仰角は-0.5pi～0.5pi
% totalflight ->今回の全飛距離
% startphase -> 開始時の位相ずれ. 回転座標で考える.
% G -> このstepにおける傾斜磁場の強さ. MPG方向にそった座標上の距離1にどれだけの傾斜があるか. 単位はミリテスラ.
% axis -> MPG方向(x,y,z). size(axis) = [3,1].
% time -> このstepがどれだけの実時間に相当するか. ラーモア周波数を考えるためなどに必要. 単位はmsec.

% 【出力系】
% endpoint ->終了位置(flightを使い切った位置). size(endpoint) = [1,3].
% new_th_xy, new_th_z -> 終了時の射出角.(定数), Z方向の射出角(仰角)(定数). 仰角は-0.5pi～0.5pi

endpoint = startpoint;
new_th = th_xy;
new_th_z = th_z;
restflight = totalflight;
new_phase = startphase;

while restflight > sn
    flight = restflight;
    [endpoint, new_th, new_th_z, restflight, centerpoint] = func_findhitobj190511(R,center,trans,endpoint,new_th,new_th_z,flight,mode3D,sn);
    frac = (flight-restflight)/(totalflight+eps);
%    phaseshift = func_phaseshift190511(centerpoint + new_exceeds.*(2*limits) * posratio, G, axis, time*frac);
    phaseshift = func_phaseshift190511(centerpoint, G, axis, time*frac);
    new_phase = mod(new_phase + real(phaseshift), 2*pi);
%     new_exceeds = new_exceeds + add_exceeds; % centerpointには新しいexceeds情報を与えてはいけないので, 今回の分を足すタイミングはここであるべき.    
end
