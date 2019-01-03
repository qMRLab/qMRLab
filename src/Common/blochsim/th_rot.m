function Rth=th_rot(phi,theta)
%TH_ROT Calculates the rotation matrix for the RF pulse flip angle, taking into
% consideration of the RF pulses phase.
%
%   phi: RF pulse flip-angle (radian)
%   theta: RF pulse phase (radian).

Rz = z_rot(-theta);
Rx = x_rot(phi);
Rth = inv(Rz)*Rx*Rz;

end
