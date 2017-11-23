function [LE,J]=CylNeumanLePerp_PGSE(d, R, G, delta, smalldel, roots)
% Substrate: Parallel, impermeable cylinders with one radius in an empty
%            background.
% Pulse sequence: Pulsed gradient spin echo
% Signal approximation: Gaussian phase distribution.
%
% [LE,J] = CylNeumanLePerp_PGSE(d, R, G, delta, smalldel, roots)
%
% returns the log signal attenuation in perpendicular direction (LePerp) for
% EACH RADIUS specified in R according to the Neuman model and the Jacobian J
% of LePerp with respect to the parameters.
%
% The Jacobian DOES NOT include derivates with respect to the fibre direction.
%
% d is the diffusivity of the material inside the cylinders.
%
% R is the list of the radii of the cylinders. It has size [1 m] where m is the
% number of radii.
%
% G, delta and smalldel are the gradient strength, pulse separation and
% pulse length of each measurement in the protocol.  Each has
% size [N 1].
%
% roots contains solutions to the Bessel function equation from function
% BesselJ_RootsCyl.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

% When R=0, no need to do any calculation
if (R == 0.00)
    LE = zeros(size(G,1), size(R,2));
    J = zeros([size(LE), 2]);
	 J(:,:,:) = 0;
    return;
end

% Check the roots array is correct
if(abs(roots(1) - 1.8412)>0.0001)
    error('Looks like the roots array is wrong.  First value should be 1.8412, but is %f', roots(1));
end

% Radial wavenumbers
GAMMA = 2.675987E8;

% number of gradient directions, i.e. number of measurements
l_q=size(G,1);
l_a=numel(R);
k_max=numel(roots);

R_mat=repmat(R,[l_q 1]);
R_mat=R_mat(:);
R_mat=repmat(R_mat,[1 1 k_max]);
R_matSq=R_mat.^2;

root_m=reshape(roots,[1 1 k_max]);
alpha_mat=repmat(root_m,[l_q*l_a 1 1])./R_mat;
amSq=alpha_mat.^2;
amP6=amSq.^3;

deltamx=repmat(delta,[1,l_a]);
deltamx_rep = deltamx(:);
deltamx_rep = repmat(deltamx_rep,[1 1 k_max]);

smalldelmx=repmat(smalldel,[1,l_a]);
smalldelmx_rep = smalldelmx(:);
smalldelmx_rep = repmat(smalldelmx_rep,[1 1 k_max]);

Gmx=repmat(G,[1,l_a]);
GmxSq = Gmx.^2;

% Perpendicular component (Neuman model)
sda2 = smalldelmx_rep.*amSq;
bda2 = deltamx_rep.*amSq;
emdsda2 = exp(-d*sda2);
emdbda2 = exp(-d*bda2);
emdbdmsda2 = exp(-d*(bda2 - sda2));
emdbdpsda2 = exp(-d*(bda2 + sda2));

sumnum1 = 2*d*sda2;
% the rest can be reused in dE/dR
sumnum2 = - 2 + 2*emdsda2 + 2*emdbda2;
sumnum2 = sumnum2 - emdbdmsda2 - emdbdpsda2;
sumnum = sumnum1 + sumnum2;

sumdenom = d^2*amP6.*(R_matSq.*amSq - 1);

% Check for zeros on top and bottom
%sumdenom(find(sumnum) == 0) = 1;
sumterms = sumnum./sumdenom;

testinds = find(sumterms(:,:,end)>0);
test = sumterms(testinds,1)./sumterms(testinds,end);
if(min(test)<1E4)
    warning('Ratio of largest to smallest terms in Neuman model sum is <1E4.  May need more terms.');
end

s = sum(sumterms,3);
s = reshape(s,[l_q,l_a]);
if(min(s)<0)
    warning('Negative sums found in Neuman sum.  Setting to zero.');
    s(find(s<0))=0;
end

LE = -2*GAMMA^2*GmxSq.*s;

% Compute the Jacobian matrix
if(nargout>1)
    
    % dLE/dd
    sumnumD = 2*sda2;
    sumnumD = sumnumD - 2*sda2.*emdsda2;
    sumnumD = sumnumD - 2*bda2.*emdbda2;
    sumnumD = sumnumD + (bda2 - sda2).*emdbdmsda2;
    sumnumD = sumnumD + (bda2 + sda2).*emdbdpsda2;
    sumtermsD = sumnumD./sumdenom;

    sD = sum(sumtermsD,3);
    sD = reshape(sD,[l_q,l_a]);

    dLEdd = -2*GAMMA^2*GmxSq.*(sD - 2*s/d);

    % dLE/dR
    sumtermsR = (6*sumterms - 2*d*sumtermsD)./R_mat;
    
    sR = sum(sumtermsR,3);
    sR = reshape(sR,[l_q,l_a]);

    dLEdr = -2*GAMMA^2*GmxSq.*sR;

    % Construct the jacobian matrix.
    J = zeros([size(LE), 2]);
    J(:,:,1) = dLEdd;
    J(:,:,2) = dLEdr;
end

