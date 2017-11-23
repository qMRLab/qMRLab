function [sumRes, resJ, H] = fobj_rician_st(xsc, meas, protocol, model, sig, fibredir, constants)
% General function called by variants of fobj_rician once fibre direction
% has been extracted and other parameters scaled appropriately.
%
% xsc is the decoded model parameter values
%
% meas is the measurements
%
% protocol is the measurement protocol
%
% model is a string encoding the model
%
% sig is the standard deviation of the Gaussian distributions underlying
% the Rician noise
%
% fibredir is the fibre direction extracted from the full parameter list.
%
% constants contains values required to compute the model signals.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%

E = SynthMeas(model, xsc, protocol, fibredir, constants);

% Find the fitting error (log probabilities of the data given the parameter
% settings).
sumRes = -RicianLogLik(meas, E, sig);

if(nargout>1)
    % Construct the Jacobian of the probabilities from the Jacobian of the
    % measurement estimates.
    scp = meas.*signals./(sig.^2);
    ysc = besseli1d0(scp);
    sc = (E - meas.*ysc)./(sig.^2);
    J = zeros(length(E), length(x));
    for i=1:(length(x)-1)
        J(:,i) = sc.*Jnn(:,i);
    end

    % Need to rescale the derivates to the scale of x
    J = J./repmat(scale(1:(end-1)),[length(E),1]);

    % Now sum over the measurements
    resJ = sum(J);
end

% Finally create the Hessian matrix.  Here in fact we use the Fisher
% information matrix instead to reduce computation and increase stability
% and convergence.  Code is the same as FishMatRician.m.
% if(nargout>2)
%     global RicCorX RicCorY;
% 
%     C = zeros(length(E),1);
%     Esc = E/sig;
%     out = find(Esc>=max(RicCorX));
%     in = find(Esc<max(RicCorX));
%     C(in) = interp1(RicCorX, RicCorY, Esc(in))*sig^2;
%     C(out) = sig^2;
%     JCor = Jnn.*repmat(C, [1,length(x)-1]);
% 
%     H = Jnn'*JCor/(sig^4);
%     
%     % Now compute the elements that depend on sigma.
%     Jsig = Jnn.*repmat(sig^2*E + E.^3 + 2*E.*C, [1,length(x)-1]);
%     H(length(x), 1:(length(x)-1)) = -2*sum(Jsig)/(sig^5);
%     H(1:(length(x)-1), length(x)) = squeeze(H(length(x), 1:(length(x)-1))');
% 
%     H(length(x), length(x)) = -4*sum(-sig^4 + sig^2*E.^2 - E.^2.*C)/(sig^6);
% end
