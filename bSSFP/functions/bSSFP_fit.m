function Fit = bSSFP_fit(MTdata, Prot, FitOpt)
% bSSFP_fit Fits analytical bSSFP model to data
% Fit a vector x = [F,kr,R1f,R1r,T2f,M0f]

[alpha, Trf, TR, W] = bSSFP_prepare(Prot, FitOpt);

% Apply B1map
if (isfield(FitOpt,'B1') && ~isempty(FitOpt.B1))
    alpha = alpha * FitOpt.B1;
end

xData = [alpha, Trf, TR, W];

% Use R1map
if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
    FitOpt.fx(3) = 1;
    FitOpt.st(3) = FitOpt.R1;
end

% Fix R1r = R1f
if (FitOpt.R1reqR1f)
    FitOpt.fx(4) = 1;
    FitOpt.st(4) = FitOpt.st(3);
end
   
fix = FitOpt.fx;

% Fitting
opt = optimoptions(@lsqcurvefit, 'Display', 'off');

x_free = lsqcurvefit(@(x,xdata) bSSFP_fun(choose( FitOpt.st, x, fix ), xdata, FitOpt),...
                     FitOpt.st(~fix), xData, MTdata, FitOpt.lb(~fix), FitOpt.ub(~fix), opt);
     
x = choose( FitOpt.st, x_free, fix );     

% Fit results
Fit.F   = x(1);
Fit.kr  = x(2);
Fit.R1f = x(3);
Fit.R1r = x(4);
Fit.T2f = x(5);
Fit.M0f = x(6);
Fit.kf   = Fit.kr .* Fit.F;
Fit.M0r  = Fit.F .* Fit.M0f;

if (FitOpt.R1reqR1f)
     Fit.R1r = Fit.R1f;
end

if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
     R1 = FitOpt.R1;
     Fit.R1f = R1 - Fit.kf*(Fit.R1r - R1) / (Fit.R1r - R1 + Fit.kf/Fit.F);
end

end

% Choose fitted or fixed parameters
function a = choose( a, x, fx ) 
a(~fx) = x;
end

