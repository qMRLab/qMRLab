function scale = GetScalingFactors(modelname)
%
% function scale = GetScalingFactors(modelname)
%
% Returns an array of scaling factors for the parameters of the model
% intended to rescale so that they all have value close to 1.
%
% Note that including the scaling factor for sigma increases the number
% of model variables by 1.
%
% Note that the scaling factor not set for theta and phi
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

parameterStrings = GetParameterStrings(modelname);

% here the scaling factors do not include the ones for theta and phi
% but include one for the sigma
scale = zeros(1, length(parameterStrings) - 1);

% the scaling factor for sigma is set to 1
scale(end) = 1;

for i=1:length(parameterStrings)
    if (strcmp(parameterStrings(i), 'di') ||...
            strcmp(parameterStrings(i), 'dh') ||...
            strcmp(parameterStrings(i), 'diso'))
        scale(i) = 1E9;
    elseif (strcmp(parameterStrings(i), 'rad'))
        scale(i) = 1E6;
    elseif (strcmp(parameterStrings(i), 'ficvf') ||...
            strcmp(parameterStrings(i), 'fiso') ||...
            strcmp(parameterStrings(i), 'irfrac') ||...
            strcmp(parameterStrings(i), 'psi') ||...
            strcmp(parameterStrings(i), 'b0') ||...
            strcmp(parameterStrings(i), 't1'))
        scale(i) = 1;
    elseif (strcmp(parameterStrings(i), 'kappa') ||...
            strcmp(parameterStrings(i), 'beta'))
        scale(i) = 0.1;
    end
end

