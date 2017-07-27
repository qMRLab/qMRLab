function mz = SPGR_Y_fun(x, xData, Prot, FitOpt)

% ----------------------------------------------------------------------------------------------------
% SPGR_Y_fun Yarnykh Analytical solution for SPGR MT data used for fitting
% ----------------------------------------------------------------------------------------------------
% x = [F, kr, R1f, R1r, T2f, T2r]
% xData = [Offsets, w1rms]
% Output : normalized mz
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% Reference : Yarnykh, V. L. (2012). Fast macromolecular proton fraction
% mapping from a single off-resonance magnetization transfer measurement.
% Magnetic Resonance in Medicine, 68(1), 166-178.
% ----------------------------------------------------------------------------------------------------

F   = x(1);
kr  = x(2);
R1f = x(3);
R1r = x(4);
T2f = x(5);
T2r = x(6);

kf  =  kr * F;
f   =  F / (1+F);       % Bound Pool Fraction

if ( FitOpt.R1reqR1f )
     R1r = x(3);
end

if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)     
    tmpParam = struct('F', F, 'kf', kf, 'R1r', R1r); % Create temp struct with required fields
    R1f = computeR1(tmpParam, FitOpt.R1);
    clear tmpParam % Not needed after this point
end

tr  =  Prot.Tr;       % delay after the excitation pulse
tm  =  Prot.Tm;       % saturation offset pulse duration
ts  =  Prot.Ts;       % delay before the excitation pulse
alpha = Prot.Alpha;   % read pulse flip angle

Offsets =  xData(:,1);
w1rms   =  xData(:,2);
nxData  =  length(w1rms);
Mz      =  zeros(nxData,1);

% COMPUTE WF, WB
if (FitOpt.fx(6))
    WB = FitOpt.WB;
else
    WB = computeWB(w1rms, Offsets, T2r, FitOpt.lineshape);
end

if (FitOpt.FixR1fT2f && FitOpt.R1map)
    WF = FitOpt.WF;
elseif (FitOpt.FixR1fT2f && ~FitOpt.R1map)
    WF = (w1rms ./ 2/pi./Offsets).^2 * R1f / FitOpt.FixR1fT2fValue;
else
    WF = (w1rms ./ 2/pi./Offsets).^2 / T2f;
end

C   =  [ cos(alpha*pi/180),  0;  0,  1 ];
I   =  eye(2);
Rl  =  [ -R1f-kf,  kr;  kf,  -R1r-kr ];
Meq =  [1-f, f]';
A   =  R1f*R1r + R1f*kr + R1r*kf;
Es  =  expm(Rl*ts);
Er  =  expm(Rl*tr);

for i=1:nxData
    W   =  [ -WF(i),  0;   0,   -WB(i) ];       
    D   =  A + (R1f+kf)*WB(i) + (R1r+kr)*WF(i) + WB(i)*WF(i);   
    xx  =  (1./D)*( (1-f)*( A + R1f*WB(i) ) );
    xy  =  (1./D)*( f*( A + R1r*WF(i) ) );
    Mss =  [xx; xy];    
    Em  =  expm( (Rl+W)*tm );   
    p1  =  I - Es*Em*Er*C;
    p2  =  ( Es*Em*(I-Er) + (I-Es) )*Meq;
    p3  =  Es*(I-Em)*Mss;
    Mzi =  p1 \ (p2+p3);
    Mz(i) = Mzi(1);
end

%NORMALIZATION
    Em0 = expm((Rl)*tm);
    D = A;
    Meq0 =  [ 1-f; f ];
    Mss0 =  1/D * [ (1-f)*(A); f*(A) ];
    p10  =  I - Es*Em0*Er*C;
    p20  =  ( Es*Em0*(I - Er) + (I-Es) )*Meq0;
    p30  =  Es * ( I-Em0 ) * Mss0;
    Mz0  =  p10 \ ( p20 + p30 );
    mz   =  Mz ./ Mz0(1);

end

