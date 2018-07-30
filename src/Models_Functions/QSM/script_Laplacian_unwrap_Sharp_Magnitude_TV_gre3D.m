%% load data

load magn_gre_3D_p6mm
load phase_wrap_gre_3D_p6mm
load mask_gre_3D_p6mm

TE = 8.1e-3;      % second
B0 = 3;           % Tesla
gyro = 2*pi*42.58;

directionFlag = 'backward';

phase_wrap = mask .* phase_wrap;

plot_axialSagittalCoronal(phase_wrap, [-pi, pi], 'Masked, wrapped phase')
plot_axialSagittalCoronal(magn, [0, 500], 'Magnitude')

%% Zero pad for Sharp kernel convolution

pad_size = [9,9,9];     % pad for Sharp recon
                        % MB: Investigate why 9 zeros for each dimension?
phase_wrap_pad = pad_volume_for_sharp(phase_wrap, pad_size);
mask_pad = pad_volume_for_sharp(mask, pad_size);

N = size(mask_pad);

%% Laplacian unwrapping

tic
phase_lunwrap = unwrap_phase_laplacian(phase_wrap_pad);
toc

plot_axialSagittalCoronal(phase_lunwrap, [-3.5,3.5], 'Laplacian unwrapping')

%% recursive filtering with decreasing filter sizes

tic
[nfm_Sharp_lunwrap, mask_sharp] = background_removal_sharp(phase_lunwrap, mask_pad, [TE B0 gyro], 'iterative');
toc

plot_axialSagittalCoronal(nfm_Sharp_lunwrap, [-.05,.05] )

%% gradient masks from magnitude image using k-space gradients

[fdx, fdy, fdz] = calc_fdr(N, directionFlag);

magn_pad = padarray(magn, pad_size) .* mask_sharp;
magn_pad = magn_pad / max(magn_pad(:));

Magn = fftn(magn_pad);
magn_grad = cat(4, ifftn(Magn.*fdx), ifftn(Magn.*fdy), ifftn(Magn.*fdz));

magn_weight = zeros(size(magn_grad));

for s = 1:size(magn_grad,4)
    magn_use = abs(magn_grad(:,:,:,s));
    
    magn_order = sort(magn_use(mask_sharp==1), 'descend');
    magn_threshold = magn_order( round(length(magn_order) * .3) );
    magn_weight(:,:,:,s) = magn_use <= magn_threshold;

    plot_axialSagittalCoronal(magn_weight(:,:,:,s), [0,.1], '')
end

%% plot L-curve for L2-regularized recon

FOV = N .* [.6, .6, .6];  % (in milimeters)

D = fftshift(kspace_kernel(FOV, N));

E2 = abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2; 
D2 = abs(D).^2;

Nfm_pad = fftn(nfm_Sharp_lunwrap);

Lambda = logspace(-3, 0, 15);


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

figure(), plot(consistency, regularization, 'marker', '*')


% cubic spline differentiation to find Kappa (largest curvature) 

eta = log(regularization.^2);
rho = log(consistency.^2);

M = [0 3 0 0;0 0 2 0;0 0 0 1;0 0 0 0];

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
disp(['Optimal lambda, consistency, regularization: ', num2str([Lambda(index_opt), consistency(index_opt), regularization(index_opt)])])

figure(), semilogx(Lambda, Kappa, 'marker', '*')

%% closed form L2-regularized solution with optimal lambda

lambda_L2 = Lambda(index_opt);

tic
    D_reg = D ./ ( eps + D2 + lambda_L2 * E2 );
    D_regx = ifftn(D_reg .* fftn(nfm_Sharp_lunwrap));
toc


chi_L2 = real(D_regx) .* mask_sharp;
chi_L2 = chi_L2(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3));

plot_axialSagittalCoronal(chi_L2, [-.15,.15], 'L2-QSM')
plot_axialSagittalCoronal(fftshift(abs(fftn(chi_L2))).^.5, [0,20], 'L2-kspace')


%% L2-regularized solution with magnitude weighting

A_frw = D2 + lambda_L2 * E2;
A_inv = 1 ./ (eps + A_frw);

b = D.*fftn(nfm_Sharp_lunwrap);

precond_inverse = @(x, A_inv) A_inv(:).*x;

F_chi0 = fftn(D_regx);      % use close-form L2-reg. solution as initial guess


tic
    [F_chi, flag, pcg_res, pcg_iter] = pcg(@(x) apply_forward(x, D2, lambda_L2, fdx, fdy, fdz, ...
            conj(fdx), conj(fdy), conj(fdz), magn_weight), b(:), 1e-3, 20, @(x) precond_inverse(x, A_inv), [], F_chi0(:));
toc

disp(['PCG iter: ', num2str(pcg_iter), '   PCG residual: ', num2str(pcg_res)])


Chi = reshape(F_chi, N);

chi_L2pcg = real(ifftn(Chi)) .* mask_sharp;
chi_L2pcg = chi_L2pcg(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3));

plot_axialSagittalCoronal(chi_L2pcg, [-.15,.15], 'L2 Magnitude Weighted')
plot_axialSagittalCoronal(fftshift(abs(fftn(chi_L2pcg))).^.5, [0,20], 'L2 Magnitude Weighted k-space')

%% Determine SB lambda using L-curve and fix mu at lambda_L2

lambda_L1 = calc_SB_lambda_L1(nfm_Sharp_lunwrap, lambda_L2, FOV, directionFlag);

%% Split Bregman QSM

chi_SB = qsm_split_bregman(nfm_Sharp_lunwrap, mask_sharp, lambda_L1, lambda_L2, directionFlag, FOV, pad_size);

