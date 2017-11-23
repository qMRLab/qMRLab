function [D, Ep] = FitLinearDT(E, protocol, fitS0)
% Fits the DT model using linear least squares.
%
% D=FitLinearDT(E, protocol, fitS0)
% returns [logS(0) Dxx Dxy Dxz Dyy Dyz Dzz].
%
% E is the set of measurements.
%
% protocol is the acquisition protocol.
%
%
% fitS0 is a flag for enabling the fitting of S0
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%         Gary Hui Zhang     (gary.zhang@ucl.ac.uk)
%

if (nargin < 3)
	fitS0 = 0;
end

if (isfield(protocol, 'dti_subset'))
    E = E(protocol.dti_subset);
    protocol.delta = protocol.delta(protocol.dti_subset);
    protocol.smalldel = protocol.smalldel(protocol.dti_subset);
    protocol.G = protocol.G(protocol.dti_subset);
    protocol.grad_dirs = protocol.grad_dirs(protocol.dti_subset,:);
    protocol.b0_Indices = intersect(protocol.b0_Indices, protocol.dti_subset);
end

X = DT_DesignMatrix(protocol);
if fitS0 == 0
  X = X(:,2:end);
end
Xi = pinv(X);

% We assume that E are all positives
% If not, first filter out the nonpositive values with RemoveNegMeas

if (fitS0)
	D = Xi*log(E);
    if (nargout > 1)
        Ep = exp(X*D);
    end
else
	S0 = squeeze(mean(E(protocol.b0_Indices)));
	E = E/S0;
	D = zeros(7,1);
	D(1) = log(S0);
	D(2:end) = Xi*log(E);
    if (nargout > 1)
        Ep = S0*exp(X*D(2:end));
    end
end

