function [h] = QualityOfFit(signal, fittedpars, model, protocol)
% Assess the quality of fit
% [h] = QualityOfFit(signal, fittedpars, model, protocol);
%
% Typical usage as follows:
% 
% 1) First fit the signal
% [gs fgs ml fml] = ThreeStageFittingVoxel(signal, protocol, model);
%
% 2) Now check the quality of fit
% QualityOfFit(signal, ml, model, protocol);
%
% Author: Gary Hui Zhang, PhD
%

b0 = GetB0(model.name, fittedpars);
fibredir = GetFibreOrientation(model.name, fittedpars);

h = figure;

% the data plot
VoxelDataViewer(protocol, signal, fibredir, b0, h);

% the predicted data plot
% constants is set to zero for NODDI but should be different for
% ActiveAx models
constants = 0;
PlotFittedModel(protocol, model.name, fittedpars, constants, h);

end

