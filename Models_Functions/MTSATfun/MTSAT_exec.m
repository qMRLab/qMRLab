

function MTsat = MTSAT_exec(data, MTParams, PDParams, T1Params, B1Params) 
% Compute MT saturation map from a PD-weigthed, a T1-weighted and a MT-weighted FLASH images
% according to Helms et al., MRM, 60:1396?1407 (2008) and equation erratum in MRM, 64:1856 (2010).
%   This function computes R1 maps and includes it in the MT saturation map calculation.

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
Alpha_B1 = B1Params(1);


Inds = find(PDw_data & T1w_data & MTw_data);
MTsat = double(zeros(size(MTw_data)));

% check if a T1 map was given in input; if not, compute it
R1 = 0.5*((alpha_T1/TR_T1)*T1w_data(Inds)  - (alpha_PD/TR_PD)*PDw_data(Inds))./(PDw_data(Inds)/alpha_PD - T1w_data(Inds)/alpha_T1);

% compute A
A = (TR_PD*alpha_T1/alpha_PD - TR_T1*alpha_PD/alpha_T1)*((PDw_data(Inds).*T1w_data(Inds))./(TR_PD*alpha_T1*T1w_data(Inds) - TR_T1*alpha_PD*PDw_data(Inds)));

% preallocate and compute MTsat; percent units
MTsat(Inds) = 100 * (TR_MT*(alpha_MT*(A./MTw_data(Inds)) - ones(size(MTw_data(Inds)))).*R1 - (alpha_MT^2)/2);

% Apply B1 correction to result
if (Alpha_B1)
    if ndims(MTsat) == ndims(data.B1map) 
        if ndims(MTsat) == 2 
            data_voxels = size(MTsat,1)*size(MTsat,2);
            mask_voxels = size(data.B1map,1)*size(data.B1map,2);
            if mask_voxels ~= data_voxels
                error(sprintf('\nError in MTSAT_exec.m Mask dimension different from volume dimension.\n')); 
            end
        elseif ndims(MTsat) == 3 
            data_voxels = size(MTsat,1)*size(MTsat,2)*size(MTsat,3);
            mask_voxels = size(data.B1map,1)*size(data.B1map,2)*size(data.B1map,3);
            if mask_voxels ~= data_voxels
                error(sprintf('\nError in MTSAT_exec.m B1 map dimension different from volume dimension.\n')); 
            end
        end
    else error(sprintf('\nError in MTSAT_exec.m B1 map dimension different from volume dimension.\n'));
    end
% Weiskopf, N., Suckling, J., Williams, G., Correia, M.M., Inkster, B., Tait, R., Ooi, C., Bullmore, E.T., Lutti, A., 2013. Quantitative multi-parameter mapping of R1, PD(*), MT, and R2(*) at 3T: a multi-center validation. Front. Neurosci. 7, 95.
    MTsat = MTsat .* (1 - Alpha_B1)./(1 - Alpha_B1 * data.B1map);
end

% Mask
if ~isempty(data.Mask)
    if ndims(MTsat) == ndims(data.Mask) 
        if ndims(MTsat) == 2 
            data_voxels = size(MTsat,1)*size(MTsat,2);
            mask_voxels = size(data.Mask,1)*size(data.Mask,2);
            if mask_voxels ~= data_voxels
                error(sprintf('\nError in MTSAT_exec.m Mask dimension different from volume dimension.\n')); 
            end
        elseif ndims(MTsat) == 3 
            data_voxels = size(MTsat,1)*size(MTsat,2)*size(MTsat,3);
            mask_voxels = size(data.Mask,1)*size(data.Mask,2)*size(data.Mask,3);
            if mask_voxels ~= data_voxels
                error(sprintf('\nError in MTSAT_exec.m Mask dimension different from volume dimension.\n')); 
            end
        end
    else error(sprintf('\nError in MTSAT_exec.m Mask dimension different from volume dimension.\n'));
    end
    MTsat = MTsat .* data.Mask;      
end

end
