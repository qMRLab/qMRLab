function [E,J]=SynthMeasWatsonSHCylSingleRadIsoV_GPD(x, protocol, fibredir, roots)
% Substrate: Impermeable cylinders with one radius in a homogeneous background.
% Orientation distribution: Watson's distribution with SH approximation
% Signal approximation: Gaussian phase distribution.
% Notes: This version includes an isotropic diffusion compartment with its own
% diffusivity.
%
% [E,J]=SynthMeasWatsonSHCylSingleRadIsoV_GPD(x, protocol, fibredir, roots)
% returns the measurements E according to the model and the Jacobian J of the
% measurements with respect to the parameters.  The Jacobian does not
% include derivates with respect to the fibre direction.
%
% x is the list of model parameters in SI units:
% x(1) is the volume fraction of the intracellular space.
% x(2) is the free diffusivity of the material inside and outside the cylinders.
% x(3) is the hindered diffusivity outside the cylinders in perpendicular directions.
% x(4) is the radius of the cylinders.
% x(5) is the concentration parameter of the Watson's distribution.
% x(6) is the volume fraction of the isotropic compartment.
% x(7) is the diffusivity of the isotropic compartment.
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

fiso = x(6);
dIso = x(7);

% Call the model with no isotropic component to get the anisotropic component.
if(nargout == 1)
    Eaniso=SynthMeasWatsonSHCylSingleRadGPD(x, protocol, fibredir, roots);
    Eiso = SynthMeasIsoGPD(dIso, protocol);
else
    [Eaniso,Janiso]=SynthMeasWatsonSHCylSingleRadGPD(x, protocol, fibredir, roots);
    [Eiso, Jiso] = SynthMeasIsoGPD(dIso, protocol);
end

E = (1-fiso)*Eaniso + fiso*Eiso;

if(nargout>1)
    
    % Update with anisotropic component.
    J = Janiso*(1-fiso);
    
    % Add derivatives wrt isotropic fraction.
    J(:,6) = Eiso - Eaniso;
    
    % Add entry for dIso
    J(:,7) = fiso*Jiso;
end

