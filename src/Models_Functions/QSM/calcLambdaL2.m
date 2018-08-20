function [lambdaL2] = calcLambdaL2(phaseUnwrapped,rangeLambda, imageResolution, directionFlag)


  N = size(phaseUnwrapped);

  [fdx, fdy, fdz] = calcFdr(N, directionFlag);

  FOV = N .* imageResolution;  % (in milimeters)

  D = fftshift(kspaceKernel(FOV, N));

  E2 = abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2;
  D2 = abs(D).^2;

  Nfm_pad = fftn(phaseUnwrapped);

  regularization = zeros(size(rangeLambda));
  consistency = zeros(size(rangeLambda));

  tic
  for t = 1:length(rangeLambda)
    disp([num2str(t) ' / ' num2str(length(rangeLambda))]);

    D_reg = D ./ ( eps + D2 + rangeLambda(t) * E2 );
    Chi_L2 = (D_reg .* Nfm_pad);

    dx = (fdx.*Chi_L2) / sqrt(prod(N));
    dy = (fdy.*Chi_L2) / sqrt(prod(N));
    dz = (fdz.*Chi_L2) / sqrt(prod(N));

    regularization(t) = sqrt(norm(dx(:))^2 + norm(dy(:))^2 + norm(dz(:))^2);

    nfm_forward = ifftn(D .* Chi_L2);

    consistency(t) = norm(phaseUnwrapped(:) - nfm_forward(:));
  end
  toc

  % figure(), subplot(1,2,1), plot(consistency, regularization, 'marker', '*')

  % Memory cleanup
  clear nfm_forward Nfm_pad

  % cubic spline differentiation to find Kappa (largest curvature)

  [index_opt, ~] = findOptimalKappa(rangeLambda, regularization, consistency, [true true]);

  disp(['Optimal lambda, consistency, regularization: ', num2str([rangeLambda(index_opt), consistency(index_opt), regularization(index_opt)])])

  %figure(get(gcf,'Number')), subplot(1,2,2), semilogx(rangeLambda, Kappa, 'marker', '*')

  %% closed form solution with optimal lambda

  lambdaL2 = rangeLambda(index_opt);

end
