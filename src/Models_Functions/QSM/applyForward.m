function [ y ] = applyForward( X, D2, mu, fdx, fdy, fdz, cfdx, cfdy, cfdz, magn_weight )
%APPLYFORWARD Summary of this function goes here
%   Detailed explanation goes here

x = reshape(X, size(D2));

y = D2 .* x + mu .* (fftn(magn_weight(:,:,:,1) .* ifftn(fdx .* x)) .* cfdx + ...
    fftn(magn_weight(:,:,:,2) .* ifftn(fdy .* x)) .* cfdy + fftn(magn_weight(:,:,:,3) .* ifftn(fdz .* x)) .* cfdz);

y = y(:);

end

