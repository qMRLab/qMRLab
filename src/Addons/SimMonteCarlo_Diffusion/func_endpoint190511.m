function [endpoint, new_th_xy, new_th_z, restflight, centerpoint] = func_endpoint190511(R,center,trans,startpoint,th_xy, th_z, flight,mode3D,sn) 

% func_endpoint190511.m
% MRathon用に改変。hitstatの廃止。endopointやcenterpointにセルを使うのを廃止。Exceedsの廃止。床処理そのものの廃止。など。
% heightがそもそももういらないので入力からも削除

% もともと細胞外専用のfunc_extracell190307として作ったが, 内外を分ける必要がなくなったので,
% func_endpoint190327と改名.

% 各構造に対して適応することを想定.なので, 対象はいつも一つ. 対象は缶詰型のZ方向に上下の範囲がある円柱を想定.
% 【入力系】
% R,center,height -> 対象のXY方向の半径(定数), 中心([x,y,z]), height(定数, Z方向の高さ(centerからの長さなので実際の高さはこの2倍))
% trans -> 対象の壁の透過率 (定数)
% startpoint, th_xy, th_z -> スタート地点(x,y,z), XY方向の射出角(定数), Z方向の射出角(仰角)(定数). 仰角は-0.5pi～0.5pi
% flight ->今回の最大飛距離 (ぶつかったらそこまでの距離を消費して処理を終わる)
% sn -> small number。壁にトラップされるのを防ぐために、飛程を少し削る。0.000000001ぐらい。


% 【出力系】
% hitstat -> ぶつかった位置, 壁処理(1)か床処理(2)か,そもそもぶつかっていない(0)か
% endpoint ->今回の終了位置(flightを使い切った時以外は基本的にぶつかった位置). size(endpoint) = [1,3]
% new_th_xy, new_th_z -> ぶつかった後の射出角.(定数), Z方向の射出角(仰角)(定数). 仰角は-0.5pi～0.5pi
% restflight -> 残存飛距離.定数.
% frac -> 今回消費した飛距離の割合. 定数.
% centerpoint -> 今回の飛程の中心. MPGをかけるときに必要. size(centerpoint) = [1,3]

xx = startpoint(1)-center(1); yy = startpoint(2)-center(2); zz = startpoint(3)-center(3); %いったん対象構造を原点中心にする.
fl_xy = flight * cos(th_z); %飛距離のxy方向成分, z方向成分の大きさ. z成分だけは負の値になり得る.(th_zの範囲が-0.5pi～0.5piなので)
%fl_z = flight * sin(th_z); これは当たり判定専用に利用していて、最終的なendpointはflyAで求めているのだから、これはもういらない。はず。 
[pos1,~, dist, stat] = func_cross_cir_line190511(xx, yy, th_xy, R); % 対象の"領空"との交点を求める.
% [~,~, distz, statz] = func_cross_line_line190307(sqrt(xx^2+yy^2), zz, th_z, height); % 床・天井との交点を求める. 進行方向とz軸がなす平面で考える(回転座標になるので注意).
frac1a = dist(1)/fl_xy;
% frac1b = dist(2)/fl_xy;
% frac2a = distz(1)/flight;

frac = 1; hitstat = 0;
%tempz = zz + fl_z * frac1a; %最初の領域壁にあたったときのz座標を求めた.

% if stat == 2 && statz>0 % 領域外、かつ領域と交点がある。Z方向も少なくとも違う方向にはいっていない。
%     if abs(tempz) <= height && frac1a < 1 % 領域外から壁にぶつかった. (角に当たった時を含む)
%         frac = frac1a;
%         hitstat = 1;
%     elseif frac1a < frac2a && frac2a < frac1b && frac2a < 1 %領域外から床か天井に当たった
%         frac = frac2a;
%         hitstat = 2;
%     end
%     
% elseif stat == 1 % 領域内
%     if frac2a < frac1a && frac2a < 1 %領空or缶詰内から床か天井に当たった
%         frac = frac2a;
%         hitstat = 2;
%     elseif frac1a < frac2a && abs(tempz) < height && frac1a < 1 % 缶詰内から壁に当たった
%         frac = frac1a;
%         hitstat = 1;
%     end
% end

% if stat >= 1 && frac1a < 1 % 交点があり、かつ飛距離以内である
%     frac = frac1a;
%     hitstat = 1;
% end
% % これら以外ならどこにもあたっていないはず。

new_th_xy = rand()*2*pi; new_th_z = (rand()-0.5)*pi*mode3D; %次の方向はランダム
% 2D指定の時はnew_th_zがゼロになる。反射で次の方向が決まるときは、初めからZ方向の角度がないのでゼロのまま。

sw = 0;
if rand() > trans &&stat >= 1 && frac1a < 1 % 交点があり、かつ飛距離以内である
    frac = frac1a;
    
    theta = acos(pos1(1)/R); % 円にぶつかった場所はX軸から何度回転した位置か
    theta = theta * sign(pos1(2)); % acosだとy軸が正の領域か負の領域か区別できないので, y軸の正負で補正.
    pos1r = func_rotate_pos_around_zero190511([xx,yy], -theta); % 円にぶつかった点が正のX軸上に来るように座標系を回転.

    % このpos1r=[x1,y1]から, [R,0]に向かってParticleが飛ぶことになり,
    % そこから[x1,-y1]に向かってparticleが跳ね返る. そのときの角度を求めて, さらに元の座標系に戻すと
    new_th_xy = acos( (pos1r(1)-R)/dist(1) ) * sign(-pos1r(2)) + theta; %th_zはそのまま
    sw  = -1;

% elseif rand() > trans && hitstat == 2 % 床反射
%     new_th_z = -th_z; %仰角はちょうど反対向きに. th_xyはいじる必要なし。
%     sw = -1;
end

[endpoint,centerpoint] = func_flyA([xx,yy,zz], flight*frac+(sn*sw), th_xy, th_z);
restflight = flight*(1-frac);


endpoint = real(endpoint) + center;
centerpoint = real(centerpoint) + center;

    
    
    
  