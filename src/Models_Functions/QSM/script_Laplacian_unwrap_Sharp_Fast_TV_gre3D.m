%%
%
%   Code refractored from Berkin Bilgic's scripts: "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m" 
%   and "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m"
%   Original source: https://martinos.org/~berkin/software.html
%
%   Original reference:
%   Bilgic et al. (2014), Fast quantitative susceptibility mapping with 
%   L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%   72: 1444-1459. doi:10.1002/mrm.25029

%% Load Data

load phase_wrap_gre_3D_p6mm
load mask_gre_3D_p6mm

%% Configure measurement parameters

imageResolution = [0.6, 0.6, 0.6]; % (in mm)
TE = 8.1e-3;      % second
B0 = 3;           % Tesla
gyro = 2*pi*42.58;

%% Configure algorithm processing parameters

pad_size = [9,9,9];     % pad for Sharp recon
                        % MB: Investigate why 9 zeros for each dimension?
directionFlag = 'forward';
preconMagWeightFlag = 0;
lambdaL1Range = logspace(-4, -2.5, 15);
lambdaL2Range = logspace(-3, 0, 15);

%% Mask wrapped phase

phase_wrap = mask .* phase_wrap;

plotAxialSagittalCoronal(phase_wrap, [-pi, pi], 'Masked, wrapped phase')

%% Zero pad for Sharp kernel convolution

phase_wrap_pad = padVolumeForSharp(phase_wrap, pad_size);
mask_pad = padVolumeForSharp(mask, pad_size);

N = size(mask_pad);

%% Laplacian unwrapping

tic
phase_lunwrap = unwrapPhaseLaplacian(phase_wrap_pad);
toc

plotAxialSagittalCoronal(phase_lunwrap, [-3.5,3.5], 'Laplacian unwrapping')

% Memory cleanup
clear mask phase_wrap phase_wrap_pad

%% Sharp filtering to remove background phase

tic
[nfm_Sharp_lunwrap, mask_sharp] = backgroundRemovalSharp(phase_lunwrap, mask_pad, [TE B0 gyro], 'once');
toc

plotAxialSagittalCoronal(nfm_Sharp_lunwrap, [-.05,.05] )

% Memory cleanup
clear mask_pad phase_lunwrap

%%  Determine optimal lambda L2

lambda_L2 = calcLambdaL2(nfm_Sharp_lunwrap, lambdaL2Range, imageResolution, directionFlag);

chi_L2 = calcChiL2(nfm_Sharp_lunwrap, lambda_L2, directionFlag, imageResolution, mask_sharp, pad_size);

%% Determine SB lambda L1 using L-curve and fix mu at lambda_L2

lambda_L1 = calcSBLambdaL1(nfm_Sharp_lunwrap, lambdaL1Range, lambda_L2, imageResolution, directionFlag);

%% Split Bregman QSM

chi_SB = qsmSplitBregman(nfm_Sharp_lunwrap, mask_sharp, lambda_L1, lambda_L2, directionFlag, imageResolution, pad_size, preconMagWeightFlag);

plotAxialSagittalCoronal(chi_SB, [-.15,.15], 'L1 solution')
plotAxialSagittalCoronal(fftshift(abs(fftn(chi_SB))).^.5, [0,20], 'L1 solution k-space')

%% plot max intensity projections for L1, L2 and phase images

nfm_disp = abs(nfm_Sharp_lunwrap(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3)));

plotMaxIntensityProjections({chi_SB, chi_L2, nfm_disp}, {[0, 0.37], [0, 0.37], [0, 0.18]})

%% k-space picture of L1 and L2 recons

kspace_L1 = log( fftshift(abs(fftn(chi_SB))) );
kspace_L2 = log( fftshift(abs(fftn(chi_L2))) );
kspace_nfm = log( fftshift(abs(fftn(nfm_Sharp_lunwrap))) );

plotKspaceVolumes({kspace_L1, kspace_L2, kspace_nfm}, {[2, 7.5], [2, 7.5], [2, 6.5]})
