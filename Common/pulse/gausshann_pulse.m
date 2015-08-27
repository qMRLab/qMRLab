function pulse = gausshann_pulse(t, Trf, PulseOpt)

% gausshann_pulse : Compute gaussian RF pulse with Hanning window

gauss = gaussian_pulse(t, Trf, PulseOpt);
hann = 0.5*(1 - cos((2*pi*t)/Trf));
pulse = gauss .* hann;

return