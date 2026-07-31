function mxy = SPGR_Srp_fun(x, xData, Prot, FitOpt)

% ----------------------------------------------------------------------------------------------------
% mxy = SPGR_Srp_fun(x, xData, Prot, FitOpt)
% Sled&Pike RP Analytical solution for SPGR MT data used for fitting
% ----------------------------------------------------------------------------------------------------
% x = [F,kr,R1f,R1r,T2f,T2r]
% xData = [Angles, Offsets, w1rp]
% Output : normalized mxy
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-Fran�ois Cabana, 2016
% reference: Sled, J. G., & Pike, G. B. (2001).
% Quantitative imaging of magnetization transfer exchange and relaxation properties in vivo using MRI.
% Magn Reson Med, 46(5), 923�931
% ----------------------------------------------------------------------------------------------------

% F   = (x(1)+0.002)*1.080 ; % Correction for overestimation
F   = x(1);
kr  = x(2);
R1f = x(3);
R1r = x(4);
T2f = x(5);
T2r = x(6);
kf  =  kr * F;
M0f = 1;
M0r = F*M0f;

if T2f<=0, warning('T2f is null. Absurd.'); mxy=nan(size(xData,1),1); return; end

if ( FitOpt.R1reqR1f )
     R1r = x(3);
end

if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
    tmpParam = struct('F', F, 'kf', kf, 'R1r', R1r); % Create temp struct with required fields
    R1f = computeR1(tmpParam, FitOpt.R1);
    clear tmpParam % Not needed after this point
end

alpha   =  Prot.Alpha*pi/180;
TR      =  Prot.TR;
Tau     =  Prot.Tau;
Angles  =  xData(:,1);
Offsets =  xData(:,2);
w1rp    =  xData(:,3);

Mxy = zeros(length(Angles),1);

if ~isfield(Prot,'Sf')
    Trf = Prot.Tm;
    shape = Prot.MTpulse.shape;
    PulseOpt = Prot.MTpulse.Npulse;
    Sf = zeros(size(Angles,1),1);
    for ii=1:length(Angles)
    MTpulse = GetPulse(Angles(ii),Offsets(ii),Trf,shape,PulseOpt);
    Sf(ii) = computeSf(T2f, MTpulse);
    end
else
    Sf = GetSf(Angles,Offsets,T2f,Prot.Sf);
end
Sr = 1;

if (FitOpt.fx(6))
    WB = FitOpt.WB;
else
    WB = computeWB(w1rp, Offsets, T2r, FitOpt.lineshape);
end

% A0 carries no saturation term, so exp(-(TR-Tau)*A0) is the same for every
% offset and for the Mxy0 normalisation. Computing it here rather than inside
% calcMxy replaces 11 identical matrix exponentials per model evaluation with
% one; the value is unchanged.
A0  = [R1f+kf,  -kr; -kf,  R1r+kr];
eA0 = expm2x2(-(TR-Tau)*A0);

for ii = 1:length(Angles)
    Mxy(ii)  = calcMxy(F,M0f,M0r,kf,kr,R1f,R1r,Sf(ii),Sr,WB(ii),TR,Tau,alpha,eA0);
end

Mxy0 = calcMxy(F,M0f,M0r,kf,kr,R1f,R1r, 1,Sr,0,TR,Tau,alpha,eA0);
mxy = Mxy ./ Mxy0;

end

function Mxy = calcMxy(F,M0f,M0r,kf,kr,R1f,R1r,Sf,Sr,W,TR,Tau,alpha,eA0)

    % expm2x2 is the closed form of expm for 2x2 arguments (see expm2x2.m).
    % MATLAB's general expm is scaling-and-squaring with a Pade approximant,
    % sized for arbitrary matrices; at 2x2 it dominated this fit.
    %
    % Only A12 carries the saturation term W and so varies per offset; eA0 is
    % offset-invariant and is passed in, computed once by the caller.
    A12  =  [R1f+kf,  -kr ; -kf,  R1r+kr+W];
    eA12 =  expm2x2( -Tau/2.*A12 );

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

    Mz(1:2,:) = (I - eA12*eA0*eA12*diag([Sf.*cos(alpha) Sr]))\ ...
        ( (I + eA12*(-I + eA0*(I -  eA12)))*Mss + eA12*(I - eA0)*M0_inf);
    
    Mxy = Mz(1,:).*sin(alpha).*S(:,1);

end