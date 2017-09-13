

function MTsat = MTSAT_exec(data, MTParams, PDParams, T1Params) % add 
% Compute MT saturation map from a PD-weigthed, a T1-weighted and a MT-weighted FLASH images
% according to Helms et al., MRM, 60:1396?1407 (2008) and equation erratum in MRM, 64:1856 (2010).
%   First 3 arguments are (becareful to respect the order): the PD-weighted image, the T1-weighted
%   image and the MT-weigthed image.
%   Next 3 arguments are the corresponding flip angles used for the acquisition of each image (in
%   the same order).
%   Next 3 arguments are the corresponding TR used for the acquisition of each image (in the same
%   order).
%   Next 2 aguments are the names of the output nifti files for the MT saturation map and the T1 map
%   in this order (optional arguments, defaults ='MTsat.nii.gz','T1.nii.gz')
%   Last argument is the path to a previously computed T1 map to give in input (optional argument).
%   If no T1 map is given in input, this function outputs it. If it is given in input, this function
%   uses it to compute the MT saturation map.

% Load nii
PDw_data = double(data.PDw); % convert data coding to double

T1w_data = double(data.T1w); % convert data coding to double

MTw_data = double(data.MTw); % convert data coding to double

% Convert angles into radians
alpha_PD = (pi/180)*PDParams(1);
TR_PD    = PDParams(2);
alpha_T1 = (pi/180)*T1Params(1);
TR_T1    = T1Params(2);
alpha_MT = (pi/180)*MTParams(1);
TR_MT    = MTParams(2);

% check if a T1 map was given in input; if not, compute it
R1 = 0.5*((alpha_T1/TR_T1)*T1w_data - (alpha_PD/TR_PD)*PDw_data)./(PDw_data/alpha_PD - T1w_data/alpha_T1);

% compute A
A = (TR_PD*alpha_T1/alpha_PD - TR_T1*alpha_PD/alpha_T1)*((PDw_data.*T1w_data)./(TR_PD*alpha_T1*T1w_data - TR_T1*alpha_PD*PDw_data));
% compute MTsat
MTsat = TR_MT*(alpha_MT*(A./MTw_data) - ones(size(MTw_data))).*R1 - (alpha_MT^2)/2;

end
