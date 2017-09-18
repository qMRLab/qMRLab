function w1rms = compute_w1rms(Pulse)
%compute_w1rms Compute the equivalent power of a rectangular pulse of same
%duration as the shaped pulse

Trf = Pulse.Trf;
omega2 = Pulse.omega2;
if moxunit_util_platform_is_octave
    int = quad(omega2, 0, Trf);
else
    int = integral(omega2, 0, Trf);
end
w1rms = sqrt( int / Trf );

end