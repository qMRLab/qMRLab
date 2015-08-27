function w1rms = compute_w1rms(Angles, Pulse)
%compute_w1rms Compute the equivalent power of a rectangular pulse of same
%duration as the shaped pulse

omega  =  Pulse.omega;
omega2 =  Pulse.omega2;
Trf = Pulse.Trf;

Beta = sqrt(integral(omega2, 0, Trf)) / integral(omega, 0, Trf);
w1rms = Angles/sqrt(Trf) * pi/180 * Beta;

end