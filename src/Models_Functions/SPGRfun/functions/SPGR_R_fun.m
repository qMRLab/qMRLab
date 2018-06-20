function mz  = SPGR_R_fun(x, xData, ~, FitOpt)
%SPGR_R_fun Ramani Analytical solution for SPGR MT data used for fitting
% Reference : Ramani, A., et al. (2002). "Precise estimate of fundamental
% in-vivo MT parameters in human brain in clinically feasible times."
% Magn Reson Imaging 20(10): 721-731.

% x = [F, kr, R1f, R1r, T2f, T2r]
% xData = [Offsets, w1cw]
% Output : normalized mz

F   = x(1);
kr  = x(2);
R1f = x(3);
R1r = x(4);
T2f = x(5);
T2r = x(6);
kf  =  kr * F;

if ( FitOpt.R1reqR1f )
     R1r = x(3);
end

if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
     tmpParam = struct('F', F, 'kf', kf, 'R1r', R1r); % Create temp struct with required fields
     
     R1f = computeR1(tmpParam, FitOpt.R1);
     
     clear tmpParam % Not needed after this point
end

Offsets =  xData(:,1);
w1cw    =  xData(:,2);

if (FitOpt.fx(6))
    WB = FitOpt.WB;
else
    WB = computeWB(w1cw, Offsets, T2r, FitOpt.lineshape);
end

if (FitOpt.FixR1fT2f)
    WF = FitOpt.WF;
else
    WF = (w1cw ./ 2/pi./Offsets).^2 / (R1f*T2f);
end

num = R1r * ( kr*F / R1f ) + WB + R1r + kr;
den = ( kr*F / R1f) .* (R1r + WB) + (1 + WF) .* (WB + R1r + kr);
mz  = num./den;

end