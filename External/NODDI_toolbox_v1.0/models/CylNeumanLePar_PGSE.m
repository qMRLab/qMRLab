function [LE,J]=CylNeumanLePar_PGSE(x, G, delta, smalldel)
% Substrate: Parallel, impermeable cylinders with one radius in an empty
%            background.
% Pulse sequence: Pulsed gradient spin echo
% Signal approximation: Gaussian phase distribution.
%
% [LE,J]=CylNeumanLePar_PGSE(x, G, delta, smalldel)
% returns the log signal attenuation in parallel direction (LePar) according
% to the Neuman model and the Jacobian J of LePar with respect to the
% parameters.  The Jacobian does not include derivates with respect to the
% fibre direction.
%
% x is the list of model parameters in SI units:
% x(1) is the diffusivity of the material inside the cylinders.
%
% G, delta and smalldel are the gradient strength, pulse separation and
% pulse length of each measurement in the protocol.  Each has
% size [N 1].
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

d=x(1);

% Radial wavenumbers
GAMMA = 2.675987E8;
modQ = GAMMA*smalldel.*G;
modQ_Sq = modQ.^2;

% diffusion time for PGSE, in a matrix for the computation below.
difftime = (delta-smalldel/3);

% Parallel component
LE =-modQ_Sq.*difftime*d;

% Compute the Jacobian matrix
if(nargout>1)
    % dLE/d
    J = -modQ_Sq.*difftime;
end

