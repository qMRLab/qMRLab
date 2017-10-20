function SimCurveResults = SPGR_SimCurve(Fit, Prot, FitOpt , same)

if ~exist('same','var'), same=0; end

FitOpt.R1map = 0;
FitOpt.R1reqR1f = 0;
FitOpt.fx(6) = true;

xFit = [Fit.F, Fit.kr, Fit.R1f, Fit.R1r, Fit.T2f, Fit.T2r];
Fit.table = xFit';

offsets = unique(Prot.Offsets);
if same
    OffsetCurve=offsets;
else
    OffsetCurve = zeros(length(offsets)*4 +2,1);
    OffsetCurve(1) = 100;
    OffsetCurve(end) = max(offsets) + 1000;
    maxOff = 100;
    offsets = [0; offsets];
    ind = 4;
    for i = 2:length(offsets)
        OffsetCurve(ind-2) = 0.5*(offsets(i) + offsets(i-1));
        OffsetCurve(ind-1) = offsets(i) - maxOff;
        OffsetCurve(ind) = offsets(i);
        OffsetCurve(ind+1) = offsets(i) + maxOff;
        ind = ind + 4;
    end
end

AngleCurve  =  unique(Prot.Angles);
if ~same
    [Prot.Angles, Prot.Offsets] = SPGR_GetSeq(AngleCurve,OffsetCurve);
end
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
        % if R1f*T2f is fixed, precompute WF
        if (FitOpt.FixR1fT2f)
            FitOpt.WF = (w1cw ./ 2/pi./Offsets).^2 / FitOpt.FixR1fT2fValue;
        else
            FitOpt.WF = [];
        end
end

Mcurve = func(xFit, xData, Prot, FitOpt);
if ~same
    Mcurve = reshape(Mcurve,length(OffsetCurve),length(AngleCurve));
end
Fit.curve = Mcurve;
Fit.Offsets = OffsetCurve;
SimCurveResults = Fit;

end