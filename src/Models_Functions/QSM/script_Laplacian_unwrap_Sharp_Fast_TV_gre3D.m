%% load data

load phase_wrap_gre_3D_p6mm
load mask_gre_3D_p6mm

TE = 8.1e-3;      % second
B0 = 3;          % Tesla
gyro = 2*pi*42.58;

phase_wrap = mask .* phase_wrap;

plot_axialSagittalCoronal(phase_wrap, 1, [-pi, pi], 'Masked, wrapped phase')


%% Zero pad for Sharp kernel convolution

pad_size = [9,9,9];     % pad for Sharp recon

mask_pad = padarray(mask, pad_size);
phase_wrap = padarray(phase_wrap, pad_size);

N = size(mask_pad);


%% Laplacian unwrapping

tic

    ksize = [3, 3, 3];               
    khsize = (ksize-1)/2;

    kernel = [];
    kernel(:,:,1) = [0 0 0; 0 1 0; 0 0 0];
    kernel(:,:,2) = [0 1 0; 1 -6 1; 0 1 0];
    kernel(:,:,3) = [0 0 0; 0 1 0; 0 0 0];

    Kernel = zeros(N);
    Kernel( 1+N(1)/2 - khsize(1) : 1+N(1)/2 + khsize(1), 1+N(2)/2 - khsize(2) : 1+N(2)/2 + khsize(2), 1+N(3)/2 - khsize(3) : 1+N(3)/2 + khsize(3) ) = -kernel;


    del_op = fftn(fftshift(Kernel));
    del_inv = zeros(size(del_op));

    del_inv( del_op~=0 ) = 1 ./ del_op( del_op~=0 );

    del_phase = cos(phase_wrap) .* ifftn( fftn(sin(phase_wrap)) .* del_op ) - sin(phase_wrap) .* ifftn( fftn(cos(phase_wrap)) .* del_op );

    phase_lunwrap = ifftn( fftn(del_phase) .* del_inv );

toc

plot_axialSagittalCoronal(phase_lunwrap, 2, [-3.5,3.5], 'Laplacian unwrapping')


%% Sharp filtering to remove background phase

tic

    ksize = [9, 9, 9];                % Sharp kernel size
    threshold = .05;                  % truncation level

    khsize = (ksize-1)/2;
    [a,b,c] = meshgrid(-khsize(2):khsize(2), -khsize(1):khsize(1), -khsize(3):khsize(3));

    kernel = (a.^2 / khsize(1)^2 + b.^2 / khsize(2)^2 + c.^2 / khsize(3)^2 ) <= 1;
    kernel = -kernel / sum(kernel(:));
    kernel(khsize(1)+1,khsize(2)+1,khsize(3)+1) = 1 + kernel(khsize(1)+1,khsize(2)+1,khsize(3)+1);

    Kernel = zeros(N);
    Kernel( 1+N(1)/2 - khsize(1) : 1+N(1)/2 + khsize(1), 1+N(2)/2 - khsize(2) : 1+N(2)/2 + khsize(2), 1+N(3)/2 - khsize(3) : 1+N(3)/2 + khsize(3) ) = -kernel;

    del_sharp = fftn(fftshift(Kernel));
    delsharp_inv = zeros(size(del_sharp));
    delsharp_inv( abs(del_sharp) > threshold ) = 1 ./ del_sharp( abs(del_sharp) > threshold );


    % erode mask to remove convolution artifacts
    erode_size = ksize + 1;

    mask_sharp = imerode(mask_pad, strel('line', erode_size(1), 0));
    mask_sharp = imerode(mask_sharp, strel('line', erode_size(2), 90));
    mask_sharp = permute(mask_sharp, [1,3,2]);
    mask_sharp = imerode(mask_sharp, strel('line', erode_size(3), 0));
    mask_sharp = permute(mask_sharp, [1,3,2]);


    % apply Sharp to Laplacian wrapped phase

    phase_del_lunwrap = ifftn(fftn(phase_lunwrap) .* del_sharp) .* mask_sharp;
    phase_Sharp_lunwrap = real( ifftn(fftn(phase_del_lunwrap) .* delsharp_inv) .* mask_sharp );

    nfm_Sharp_lunwrap = phase_Sharp_lunwrap / (B0 * gyro * TE);

toc

plot_axialSagittalCoronal(nfm_Sharp_lunwrap, 3, [-.05,.05] )



%% plot L-curve for L2-regularized recon

[k2,k1,k3] = meshgrid(0:N(2)-1, 0:N(1)-1, 0:N(3)-1);
fdx = 1 - exp(-2*pi*1i*k1/N(1));
fdy = 1 - exp(-2*pi*1i*k2/N(2));
fdz = 1 - exp(-2*pi*1i*k3/N(3));

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

figure(4), subplot(1,2,1), plot(consistency, regularization, 'marker', '*')


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

figure(4), subplot(1,2,2), semilogx(Lambda, Kappa, 'marker', '*')


%% closed form solution with optimal lambda

lambda_L2 = Lambda(index_opt);

tic
    D_reg = D ./ ( eps + abs(D).^2 + lambda_L2 *( abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2 ) );
    D_regx = ifftn(D_reg .* fftn(nfm_Sharp_lunwrap));
toc


chi_L2 = real(D_regx) .* mask_sharp;
chi_L2 = chi_L2(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3));

plot_axialSagittalCoronal(chi_L2, 1, [-.15,.15])


%% Determine SB lambda using L-curve and fix mu at lambda_L2


mu = lambda_L2;         % Gradient consistency => pick from L2-closed form recon
                        % since the first iteration gives L2 recon    

[k2,k1,k3] = meshgrid(0:N(2)-1, 0:N(1)-1, 0:N(3)-1);
fdx = 1 - exp(-2*pi*1i*k1/N(1));
fdy = 1 - exp(-2*pi*1i*k2/N(2));
fdz = 1 - exp(-2*pi*1i*k3/N(3));

