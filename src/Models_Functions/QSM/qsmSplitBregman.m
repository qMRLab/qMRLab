function chi_SB = qsmSplitBregman(nfm_Sharp_lunwrap, mask_sharp, lambda_L1, lambda_L2, directionFlag, imageResolution, pad_size, preconMagWeightFlag, magn_weight)
%QSMSPLITBREGMAN Calculates the QSM susceptibility map using a split-Bregman
%algorithm and L1-regularization.
%   
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
%   ... which references:
%
%   Goldstein T, Osher S. The split Bregman method for L1-regularized 
%   problems. SIAM J Imaging Sci 2009;2:323?343.

    if nargin < 8
       preconMagWeightFlag = 0; 
    end

        
    lambda = lambda_L1;     % L1 penalty

    mu = lambda_L2;         % Gradient consistency => pick from L2-closed form recon
                            % since the first iteration gives L2 recon    

    threshold = lambda/mu;

    N = size(mask_sharp);
    FOV = N .* imageResolution;  % (in milimeters)
    
    [fdx, fdy, fdz] = calcFdr(N, directionFlag);
    
    cfdx = conj(fdx);           cfdy = conj(fdy);          cfdz = conj(fdz);

    D = fftshift(kspaceKernel(FOV, N));
    DFy = conj(D) .* fftn(nfm_Sharp_lunwrap);

    E2 = abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2;
    D2 = abs(D).^2;

    SB_reg = 1 ./ (eps + D2 + mu * E2);

    vx = zeros(N);          vy = zeros(N);          vz = zeros(N);
    nx = zeros(N);          ny = zeros(N);          nz = zeros(N);
    
    if preconMagWeightFlag
        D_reg = D ./ ( eps + abs(D).^2 + lambda_L2 *( abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2 ) );
        D_regx = ifftn(D_reg .* fftn(nfm_Sharp_lunwrap));
        
        Pcg_iter = 0;

        Fu = fftn(D_regx);      % use close-form L2-reg. solution as initial guess

        precond_inverse = @(x,SB_reg) SB_reg(:).*x;
    else
         Fu = zeros(N);
    end

    tic
    for t = 1:20

        Fu_prev = Fu;

        if preconMagWeightFlag
             b = DFy + mu * (cfdx.*fftn( (vx - nx).*magn_weight(:,:,:,1) ) + cfdy.*fftn( (vy - ny).*magn_weight(:,:,:,2) ) + cfdz.*fftn( (vz - nz).*magn_weight(:,:,:,3) ));
    
            % solve A * (Fu) = b with preconditioned cg  
            [Fu, flag, pcg_res, pcg_iter] = pcg(@(x) applyForward( x, D2, mu, fdx, fdy, fdz, cfdx, cfdy, cfdz, magn_weight ), b(:), 1e-2, 10, @(x) precond_inverse(x, SB_reg), [], Fu_prev(:));
    
            Fu = reshape(Fu, N);
    
            Rxu = magn_weight(:,:,:,1) .* ifftn(fdx .*  Fu);    
            Ryu = magn_weight(:,:,:,2) .* ifftn(fdy .*  Fu);    
            Rzu = magn_weight(:,:,:,3) .* ifftn(fdz .*  Fu);
        else
            Fu = ( DFy + mu * (cfdx.*fftn(vx - nx) + cfdy.*fftn(vy - ny) + cfdz.*fftn(vz - nz)) ) .* SB_reg;

            Rxu = ifftn(fdx .*  Fu);    Ryu = ifftn(fdy .*  Fu);    Rzu = ifftn(fdz .*  Fu);
        end

        rox = Rxu + nx;    roy = Ryu + ny;    roz = Rzu + nz;

        vx = max(abs(rox) - threshold, 0) .* sign(rox);
        vy = max(abs(roy) - threshold, 0) .* sign(roy);
        vz = max(abs(roz) - threshold, 0) .* sign(roz);

        nx = rox - vx;     ny = roy - vy;     nz = roz - vz; 

        res_change = 100 * norm(Fu(:) - Fu_prev(:)) / norm(Fu(:));
        
        if preconMagWeightFlag
            Pcg_iter = pcg_iter + Pcg_iter;
            disp(['Iteration  ', num2str(t), '  ->  Change in Chi: ', num2str(res_change), ' %', '    PCG iter: ', num2str(pcg_iter), '   PCG residual: ', num2str(pcg_res)])
        else
            disp(['Iteration  ', num2str(t), '  ->  Change in Chi: ', num2str(res_change), ' %'])
        end

        if res_change < 1
            break
        end

    end
    toc

    chi_sb = ifftn(Fu) .* mask_sharp;
    chi_SB = real( chi_sb(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3)) ) ;
    
    toc
end
