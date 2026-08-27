function PulseOpt = AI_defaultHsnParams(PulseOpt)

% Function designed to be used with the adiabatic pulse code
% Fills in default values if they are not user-defined
% If n is changed from 8 these params will also need to change 

if(~isfield(PulseOpt,'beta') || isempty(PulseOpt.beta) || ~isfinite(PulseOpt.beta))
    % Default beta value in rad/s
    PulseOpt.beta = 265;       
end

if(~isfield(PulseOpt,'n') || isempty(PulseOpt.n) || ~isfinite(PulseOpt.n))
    % Default sech exponent (n = 2-8)
    PulseOpt.n = 8;       
end

if(~isfield(PulseOpt,'A0') || isempty(PulseOpt.A0) || ~isfinite(PulseOpt.A0))
    % Peak B1 of the pulse in microTesla
    PulseOpt.A0 = 11;       
end

if(~isfield(PulseOpt,'nSamples') || isempty(PulseOpt.nSamples) || ~isfinite(PulseOpt.nSamples))
    % Default number of samples taken based on machine properties
    PulseOpt.nSamples = 512;       
end

if(~isfield(PulseOpt,'Q') || isempty(PulseOpt.Q) || ~isfinite(PulseOpt.Q))
    % Adiabaticity Factor
    PulseOpt.Q = 3.9e-4;       
end

if(~isfield(PulseOpt,'Trf') || isempty(PulseOpt.Trf) || ~isfinite(PulseOpt.Trf))
    % Adiabatic pulse duration (ms) 
    PulseOpt.Trf = 10/1000;       
end


return;
