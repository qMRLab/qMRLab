function mxy = SPGR_Srp_fun(x, xData, Prot, FitOpt)
%SPGR_Y_fun Sled&Pike RP Analytical solution for SPGR MT data used for fitting
% x = [F,kr,R1f,R1r,T2f,T2r]
% xData = [Angles, Offsets, w1rp]
% Output : normalized mxy


F   = x(1);
kr  = x(2);
R1f = x(3);
R1r = x(4);
T2f = x(5);
T2r = x(6);
kf  =  kr * F;
M0f = 1;
M0r = F*M0f;

if ( FitOpt.R1reqR1f )
     R1r = x(3);
end

if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
     R1 = FitOpt.R1;
     R1f = R1 - kf*(R1r - R1) / (R1r - R1 + kf/F);
end

alpha   =  Prot.Alpha;
TR      =  Prot.TR;
Tau     =  Prot.Tau;
Angles  =  xData(:,1);
Offsets =  xData(:,2);
w1rp    =  xData(:,3);

Mxy = zeros(length(Angles),1);

Sf = GetSf(Angles,Offsets,T2f,FitOpt.SfTable);
Sr = 1;

if (FitOpt.fx(6))
    WB = FitOpt.WB;
else
    WB = computeWB(w1rp, Offsets, T2r, FitOpt.lineshape);
end

for ii = 1:length(Angles)
    Mxy(ii)  = calcMxy(F,M0f,M0r,kf,kr,R1f,R1r,Sf(ii),Sr,WB(ii),TR,Tau,alpha);
end

Mxy0 = calcMxy(F,M0f,M0r,kf,kr,R1f,R1r, 1,Sr,0,TR,Tau,alpha);
mxy = Mxy ./ Mxy0;

end

function Mxy = calcMxy(F,M0f,M0r,kf,kr,R1f,R1r,Sf,Sr,W,TR,Tau,alpha)

    A12  =  [R1f+kf,  -kr ; -kf,  R1r+kr+W];
    eA12 =  expm( -Tau/2.*A12 );
    A0  = [R1f+kf,  -kr; -kf,  R1r+kr];
    eA0 = expm(-(TR-Tau)*A0);

    if(F == 0)
        Mzf_inf = M0f;
        Mzr_inf = 0;
    else  
        Mssn1 =  M0f*(R1r*kf + R1r*R1f + R1f*kr + W*R1f);
        Mssn2 =  M0r*(R1r*kf + R1r*R1f + R1f*kr);
        Mssd  =  R1r*kf + R1r*R1f + R1f*kr + W*R1f + W*kf;
        Mzf_inf = Mssn1/Mssd; 
        Mzr_inf = Mssn2/Mssd; 
    end

    Mss = [Mzf_inf; Mzr_inf];
    M0_inf = [M0f; M0r]; 
    I = eye(2);
    S  = [Sf, Sr];

    Mz(1:2,:) = inv(I - eA12*eA0*eA12*diag([Sf Sr]))* ...
        ( (I + eA12*(-I + eA0*(I -  eA12)))*Mss + eA12*(I - eA0)*M0_inf);

    Mxy = Mz(1,:).*sin(alpha*pi/180).*S(:,1);

end