function [ magn_weight ] = calcGradientMaskFromMagnitudeImage(magn, mask_sharp, pad_size, directionFlag)
%CALCGRADIENTMASKFROMMAGNITUDEplot_axialSagittalCoronalIMAGE Calculate gradient masks from 
%magnitude image using k-space gradients
%   magn: Volume of magnitude data
%   mask_sharp: Mask volume (output of SHARP processing)
%   pad_size: Image padding size
%
%   Code refractored from Berkin Bilgic's scripts: "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m" 
%   and "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m"
%   Original source: https://martinos.org/~berkin/software.html
%
%   Original reference:
%   Bilgic et al. (2014), Fast quantitative susceptibility mapping with 
%   L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%   72: 1444-1459. doi:10.1002/mrm.25029

    N = size(mask_sharp);

    [fdx, fdy, fdz] = calcFdr(N, directionFlag);

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

    end

end
