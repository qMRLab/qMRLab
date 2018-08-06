function [chi_SB, chi_L2, chi_L2pcg, nfm_disp] = qsm_gre_exec(data, PhaseParams, Opt)

% MagnGRE is an optional field 

if not(isempty(data.MagnGRE))
   
    magnFlag = 1;
    disp('MagnFlag triggered')
    magn = data.MagnGRE;
    
else
    
    magnFlag = 0;
    
end

%% Decompose data and params

phase_wrap = data.PhaseGRE;
mask = data.Mask; 

TE = PhaseParams(1);
B0 = PhaseParams(5);
imageResolution = PhaseParams(2:4); 

%% Mask 

phase_wrap = mask .* phase_wrap;

%% Zero pad for Sharp kernel convolution
disp(['Padding mask and phase with ' num2str(Opt.pad_size)]);

phase_wrap_pad = padVolumeForSharp(phase_wrap, Opt.pad_size);
mask_pad = padVolumeForSharp(mask, Opt.pad_size);

N = size(mask_pad);

%% Laplacian unwrapping
disp('Unwrapping phase using Laplacian technique...')

tic
phase_lunwrap = unwrapPhaseLaplacian(phase_wrap_pad);
toc

% Memory cleanup
clear mask phase_wrap phase_wrap_pad
%% Background filtering
disp('Running SHARP backgrond removal...')

tic
[nfm_Sharp_lunwrap, mask_sharp] = backgroundRemovalSharp(phase_lunwrap, mask_pad, [TE B0 Opt.gyro], Opt.sharp_mode);
toc


%%  Determine optimal lambda L2

if magnFlag
    
    [ magn_weight ] = calcGradientMaskFromMagnitudeImage(magn, mask_sharp, Opt.pad_size, Opt.direction);

    [ lambda_L2, chi_L2, chi_L2pcg ] = calcLambdaL2(nfm_Sharp_lunwrap, mask_sharp, Opt.lambdaL2Range, imageResolution, Opt.direction, Opt.pad_size, magn_weight);

else
    
    [ lambda_L2, chi_L2 ] = calcLambdaL2(nfm_Sharp_lunwrap, mask_sharp, Opt.lambdaL2Range, imageResolution, Opt.direction, Opt.pad_size);
    chi_L2pcg = [];
end
%% Determine SB lambda L1 using L-curve and fix mu at lambda_L2

lambda_L1 = calcSBLambdaL1(nfm_Sharp_lunwrap, Opt.lambdaL1Range, lambda_L2, imageResolution, Opt.direction);

%% Split Bregman QSM

if magnFlag
 
 disp('Running Bregman QSM with magnitude weighting...');   
 chi_SB = qsmSplitBregman(nfm_Sharp_lunwrap, mask_sharp, lambda_L1, lambda_L2, Opt.direction, imageResolution, Opt.pad_size, magnFlag, magn_weight);


else
  
  disp('Running Bregman QSM without magnitude weighting...');     
  chi_SB = qsmSplitBregman(nfm_Sharp_lunwrap, mask_sharp, lambda_L1, lambda_L2, Opt.direction, imageResolution, Opt.pad_size, magnFlag);  
    
end

%% plot max intensity projections for L1, L2 and phase images

nfm_disp = abs(nfm_Sharp_lunwrap(1+pad_size(1):end-pad_size(1),1+pad_size(2):end-pad_size(2),1+pad_size(3):end-pad_size(3)));

end