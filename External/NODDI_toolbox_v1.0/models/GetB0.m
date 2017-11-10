function b0 = GetB0(modelname, fittedpars)
%
% function b0 = GetB0(modelname, fittedpars)
%
% Returns the b=0 signal estimate.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

b0Idx = GetParameterIndex(modelname, 'b0');
if b0Idx > 0
    b0 = fittedpars(b0Idx);
else
    b0 = 1;
end

