function [Afp,Bfp]=free_precess(T,T1,T2,df)
%FREE_PRECESS Function simulates free precession and decay over a time 
%interval T, given relaxation times T1 and T2 and off-resonance df.  
% T, T1, T2 in ms
% df in Hz.
%
%   Outputs:
%       Afp = Decay matrix.
%       Bfp = Regrowth array.

phi = 2*pi*df*(T/1000);	% Off-resonance precession, radians.

% Relaxation exponentials
E1 = exp(-T/T1);
E2 = exp(-T/T2);

% Decay and phase due to off-resonance
Afp = [E2 0 0;0 E2 0;0 0 E1]*z_rot(phi);

% Regrowth
Bfp = [0 0 1-E1]';
