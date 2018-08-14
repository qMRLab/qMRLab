function pulse = gaussian_pulse(t, Trf, PulseOpt)
%GAUSSIAN_PULSE Gaussian RF pulse function.
%   pulse = gaussian_pulse(t, Trf, PulseOpt)
%
%   The Gaussian pulse is defined to be 0 outside the pulse window (before 
%   t = 0 or after t=Trf), and follows a symmetric Gaussian lineshape 
%   within.
%
%   --args--
%   t: Function handle variable, represents the time.
%   Trf: Duration of the Gaussian RF pulse.
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
%              Handbook of MRI Pulse Sequences, pp. 110, Eq. 4.10, (2004)
%
%   See also GETPULSE, VIEWPULSE.
%

if (nargin < 3); PulseOpt = struct; end

if(~isfield(PulseOpt,'bw') || isempty(PulseOpt.bw) || ~isfinite(PulseOpt.bw))
    % Default sigma determined assuming that pulse duration is set at 60 dB
    % amplitude according to Chapter 4 in Handbook of MRI Pulse Sequences.
    sigma2 = (Trf / 7.434).^2;       
else
    bw = PulseOpt.bw;
    sigma2 = 2*log(2) / (pi*bw).^2; % In the reference, sqrt(2*log(2))/pi 
                                    % calculated implicitly (= 0.3748).
end

pulse = exp( -((t-(Trf/2)).^2)/(2*sigma2));
pulse((t < 0 | t>Trf)) = 0;

return