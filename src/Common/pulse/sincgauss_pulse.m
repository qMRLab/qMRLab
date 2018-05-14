function pulse = sincgauss_pulse(t,Trf,PulseOpt)
% sincgauss_pulse : Compute sinc RF pulse with gaussian window

sincpulse = sinc_pulse(t,Trf,PulseOpt);
gauss = gaussian_pulse(t, Trf, PulseOpt);
pulse = gauss .* sincpulse;

end
