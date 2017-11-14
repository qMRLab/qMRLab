function dt = MakeDT_Matrix(d11, d12, d13, d22, d23, d33)
% Makes a diffusion tensor matrix out of the six elements.
%
% dt = MakeDT_Matrix(d11, d12, d13, d22, d23, d33)
% returns the matrix
% [d11 d12 d13]
% [d12 d22 d23]
% [d13 d23 d33]
%
% author: Daniel C Alexander (d.alexander@ucl.ac.uk)
%

dt = [d11 d12 d13; d12 d22 d23; d13 d23 d33];

