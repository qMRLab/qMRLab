function [E,J]=SynthMeasWatsonSHCylSingleRadTortGPD(x, protocol, fibredir, roots)
% Substrate: Impermeable cylinders with one radius in a homogeneous background.
% Orientation distribution: Watson's distribution with SH approximation
% Pulse sequence: Any
% Signal approximation: Gaussian phase distribution.
% Notes: This version estimates the hindered diffusivity from the free diffusivity
% and packing density using Szafer et al's tortuosity model for randomly
% packed cylinders.
%
% [E,J]=SynthMeasWatsonSHCylSingleRadTortGPD(x, protocol, fibredir, roots)
% returns the measurements E according to the model and the Jacobian J of the
% measurements with respect to the parameters.  The Jacobian does not
% include derivates with respect to the fibre direction.
%
% x is the list of model parameters in SI units:
% x(1) is the volume fraction of the intracellular space.
% x(2) is the free diffusivity of the material inside and outside the cylinders.
% x(3) is the radius of the cylinders.
% x(4) is the concentration parameter of the Watson's distribution.
%
% protocol is the object containing the acquisition protocol.
%
% fibredir is a unit vector along the symmetry axis of the Watson's
% distribution.  It must be in Cartesian coordinates [x y z]' with size [3 1].
%
% roots contains solutions to the Bessel function equation from function
% BesselJ_RootsCyl.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%


f=x(1);
dPar=x(2);
% This version is for cylinders with regular packing.
%dPerp = dPar/((1 + f^(3/2))^2);
% This one is for randomly packed cylinders
dPerp = dPar*(1-f);
R=[x(3)]; 
kappa=x(4);

x_full = [f dPar dPerp R kappa];

% Call the model with no isotropic component to get the anisotropic component.
if(nargout == 1)
    E=SynthMeasWatsonSHCylSingleRadGPD(x_full, protocol, fibredir, roots);
else
    [E,J_full]=SynthMeasWatsonSHCylSingleRadGPD(x_full, protocol, fibredir, roots);
    J(:,1) = J_full(:,1) - J_full(:,3)*dPar;
    J(:,2) = J_full(:,2) + J_full(:,3)*(1-f);
    J(:,3) = J_full(:,4);
    J(:,4) = J_full(:,5);
end
