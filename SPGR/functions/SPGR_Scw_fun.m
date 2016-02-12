function mxy = SPGR_Scw_fun(x, xData, Prot, FitOpt)
%SPGR_Y_fun Sled&Pike CW Analytical solution for SPGR MT data used for fitting
% x = [F,kr,R1f,R1r,T2f,T2r]
% xData = [Angles, Offsets, w1cw]
% Output : normalized mxy

F   = x(1);
kr  = x(2);
R1f = x(3);
R1r = x(4);
T2f = x(5);
T2r = x(6);
kf  = kr * F;

if ( FitOpt.R1reqR1f )
     R1r = x(3);
end

if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
     R1  =  FitOpt.R1;
     R1f =  R1 - kf*(R1r - R1) / (R1r - R1 + kf/F);
end

alpha   =  Prot.Alpha;
TR      =  Prot.TR;
Angles  =  xData(:,1);
Offsets =  xData(:,2);
w1cw    =  xData(:,3);

Sf = GetSf(Angles,Offsets,T2f,Prot.Sf);

if (FitOpt.fx(6))
    WB = FitOpt.WB;
else
    WB = computeWB(w1cw, Offsets, T2r, FitOpt.lineshape);
end

Mxy  = calcMxy(kf,kr,R1f,R1r,Sf,WB,TR,alpha);
Mxy0 = calcMxy(kf,kr,R1f,R1r, 1,0,TR,alpha);

mxy = Mxy ./ Mxy0;

end

function Mxy = calcMxy(kf,kr,R1f,R1r,Sf,W,TR,alpha)
Mssn1 =  (R1r*kf + R1r*R1f + R1f*kr + W*R1f);
Mssd  =  R1r*kf + R1r*R1f + R1f*kr + W*R1f + W*kf;
Mss   =  Mssn1./Mssd;

sq  =  sqrt( (R1f + kf + R1r + kr + W).^2 - 4*(R1f*R1r + kf*R1r + R1f*kr + R1f*W + kf*W) );
L1  =  0.5*( (R1f + kf + R1r + kr + W) + sq );
L2  =  0.5*( (R1f + kf + R1r + kr + W) - sq );
E1  =  exp( -L1*TR );
E2  =  exp( -L2*TR );

Mn  =  (E1-1) .* (E2-1) .* (L2-L1) .* Sf .* Mss .* sin(alpha*pi/180);
Md  =  (E1-1) .* (Sf.*E2-1) .* (L2-L1) + (Sf-1) .* (E2-E1) .* (L2 - R1f - kf);
Mxy =  Mn ./ Md;
end