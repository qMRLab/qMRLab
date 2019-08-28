function [magnitude, integphase] = func_integphase190511(phase)

% 【入力】
%  phase -> ベクトル. n個のphase(radian)を並べたベクトル. (全てが単位ベクトルを想定)

% 【出力】
%  magnitude -> 合成したベクトルの大きさ
%　integphase -> 合成したベクトルのphase.

numelmol = size(phase,1);

X = sum(cos(phase),1)/numelmol;
Y = sum(sin(phase),1)/numelmol;

magnitude = sqrt(X.^2+Y.^2);
integphase = acos(X/(magnitude)) .* sign(Y);
