function [ lambda_L2, chi_L2, chi_L2pcg] = calc_lambda_L2(nfm_Sharp_lunwrap, mask_sharp, Lambda, imageResolution, directionFlag, pad_size, magn_weight)
%CALC_SB_LAMBDA_L2 Determine optimal Lambda L2 using using L-curve analysis
%and get closed-form QSM solution with it.
%   nfm_Sharp_lunwrap: Sharp-unwrapped phase.
%   mask_sharp: Erroded mask that remove convolution artifacts.
%   Lambda: Range of L2 regularization weights to optimize
%   imageResolution: Image resolution in mm.
%   directionFlag: forward' or 'backward', direction of the
%   differentiation.
%   (optional) magn_weight: Gradient mask from magnitude image
%
%   Code refractored from Berkin Bilgic's scripts: "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m" 
%   and "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m"
%   Original source: https://martinos.org/~berkin/software.html
%
%   Original reference:
%   Bilgic et al. (2014), Fast quantitative susceptibility mapping with 
%   L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%   72: 1444-1459. doi:10.1002/mrm.25029
%

    N = size(nfm_Sharp_lunwrap);

    [fdx, fdy, fdz] = calc_fdr(N, directionFlag);

    FOV = N .* imageResolution;  % (in milimeters)

    D = fftshift(kspace_kernel(FOV, N));

    E2 = abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2; 
    D2 = abs(D).^2;

    Nfm_pad = fftn(nfm_Sharp_lunwrap);

    regularization = zeros(size(Lambda));
    consistency = zeros(size(Lambda));

    tic
    for t = 1:length(Lambda) 
        disp(num2str(t))

        D_reg = D ./ ( eps + D2 + Lambda(t) * E2 );
        Chi_L2 = (D_reg .* Nfm_pad);

        dx = (fdx.*Chi_L2) / sqrt(prod(N));
        dy = (fdy.*Chi_L2) / sqrt(prod(N));
        dz = (fdz.*Chi_L2) / sqrt(prod(N));

        regularization(t) = sqrt(norm(dx(:))^2 + norm(dy(:))^2 + norm(dz(:))^2);

        nfm_forward = ifftn(D .* Chi_L2);

        consistency(t) = norm(nfm_Sharp_lunwrap(:) - nfm_forward(:));
    end
    toc

    figure(), subplot(1,2,1), plot(consistency, regularization, 'marker', '*')
    
    % Memory cleanup
    clear nfm_forward Nfm_pad
    
    % cubic spline differentiation to find Kappa (largest curvature) 

    index_opt = findOptimalKappa(Lambda, regularization, consistency);
 
    disp(['Optimal lambda, consistency, regularization: ', num2str([Lambda(index_opt), consistency(index_opt), regularization(index_opt)])])

    figure(get(gcf,'Number')), subplot(1,2,2), semilogx(Lambda, Kappa, 'marker', '*')

    %% closed form solution with optimal lambda

    lambda_L2 = Lambda(index_opt);

    tic
        D_reg = D ./ ( eps + D2 + lambda_L2 * E2 );
        D_regx = ifftn(D_reg .* fftn(nfm_Sharp_lunwrap));
    toc

    chi_L2 = real(D_regx) .* mask_sharp;
    chi_L2 = chi_L2(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3));

    plot_axialSagittalCoronal(chi_L2, [-.15,.15])
    plot_axialSagittalCoronal(fftshift(abs(fftn(chi_L2))).^.5, [0,20], 'L2-kspace')
    
    % Memory cleanup
    clear D_reg

    %% L2-regularized solution with pre-conditionned magnitude weighting
    
    if exist('magn_weight', 'var')
        %            (eps +     (A_frw)        )   - for better memory management
        A_inv = 1 ./ (eps + D2 + lambda_L2 * E2);

        b = D.*fftn(nfm_Sharp_lunwrap);

        precond_inverse = @(x, A_inv) A_inv(:).*x;

        F_chi0 = fftn(D_regx);      % use close-form L2-reg. solution as initial guess

        tic
            [F_chi, ~, pcg_res, pcg_iter] = pcg(@(x) apply_forward(x, D2, lambda_L2, fdx, fdy, fdz, ...
                    conj(fdx), conj(fdy), conj(fdz), magn_weight), b(:), 1e-3, 20, @(x) precond_inverse(x, A_inv), [], F_chi0(:));
        toc

        disp(['PCG iter: ', num2str(pcg_iter), '   PCG residual: ', num2str(pcg_res)])

        Chi = reshape(F_chi, N);

        chi_L2pcg = real(ifftn(Chi)) .* mask_sharp;
        chi_L2pcg = chi_L2pcg(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3));

        plot_axialSagittalCoronal(chi_L2pcg, [-.15,.15], 'L2 Magnitude Weighted')
        plot_axialSagittalCoronal(fftshift(abs(fftn(chi_L2pcg))).^.5, [0,20], 'L2 Magnitude Weighted k-space')
    else
        chi_L2pcg = [];
    end

end
