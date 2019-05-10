function pulse = gausshann_pulse(t, Trf, PulseOpt)
%GAUSSHANN_PULSE Hanning-apodized Gaussian RF pulse function.
%   pulse = gausshann_pulse(t, Trf, PulseOpt)
%
%   The Gaussian pulse is defined to be 0 outside the pulse window (before 
%   t = 0 or after t=Trf), and follows a symmetric Gaussian lineshape 
%   within, and is apodized by a Hanning window.
%
%   --args--
%   t: Function handle variable, represents the time.
%   Trf: Duration of the Gaussian-Hann RF pulse.
%
%   --optional args--
%   PulseOpt: Struct. Contains optional parameters for pulse shapes.
%
%             -properties-
%             bw: FWHM of the Fourier Transform of the Gaussian function. 
%                 Conventionnally a measure of the RF bandwidth. See
%                 deltaf_G in the reference for more details (between Eqs.
%                 4.12 and 2.14.).
%
%   Reference: Matt A. Bernstein, Kevin F. Kink and Xiaohong Joe Zhou.
%              Handbook of MRI Pulse Sequences, pp. 39 and 110, Eqs. 2.6
%              and 4.10, (2004)
%
%   See also GAUSSIAN_PULSE, GETPULSE, VIEWPULSE.
%

gauss = gaussian_pulse(t, Trf, PulseOpt);
hann = 0.5*(1 - cos((2*pi*t)/Trf));
pulse = gauss .* hann;

end
