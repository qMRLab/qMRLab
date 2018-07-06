function [fdx, fdy, fdz] = calc_fdr(N)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

    [k2,k1,k3] = meshgrid(0:N(2)-1, 0:N(1)-1, 0:N(3)-1);
    fdx = 1 - exp(-2*pi*1i*k1/N(1));
    fdy = 1 - exp(-2*pi*1i*k2/N(2));
    fdz = 1 - exp(-2*pi*1i*k3/N(3));

end

