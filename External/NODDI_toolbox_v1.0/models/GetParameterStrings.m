function strings = GetParameterStrings(modelname)
%
% function strings = GetParameterStrings(modelname)
%
% Given an input modelname, this function returns the names of the model
% parameters
%
% author: Gary Hui Zhang (gary.zhang@ucl.ac.uk)
%

if (strcmp(modelname, 'StickIsoV_B0'))
    strings = {'ficvf', 'di', 'dh', 'fiso', 'diso', 'b0', 'theta', 'phi'};
elseif (strcmp(modelname, 'StickTortIsoV_B0'))
    strings = {'ficvf', 'di', 'fiso', 'diso', 'b0', 'theta', 'phi'};
elseif (strcmp(modelname, 'WatsonSHStick'))
    strings = {'ficvf', 'di', 'dh', 'kappa', 'theta', 'phi'};
elseif (strcmp(modelname, 'WatsonSHStickIsoV_B0'))
    strings = {'ficvf', 'di', 'dh', 'kappa', 'fiso', 'diso', 'b0', 'theta', 'phi'};
elseif (strcmp(modelname, 'WatsonSHStickIsoVIsoDot_B0'))
    strings = {'ficvf', 'di', 'dh', 'kappa', 'fiso', 'diso', 'irfrac', 'b0', 'theta', 'phi'};
elseif (strcmp(modelname, 'WatsonSHStickTortIsoV_B0'))
    strings = {'ficvf', 'di', 'kappa', 'fiso', 'diso', 'b0', 'theta', 'phi'};
elseif (strcmp(modelname, 'WatsonSHStickTortIsoVIsoDot_B0'))
    strings = {'ficvf', 'di', 'kappa', 'fiso', 'diso', 'irfrac', 'b0', 'theta', 'phi'};
elseif (strcmp(modelname, 'BinghamStickTortIsoV_B0'))
    strings = {'ficvf', 'di', 'kappa', 'beta', 'psi', 'fiso', 'diso', 'b0', 'theta', 'phi'};
elseif (strcmp(modelname, 'WatsonSHCylSingleRadTortIsoV_GPD_B0'))
    strings = {'ficvf', 'di', 'rad', 'kappa', 'fiso', 'diso', 'b0', 'theta', 'phi'};
elseif (strcmp(modelname, 'CylSingleRadIsoDotTortIsoV_GPD_B0'))
    strings = {'ficvf', 'di', 'rad', 'irfrac', 'fiso', 'diso', 'b0', 'theta', 'phi'};
else
    error(['Parameter strings yet to be defined for this model:', modelname]);
end

