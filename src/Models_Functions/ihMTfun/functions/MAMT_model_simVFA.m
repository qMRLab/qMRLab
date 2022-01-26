function [R1app_vfa, Aapp_vfa] = MAMT_model_simVFA(Params)
%% Recreate the MAMT Model from Portnoy and Stanisz (2007)

% Updated Aug 4, 2021, for two TR's and allow flexible input of VFA values.
% VFA_FA1 -> low flip angle in degrees
% VFA_FA2 -> high flip angle in degrees
% VFA_TR1 -> TR for the low flip angle image in seconds
% VFA_TR2 -> TR for the high flip angle image in seconds

% Sim the VFA experiment for the calculation of MTsat.
if ~isfield(Params,'VFA_FA1') % if not defined, assume 3T
    Params.VFA_FA1 = 5; % in degrees
end

if ~isfield(Params,'VFA_FA2') % if not defined, assume 3T
    Params.VFA_FA2 = 20; % in degrees
end

if ~isfield(Params,'VFA_TR') % if not defined, total repetition time = MT pulse train and readout.
    Params.VFA_TR = 30/1000; % in ms
end

if ~isfield(Params,'VFA_TR2') % if not defined, total repetition time = MT pulse train and readout.
    Params.VFA_TR2 = Params.VFA_TR; % in ms
end

%% Currently assumes 30ms TR and 5 and 20 degree flip angle. 
Params.b1 = 0; % microTesla
Params.numSatPulse =1;
Params.pulseDur = 1/1000; %duration of 1 MT pulse in seconds = step size
Params.pulseGapDur = 0.3/1000; %ms gap between MT pulses in train = step size
Params.TR = Params.VFA_TR; % total repetition time = MT pulse train and readout.
Params.WExcDur = 3/1000; % duration of water pulse
Params.numExcitation = 1; % number of readout lines/TR
Params.flipAngle = Params.VFA_FA1; % excitation flip angle water.

lfa = MAMT_model_2007_5(Params);

% second flip angle
Params.flipAngle = Params.VFA_FA2; % excitation flip angle water.

hfa = MAMT_model_2007_5(Params);

%% VFA R1 and Aapp calculation
a1 = Params.VFA_FA1 * pi/180;
a2 = Params.VFA_FA2 * pi / 180;
TR1 = Params.VFA_TR;
TR2 = Params.VFA_TR2;

R1app_vfa = 0.5 .* (hfa.*a2./ TR2 - lfa.*a1./TR1) ./ (lfa./(a1) - hfa./(a2));
Aapp_vfa = lfa .* hfa .* (TR1 .* a2./a1 - TR2.* a1./a2) ./ (hfa.* TR1 .*a2 - lfa.* TR2 .*a1);





























