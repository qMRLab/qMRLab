function [pos2] = func_rotate_pos_around_zero190511(pos1, theta)

% ì¸óÕç¿ïWÇå¥ì_íÜêSÇ…thetaâÒì]Ç≥ÇπÇΩç¿ïWÇèoóÕÇ∑ÇÈ(XYïΩñ )

% Åyì¸óÕånÅz
%   pos1 -> ì¸óÕÇÃç¿ïW. size(pos1) = [1,2]
%   theta -> âÒì]Ç∑ÇÈäpìx(radian). íËêî
% ÅyèoóÕånÅz
%   pos2 -> èoóÕÇÃç¿ïW. size(pos2) = [1,2]

    matrix = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    pos2 = (matrix * pos1(:))';
    