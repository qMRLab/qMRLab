function [E,J]=SynthMeasWatsonSHCylNeuman_PGSE(x, grad_dirs, G, delta, smalldel, fibredir, roots)
% Substrate: Impermeable cylinders with one radius in an empty background.
% Orientation distribution: Watson's distribution with SH approximation
% Pulse sequence: Pulsed gradient spin echo
% Signal approximation: Gaussian phase distribution.
%
% [E,J]=SynthMeasWatsonSHCylNeuman_PGSE(x, grad_dirs, G, delta, smalldel, fibredir, roots)
% returns the measurements E according to the model and the Jacobian J of the
% measurements with respect to the parameters.  The Jacobian does not
% include derivates with respect to the fibre direction.
%
% x is the list of model parameters in SI units:
% x(1) is the diffusivity of the material inside the cylinders.
% x(2) is the radius of the cylinders.
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
% roots contains solutions to the Bessel function equation from function
% BesselJ_RootsCyl.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

if length(x) ~= 3
    error('the first argument should have exactly three parameters');
end

d=x(1);
R=x(2);
kappa=x(3);

l_q = size(grad_dirs,1);

% Parallel component
if nargout > 1
    [LePar, J_LePar] = CylNeumanLePar_PGSE(d, G, delta, smalldel);
else
    LePar = CylNeumanLePar_PGSE(d, G, delta, smalldel);
end

% Perpendicular component
if nargout > 1
    [LePerp, J_LePerp] = CylNeumanLePerp_PGSE(d, R, G, delta, smalldel, roots);
else
    LePerp = CylNeumanLePerp_PGSE(d, R, G, delta, smalldel, roots);
end
ePerp = exp(LePerp);

% Compute the Legendre weighted signal
Lpmp = LePerp - LePar;
if nargout > 1
    [lgi, J_lgi] = LegendreGaussianIntegral(Lpmp, 6);
else
    lgi = LegendreGaussianIntegral(Lpmp, 6);
end

% Compute the spherical harmonic coefficients of the Watson's distribution
if nargout > 1
    [coeff, J_coeff] = WatsonSHCoeff(kappa);
else
    coeff = WatsonSHCoeff(kappa);
end
coeffMatrix = repmat(coeff, [l_q, 1]);

% Compute the dot product between the symmetry axis of the Watson's distribution
% and the gradient direction
%
% For numerical reasons, cosTheta might not always be between -1 and 1
% Due to round off errors, individual gradient vectors in grad_dirs and the
% fibredir are never exactly normal.  When a gradient vector and fibredir are
% essentially parallel, their dot product can fall outside of -1 and 1.
%
% BUT we need make sure it does, otherwise the legendre function call below
% will FAIL and abort the calculation!!!
%
cosTheta = grad_dirs*fibredir;
badCosTheta = find(abs(cosTheta)>1);
cosTheta(badCosTheta) = cosTheta(badCosTheta)./abs(cosTheta(badCosTheta));

% Compute the SH values at cosTheta
sh = zeros(size(coeff));
shMatrix = repmat(sh, [l_q, 1]);
for i = 1:7
    shMatrix(:,i) = sqrt((i - .75)/pi);
    % legendre function returns coefficients of all m from 0 to l
    % we only need the coefficient corresponding to m = 0
    % WARNING: make sure to input ROW vector as variables!!!
    % cosTheta is expected to be a COLUMN vector.
    tmp = legendre(2*i - 2, cosTheta');
    tmp = tmp';
    shMatrix(:,i) = shMatrix(:,i) .* tmp(:,1);
end

E = sum(lgi.*coeffMatrix.*shMatrix, 2);
% with the SH approximation, there will be no guarantee that E will be positive
% but we need to make sure it does!!! replace the negative values with 10% of
% the smallest positive values
E(find(E<=0)) = min(E(find(E>0)))*0.1;
E = 0.5*E.*ePerp;

% Compute the Jacobian matrix
if(nargout>1)
    % dePerp/dd
    dePerpdd = E.*J_LePerp(1);
    % dePar/dd
    dElgi = sum(J_lgi.*coeffMatrix.*shMatrix, 2);
    dePardd = 0.5*dElgi.*(J_LePerp(:,:,1) - J_LePar).*ePerp;
    % dE/dd
    dEdd = dePardd + dePerpdd;
    
	% dePerp/dR
    dePerpdR = E.*J_LePerp(2);
    % dePar/dR
    dePardR = 0.5*dElgi.*J_LePerp(:,:,2).*ePerp;
    % dE/dR
    dEdR = dePardR + dePerpdR;
    
    % dE/dK
    J_coeffMatrix = repmat(J_coeff, [l_q, 1]);
    dEdk = sum(lgi.*J_coeffMatrix.*shMatrix,2);
    dEdk = 0.5*dEdk.*ePerp;
    
    % Construct the jacobian matrix.
    J = zeros(length(E), 3);
    J(:,1) = dEdd;
    J(:,2) = dEdR;
    J(:,3) = dEdk;
end

