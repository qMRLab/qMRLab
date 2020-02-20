function [nfm_Sharp_lunwrap, mask_sharp] = backgroundRemovalSharp(phase_lunwrap, mask_pad, filterMode)
%BACKGROUNDREMOVALSHARP Background phase removal using SHARP (Sophisticated harmonic artifact reduction for phase data)
%   Code refractored from Berkin Bilgic's scripts: "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m" 
%   and "script_Laplacian_unwrap_Sharp_Fast_TV_gre3D.m"
%   Original source: https://martinos.org/~berkin/software.html
%
%   phase_lunwrap: unwrapped phase volume
%   mask_pad: zero-padded mask volume
%   filterMode: 'once' or 'iterative'
%
%   Original reference: 
%   Bilgic et al. (2014), Fast quantitative susceptibility mapping with 
%   L1-regularization and automatic parameter selection. Magn. Reson. Med.,
%   72: 1444-1459. doi:10.1002/mrm.25029
%
%   ... which references:
%
%   Li W, Wu B, Liu C. Quantitative susceptibility mapping of 
%   human brain reflects spatial variation in tissue composition. 
%   NeuroImage 2011; 55(4): 1645?1656.
%


    if nargin < 4
        filterMode = 'once';
    end
    switch filterMode
        case 'once'
            [nfm_Sharp_lunwrap, mask_sharp] = sharp_once(phase_lunwrap, mask_pad);
        case 'iterative'
            [nfm_Sharp_lunwrap, mask_sharp] = sharp_iterative(phase_lunwrap, mask_pad);
    end

end

function [nfm_Sharp_lunwrap, mask_sharp] = sharp_once(phase_lunwrap, mask_pad)

    N = size(mask_pad);

    ksize = [9, 9, 9];                % Sharp kernel size
    threshold = .05;                  % truncation level

    % calculate del kernel and its inverse
    del_sharp = calc_del_kernel(ksize, N);

    delsharp_inv = zeros(size(del_sharp));
    delsharp_inv( abs(del_sharp) > threshold ) = 1 ./ del_sharp( abs(del_sharp) > threshold );

    % erode mask to remove convolution artifacts
    mask_sharp = erode_mask(mask_pad, ksize);

    % apply Sharp to Laplacian wrapped phase
    phase_del = ifftn(fftn(phase_lunwrap) .* del_sharp);
    Phase_Del = phase_del .* mask_sharp;

    phase_Sharp_lunwrap = real( ifftn(fftn(Phase_Del) .* delsharp_inv) .* mask_sharp );

    nfm_Sharp_lunwrap = phase_Sharp_lunwrap;
end


function [nfm_Sharp_lunwrap, mask_sharp] = sharp_iterative(phase_lunwrap, mask_pad)

    N = size(mask_pad);

    threshold = .05;                     % truncation level

    Kernel_Sizes = 9:-2:3;

    % initiate volumes
    Phase_Del = zeros(N);
    mask_prev = zeros(N);

    for k = 1:length(Kernel_Sizes)

        disp(['Kernel size: ', num2str(Kernel_Sizes(k))])

        Kernel_Size = Kernel_Sizes(k);
        ksize = [Kernel_Size, Kernel_Size, Kernel_Size];                % Sharp kernel size

        % calculate del kernel and its inverse
        del_sharp = calc_del_kernel(ksize, N);

        if k == 1
            delsharp_inv = zeros(size(del_sharp));
            delsharp_inv( abs(del_sharp) > threshold ) = 1 ./ del_sharp( abs(del_sharp) > threshold );
        end

        % erode mask to remove convolution artifacts
        mask_sharp = erode_mask(mask_pad, ksize);

        % apply Sharp to Laplacian unwrapped phase
        phase_del = ifftn(fftn(phase_lunwrap) .* del_sharp);
        Phase_Del = Phase_Del + phase_del .* (mask_sharp - mask_prev);

        mask_prev = mask_sharp;

    end

    phase_Sharp_lunwrap = real( ifftn(fftn(Phase_Del) .* delsharp_inv) .* mask_sharp );
    nfm_Sharp_lunwrap = phase_Sharp_lunwrap;

end

function del_sharp = calc_del_kernel(ksize, N)

    khsize = (ksize-1)/2;
    [a,b,c] = meshgrid(-khsize(2):khsize(2), -khsize(1):khsize(1), -khsize(3):khsize(3));

    kernel = (a.^2 / khsize(1)^2 + b.^2 / khsize(2)^2 + c.^2 / khsize(3)^2 ) <= 1;
    kernel = -kernel / sum(kernel(:));
    kernel(khsize(1)+1,khsize(2)+1,khsize(3)+1) = 1 + kernel(khsize(1)+1,khsize(2)+1,khsize(3)+1);

    Kernel = zeros(N);
    Kernel( 1+N(1)/2 - khsize(1) : 1+N(1)/2 + khsize(1), 1+N(2)/2 - khsize(2) : 1+N(2)/2 + khsize(2), 1+N(3)/2 - khsize(3) : 1+N(3)/2 + khsize(3) ) = -kernel;

    del_sharp = fftn(fftshift(Kernel));

end

function mask_sharp = erode_mask(mask_pad, ksize)

    erode_size = ksize + 1;

    mask_sharp = imerode(mask_pad, strel('line', erode_size(1), 0));
    mask_sharp = imerode(mask_sharp, strel('line', erode_size(2), 90));
    mask_sharp = permute(mask_sharp, [1,3,2]);
    mask_sharp = imerode(mask_sharp, strel('line', erode_size(3), 0));
    mask_sharp = permute(mask_sharp, [1,3,2]);

end