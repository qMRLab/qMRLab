function [min_val max_val] = GradDescLimits(modelname)
%
% function [min_val max_val] = GradDescLimits(modelname)
%
% Returns maximum and minimum settings for the parameters of different
% models to use during direct fitting.
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

LARGE = 100000;

D_MIN = 0.001;
D_MAX = 3;
D_PERP_MIN = 0.001;

ANGLEMAX=100;

R_MIN = 0.1;
R_MAX = 5;

% the values need to account for scaling defined
% in GetScalingFactors.m
K_MIN = 0;
K_MAX = 6.4;

B_MIN = 0;
B_MAX = 3.2;

parameterStrings = GetParameterStrings(modelname);
min_val = zeros(1, length(parameterStrings));
max_val = zeros(1, length(parameterStrings));

for i=1:length(parameterStrings)
    if (strcmp(parameterStrings(i), 'ficvf') ||...
        strcmp(parameterStrings(i), 'fiso') ||...
        strcmp(parameterStrings(i), 'irfrac'))
        min_val(i) = 0;
        max_val(i) = LARGE;
    elseif (strcmp(parameterStrings(i), 'di') ||...
            strcmp(parameterStrings(i), 'diso'))
        min_val(i) = sqrt(D_MIN);
        max_val(i) = sqrt(D_MAX);
    elseif (strcmp(parameterStrings(i), 'dh'))
        min_val(i) = sqrt(D_PERP_MIN);
        max_val(i) = LARGE;
    elseif (strcmp(parameterStrings(i), 'rad'))
        min_val(i) = sqrt(R_MIN);
        max_val(i) = sqrt(R_MAX);
    elseif (strcmp(parameterStrings(i), 'kappa'))
        min_val(i) = sqrt(K_MIN);
        max_val(i) = sqrt(K_MAX);
    elseif (strcmp(parameterStrings(i), 'beta'))
        min_val(i) = sqrt(B_MIN);
        max_val(i) = sqrt(B_MAX);
    elseif (strcmp(parameterStrings(i), 'theta') ||...
            strcmp(parameterStrings(i), 'phi') ||...
            strcmp(parameterStrings(i), 'psi'))
        min_val(i) = -ANGLEMAX;
        max_val(i) = ANGLEMAX;
    elseif (strcmp(parameterStrings(i), 'b0'))
        min_val(i) = 0.001;
        max_val(i) = LARGE;
    elseif (strcmp(parameterStrings(i), 't1'))
        min_val(i) = 0.1;
        max_val(i) = 1;
    end
end

