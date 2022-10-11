function pulse = sinc_pulse(t,Trf,PulseOpt)
%SINC_PULSE Sinc RF pulse function.
%   pulse = sinc_pulse(t,Trf,PulseOpt)
%
%   The sinc pulse is defined to be 0 outside the pulse window (before 
%   t = 0 or after t=Trf), and follows a symmetric sinc lineshape within.
%
%   --args--
%   t: Function handle variable, represents the time.
%   Trf: Duration of the Sinc RF pulse.
%
%   --optional args--
%   PulseOpt: Struct. Contains optional parameters for pulse shapes.
%
%             -properties-
%             TBW: Time-bandwidth product. If TBW is an even numnber, it's
%                  also the # of zero crossings of the RF envelope,
%                  including the margins.
%
%   Reference: Matt A. Bernstein, Kevin F. Kink and Xiaohong Joe Zhou.
%              Handbook of MRI Pulse Sequences, pp. 38, Eqs. 2.2-2.4, (2004)
%
%   See also GETPULSE, VIEWPULSE.
%


if (nargin < 3); PulseOpt = struct; end

if(~isfield(PulseOpt,'TBW') || isempty(PulseOpt.TBW) || ~isfinite(PulseOpt.TBW))
    TBW = 4;
else
    TBW = PulseOpt.TBW;
end

pulse = sinc_fn( TBW/Trf * (t - Trf/2) );
pulse((t < 0 | t>Trf)) = 0;

end
