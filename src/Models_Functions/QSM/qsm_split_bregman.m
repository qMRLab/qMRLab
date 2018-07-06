function chi_SB = qsm_split_bregman(nfm_Sharp_lunwrap, mask_sharp, lambda_L1, lambda_L2, FOV, pad_size)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

    lambda = lambda_L1;     % L1 penalty

    mu = lambda_L2;         % Gradient consistency => pick from L2-closed form recon
                            % since the first iteration gives L2 recon    

    threshold = lambda/mu;

    N = size(mask_sharp);

    [fdx, fdy, fdz] = calc_fdr(N);

    cfdx = conj(fdx);           cfdy = conj(fdy);          cfdz = conj(fdz);

    D = fftshift(kspace_kernel(FOV, N));
    DFy = conj(D) .* fftn(nfm_Sharp_lunwrap);

    E2 = abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2;
    D2 = abs(D).^2;

    SB_reg = 1 ./ (eps + D2 + mu * E2);

    vx = zeros(N);          vy = zeros(N);          vz = zeros(N);
    nx = zeros(N);          ny = zeros(N);          nz = zeros(N);
    Fu = zeros(N);


    tic
    for t = 1:20

        Fu_prev = Fu;

        Fu = ( DFy + mu * (cfdx.*fftn(vx - nx) + cfdy.*fftn(vy - ny) + cfdz.*fftn(vz - nz)) ) .* SB_reg;

        Rxu = ifftn(fdx .*  Fu);    Ryu = ifftn(fdy .*  Fu);    Rzu = ifftn(fdz .*  Fu);

        rox = Rxu + nx;    roy = Ryu + ny;    roz = Rzu + nz;

        vx = max(abs(rox) - threshold, 0) .* sign(rox);
        vy = max(abs(roy) - threshold, 0) .* sign(roy);
        vz = max(abs(roz) - threshold, 0) .* sign(roz);

        nx = rox - vx;     ny = roy - vy;     nz = roz - vz; 

        res_change = 100 * norm(Fu(:) - Fu_prev(:)) / norm(Fu(:));
        disp(['Iteration  ', num2str(t), '  ->  Change in Chi: ', num2str(res_change), ' %'])

        if res_change < 1
            break
        end

    end
    toc

    chi_sb = ifftn(Fu) .* mask_sharp;
    chi_SB = real( chi_sb(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3)) ) ;

end

