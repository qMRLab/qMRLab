function unwrappedPhase = unwrapPhaseLaplacian(wrappedPhase)
%UNWRAPPHASELAPLACIAN Unwrap phase volume using the Laplacian technique.
%   
%   Laplacians and inverse Laplacians in this algorithm are calculated
%   using the discrete Laplacian operator (for convolutions) as well as the
%   convolution theorem.
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
%   Li et al. (2012), Magnetic susceptibility anisotropy of human brain in
%   vivo and its molecular underpinnings, NeuroImage, 59:2088-2097,
%   doi.org/10.1016/j.neuroimage.2011.10.038.   
%   
%   ... which references:
%
%   Li et al. (2011), Quantitative susceptibility mapping of human brain
%   reflects spatial variation in tissue composition, NeuroImage,
%   55:1645-1656, doi.org/10.1016/j.neuroimage.2010.11.088.
%
%   .... which finally references:
%
%   Schofield and Zhu (2003), Fast phase unwrapping algorithm for 
%   interferometric applications, Opt. Lett.,  28:1194-1196. 

    N = size(wrappedPhase);
    
    % Kernel size (and difference "h" size)
    ksize = [3, 3, 3];               
    khsize = (ksize-1)/2;

    % Discrete Laplacian operator 
    kernel = [];
    kernel(:,:,1) = [0  0  0; ...
                     0  1  0; ...
                     0  0  0];
    
    kernel(:,:,2) = [0  1  0; ...
                     1 -6  1;... 
                     0  1  0];

    kernel(:,:,3) = [0  0  0; ...
                     0  1  0; ...
                     0  0  0];
    % See wiki for 1D and 2D filters: https://en.wikipedia.org/wiki/Discrete_Laplace_operator#Implementation_via_operator_discretization

    % Extend kernel to image size for use by convolution theorem (need to
    % be same dimension as the volume, as the FT of it will be multiplied
    % voxel-wise, unlike the convolution operation.
    Kernel = zeros(N);
    Kernel( 1+N(1)/2 - khsize(1) : 1+N(1)/2 + khsize(1), ...
            1+N(2)/2 - khsize(2) : 1+N(2)/2 + khsize(2), ...
            1+N(3)/2 - khsize(3) : 1+N(3)/2 + khsize(3) )        = -kernel; % MB: Why the negative of the kernel?

    % FFT of the discrete Laplacian operator
    del_op = fftn(fftshift(Kernel));

    % FFT of the inverse of the discrete Laplacian operator
    del_inv = zeros(size(del_op));
    del_inv( del_op~=0 ) = 1 ./ del_op( del_op~=0 ); % MB: It appears that the indexing here is not necessary. I tested it without it using Berkin's sample dataset, and it results in the same matrix with or without the indexing.

    % The next equation is from Schofield 2003, p.1194, column 2, paragraph
    % 3, line 10. Except here the Laplacian are numerically calculated by
    % using the convolution theorem.
    del_phase = cos(wrappedPhase) .* ifftn( fftn(sin(wrappedPhase)) .* del_op ) - sin(wrappedPhase) .* ifftn( fftn(cos(wrappedPhase)) .* del_op );

    % Unwrapped phase numerically caluculated by using the convolution
    % theorem.
    unwrappedPhase = ifftn( fftn(del_phase) .* del_inv );

end
