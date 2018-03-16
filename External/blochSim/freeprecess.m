function [Afp,Bfp]=freeprecess(T,T1,T2,df)
%
%	Function simulates free precession and decay
%	over a time interval T, given relaxation times T1 and T2
%	and off-resonance df.  Times in ms, off-resonance in Hz.

phi = 2*pi*df*(T/1000);	% Off-resonance precession, radians.

% Relaxation exponentials
E1 = exp(-T/T1);	
E2 = exp(-T/T2);

% Decay and phase due to off-resonance
Afp = [E2 0 0;0 E2 0;0 0 E1]*zrot(phi); % Mathieu, check order of matrix multiplication

% Regrowth
Bfp = [0 0 1-E1]';


