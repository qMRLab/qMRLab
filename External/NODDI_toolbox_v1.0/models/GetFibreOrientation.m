function fibredir = GetFibreOrientation(modelname, fittedpars)
%
% function fibredir = GetFibreOrientation(modelname, fittedpars)
%
% Returns the fibre orientation as a unit vector from fitted parameters.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

theta = fittedpars(:, GetParameterIndex(modelname, 'theta'));
phi = fittedpars(:, GetParameterIndex(modelname, 'phi'));

fibredir = [cos(phi).*sin(theta) sin(phi).*sin(theta) cos(theta)]';

