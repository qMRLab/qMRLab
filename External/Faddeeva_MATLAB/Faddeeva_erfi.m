% Usage: e = Faddeeva_erfi(z [, relerr])
% 
% Compute erfi(z) = -i*erf(i*z), the imaginary error function,
% for an array or matrix of complex values z.
% 
% relerr, if supplied, indicates a desired relative error tolerance in
% w; the default is 0, indicating that machine precision is requested (and
% a relative error < 1e-13 is usually achieved).  Specifying a larger
% relerr may improve performance for some z (at the expense of accuracy).
% 
% S. G. Johnson, http://ab-initio.mit.edu/Faddeeva