cfdx = conj(fdx);           cfdy = conj(fdy);          cfdz = conj(fdz);

E2 = abs(fdx).^2 + abs(fdy).^2 + abs(fdz).^2;
D2 = abs(D).^2;

SB_reg = 1 ./ (eps + D2 + mu * E2);

DFy = conj(D) .* fftn(nfm_Sharp_lunwrap);

Lambda = logspace(-4, -2.5, 15);


SB_consistency = zeros(size(Lambda));
SB_regularization = zeros(size(Lambda));

    
tic
for h = 1:length(Lambda)

    threshold = Lambda(h)/mu;

    vx = zeros(N);          vy = zeros(N);          vz = zeros(N);
    nx = zeros(N);          ny = zeros(N);          nz = zeros(N);
    Fu = zeros(N);

    for t = 1:10
        
        Fu_prev = Fu;
        Fu = ( DFy + mu * (cfdx.*fftn(vx - nx) + cfdy.*fftn(vy - ny) + cfdz.*fftn(vz - nz)) ) .* SB_reg;

        Rxu = ifftn(fdx .*  Fu);
        Ryu = ifftn(fdy .*  Fu);
        Rzu = ifftn(fdz .*  Fu);

        rox = Rxu + nx;         roy = Ryu + ny;          roz = Rzu + nz;

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


figure(5), subplot(1,2,1), plot(SB_consistency, SB_regularization, 'marker', '*'), axis square


% cubic spline differentiation to find Kappa (largest curvature) 

eta = log(SB_regularization);
rho = log(SB_consistency.^2);

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
disp(['Optimal lambda, consistency, regularization: ', num2str([Lambda(index_opt), SB_consistency(index_opt), SB_regularization(index_opt)])])

figure(5), subplot(1,2,2), semilogx(Lambda, Kappa, 'marker', '*'), axis tight

lambda_L1 = Lambda(index_opt);



%% Split Bregman QSM


lambda = lambda_L1;     % L1 penalty

mu = lambda_L2;         % Gradient consistency => pick from L2-closed form recon
                        % since the first iteration gives L2 recon    
                        
threshold = lambda/mu;


cfdx = conj(fdx);           cfdy = conj(fdy);          cfdz = conj(fdz);

DFy = conj(D) .* fftn(nfm_Sharp_lunwrap);

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
    
plot_axialSagittalCoronal(chi_SB, 2, [-.15,.15])


%% plot max intensity projections for L1, L2 and phase images

scale1 = [0,.37];
figure(10), subplot(1,3,1), imagesc(max(chi_SB, [], 3), scale1), colormap gray, axis image off   
figure(10), subplot(1,3,2), imagesc(imrotate(squeeze(max(chi_SB, [], 2)), 90), scale1), colormap gray, axis square off
figure(10), subplot(1,3,3), imagesc(imrotate(squeeze(max(chi_SB, [], 1)), 90), scale1), colormap hot, axis square off

scale2 = [0,.37];
figure(11), subplot(1,3,1), imagesc(max(chi_L2, [], 3), scale2), colormap gray, axis image off
figure(11), subplot(1,3,2), imagesc(imrotate(squeeze(max(chi_L2, [], 2)), 90), scale2), colormap gray, axis square off
figure(11), subplot(1,3,3), imagesc(imrotate(squeeze(max(chi_L2, [], 1)), 90), scale2), colormap hot, axis square off

scale3 = [0,.18];
nfm_disp = abs(nfm_Sharp_lunwrap(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3)));
figure(12), subplot(1,3,1), imagesc(max(nfm_disp, [], 3), scale3), colormap gray, axis image off
figure(12), subplot(1,3,2), imagesc(imrotate(squeeze(max(nfm_disp, [], 2)), 90), scale3), colormap gray, axis square off
figure(12), subplot(1,3,3), imagesc(imrotate(squeeze(max(nfm_disp, [], 1)), 90), scale3), colormap hot, axis square off



%% k-space picture of L1 and L2 recons

kspace_L1 = log( fftshift(abs(fftn(chi_SB))) );
kspace_L2 = log( fftshift(abs(fftn(chi_L2))) );
kspace_nfm = log( fftshift(abs(fftn(nfm_Sharp_lunwrap))) );


scale_log = [2, 7.5];
scale_nfm = [2, 6.5];


figure(13), subplot(1,3,1), imagesc( kspace_L1(:,:,1+end/2), scale_log ), axis square off, colormap gray
figure(13), subplot(1,3,2), imagesc( squeeze(kspace_L1(:,1+end/2,:)), scale_log ), axis square off, colormap gray
figure(13), subplot(1,3,3), imagesc( squeeze(kspace_L1(1+end/2,:,:)), scale_log ), axis square off, colormap gray

figure(14), subplot(1,3,1), imagesc( kspace_L2(:,:,1+end/2), scale_log ), axis square off, colormap gray
figure(14), subplot(1,3,2), imagesc( squeeze(kspace_L2(:,1+end/2,:)), scale_log ), axis square off, colormap gray
figure(14), subplot(1,3,3), imagesc( squeeze(kspace_L2(1+end/2,:,:)), scale_log ), axis square off, colormap gray

figure(15), subplot(1,3,1), imagesc( kspace_nfm(:,:,1+end/2), scale_nfm ), axis square off, colormap gray
figure(15), subplot(1,3,2), imagesc( squeeze(kspace_nfm(:,1+end/2,:)), scale_nfm ), axis square off, colormap gray
figure(15), subplot(1,3,3), imagesc( squeeze(kspace_nfm(1+end/2,:,:)), scale_nfm), axis square off, colormap gray


