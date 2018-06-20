function w1cw = compute_w1cw(TR, Pulse)
%compute_w1cw Compute the constant wave equivalent power over a period TR for a given pulse

Trf = Pulse.Trf;
omega2 = Pulse.omega2;
if moxunit_util_platform_is_octave
    int = quad(omega2, 0, Trf);
else
    int = integral(omega2, 0, Trf);
end
w1cw = sqrt( int / TR );

