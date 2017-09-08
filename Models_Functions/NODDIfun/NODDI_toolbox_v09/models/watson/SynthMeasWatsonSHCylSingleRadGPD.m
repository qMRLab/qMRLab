function [E,J]=SynthMeasWatsonSHCylSingleRadGPD(x, protocol, fibredir, roots)
% Substrate: Impermeable cylinders with one radius in a homogeneous background.
% Orientation distribution: Watson's distribution with SH approximation
% Pulse sequence: Any
% Signal approximation: Gaussian phase distribution.
%
% [E,J]=SynthMeasWatsonSHCylSingleRadGPD(x, protocol, fibredir, roots)
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

if(strcmp(protocol.pulseseq, 'PGSE') || strcmp(protocol.pulseseq, 'STEAM'))
    if(nargout == 1)
        [E] = SynthMeasWatsonSHCylSingleRadGPD_PGSE(x, protocol.grad_dirs, protocol.G', protocol.delta', protocol.smalldel', fibredir, roots);
    else
        [E J] = SynthMeasWatsonSHCylSingleRadGPD_PGSE(x, protocol.grad_dirs, protocol.G', protocol.delta', protocol.smalldel', fibredir, roots);
    end
elseif(strcmp(protocol.pulseseq, 'DSE'))
    if(nargout == 1)
        [E] = SynthMeasWatsonSHCylSingleRadGPD_DSE(x, protocol.grad_dirs, protocol.G', protocol.TE, protocol.delta1', protocol.delta2', protocol.delta3', protocol.t1', protocol.t2', protocol.t3', fibredir, roots);
    else
        [E J] = SynthMeasWatsonSHCylSingleRadGPD_DSE(x, protocol.grad_dirs, protocol.G', protocol.TE, protocol.delta1', protocol.delta2', protocol.delta3', protocol.t1', protocol.t2', protocol.t3', fibredir, roots);
    end
else
    error(['Unknown pulse sequence: ' protocol.pulseseq]);
end            

