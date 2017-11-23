function [dw, Jdw]=WatsonHinderedDiffusionCoeff(dPar, dPerp, kappa)
% Substrate: Anisotropic hindered diffusion compartment
% Orientation distribution: Watson's distribution
%
% [dw, Jdw]=WatsonHinderedDiffusionCoeff(dPar, dPerp, kappa)
% returns the equivalent parallel and perpendicular diffusion coefficients
% for hindered compartment with impermeable cylinder's oriented with a
% Watson's distribution with a cocentration parameter of kappa
%
% dPar is the free diffusivity of the material inside and outside the cylinders.
% dPerp is the hindered diffusivity outside the cylinders in perpendicular directions.
% kappa is the concentration parameter of the Watson's distribution
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

% compute the equivalent diffusion coefficient after integrating
% for all possible orientations
dw = zeros(2,1);
dParMdPerp = dPar - dPerp;

if kappa < 1e-5
	dParP2dPerp = dPar + 2*dPerp;
	k2 = kappa*kappa;
	dw(1) = dParP2dPerp/3 + 4*dParMdPerp*kappa/45 + 8*dParMdPerp*k2/945;
	dw(2) = dParP2dPerp/3 - 2*dParMdPerp*kappa/45 - 4*dParMdPerp*k2/945;
    if (nargout==2)
        Jdw(1,1) = 1/3 + 4/45*kappa + 8/945*k2;
        Jdw(1,2) = 2/3 - 4/45*kappa - 8/945*k2;
        Jdw(1,3) = 4/45*dParMdPerp + 16/945*dParMdPerp*kappa;
        Jdw(2,1) = 1/3 - 2/45*kappa - 4/945*k2;
        Jdw(2,2) = 2/3 + 2/45*kappa + 4/945*k2;
        Jdw(2,3) = -2/45*dParMdPerp - 8/945*dParMdPerp*kappa;
    end
else
	sk = sqrt(kappa);
	dawsonf = 0.5*exp(-kappa)*sqrt(pi)*erfi(sk);
	factor = sk/dawsonf;
	dw(1) = (-dParMdPerp+2*dPerp*kappa+dParMdPerp*factor)/(2*kappa);
	dw(2) = (dParMdPerp+2*(dPar+dPerp)*kappa-dParMdPerp*factor)/(4*kappa);
    if (nargout==2)
        % D[DawsonF(x),x] = 1 - 2xDawsonF(x)
        dfactordk = ((1+2*kappa)*dawsonf - sk)/(2*sk*dawsonf*dawsonf);
        Jdw(1,1) = (-1 + factor)/(2*kappa);
        Jdw(1,2) = (1 + 2*kappa - factor)/(2*kappa);
        Jdw(1,3) = (-2*dw(1) + 2*dPerp + dParMdPerp*dfactordk)/(2*kappa);
        Jdw(2,1) = (1 + 2*kappa - factor)/(4*kappa);
        Jdw(2,2) = (-1 + 2*kappa + factor)/(4*kappa);
        Jdw(2,3) = (-4*dw(2) + 2*(dPar+dPerp) - dParMdPerp*dfactordk)/(4*kappa);
    end
end
