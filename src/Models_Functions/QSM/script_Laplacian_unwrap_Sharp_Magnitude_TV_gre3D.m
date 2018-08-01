%% Load Data

load phase_wrap_gre_3D_p6mm
load mask_gre_3D_p6mm
load magn_gre_3D_p6mm

%% Configure measurement parameters

imageResolution = [0.6, 0.6, 0.6]; % (in mm)
TE = 8.1e-3;      % second
B0 = 3;           % Tesla
gyro = 2*pi*42.58;

%% Configure algorithm processing parameters

pad_size = [9,9,9];     % pad for Sharp recon
                        % MB: Investigate why 9 zeros for each dimension?
directionFlag = 'backward';
preconMagWeightFlag = 1;

%% Mask wrapped phase

phase_wrap = mask .* phase_wrap;

plot_axialSagittalCoronal(phase_wrap, [-pi, pi], 'Masked, wrapped phase')
plot_axialSagittalCoronal(magn, [0, 500], 'Magnitude')

%% Zero pad for Sharp kernel convolution

phase_wrap_pad = pad_volume_for_sharp(phase_wrap, pad_size);
mask_pad = pad_volume_for_sharp(mask, pad_size);

N = size(mask_pad);

%% Laplacian unwrapping

tic
phase_lunwrap = unwrap_phase_laplacian(phase_wrap_pad);
toc

plot_axialSagittalCoronal(phase_lunwrap, [-3.5,3.5], 'Laplacian unwrapping')

% Memory cleanup
clear mask phase_wrap phase_wrap_pad

%% recursive filtering with decreasing filter sizes

tic
[nfm_Sharp_lunwrap, mask_sharp] = background_removal_sharp(phase_lunwrap, mask_pad, [TE B0 gyro], 'iterative');
toc

plot_axialSagittalCoronal(nfm_Sharp_lunwrap, [-.05,.05] )

% Memory cleanup
clear mask_pad phase_lunwrap

%% gradient masks from magnitude image using k-space gradients

[ magn_weight ] = calc_gradient_mask_from_magnitude_image(magn, mask_sharp, pad_size, directionFlag);

% Memory cleanup
clear magn

%% Determine optimal Lambda L2

[ lambda_L2, chi_L2, chi_L2pcg ] = calc_lambda_L2(nfm_Sharp_lunwrap, mask_sharp, imageResolution, directionFlag, pad_size, magn_weight);

%% Determine SB lambda using L-curve and fix mu at lambda_L2

lambda_L1 = calc_SB_lambda_L1(nfm_Sharp_lunwrap, lambda_L2, imageResolution, directionFlag);

%% Split Bregman QSM

chi_SB = qsm_split_bregman(nfm_Sharp_lunwrap, mask_sharp, lambda_L1, lambda_L2, directionFlag, imageResolution, pad_size, 0);

plot_axialSagittalCoronal(chi_SB, [-.15,.15], 'L1 solution')
plot_axialSagittalCoronal(fftshift(abs(fftn(chi_SB))).^.5, [0,20], 'L1 solution k-space')

%% Split Bregman QSM with preconditioner and magnitude weighting

chi_SBM = qsm_split_bregman(nfm_Sharp_lunwrap, mask_sharp, lambda_L1, lambda_L2, directionFlag, imageResolution, pad_size, preconMagWeightFlag, magn_weight);

plot_axialSagittalCoronal(chi_SBM, [-.15,.15], 'L1 solution with magnitude weighting')
plot_axialSagittalCoronal(fftshift(abs(fftn(chi_SBM))).^.5, [0,20], 'L1 magn weighting k-space')

%% plot max intensity projections for L1, L2 and phase images

nfm_disp = abs(nfm_Sharp_lunwrap(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3)));

plot_max_intensity_projections({chi_SB, chi_SBM, chi_L2, chi_L2pcg, nfm_disp}, {[0, 0.37], [0, 0.37], [0, 0.37], [0, 0.37], [0, 0.18]})

%% k-space picture of L1 and L2 recons

kspace_L1 = log( fftshift(abs(fftn(chi_SB))) );
kspace_L2 = log( fftshift(abs(fftn(chi_L2))) );
kspace_L1M = log( fftshift(abs(fftn(chi_SBM))) );
kspace_L2M = log( fftshift(abs(fftn(chi_L2pcg))) );
kspace_nfm = log( fftshift(abs(fftn(nfm_Sharp_lunwrap))) );

plot_kspace_volumes({kspace_L1, kspace_L1M, kspace_L2, kspace_L2M, kspace_nfm}, {[2, 7.5], [2, 7.5], [2, 7.5], [2, 7.5], [2, 6.5]})
