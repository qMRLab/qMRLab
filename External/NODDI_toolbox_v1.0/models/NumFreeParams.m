function numParams = NumFreeParams(modelname)
%
% function numParams = NumFreeParams(modelname)
%
% Given an input modelname, returns the number of free parameters of the model.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

numParams = length(GetParameterStrings(modelname));

