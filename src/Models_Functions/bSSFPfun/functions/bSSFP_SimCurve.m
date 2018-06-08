function SimCurveResults = bSSFP_SimCurve(Fit, Prot, FitOpt)
FitOpt.R1map = 0;
FitOpt.R1reqR1f = 0;

xFit = [Fit.F, Fit.kr, Fit.R1f, Fit.R1r, Fit.T2f, Fit.M0f];
Fit.table = xFit';

FixAlpha =  find(diff(Prot.alpha)==0);
FixTrf   =  find(diff(Prot.Trf)==0);

Prot1 = Prot;
Prot2 = Prot;

if (~isempty(FixTrf))
    ii = FixTrf(1);
    Prot1.alpha = linspace(min(Prot.alpha),max(Prot.alpha),20)';
    Prot1.Trf = Prot.Trf(ii) * ones(length(Prot1.alpha),1);
    [alpha1, Trf1, TR1, W1] = bSSFP_prepare(Prot1,FitOpt);
    xdata = [alpha1, Trf1, TR1, W1];
    Fit.alphaCurve = bSSFP_fun( xFit, xdata, FitOpt );
    Fit.alpha = alpha1;
end

if (~isempty(FixAlpha))
    ii = FixAlpha(1);
    Prot2.Trf = linspace(min(Prot.Trf),max(Prot.Trf),20)';
    Prot2.alpha = Prot.alpha(ii) * ones(length(Prot2.Trf),1);
    [alpha2, Trf2, TR2, W2] = bSSFP_prepare(Prot2,FitOpt);
    xdata = [alpha2, Trf2, TR2, W2];
    Fit.TrfCurve = bSSFP_fun( xFit, xdata, FitOpt );
    Fit.Trf = Trf2;
end

SimCurveResults = Fit;