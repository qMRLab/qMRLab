function [E,J]=SynthMeasWatsonSHCylSingleRadGPD_PGSE(x, grad_dirs, G, delta, smalldel, fibredir, roots)
% Substrate: Impermeable cylinders with one radius in a homogeneous background.
% Orientation distribution: Watson's distribution with SH approximation
% Pulse sequence: Pulsed gradient spin echo
% Signal approximation: Gaussian phase distribution.
%
% [E,J]=SynthMeasWatsonSHCylSingleRadGPD_PGSE(x, grad_dirs, G, delta, smalldel, fibredir, roots)
% returns the measurements E according to the model and the Jacobian J of the
% measurements with respect to the parameters.  The Jacobian does not
% include derivates with respect to the fibre direction.
%
% x is the list of model parameters in SI units:
% x(1) is the volume fraction of the intracellular space.
% x(2) is the free diffusivity of the material inside and outside the cylinders.
% x(3) is the hindered diffusivity outside the cylinders in perpendicular directions.
% x(4) is the radius of the cylinders.
% x(5) is the concentration parameter of the Watson's distribution
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
% roots contains solutions to the Bessel function equation from function
% BesselJ_RootsCyl.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%


% Duplication with SynthMeasDistributedRadVG remains, because of the
% derivative computation.

f=x(1);
dPar=x(2);
dPerp=x(3);
R=x(4);
kappa=x(5);

% build the input x vector for hindered compartment
x_h = [dPar dPerp kappa];

% build the input x vector for restricted diffusion in Neuman cylinder model
% set diffusion coeff in restricted compartment same as parallel one in
% hindered.
x_r = [dPar R kappa];

% Synthesize measurements from model
if (nargout>1)
	[E_h, J_h] = SynthMeasWatsonHinderedDiffusion_PGSE(x_h, grad_dirs, G, delta, smalldel, fibredir);
	[E_r, J_r] = SynthMeasWatsonSHCylNeuman_PGSE(x_r, grad_dirs, G, delta, smalldel, fibredir, roots);
else
	E_h = SynthMeasWatsonHinderedDiffusion_PGSE(x_h, grad_dirs, G, delta, smalldel, fibredir);
	E_r = SynthMeasWatsonSHCylNeuman_PGSE(x_r, grad_dirs, G, delta, smalldel, fibredir, roots);
end

E=(1-f)*E_h+f*E_r;

% Compute the Jacobian matrix
if(nargout>1)
    
    % dE_tot/df = E_r - E_h
    dEtdf = E_r - E_h;
    
    % dE_tot/ddPar
    dEtddPar = (1-f)*J_h(:,1) + f*J_r(:,1);
    
    % dE_tot/ddPerp
    dEtddPerp = (1-f)*J_h(:,2);
    
    % dE_tot/dR
    dEtdr = f*J_r(:,2);
    
    % dE_tot/dk
    dEtdk = (1-f)*J_h(:,3) + f*J_r(:,3);
    
    % Construct the jacobian matrix. 
    J = zeros(length(E), 5);
    J(:,1) = dEtdf;
    J(:,2) = dEtddPar;
    J(:,3) = dEtddPerp;
    J(:,4) = dEtdr;
    J(:,5) = dEtdk;
end

