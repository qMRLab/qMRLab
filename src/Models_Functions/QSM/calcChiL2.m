function [chiL2, chiL2pcg] = calcChiL2(phaseUnwrapped, lambdaL2, directionFlag, imageResolution, mask, paddingSize, magnWeight)

  N = size(phaseUnwrapped);

  [fdx, fdy, fdz] = calcFdr(N, directionFlag);

  FOV = N .* imageResolution;  % (in milimeters)

  D = fftshift(kspaceKernel(FOV, N));

  E2 = abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2;
  D2 = abs(D).^2;


  tic
  D_reg = D ./ ( eps + D2 + lambdaL2 * E2 );
  D_regx = ifftn(D_reg .* fftn(phaseUnwrapped));
  toc


  chiL2 = real(D_regx) .* mask;
  chiL2 = chiL2(1+paddingSize(1):end-paddingSize(1),1+paddingSize(2):end-paddingSize(2),1+paddingSize(3):end-paddingSize(3));


  % Memory cleanup in case magn weight will be performed
  clear D_reg

  %% L2-regularized solution with pre-conditionned magnitude weighting

  if exist('magnWeight', 'var') && nargout == 2
    %            (eps +     (A_frw)        )   - for better memory management
    A_inv = 1 ./ (eps + D2 + lambdaL2 * E2);

    b = D.*fftn(phaseUnwrapped);

    precond_inverse = @(x, A_inv) A_inv(:).*x;

    F_chi0 = fftn(D_regx);      % use close-form L2-reg. solution as initial guess

    tic
    [F_chi, ~, pcg_res, pcg_iter] = pcg(@(x) applyForward(x, D2, lambdaL2, fdx, fdy, fdz, ...
    conj(fdx), conj(fdy), conj(fdz), magnWeight), b(:), 1e-3, 20, @(x) precond_inverse(x, A_inv), [], F_chi0(:));
    toc

    disp(['PCG iter: ', num2str(pcg_iter), '   PCG residual: ', num2str(pcg_res)])

    Chi = reshape(F_chi, N);

    chiL2pcg = real(ifftn(Chi)) .* mask;
    chiL2pcg = chiL2pcg(1+paddingSize(1):end-paddingSize(1),1+paddingSize(2):end-paddingSize(2),1+paddingSize(3):end-paddingSize(3));

  end

end
