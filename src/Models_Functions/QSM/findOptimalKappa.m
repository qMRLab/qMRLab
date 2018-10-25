function [index_opt, Kappa] = findOptimalKappa(Lambda, regularization, consistency, pow2Flags)
%FINDOPTIMALKAPPA cubic spline differentiation to find Kappa index 
%(largest curvature) 
%   Lambda:Range of regularization weights to optimize
%   regularization: Regularization values array
%   consistency: Consistency values array
%
%   Code refractored from Berkin Bilgic's scripts: "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m" 
%   and "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m"
%   Original source: https://martinos.org/~berkin/software.html
%
%   Original reference:
%   Bilgic et al. (2014), Fast quantitative susceptibility mapping with 
%   L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%   72: 1444-1459. doi:10.1002/mrm.25029

    if pow2Flags(1) == true
        eta = log(regularization.^2);
    else
        eta = log(regularization);
    end
    
    if pow2Flags(2) == true
        rho = log(consistency.^2);
    else
        rho = log(consistency);
    end

    M = [0 3 0 0; 0 0 2 0; 0 0 0 1; 0 0 0 0];

    pp = spline(Lambda, eta);
    ppd = pp;

    ppd.coefs = ppd.coefs*M;
    eta_del = ppval(ppd, Lambda);
    ppd.coefs = ppd.coefs*M;
    eta_del2 = ppval(ppd, Lambda);


    pp = spline(Lambda, rho);
    ppd = pp;

    ppd.coefs = ppd.coefs*M;
    rho_del = ppval(ppd, Lambda);
    ppd.coefs = ppd.coefs*M;
    rho_del2 = ppval(ppd, Lambda);


    Kappa = 2 * (rho_del2 .* eta_del - eta_del2 .* rho_del) ./ (rho_del.^2 + eta_del.^2).^1.5;

    index_opt = find(Kappa == max(Kappa));

end

