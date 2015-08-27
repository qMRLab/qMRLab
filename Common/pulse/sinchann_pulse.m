function pulse = sinchann_pulse(t,Trf,PulseOpt)
% sinc_pulse : Compute sinc RF pulse

sincpulse = sinc_pulse(t,Trf,PulseOpt);
hann = 0.5*(1 - cos((2*pi*t)/Trf));
pulse = hann .* sincpulse;

end
