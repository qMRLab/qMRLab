function PulseOpt = AI_defaultHs1Params(PulseOpt)

% Function designed to be used with the adiabatic pulse code
% Fills in default values if they are not user-defined

if(~isfield(PulseOpt,'beta') || isempty(PulseOpt.beta) || ~isfinite(PulseOpt.beta))
    % Default beta value in rad/s (modulation angular frequency)
    PulseOpt.beta = 672;       
end

if(~isfield(PulseOpt,'n') || isempty(PulseOpt.n) || ~isfinite(PulseOpt.n))
    % Default sech exponent
    PulseOpt.n = 1;       
end

if(~isfield(PulseOpt,'Q') || isempty(PulseOpt.Q) || ~isfinite(PulseOpt.Q))
    % Default phase modulation parameter
    PulseOpt.Q = 5;       
end

if(~isfield(PulseOpt,'A0') || isempty(PulseOpt.A0) || ~isfinite(PulseOpt.A0))
    % Peak B1 of the pulse in microTesla
    PulseOpt.A0 = 13.726;       
end

if(~isfield(PulseOpt,'nSamples') || isempty(PulseOpt.nSamples) || ~isfinite(PulseOpt.nSamples))
    % Default number of samples taken based on machine properties
    PulseOpt.nSamples = 512;       
end

if(~isfield(PulseOpt,'Trf') || isempty(PulseOpt.Trf) || ~isfinite(PulseOpt.Trf))
    % Adiabatic pulse duration (ms)
    PulseOpt.Trf = 10.24/1000;       
end

return



















