function [fdx, fdy, fdz] = calcFdr(N, directionFlag)
%CALCFDR Function who's
%diagonals are the k-space representation of the image-domain differencing
%operator. See "vx" in the reference below.
%
%   N: Size of volume
%   directionFlag: 'forward' or 'backward', direction of the
%   differentiation.
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

    [k2,k1,k3] = meshgrid(0:N(2)-1, 0:N(1)-1, 0:N(3)-1);

    switch directionFlag
        case 'forward'
            fdx = 1 - exp(-2*pi*1i*k1/N(1));
            fdy = 1 - exp(-2*pi*1i*k2/N(2));
            fdz = 1 - exp(-2*pi*1i*k3/N(3));
        case 'backward'
            fdx = -1 + exp(2*pi*1i*k1/N(1));
            fdy = -1 + exp(2*pi*1i*k2/N(2));
            fdz = -1 + exp(2*pi*1i*k3/N(3));
    end

end
