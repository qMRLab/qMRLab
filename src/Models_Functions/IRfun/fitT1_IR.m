function [T1,b,a,res,idx]=fitT1_IR(data,T_IR,method)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function estimates T1 using IR data.
%
% INPUT VARIABLES :
%     -data:  Array of signal values (at each TI)
%     -T_IR:  Array containing the IR times, in ms. For example :
%                 T_IR=[50 419 800 1200 2200];
%     -method: Method to use in order to fit the data, based on whether
%               complex or only magnitude data is available.
%                 'complex'   : RD-NLS (Reduced-Dimension Non-Linear Least
%                                Squares)
%                              S=a + b*exp(-TI/T1)
%             or  'magnitude' : RD-NLS-PR (Reduced-Dimension Non-Linear Least Squares
%                               with Polarity Restoration)
%                              S=|c + d*exp(-TI/T1)|
%
% OUTPUT VARIABLES :
%     -T1: T1 value
%     -rb: b parameter
%     -ra: a prameter
%     -res: residual of the fit
%     -idx: index of last polaroty restored datapoint (only used for magnitude data)
%
% Original function T1ScanExperiment.m written by :
%     J. Barral, M. Etezadi-Amoli, E. Gudmundson, and N. Stikov, 2009
% Edited for direct use of data by :
%     A. Daigle-Martel for direct use of available data, 2016
% Modified by Ilana Leppert
%   June 2017
%
% (c) Board of Trustees, Leland Stanford Junior University
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The search grid depends only on the protocol (T_IR) and the T1 range below --
% never on the voxel data. FitData calls this function once per voxel, so
% rebuilding the grid on every call dominated the fit. Cache it and rebuild only
% when the protocol changes.
%
% The hardcoded T1 range does not need to be part of the key: editing this file
% clears its persistent variables, so the cache cannot outlive a change to it.
% Under parfor each worker holds its own copy and builds it once.
persistent nlsS_cache nlsS_key

key = T_IR(:).';
if isempty(nlsS_key) || ~isequal(key, nlsS_key)
    extra.tVec = T_IR;
    extra.T1Vec = 1:5000; % Range can be reduced if a priori information is available
    nlsS_cache = getNLSStruct(extra,0);
    nlsS_key = key;
end
nlsS = nlsS_cache;

savefitdata = 0; % Can be changed to 1 if the fit data needs to be saved


switch method
    case{'Complex'}
        [T1,b,a,res] = rdNls(data,nlsS);
        idx = []; %don't need to polarity restore
    case{'Magnitude'}
        data = abs(data);
        [T1,b,a,res,idx] = rdNlsPr(data,nlsS);

end



% for each voxel, namely:
% (1) T1
% (2) 'b' or 'rb' parameter
% (3) 'a' or 'ra' parameter
% (4) residual from the fit
%
%     if (savefitdata)
%         save(tmp,'T1','rb','ra','res','mask','nlsS')
%     end



end