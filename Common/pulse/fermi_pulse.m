function pulse = fermi_pulse(t, Trf, PulseOpt)
% fermi_pulse : Compute Fermi RF pulse shape

if (nargin < 3)
    PulseOpt = struct;
end

% Setting pulse duration at 60 dB (from the Bernstein handbook)
if(~isfield(PulseOpt,'slope') || isempty(PulseOpt.slope) || ~isfinite(PulseOpt.slope))
    slope = Trf/33.81;          % Assuming t0 = 10a  
else
    slope = PulseOpt.slope;  
end

t0 = (Trf - 13.81*slope)/2;  
pulse = 1 ./ ( 1 + exp( (abs(t-Trf/2) - t0) ./ slope ) );
pulse((t < 0 | t>Trf)) = 0;

return