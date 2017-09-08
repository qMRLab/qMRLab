function [E,J]=SynthMeasHinderedDiffusion_PGSE(x, grad_dirs, G, delta, smalldel, fibredir)
% Substrate: Anisotropic hindered diffusion compartment
% Pulse sequence: Pulsed gradient spin echo
% Signal approximation: N/A
%
% [E,J]=SynthMeasHinderedDiffusion_PGSE(x, grad_dirs, G, delta, smalldel, fibredir)
% returns the measurements E according to the model and the Jacobian J of the
% measurements with respect to the parameters.  The Jacobian does not
% include derivates with respect to the fibre direction.
%
% x is the list of model parameters in SI units:
% x(1) is the free diffusivity of the material inside and outside the cylinders.
% x(2) is the hindered diffusivity outside the cylinders in perpendicular directions.
%
% grad_dirs is the gradient direction for each measurement.  It has size [N
% 3] where N is the number of measurements.
%
% G, delta and smalldel are the gradient strength, pulse separation and
% pulse length of each measurement in the protocol.  Each has
% size [N 1].
%
% fibredir is a unit vector along the cylinder axis.  It must be in
% Cartesian coordinates [x y z]' with size [3 1].
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

dPar=x(1);
dPerp=x(2);

% Radial wavenumbers
GAMMA = 2.675987E8;
modQ = GAMMA*smalldel.*G;
modQ_Sq = modQ.^2;

% Angles between gradient directions and fibre direction.
cosTheta = grad_dirs*fibredir;
cosThetaSq = cosTheta.^2;
sinThetaSq = 1-cosThetaSq;

% b-value
bval = (delta-smalldel/3).*modQ_Sq;

% Find hindered signals
E=exp(-bval.*((dPar - dPerp)*cosThetaSq + dPerp));

% Compute the Jacobian matrix
if(nargout>1)
    bvalE = bval.*E;
    % dE/ddPar
    dEddPar = -bvalE.*cosThetaSq;
    
    % dE/ddPerp
    dEddPerp = -bvalE.*sinThetaSq;
    
    % Construct the jacobian matrix.
    J = zeros(size(E, 1), 2);
    J(:,1) = dEddPar;
    J(:,2) = dEddPerp;
end

