function [pos1, pos2, dist, stat] = func_cross_cir_line190511(x,y,th,R)

% 原点中心, 半径Rの円と, 点x,yを通り,角度thの直線との交点, 交点までの距離を求める. (xy平面での演算)

% 【入力系】
% x,y -> 直線の通る点の座標. それぞれ定数.
% th -> 直線の傾きをX軸からの回転角(rad)で表す.
% R -> 原点中心の円の半径. 定数
% inv -> 1なら近いほうを無視する。(壁の直近(上)にあるケース)

% 【出力系】
% pos1, pos2 -> [x,y]からth方向に進んだときの近い方, 遠い方の交点のxy座標. それぞれ長さ2のベクトル.
% 交点がないときはゼロ. size = [1,2]
% dist -> [x,y]から近い方, 遠い方の交点までの距離. 長さ2のベクトル. 要素は正の数. size = [1,2]
% stat -> 接点が2つない, あるいは,両方とも逆方向にあればゼロ. 両方進行方向にあれば2. 一方が進行方向の反対側(円の内側にいる場合)は1. 定数


% このとき直線の式は: Y = tan(th)*X + (y - tan(th)*x)

D1 = abs(y -tan(th)*x) / sqrt(tan(th)^2 + 1); % 直線と原点の距離

if D1 < R % ぶつかる可能性あり(接しているときはぶつからないと考える)
    al = tan(th)^2 + 1; be = tan(th) * (y-tan(th)*x); ga = (y - tan(th)*x)^2 - R^2;
    % 円と直線の交点を求めるための2次式…の各成分: (al)+x^2 + 2*(be)*x + ga = 0 
    t = sqrt(be^2 - (al*ga));
    
    xpos = [ (-be+t)/al, (-be-t)/al]; ypos = tan(th)*xpos + (y - tan(th)*x);
    
    % どちらが進行方向に対して近くにあるかを知りたい. (負なら反対方向)
    Dx = (xpos - x)/sign(cos(th)+eps); % size(Dx) = [1,2];
    Dy = (ypos - y)/sign(sin(th)+eps);
    D = sqrt(Dx.^2 + Dy.^2);
    
    temp = sign(sum([Dx;Dy],1)); % Dx(n),Dy(n)が両方とも正,あるいは片方が正なら進行方向に交点がある.
    stat = sum(temp>0);
    
    if stat==0 %完全に反対方向に向かっている
        pos1 = NaN; pos2 = NaN; dist = [NaN,NaN];
    else
        temp = 1./(Dx+Dy-eps); % 逆数にすることで距離が小さく(近く),値が正(進行方向)のものが最も大きな数になる.極小値を引いているのは壁上の距離ゼロを負にしてはじくため.
        sel = find(temp==max(temp),1); % 接している場合は交点なしの扱いになっているはずだが, 念のため複数選択されないように.

        pos1 = [xpos(sel),ypos(sel)];
        pos2 = [xpos(3-sel),ypos(3-sel)]; % selは1か2なので
        dist = [D(sel), D(3-sel)];
           
    end
else
    pos1 = NaN; pos2 = NaN; dist = [NaN,NaN]; stat = 0;
end
