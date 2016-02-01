function Fit = SIRFSE_fit(MTdata, Prot, FitOpt)
%%SIRFSE_fit Fits analytical SIR model to data
% Fit a vector x = [F,kr,R1f,R1r,Sf,Sr,M0f]

ti = Prot.ti;
td = Prot.td;
t = [ti,td];

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

[x_free, resnorm, residuals] = lsqcurvefit(@(x,xdata) SIRFSE_fun(choose( FitOpt.st, x, fix ),xdata, FitOpt),...
                     FitOpt.st(~fix), t, MTdata, FitOpt.lb(~fix), FitOpt.ub(~fix), opt);
                 
x = choose( FitOpt.st, x_free, fix );

Fit.F   = x(1);
Fit.kr  = x(2);
Fit.R1f = x(3);
Fit.R1r = x(4);
Fit.Sf  = abs(x(5));
Fit.Sr  = x(6);
Fit.M0f = x(7);
Fit.kf  = Fit.kr .* Fit.F;
Fit.M0r  = Fit.F.*Fit.M0f;

if (FitOpt.R1reqR1f)
     Fit.R1r = Fit.R1f;
end

if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
     R1 = FitOpt.R1;
     Fit.R1f = R1 - Fit.kf*(Fit.R1r - R1) / (Fit.R1r - R1 + Fit.kf/Fit.F);
end

% Fit.residuals = residuals;
Fit.resnorm = resnorm;

end

% Choose fitted or fixed parameters
function a = choose( a, x, fx )
a(~fx) = x;
end

