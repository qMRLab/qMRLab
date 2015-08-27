function dM = BlochNoMT(t, M, T2f, Pulse)
%BlochNoMT Free pool ODEs with RF pulse excitation, without MT effect
%or T1 recovery
% M : magnetization vector [Mxf, Myf, Mzf]

dM    =  zeros(3,1);
omega =  Pulse.omega(t);
delta =  Pulse.delta;

dM(1) = - M(1)/T2f - 2*pi*delta*M(2);
dM(2) = - M(2)/T2f + 2*pi*delta*M(1) + omega*M(3);
dM(3) = - omega*M(2);
