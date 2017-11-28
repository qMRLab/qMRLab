function [sumRes, resJ, H]=fobj_rician(x, meas, protocol, model, sig, constants)
% Objective function for fitting models using a Rician noise  model.
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
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%

% Need to transform to actual parameter values from optimized quantities.
xdec = GradDescDecode(model, x);

scale = GetScalingFactors(model);
if (strcmp(model, 'ExCrossingCylSingleRadGPD') ||...
    strcmp(model, 'ExCrossingCylSingleRadIsoDotTortIsoV_GPD_B0'))
    xsc = xdec(1:(end-4))./scale(1:(end-1));
    theta = [xdec(end-3) xdec(end-1)]';
    phi = [xdec(end-2) xdec(end)]';
    fibredir = [cos(phi).*sin(theta) sin(phi).*sin(theta) cos(theta)]';
else
    xsc = xdec(1:(end-2))./scale(1:(end-1));
    theta = xdec(end-1);
    phi = xdec(end);
    fibredir = [cos(phi)*sin(theta) sin(phi)*sin(theta) cos(theta)]';
end

if(nargout == 1)
    sumRes = fobj_rician_st(xsc, meas, protocol, model, sig, fibredir, constants);
elseif(nargout == 2)
    [sumRes resJ] = fobj_rician_st(xsc, meas, protocol, model, sig, fibredir, constants);
else
    [sumRes, resJ, H] = fobj_rician_st(xsc, meas, protocol, model, sig, fibredir, constants);
end
