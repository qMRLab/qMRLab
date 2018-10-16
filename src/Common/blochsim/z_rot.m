function Rz=z_rot(phi)
%Z_ROT Matrix creating a rotation around the z axis by an angle phi.
%   phi: angle in radians.

Rz = [cos(phi) -sin(phi) 0;sin(phi) cos(phi) 0; 0 0 1];


