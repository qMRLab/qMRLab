function pulse = gaussian_pulse(t, Trf, PulseOpt)
% gaussian_pulse : Compute gaussian RF pulse shape

if (nargin < 3); PulseOpt = struct; end

if(~isfield(PulseOpt,'bw') || isempty(PulseOpt.bw) || ~isfinite(PulseOpt.bw))
    % sigma determined assuming that pulse duration is set at 60 dB amplitude
    % according to Chapter 4 in Handbook of MRI Pulse Sequences
    sigma2 = (Trf / 7.434).^2;       
else
    bw = PulseOpt.bw;
    sigma2 = 2*log(2) / (pi*bw).^2;
end

pulse = exp( -((t-(Trf/2)).^2)/(2*sigma2));
pulse((t < 0 | t>Trf)) = 0;

return