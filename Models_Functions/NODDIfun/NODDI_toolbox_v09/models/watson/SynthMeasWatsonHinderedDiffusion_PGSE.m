function [E,J]=SynthMeasWatsonHinderedDiffusion_PGSE(x, grad_dirs, G, delta, smalldel, fibredir)
% Substrate: Anisotropic hindered diffusion compartment
% Orientation distribution: Watson's distribution
% Pulse sequence: Pulsed gradient spin echo
% Signal approximation: N/A
%
% [E,J]=SynthMeasWatsonHinderedDiffusion_PGSE(x, grad_dirs, G, delta, smalldel, fibredir)
% returns the measurements E according to the model and the Jacobian J of the
% measurements with respect to the parameters.  The Jacobian does not
% include derivates with respect to the fibre direction.
%
% x is the list of model parameters in SI units:
% x(1) is the free diffusivity of the material inside and outside the cylinders.
% x(2) is the hindered diffusivity outside the cylinders in perpendicular directions.
% x(3) is the concentration parameter of the Watson's distribution
%
% grad_dirs is the gradient direction for each measurement.  It has size [N
% 3] where N is the number of measurements.
%
% G, delta and smalldel are the gradient strength, pulse separation and
% pulse length of each measurement in the protocol.  Each has
% size [N 1].
%
% fibredir is a unit vector along the symmetry axis of the Watson's
% distribution.  It must be in Cartesian coordinates [x y z]' with size [3 1].
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

dPar = x(1);
dPerp = x(2);
kappa = x(3);

% get the equivalent diffusivities
if (nargout == 1)
    dw = WatsonHinderedDiffusionCoeff(dPar, dPerp, kappa);
else
    [dw, Jdw] = WatsonHinderedDiffusionCoeff(dPar, dPerp, kappa);
end

xh = [dw(1) dw(2)];
if (nargout == 1)
    E = SynthMeasHinderedDiffusion_PGSE(xh, grad_dirs, G, delta, smalldel, fibredir);
else
    [E, Jh] = SynthMeasHinderedDiffusion_PGSE(xh, grad_dirs, G, delta, smalldel, fibredir);
end

% Compute the Jacobian matrix
if(nargout>1)
    % Construct the jacobian matrix.
    J = zeros(size(E, 1), 3);
    J(:,1) = Jh(:,1)*Jdw(1,1) + Jh(:,2)*Jdw(2,1);
    J(:,2) = Jh(:,1)*Jdw(1,2) + Jh(:,2)*Jdw(2,2);
    J(:,3) = Jh(:,1)*Jdw(1,3) + Jh(:,2)*Jdw(2,3);
end

