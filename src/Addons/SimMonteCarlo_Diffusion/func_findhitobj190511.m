function [endpoint, new_th, new_th_z, restflight, centerpoint] = func_findhitobj190511(R,center,trans,startpoint,th_xy,th_z,flight,mode3D,sn)

%★ func_findhitobj190511
%  func_findhitobj190403より改変。MRathon用に、あえてExceedsを外す。
%
%また、R、center、transがセルではなくて行列で表現されるように全体に改変している。床反射や天井反射も不要なので削除。hightももはや不要。

%★ func_findhitobj190403
% func_findhitobj190327より改変.
% 決まった範囲を超えるとマリオ移動(下に落ちると上から出てくる)するように.

% 【入力系】
% R,center,height -> centerはセル.　各要素が各構造物に対応. 対象のXY方向の半径(定数), 中心([x,y,z]), height(定数, Z方向の高さ(centerからの長さなので実際の高さはこの2倍))
% trans -> セル. 対象の壁の透過率 (定数)
% startpoint, th_xy, th_z -> スタート地点(x,y,z), XY方向の射出角(定数), Z方向の射出角(仰角)(定数). 仰角は-0.5pi～0.5pi
% totalflight ->今回の全飛距離
% startphase -> 開始時の位相ずれ. 回転座標で考える.
% G -> このstepにおける傾斜磁場の強さ. MPG方向にそった座標上の距離1にどれだけの傾斜があるか. 単位はミリテスラ.
% axis -> MPG方向. [th_xy, th_z]のようにx軸からの角度と仰角で表現することにする.
% time -> このstepがどれだけの実時間に相当するか. ラーモア周波数を考えるためなどに必要. 単位はmicrosec.

% limits -> length(limits) = 3. [-x,x],[-y,y],[-z,z]の範囲を超えると反対側から出てくる.

% 【出力系】
% endpoint ->それぞれのobjectを想定したときの終了位置. size(endpoint) = [1,3]
% new_th_xy, new_th_z -> 終了時の射出角.(定数), Z方向の射出角(仰角)(定数). 仰角は-0.5pi～0.5pi
% restflight -> 残存飛距離

% exceeds -> length(exceeds) = 3; x,y,zのlimit方向に今回の処理で何回限界突破したか. 正方向なら+1,
% 負方向なら-1が入る.限界突破したところで一度止まるので2以上の数は入らない.


numelobj = size(center,1);
% endpoint_ = cell(numelobj+1,1); % +1はxyz限界(のうち一番近いもの)を候補に入れるため
% centerpoint_ = cell(numelobj+1,1);
% results = zeros(numelobj+1,3); % new_th, new_th_z, restflight
% exceeds_ = zeros(numelobj+1,3); 

endpoint_ = zeros(numelobj,3);
centerpoint_ = zeros(numelobj,3);
results = zeros(numelobj,3); % new_th, new_th_z, restflight
for r = 1:numelobj
%     [endpoint_{r},~,results(r,1), results(r,2), results(r,3), centerpoint_{r}] =...
%         func_endpoint190327(R(r),center{r},height(r),trans(r),startpoint,th_xy,th_z,flight,sn);

[endpoint_(r,:), results(r,1), results(r,2), results(r,3), centerpoint_(r,:)] =...
        func_endpoint190511(R(r),center(r,:),trans(r),startpoint,th_xy,th_z,flight,mode3D,sn);
   
end

% % x,y,z限界に達した場合の残存flightを求める.
% flight_lims = flight * [cos(th_z) * cos(th_xy), cos(th_z) * sin(th_xy), sin(th_z)]; % x,y,z方向への残存飛距離(符号付き)
% fracs = (sign(flight_lims) .* limits - startpoint)./flight_lims; % length(fracs) = 3となる. それぞれの進行方向の限界までの距離が残存飛距離の何倍になるか.
% fracs(isinf(fracs)) = intmax;
% limid = false(1,3);
% limid(find(fracs==min(fracs),1)) = true; % e.g.) limid = [1,0,0]
% 
% [temp, centerpoint_{end}] = func_flyA(startpoint, flight*fracs(limid), th_xy, th_z); %限界突破したところで止まるので, centerpointはそのままで良い.
% endpoint_{end} = temp + abs(limits)*2 .* limid .* -sign(flight_lims); % endpointはマリオ処理. 限界突破した軸について, 進行方向の逆にlimitの2倍移動する, という処理.
% 
% results(end,:) = [th_xy, th_z, flight*(1-fracs(limid))];
% exceeds_(end,:) = limid .* sign(flight_lims); % 本命以外はどうせゼロ
% 
% hitid = find(results(:,3) == max(results(:,3)),1); % 順番的に,限界突破とヒットが同時なら, ヒットが優先される.

hitid = find(results(:,3) == max(results(:,3)),1);
endpoint = endpoint_(hitid,:);
new_th = results(hitid,1); new_th_z = results(hitid,2); restflight = results(hitid,3);
centerpoint = centerpoint_(hitid,:);
%exceeds = exceeds_(hitid,:);


    
        

