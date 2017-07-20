function loglik = RicianLogLik(meas, signals, sig)
% Computes the log likelihood of the measurements given the model signals
% for the Rician noise model.
%
% loglik = RicianLogLik(meas, signals, sig) returns the likelihood ofician distribution.
% measuring meas given the signals and the noise standard deviation sig. 
%
% meas are the measurements
%
% signals are computed from a model
%
% sig is the standard deviation of the Gaussian distributions underlying
% the Rician distribution.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%

% NONCENTRAL CHI
% loglik = -sum(log(noncentralchi(meas, N,sig,signals)));

sumsqsc = (signals.^2 + meas.^2)./(2*sig.^2);
scp = meas.*signals./(sig.^2);
lb0 = logbesseli0(scp);
logliks = - 2*log(sig) - sumsqsc + log(signals) + lb0;
loglik = sum(logliks);

% RICIAN MAISON
% loglik=-sum(log(pdf('rician',meas,signals,sig)));

end

function p= noncentralchi(x, N,sigma_g,eta)
p = abs(x).^N./(sigma_g^2*eta^(N-1)).*exp(-(x.^2+eta^2)/(2*sigma_g^2)).*besseli(N-1,x*eta/sigma_g^2);
end
