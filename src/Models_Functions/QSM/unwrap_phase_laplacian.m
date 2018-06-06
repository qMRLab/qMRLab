function unwrappedPhase = unwrap_phase_laplacian(wrappedPhase)
%UNWRAP_PHASE_LAPLACIAN Unwrap phase volume using the Laplacian technique.
%   
%   References:
%   Bilgic et al. (2014), Fast quantitative susceptibility mapping with 
%   L1?regularization and automatic parameter selection. Magn. Reson. Med.,
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

    del_phase = cos(wrappedPhase) .* ifftn( fftn(sin(wrappedPhase)) .* del_op ) - sin(wrappedPhase) .* ifftn( fftn(cos(wrappedPhase)) .* del_op );

    unwrappedPhase = ifftn( fftn(del_phase) .* del_inv );

end
