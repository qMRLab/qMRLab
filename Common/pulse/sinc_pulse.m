function pulse = sinc_pulse(t,Trf,PulseOpt)
% sinc_pulse : Compute sinc RF pulse

if (nargin < 3); PulseOpt = struct; end

if(~isfield(PulseOpt,'TBW') || isempty(PulseOpt.TBW) || ~isfinite(PulseOpt.TBW))
    TBW = 4;    % time-bandwidth window (# of zeros)
else
    TBW = PulseOpt.TBW;
end

pulse = sinc( TBW/Trf * (t - Trf/2) );
pulse((t < 0 | t>Trf)) = 0;

end
