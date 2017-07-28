function pulse = fermi_pulse(t, Trf, PulseOpt)
%FERMI_PULSE Fermi RF pulse function.
%   pulse = germi_pulse(t, Trf, PulseOpt)
%
%   The Fermi pulse is defined to be 0 outside the pulse window (before 
%   t = 0 or after t=Trf), and follows a symmetric Fermi lineshape within.
%
%   --args--
%   t: Function handle variable, represents the time.
%   Trf: Duration of the Fermi RF pulse.
%
%   --optional args--
%   PulseOpt: Struct. Contains optional parameters for pulse shapes.
%
%             -properties-
%             slope: Measure of the transition width. Parameter "a" in
%                    Eq. 4.14 of the reference.
%
%   Reference: Matt A. Bernstein, Kevin F. Kink and Xiaohong Joe Zhou.
%              Handbook of MRI Pulse Sequences, pp. 111, Eq. 4.14, (2004)
%
%   See also GETPULSE, VIEWPULSE.
%

if (nargin < 3)
    PulseOpt = struct;
end

if(~isfield(PulseOpt,'slope') || isempty(PulseOpt.slope) || ~isfinite(PulseOpt.slope))
    % Setting pulse duration at 60 dB (from the Bernstein handbook)
    slope = Trf/33.81;          % Assuming t0 = 10a  
else
    slope = PulseOpt.slope;  
end

t0 = (Trf - 13.81*slope)/2;  
pulse = 1 ./ ( 1 + exp( (abs(t-Trf/2) - t0) ./ slope ) );
pulse((t < 0 | t>Trf)) = 0;

end