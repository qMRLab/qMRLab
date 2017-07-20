function x = fstoint(x)

% function x = fstoint(x)
%
% <x> is a 3D volume
%
% Perform various flips and permutations to go from
% FreeSurfer space to our internal MATLAB space.

x = flipdim(flipdim(permute(x,[1 3 2]),3),1);
