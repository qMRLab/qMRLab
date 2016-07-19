function w1rms = compute_w1rms(Pulse)
%compute_w1rms Compute the equivalent power of a rectangular pulse of same
%duration as the shaped pulse

Trf = Pulse.Trf;
omega2 = Pulse.omega2;
int = integral(omega2, 0, Trf);
w1rms = sqrt( int / Trf );

end