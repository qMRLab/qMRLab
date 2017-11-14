function params = GradDescDecode(modelname, optoutput)
%
% function params = GradDescDecode(modelname, optoutput)
%
% Encodes raw parameter values to enforce simple constraints during direct fitting.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

parameterStrings = GetParameterStrings(modelname);
params = zeros(1, length(parameterStrings));

for i=1:length(parameterStrings)
    if (strcmp(parameterStrings(i), 'ficvf') ||...
        strcmp(parameterStrings(i), 'fiso') ||...
        strcmp(parameterStrings(i), 'irfrac'))
       params(i) = sin(optoutput(i))^2;
    elseif (strcmp(parameterStrings(i), 'di') ||...
            strcmp(parameterStrings(i), 'diso') ||...
            strcmp(parameterStrings(i), 'rad') ||...
            strcmp(parameterStrings(i), 'kappa') ||...
            strcmp(parameterStrings(i), 'b0') ||...
            strcmp(parameterStrings(i), 't1'))
       params(i) = optoutput(i)^2;
    elseif (strcmp(parameterStrings(i), 'dh'))
		 diIdx = GetParameterIndex(modelname, 'di');
       params(i) = params(diIdx)*sin(optoutput(i))^2;
	 elseif (strcmp(parameterStrings(i), 'beta'))
		 kappaIdx = GetParameterIndex(modelname, 'kappa');
       params(i) = params(kappaIdx)*sin(optoutput(i))^2;
    elseif (strcmp(parameterStrings(i), 'theta') ||...
            strcmp(parameterStrings(i), 'phi') ||...
            strcmp(parameterStrings(i), 'psi'))
       params(i) = optoutput(i);
	 end
end

