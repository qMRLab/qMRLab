function [sumRes, resJ, H]=fobj_rician_fix(x, meas, protocol, model, sig, constants, fix, x0)
% Wrapper for fobj_rician for use with fmincon_fix.
%
% x is the encoded model parameter values
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
% constants contains values required to compute the model signals.
%
% fix is a binary array specifying which parameters are fixed and which
% vary.
%
% x0 is the full starting point including the fixed parameters.
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%

% Construct the full parameter list including fixed values.
xf = fix.*x0;
xf(find(fix==0)) = x;

% Now call the full objective function.
if(nargout == 1)
    sumRes = fobj_rician(xf, meas, protocol, model, sig, constants);
elseif(nargout == 2)
    [sumRes resJ] = fobj_rician(xf, meas, protocol, model, sig, constants);
else
    [sumRes, resJ, H] = fobj_rician(xf, meas, protocol, model, sig, constants);
end
