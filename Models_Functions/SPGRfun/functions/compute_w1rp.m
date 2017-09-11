function [w1rp, Tau] = compute_w1rp(Pulse)
%compute_w1rms Compute the equivalent power of a rectangular pulse of
%duration of the FWHM of the shaped pulse
      
Trf = Pulse.Trf;
omega2 = Pulse.omega2;
if moxunit_util_platform_is_octave
    int = quad(omega2, 0, Trf);
else
    int = integral(omega2, 0, Trf);
end

if strcmp(Pulse.shape,'hard')
    Tau = Trf;
else
    x = 0:Trf/1000:Trf;
    y = omega2(x);
    Tau = fwhm(x,y);
end

w1rp = sqrt( int / Tau );

end
