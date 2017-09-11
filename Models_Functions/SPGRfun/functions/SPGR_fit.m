function Fit = SPGR_fit(MTdata, Prot, FitOpt )

% ----------------------------------------------------------------------------------------------------
% SPGR_fit Fits analytical SPGR model to data
% ----------------------------------------------------------------------------------------------------
% MTdata = struct with fields 'MTdata', and optionnaly 'Mask','R1map','B1map','B0map'
% Output : Fit structure with fitted parameters
% ----------------------------------------------------------------------------------------------------
% Written by: Jean-François Cabana, 2016
% ----------------------------------------------------------------------------------------------------
% If you use qMRLab in your work, please cite :

% Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S.,
% Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016),
% Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation,
% analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
% ----------------------------------------------------------------------------------------------------

if ~isfield(Prot,'Sf') || isempty(Prot.Sf)
    warndlg('Build Sf Lookup Table in the options panel for faster fitting...','Lookup Table empty'); 
end

if length(Prot.Angles)~=length(MTdata)
    errordlg(['You set a protocol with ' num2str(length(Prot.Angles)) ' offsets/angles but your input has ' num2str(length(MTdata)) ' MTdata']); 
end

% Apply B1map
if (isfield(FitOpt,'B1') && ~isempty(FitOpt.B1))
    Prot.Angles = Prot.Angles * FitOpt.B1;
    Prot.Alpha = Prot.Alpha * FitOpt.B1;
end

% Apply B0map
if (isfield(FitOpt,'B0') && ~isempty(FitOpt.B0))
    Prot.Offsets = Prot.Offsets + FitOpt.B0;
end

% Use R1map
if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
    FitOpt.R1 = max(0.1,FitOpt.R1);
    FitOpt.fx(3) = 1;
    FitOpt.st(3) = FitOpt.R1;
end

% Fix R1r = R1f
if (FitOpt.R1reqR1f)
    FitOpt.fx(4) = 1;
    FitOpt.st(4) = FitOpt.st(3);
end

fix = FitOpt.fx;
[Angles, Offsets, w1cw, w1rms, w1rp, Tau] = SPGR_prepare( Prot );
Prot.Tau = Tau(1);

switch FitOpt.model   
    case 'SledPikeCW'
        % if T2r is fixed, precompute WB
        if (fix(6))
            FitOpt.WB = computeWB(w1cw, Offsets, FitOpt.st(6), FitOpt.lineshape);
        else
            FitOpt.WB = [];
        end
        xData = [Angles, Offsets, w1cw];
        func = @(x,xdata) SPGR_Scw_fun(choose( FitOpt.st, x, fix ), xdata, Prot, FitOpt);
        
    case 'SledPikeRP'
        % if T2r is fixed, precompute WB
        if (fix(6))
            FitOpt.WB = computeWB(w1rp, Offsets, FitOpt.st(6), FitOpt.lineshape);
        else
            FitOpt.WB = [];
        end
        xData = [Angles, Offsets, w1rp];
        func = @(x,xdata) SPGR_Srp_fun(choose( FitOpt.st, x, fix ), xdata, Prot, FitOpt);
        
    case 'Yarnykh'
        % if T2r is fixed, precompute WB
        if (fix(6))
            FitOpt.WB = computeWB(w1rms, Offsets, FitOpt.st(6), FitOpt.lineshape);
        else
            FitOpt.WB = [];
        end
        
        % if R1f*T2f is fixed, and R1f = R1, precompute WF
        if (FitOpt.FixR1fT2f && FitOpt.R1map)
            FitOpt.fx(5) = true;
            FitOpt.st(5) = FitOpt.FixR1fT2fValue / FitOpt.st(3);
            FitOpt.WF = (w1rms ./ 2/pi./Offsets).^2 * FitOpt.st(3) / FitOpt.FixR1fT2fValue;
        else
            FitOpt.WF = [];
        end
        fix = FitOpt.fx;
        xData = [Offsets, w1rms];
        func = @(x,xdata) SPGR_Y_fun(choose( FitOpt.st, x, fix ), xdata, Prot, FitOpt);
        
    case 'Ramani'
        % if T2r is fixed, precompute WB
        if (fix(6))
            FitOpt.WB = computeWB(w1cw, Offsets, FitOpt.st(6), FitOpt.lineshape);
        else
            FitOpt.WB = [];
        end
        
        % if R1f*T2f is fixed, precompute WF
        if (FitOpt.FixR1fT2f)
            FitOpt.WF = (w1cw ./ 2/pi./Offsets).^2 / FitOpt.FixR1fT2fValue;
        else
            FitOpt.WF = [];
        end
        fix = FitOpt.fx;
        xData = [Offsets, w1cw];
        func = @(x,xdata) SPGR_R_fun(choose( FitOpt.st, x, fix ), xdata, Prot, FitOpt); 
end

% Fitting
opt.Display = 'off';
[x_free,resnorm] = lsqcurvefit(func, FitOpt.st(~fix), xData, MTdata, FitOpt.lb(~fix), FitOpt.ub(~fix), opt);

x = choose( FitOpt.st, x_free, fix );

% Fit results
Fit.F   = x(1);
Fit.kr  = x(2);
Fit.R1f = x(3);
Fit.R1r = x(4);
Fit.T2f = x(5);
Fit.T2r = x(6);
Fit.kf  = Fit.kr * Fit.F;

if (FitOpt.R1reqR1f)
    Fit.R1r = Fit.R1f;
end

if (isfield(FitOpt,'R1') && ~isempty(FitOpt.R1) && FitOpt.R1map)
     Fit.R1f = computeR1(Fit, FitOpt.R1);
end

if ( strcmp(FitOpt.model, {'Yarnykh', 'Ramani'}) )
    if (FitOpt.FixR1fT2f)
        Fit.T2f = FitOpt.FixR1fT2fValue/Fit.R1f;
    end
end

% Fit.residuals = residuals;
Fit.resnorm = resnorm;

function a = choose( a, x, fx )
    a(~fx) = x;
end

end