plot_axialSagittalCoronal(chi_SB, [-.15,.15], 'L1 solution')
plot_axialSagittalCoronal(fftshift(abs(fftn(chi_SB))).^.5, [0,20], 'L1 solution k-space')

%% Split Bregman QSM with preconditioner and magnitude weighting

preconMagWeightFlag = 1;
chi_SBM = qsm_split_bregman(nfm_Sharp_lunwrap, mask_sharp, lambda_L1, lambda_L2, directionFlag, FOV, pad_size, preconMagWeightFlag, magn_weight);

plot_axialSagittalCoronal(chi_SBM, [-.15,.15], 'L1 solution with magnitude weighting')
plot_axialSagittalCoronal(fftshift(abs(fftn(chi_SBM))).^.5, [0,20], 'L1 magn weighting k-space')

%% plot max intensity projections for L1, L2 and phase images

scale1 = [0,.37];
figure(), subplot(1,3,1), imagesc(max(chi_SB, [], 3), scale1), colormap gray, axis image off   
figure(get(gcf,'Number')), subplot(1,3,2), imagesc(imrotate(squeeze(max(chi_SB, [], 2)), 90), scale1), colormap gray, axis square off
figure(get(gcf,'Number')), subplot(1,3,3), imagesc(imrotate(squeeze(max(chi_SB, [], 1)), 90), scale1), colormap hot, axis square off

scale2 = [0,.37];
figure(), subplot(1,3,1), imagesc(max(chi_SBM, [], 3), scale2), colormap gray, axis image off   
figure(get(gcf,'Number')), subplot(1,3,2), imagesc(imrotate(squeeze(max(chi_SBM, [], 2)), 90), scale2), colormap gray, axis square off
figure(get(gcf,'Number')), subplot(1,3,3), imagesc(imrotate(squeeze(max(chi_SBM, [], 1)), 90), scale2), colormap hot, axis square off

scale3 = [0,.37];
figure(), subplot(1,3,1), imagesc(max(chi_L2, [], 3), scale3), colormap gray, axis image off
figure(get(gcf,'Number')), subplot(1,3,2), imagesc(imrotate(squeeze(max(chi_L2, [], 2)), 90), scale3), colormap gray, axis square off
figure(get(gcf,'Number')), subplot(1,3,3), imagesc(imrotate(squeeze(max(chi_L2, [], 1)), 90), scale3), colormap hot, axis square off

scale4 = [0,.37];
figure(), subplot(1,3,1), imagesc(max(chi_L2pcg, [], 3), scale4), colormap gray, axis image off
figure(get(gcf,'Number')), subplot(1,3,2), imagesc(imrotate(squeeze(max(chi_L2pcg, [], 2)), 90), scale4), colormap gray, axis square off
figure(get(gcf,'Number')), subplot(1,3,3), imagesc(imrotate(squeeze(max(chi_L2pcg, [], 1)), 90), scale4), colormap hot, axis square off

scale5 = [0,.18];
nfm_disp = abs(nfm_Sharp_lunwrap(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3)));
figure(), subplot(1,3,1), imagesc(max(nfm_disp, [], 3), scale5), colormap gray, axis image off
figure(get(gcf,'Number')), subplot(1,3,2), imagesc(imrotate(squeeze(max(nfm_disp, [], 2)), 90), scale5), colormap gray, axis square off
figure(get(gcf,'Number')), subplot(1,3,3), imagesc(imrotate(squeeze(max(nfm_disp, [], 1)), 90), scale5), colormap hot, axis square off

%% k-space picture of L1 and L2 recons

kspace_L1 = log( fftshift(abs(fftn(chi_SB))) );
kspace_L2 = log( fftshift(abs(fftn(chi_L2))) );
kspace_L1M = log( fftshift(abs(fftn(chi_SBM))) );
kspace_L2M = log( fftshift(abs(fftn(chi_L2pcg))) );
kspace_nfm = log( fftshift(abs(fftn(nfm_Sharp_lunwrap))) );

scale_log = [2, 7.5];
scale_nfm = [2, 6.5];


figure(), subplot(1,3,1), imagesc( kspace_L1(:,:,1+end/2), scale_log ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,2), imagesc( squeeze(kspace_L1(:,1+end/2,:)), scale_log ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,3), imagesc( squeeze(kspace_L1(1+end/2,:,:)), scale_log ), axis square off, colormap gray

figure(), subplot(1,3,1), imagesc( kspace_L1M(:,:,1+end/2), scale_log ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,2), imagesc( squeeze(kspace_L1M(:,1+end/2,:)), scale_log ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,3), imagesc( squeeze(kspace_L1M(1+end/2,:,:)), scale_log ), axis square off, colormap gray

figure(), subplot(1,3,1), imagesc( kspace_L2(:,:,1+end/2), scale_log ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,2), imagesc( squeeze(kspace_L2(:,1+end/2,:)), scale_log ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,3), imagesc( squeeze(kspace_L2(1+end/2,:,:)), scale_log ), axis square off, colormap gray

figure(), subplot(1,3,1), imagesc( kspace_L2M(:,:,1+end/2), scale_log ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,2), imagesc( squeeze(kspace_L2M(:,1+end/2,:)), scale_log ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,3), imagesc( squeeze(kspace_L2M(1+end/2,:,:)), scale_log ), axis square off, colormap gray

figure(), subplot(1,3,1), imagesc( kspace_nfm(:,:,1+end/2), scale_nfm ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,2), imagesc( squeeze(kspace_nfm(:,1+end/2,:)), scale_nfm ), axis square off, colormap gray
figure(get(gcf,'Number')), subplot(1,3,3), imagesc( squeeze(kspace_nfm(1+end/2,:,:)), scale_nfm), axis square off, colormap gray
