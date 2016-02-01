function SimCurveResults = SPGR_SimCurve(Fit, Prot, FitOpt )

FitOpt.R1map = 0;
FitOpt.R1reqR1f = 0;
FitOpt.fx(6) = true;

xFit = [Fit.F, Fit.kr, Fit.R1f, Fit.R1r, Fit.T2f, Fit.T2r];
Fit.table = xFit';

OffsetCurve =  logspace(2,5,30)';
AngleCurve  =  unique(Prot.Angles);
[Prot.Angles, Prot.Offsets] = SPGR_GetSeq(AngleCurve,OffsetCurve);
[Angles, Offsets, w1cw, w1rms, w1rp, Tau] = SPGR_prepare( Prot );
Prot.Tau = Tau(1);

% Fitted curve
switch FitOpt.model    
    case 'SledPikeCW'
        FitOpt.WB = computeWB(w1cw, Offsets, Fit.T2r, FitOpt.lineshape);
        xData = [Angles, Offsets, w1cw];
        func = @SPGR_Scw_fun;       
    case 'SledPikeRP'
        FitOpt.WB = computeWB(w1rp, Offsets, Fit.T2r, FitOpt.lineshape);
        xData = [Angles, Offsets, w1rp];
        func = @SPGR_Srp_fun;        
    case 'Yarnykh'
        FitOpt.WB = computeWB(w1rms, Offsets, Fit.T2r, FitOpt.lineshape);
        xData = [Offsets, w1rms];
        func = @SPGR_Y_fun;      
    case 'Ramani'
        FitOpt.WB = computeWB(w1cw, Offsets, Fit.T2r, FitOpt.lineshape);
        xData = [Offsets, w1cw];
        func = @SPGR_R_fun;    
end

Mcurve = func(xFit, xData, Prot, FitOpt);
Mcurve = reshape(Mcurve,length(OffsetCurve),length(AngleCurve));
Fit.curve = Mcurve;
Fit.Offsets = OffsetCurve;
SimCurveResults = Fit;

end