function Rx=x_rot(phi)
%X_ROT Matrix creating a rotation around the x axis by an angle phi.
%   phi: angle in radians.

Rx = [1 0 0; 0 cos(phi) -sin(phi);0 sin(phi) cos(phi)];


