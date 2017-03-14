function w1cw = compute_w1cw(TR, Pulse)
%compute_w1cw Compute the constant wave equivalent power over a period TR for a given pulse

Trf = Pulse.Trf;
omega2 = Pulse.omega2;
int = integral(omega2, 0, Trf);
w1cw = sqrt( int / TR );

