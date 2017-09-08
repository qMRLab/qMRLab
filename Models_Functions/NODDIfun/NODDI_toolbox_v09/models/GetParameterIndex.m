function idx = GetParameterIndex(modelname, parametername)
%
% function idx = GetParameterIndex(modelname, parametername)
%
% Given an input modelname and parametername, this function returns the index
% of the parameter within the model.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

strings = GetParameterStrings(modelname);

for i=1:length(strings)
    if (strcmp(strings(i), parametername))
        idx = i;
        return;
    end
end

idx = -1;
