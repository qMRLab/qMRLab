function x = inttofs(x)

% function x = inttofs(x)
%
% <x> is a 3D volume
%
% Perform various flips and permutations to go from
% our internal MATLAB space to FreeSurfer space.

x = permute(flipdim(flipdim(x,1),3),[1 3 2]);
