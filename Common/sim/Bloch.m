function dM = Bloch(t, M, Param, Pulse)
%Bloch ODEs with RF pulse excitation
% M : magnetization vector [Mxf, Myf, Mzf, Mzr]

dM = zeros(4,1);

if (nargin < 4)
    omega  = 0;
    omega2 = 0;
    delta  = 0;
else
    omega  = Pulse.omega(t);
    omega2 = Pulse.omega2(t);
    delta  = Pulse.delta;
end

W = pi*Param.G.*omega2;
R2f = 1/Param.T2f;
kf = Param.kr*Param.F;
M0r = Param.M0f*Param.F;

dM(1) = -R2f*M(1) - 2*pi*delta*M(2);
dM(2) = -R2f*M(2) + 2*pi*delta*M(1) + omega*M(3);
dM(3) =  Param.R1f*(Param.M0f-M(3)) - kf*M(3) + Param.kr*M(4) - omega*M(2);
dM(4) =  Param.R1r*(M0r-M(4)) + kf*M(3) - Param.kr*M(4) - W*M(4);

% Reference: M. Gloor, K. Scheffler, and O. Bieri. "Quantitative
% Magnetization Transfer Imaging Using Balanced SSFP", Magnetic Resonance
% in Medicine 60:691–700 (2008)
