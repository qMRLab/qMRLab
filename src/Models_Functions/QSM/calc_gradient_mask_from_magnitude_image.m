function [ magn_weight ] = calc_gradient_mask_from_magnitude_image(magn, mask_sharp, pad_size, directionFlag)
%CALC_GRADIENT_MASK_FROM_MAGNITUDE_IMAGE Calculate gradient masks from 
%magnitude image using k-space gradients
%   magn: Volume of magnitude data
%   mask_sharp: Mask volume (output of SHARP processing)
%   pad_size: Image padding size
%

    N = size(mask_sharp);

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

end
