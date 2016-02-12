function SimCurveResults = SPGR_SimCurve(Fit, Prot, FitOpt )

FitOpt.R1map = 0;
FitOpt.R1reqR1f = 0;
FitOpt.fx(6) = true;

xFit = [Fit.F, Fit.kr, Fit.R1f, Fit.R1r, Fit.T2f, Fit.T2r];
Fit.table = xFit';

% OffsetCurve =  logspace(2,5,30)';
% OffsetCurve =  linspace(min(Prot.Offsets)*0.5, max(Prot.Offsets)*1.25, 20);
offsets = unique(Prot.Offsets);
lower = min(offsets)*0.25;
upper = max(offsets)*1.75;
offsets = [lower; offsets; upper];
OffsetCurve = zeros(length(offsets)*3 -2,1);
ind = 1;
for i = 1:length(offsets)-1
    OffsetCurve(ind) = offsets(i);
    OffsetCurve(ind+1) = offsets(i) + (offsets(i+1) - offsets(i))/3;
    OffsetCurve(ind+2) = offsets(i) + 2*((offsets(i+1) - offsets(i))/3);
    ind = ind + 3;
end
OffsetCurve(end) = offsets(end);

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