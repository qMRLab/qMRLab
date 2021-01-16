%% throt function
% Calculates the rotation matrix for the RF pulse flip angle, taking into
% consideration of the RF pulses phase.
function Rth=throt(phi,theta)

Rz = zrot(-theta);
Rx = xrot(phi);
Rth = inv(Rz)*Rx*Rz;


