function Ry=y_rot(phi)
%Y_ROT Matrix creating a rotation around the y axis by an angle phi.
%   phi: angle in radians.

Ry = [cos(phi) 0 sin(phi);0 1 0;-sin(phi) 0 cos(phi)];


