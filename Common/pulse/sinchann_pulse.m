function pulse = sinchann_pulse(t,Trf,PulseOpt)
%SINCHANN_PULSE Hanning-apodized sinc RF pulse function.
%   pulse = sinchann_pulse(t,Trf,PulseOpt)
%
%   The sinc-hann pulse is defined to be 0 outside the pulse window (before 
%   t = 0 or after t=Trf), follows a symmetric sinc lineshape within, and  
%   is apodized by a Hanning window.
%
%   --args--
%   t: Function handle variable, represents the time.
%   Trf: Duration of the Sinc-Hann RF pulse.
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
%              Handbook of MRI Pulse Sequences, pp. 38-39, Eqs. 2.2-2.4 and
%              2.6, (2004)
%
%   See also SINC_PULSE, GETPULSE, VIEWPULSE.
%

sincpulse = sinc_pulse(t,Trf,PulseOpt);
hann = 0.5*(1 - cos((2*pi*t)/Trf));
pulse = hann .* sincpulse;

end
