function [ index_opt ] = findOptimalKappa(Lambda, regularization, consistency)
%FINDOPTIMALKAPPA cubic spline differentiation to find Kappa index 
%(largest curvature) 
%   Lambda:Range of regularization weights to optimize
%   regularization: Regularization values array
%   consistency: Consistency values array

    eta = log(regularization);
    rho = log(consistency.^2);

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

