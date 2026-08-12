function signal = MP2RAGEfunc(MPRAGE_tr, inversiontimes, nZslices, FLASH_tr, flipangle, T1s, varargin)
% S = MP2RAGEfunc(TRs, IT, n, TRf, FA, T1, [inveff, seq, Ni]) - Simulate MP2RAGE signal
%
% INPUTS:
%   TRs: [scalar] repetition time of the complete MP2RAGE sequence (ms)
%   IT: [1 x Ni] vector of inversion times (ms), from inversion pulse to the
%       center(*) of k-space for each image
%   n: [scalar / 2-tuple] number of Z-slices. A tuple [n_before, n_after] shifts the
%       "center" of k-space accordingly.
%   TRf: [scalar] repetition time of the FLASH readout (ms)
%   FA: [scalar or 1 x Ni] flip angle(s) of the FLASH readout (degrees)
%   T1s: [Nv x 1] vector of T1 values to simulate (ms)
%   inveff: [scalar] inversion efficiency (default: 0.96)
%   seq: [string] 'normal' or 'waterexcitation' (default: 'normal')
%   Ni: [scalar] number of images i.e. GRE imaging blocks (default: numel(IT))
%
% OUTPUTS:
%   S: [Nv x Ni] simulated signal values
%
% See also: mp2rage, MP2RAGEfunc_Test

%% Parse inputs
varargin(end+1:3) = {[]};
assert(numel(varargin) == 3, 'Too many arguments')
[inveff, sequence, nimages] = deal(varargin{:});

isrealscalar = @(x) isnumeric(x) && isscalar(x) && isreal(x);
assert(isrealscalar(MPRAGE_tr) && MPRAGE_tr > 0)
assert(isrealscalar(FLASH_tr) && FLASH_tr > 0)

if isempty(nimages), nimages = numel(inversiontimes); end
assert(isrealscalar(nimages) && nimages > 0 && mod(nimages,1) == 0)

isrealntuple = @(x) isnumeric(x) && numel(x) == nimages && isreal(x);
assert(isrealntuple(inversiontimes) && all(inversiontimes > 0) && issorted(inversiontimes))

if isscalar(flipangle), flipangle = repmat(flipangle, [1, nimages]); end
assert(isrealntuple(flipangle) && all(flipangle ~= 0))

assert(isnumeric(nZslices) && isreal(nZslices))
switch numel(nZslices)
    case 2
        nZ_bef = nZslices(1);
        nZ_aft = nZslices(2);
        nZslices = sum(nZslices);
    case 1
        nZ_bef = nZslices / 2;
        nZ_aft = nZslices / 2;
    otherwise
        error('Expecting scalar or 2-tuple for n number of slices')
end
assert(mod(nZslices,1) == 0)

if isempty(inveff)
    inveff = 0.96;  % Siemens MP2RAGE PULSE
else
    assert(isrealscalar(inveff) && inveff > 0 && inveff <= 1)
end

if isempty(sequence), sequence = 'normal'; end
assert(ischar(sequence));
if strcmpi(sequence,'normal')
    normalsequence = true;
    waterexcitation = false;
else
    normalsequence = false;
    waterexcitation = true;
    B0 = 7;
    FatWaterCSppm = 3.3;  % ppm
    gamma = 42.576;  % MHz/T
    pulseSpace = 0.5 / (FatWaterCSppm * B0 * gamma);
end

assert(isnumeric(T1s) && isvector(T1s));

%% calculating the relevant timing and associated values

% Reserve first dimension for voxels, second for images
T1s = T1s(:);                        % [Nv, 1] vector
fliprad = flipangle(:)' / 180 * pi;  % [1, Ni] vector

E_1 = exp(-FLASH_tr ./ T1s);  % [Nv, 1] recovery between two excitaions

TA = nZslices * FLASH_tr;
TA_bef = nZ_bef * FLASH_tr;
TA_aft = nZ_aft * FLASH_tr;

% TD: [1, Ni + 1] vector of delay times
TD(1) = inversiontimes(1) - TA_bef;
TD(2:nimages) = diff(inversiontimes) - TA;
TD(nimages+1) = MPRAGE_tr - inversiontimes(nimages) - TA_aft;
if ~all(TD > 0)
    error('TRs, IT, n, TRf parameters result in negative delay time(s). Please check your inputs.')
end

E_TD = exp(-TD ./ T1s);  % [Nv, Ni + 1]

if normalsequence
    cosalfaE1 = cos(fliprad) .* E_1;  % [Nv, Ni]
    sinalfa = sin(fliprad);
    % oneminusE1 = 1 - E_1;
end
if waterexcitation

    E_1A = exp(-pulseSpace ./ T1s);
    E_2A = exp(-pulseSpace ./ 0.06);  % 60 ms is an extimation of the T2star.. not very relevant
    E_1B = exp(-(FLASH_tr - pulseSpace) ./ T1s);

    cosalfaE1 = cos(fliprad/2).^2 .* (E_1A .* E_1B) - sin(fliprad/2).^2 .* (E_2A .* E_1B);
    sinalfa = sin(fliprad/2) .* cos(fliprad/2) .* (E_1A + E_2A);

    % TODO: is this meant to be used?
    % oneminusE1 = 1 - (1 - (1 - E_1A) .* cos(fliprad/2)) .* E_1B;
end

%% steady state calculation

% an expression pattern that occurs in several places
aux = @(k, c, n) k .* c.^n + (1 - E_1) .* (1 - c.^n) ./ (1 - c);

MZsteadystate = 1 ./ (1 + inveff * prod(cosalfaE1, 2).^nZslices .* prod(E_TD, 2));

MZsteadystatenumerator = 1 - E_TD(:, 1);
for k = 1:nimages
    %term relative to the image aquisition;
    MZsteadystatenumerator = aux(MZsteadystatenumerator, cosalfaE1(:,k), nZslices);

    %term for the relaxation time after it;
    MZsteadystatenumerator = 1 + (MZsteadystatenumerator - 1).*E_TD(:, k+1);
end
MZsteadystate = MZsteadystate .* MZsteadystatenumerator;

%% signal
temp = aux(1 - E_TD(:,1).*(1 + inveff * MZsteadystate), cosalfaE1(:,1), nZ_bef);

signal = nan(size(temp,1), nimages);
signal(:,1) = sinalfa(:,1) .* temp;

if nimages > 1
    for m = 2:nimages
        temp = aux(temp, cosalfaE1(:, m-1), nZ_aft);
        temp = aux(1 + (temp - 1) .* E_TD(:, m), cosalfaE1(:, m), nZ_bef);
        signal(:, m) = sinalfa(:, m) .* temp;
    end
end
