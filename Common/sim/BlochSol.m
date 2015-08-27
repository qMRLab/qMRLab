function M = BlochSol(t, M, Param, Pulse)
%BlochSol Analytical solution to Bloch equations for free or constant RF
%Faster than solving the ODE numerically

gamma = 2*pi*42576;
R1f = Param.R1f;
R2f = Param.R2f;
R1r = Param.R1r;
kf  = Param.kf;
kr  = Param.kr;
M0f = Param.M0f;
M0r = Param.M0r;
M0  = [0; 0; M0f; M0r];

if (nargin < 4)
        omega = 0;
        delta = 0;
else
        omega = gamma*Pulse.amp;
        delta = Pulse.delta;
end

W = pi*Param.G*omega^2;

A = [      -R2f, -2*pi*delta,         0,      0; ...
     2*pi*delta,        -R2f,     omega,      0; ...
              0,      -omega, -(R1f+kf),     kr; ...
              0,           0,        kf, -(R1r+kr+W)];

B = [ 0,    0,   0,   0; ...
      0,    0,   0,   0; ...
      0,    0, R1f,   0; ...
      0,    0,   0, R1r];
          
EA = expm(A*t);
I = eye(4);
M = EA*M + A\(EA - I)*B*M0;

end

