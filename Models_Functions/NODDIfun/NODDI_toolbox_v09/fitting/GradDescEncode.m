function optarray = GradDescEncode(modelname, x)
%
% function optarray = GradDescEncode(modelname, x)
%
% Encodes raw parameter values to enforce simple constraints during direct fitting.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

parameterStrings = GetParameterStrings(modelname);
optarray = zeros(1, length(parameterStrings));

for i=1:length(parameterStrings)
    if (strcmp(parameterStrings(i), 'ficvf') ||...
        strcmp(parameterStrings(i), 'fiso') ||...
        strcmp(parameterStrings(i), 'irfrac'))
       optarray(i) = asin(sqrt(x(i)));
    elseif (strcmp(parameterStrings(i), 'di') ||...
            strcmp(parameterStrings(i), 'diso') ||...
            strcmp(parameterStrings(i), 'rad') ||...
            strcmp(parameterStrings(i), 'kappa') ||...
            strcmp(parameterStrings(i), 'b0') ||...
            strcmp(parameterStrings(i), 't1'))
       optarray(i) = sqrt(x(i));
    elseif (strcmp(parameterStrings(i), 'dh'))
		 diIdx = GetParameterIndex(modelname, 'di');
       optarray(i) = asin(sqrt(x(i)/x(diIdx)));
	 elseif (strcmp(parameterStrings(i), 'beta'))
		 kappaIdx = GetParameterIndex(modelname, 'kappa');
		 if (x(kappaIdx) == 0)
           optarray(i) = 0;
       else
           optarray(i) = asin(sqrt(x(i)/x(kappaIdx)));
       end
    elseif (strcmp(parameterStrings(i), 'theta') ||...
            strcmp(parameterStrings(i), 'phi') ||...
            strcmp(parameterStrings(i), 'psi'))
       optarray(i) = x(i);
	 end
end

