function lambda_L1 = calcSBLambdaL1(nfm_Sharp_lunwrap, Lambda, lambda_L2, imageResolution, directionFlag)
%calcSBLambdaL1 Determine Split-Berman lambda L1 using L-curve and fix mu at lambda_L2
%   nfm_Sharp_lunwrap: Sharp-unwrapped phase
%   Lambda: Range of L1 regularization weights to optimize
%   lambda_L2: L2 regularization term
%   directionFlag: 'forward' or 'backward', direction of the
%   differentiation.
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
    FOV = N .* imageResolution;  % (in milimeters)

    mu = lambda_L2;         % Gradient consistency => pick from L2-closed form recon
                            % since the first iteration gives L2 recon   

    [fdx, fdy, fdz] = calcFdr(N, directionFlag);

    cfdx = conj(fdx);           cfdy = conj(fdy);          cfdz = conj(fdz);

    E2 = abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2;
    
    D = fftshift(kspaceKernel(FOV, N));
    
    D2 = abs(D).^2;

    SB_reg = 1 ./ (eps + D2 + mu * E2);
    
    DFy = conj(D) .* fftn(nfm_Sharp_lunwrap);

    SB_consistency = zeros(size(Lambda));
    SB_regularization = zeros(size(Lambda));

    % Memory cleanup
    clear E2 D2
    
    tic
    for h = 1:length(Lambda)

        threshold = Lambda(h)/mu;

        vx = zeros(N);          vy = zeros(N);          vz = zeros(N);
        nx = zeros(N);          ny = zeros(N);          nz = zeros(N);
        Fu = zeros(N);

        for t = 1:10

            Fu_prev = Fu;
            Fu = ( DFy + mu * (cfdx.*fftn(vx - nx) + cfdy.*fftn(vy - ny) + cfdz.*fftn(vz - nz)) ) .* SB_reg;

            %     (      Rxu      )                     (      Ryu      )                      (      Rzu      )
            rox = ifftn(fdx .*  Fu) + nx;         roy = ifftn(fdy .*  Fu) + ny;          roz = ifftn(fdz .*  Fu) + nz;

            vx = max(abs(rox) - threshold, 0) .* sign(rox);
            vy = max(abs(roy) - threshold, 0) .* sign(roy);
            vz = max(abs(roz) - threshold, 0) .* sign(roz);

            nx = rox - vx;          ny = roy - vy;          nz = roz - vz; 

            res_change = 100 * norm(Fu(:) - Fu_prev(:)) / norm(Fu(:));
            disp(['Change in Chi: ', num2str(res_change), ' %'])

            if res_change < 1
                break
            end
        end

        residual = ifftn(D .* Fu) - nfm_Sharp_lunwrap;
        SB_consistency(h) = norm(residual(:));
        SB_regularization(h) = sum(abs(vx(:))) + sum(abs(vy(:))) + sum(abs(vz(:)));

        disp([num2str(h), ' ->   Lambda: ', num2str(Lambda(h)), '   Consistency: ', num2str(SB_consistency(h)), '   Regularization: ', num2str(SB_regularization(h))])
    end
    toc

    % Memory cleanup
    clear D DFy Fu nfm_Sharp_lunwrap nx ny nz residual rox roy roz vx vy vz

    %figure(), subplot(1,2,1), plot(SB_consistency, SB_regularization, 'marker', '*'), axis square

    % cubic spline differentiation to find Kappa (largest curvature) 

    [index_opt, ~] = findOptimalKappa(Lambda, SB_regularization, SB_consistency, [false true]);
    
    disp(['Optimal lambda, consistency, regularization: ', num2str([Lambda(index_opt), SB_consistency(index_opt), SB_regularization(index_opt)])])

%    figure(get(gcf,'Number')), subplot(1,2,2), semilogx(Lambda, Kappa, 'marker', '*'), axis tight

    lambda_L1 = Lambda(index_opt);

end
