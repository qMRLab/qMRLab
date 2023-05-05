

function [MTsat, R1, R1cor, MTsatcor] = MTSAT_exec(data, MTParams, PDParams, T1Params, B1Params) 
% Compute MT saturation map from a PD-weighted, a T1-weighted and a MT-weighted FLASH images
% according to Helms et al., MRM, 60:1396?1407 (2008) and equation erratum in MRM, 64:1856 (2010).
%   This function computes R1 maps and includes it in the MT saturation map calculation.

% Initialize variables
R1cor=[];
MTsatcor=[];

% Load nii
PDw_data = double(data.PDw); % convert data coding to double
T1w_data = double(data.T1w); % convert data coding to double
MTw_data = double(data.MTw); % convert data coding to double
R1       = zeros(size(PDw_data));


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

% ===========================================================

low_flip_angle = PDParams(1);    % flip angle in degrees -> USER DEFINED
high_flip_angle = T1Params(1);  % flip angle in degrees -> USER DEFINED
TR1 = TR_PD*1000;               % low flip angle repetition time of the GRE kernel in milliseconds -> USER DEFINED
TR2 = TR_T1*1000;               % high flip angle repetition time of the GRE kernel in milliseconds -> USER DEFINED

% If a B1 map is available B1 corrected T1 map will be also exported. 
% If sequence details are known (esp MT pulse), then simulation framework 
% by Rowley et al. (https://doi.org/10.1002/mrm.28831) can be incorporated. 

if isfield(data,'B1map') && ~isempty(data.B1map)
    R1cor  = zeros(size(PDw_data));
    % Code adapted from https://github.com/TardifLab/MTsatB1correction
    B1_data = double(data.B1map);
    a1 = low_flip_angle*pi/180 .* B1_data; % note the inclusion of b1 here.
    a2 = high_flip_angle*pi/180 .* B1_data;
    % New code Aug 4, 2021 CR for two TR's
    R1cor(Inds) = 0.5 .* (T1w_data(Inds).*a2(Inds)./ TR2 - PDw_data(Inds).*a1(Inds)./TR1) ./ (PDw_data(Inds)./(a1(Inds)) - T1w_data(Inds)./(a2(Inds)));
    R1cor = R1cor.*1000; % qMRlab convention
    App = PDw_data(Inds) .* T1w_data(Inds) .* (TR1 .* a2(Inds)./a1(Inds) - TR2.* a1(Inds)./a2(Inds)) ./ (T1w_data(Inds).* TR1 .*a2(Inds) - PDw_data(Inds).* TR2 .*a1(Inds));
else
    R1cor = [];
    App = [];
end


% check if a T1 map was given in input; if not, compute it
R1(Inds) = 0.5*((alpha_T1/TR_T1)*T1w_data(Inds)  - (alpha_PD/TR_PD)*PDw_data(Inds))./(PDw_data(Inds)/alpha_PD - T1w_data(Inds)/alpha_T1);

% compute A
A = (TR_PD*alpha_T1/alpha_PD - TR_T1*alpha_PD/alpha_T1)*((PDw_data(Inds).*T1w_data(Inds))./(TR_PD*alpha_T1*T1w_data(Inds) - TR_T1*alpha_PD*PDw_data(Inds)));

% preallocate and compute MTsat; percent units
MTsat(Inds) = 100 * (TR_MT*(alpha_MT*(A./MTw_data(Inds)) - ones(size(MTw_data(Inds)))).*R1(Inds) - (alpha_MT^2)/2);

% Apply B1 correction to result
if isfield(data,'B1map') && ~isempty(data.B1map)
	if any(size(data.B1map) ~= size(MTsat)), error('\nError in MTSAT_exec.m: B1 map dimension different from volume dimension.\n'); end

% Weiskopf, N., Suckling, J., Williams, G., Correia, M.M., Inkster, B., Tait, R., Ooi, C., Bullmore, E.T., Lutti, A., 2013. Quantitative multi-parameter mapping of R1, PD(*), MT, and R2(*) at 3T: a multi-center validation. Front. Neurosci. 7, 95.
    MTsatcor = MTsat .* (1 - Alpha_B1)./(1 - Alpha_B1 * data.B1map);
else
    MTsatcor = [];
end

% Mask
if isfield(data,'Mask') && ~isempty(data.Mask)
    if any(size(data.Mask) ~= size(MTsat)), error('\nError in MTSAT_exec.m: Mask dimension different from volume dimension.\n'); end
    MTsat = MTsat .* data.Mask;      
end

end
