% Usage: e = Faddeeva_erfc(z [, relerr])
% 
% Compute erfc(z) = 1 - erf(z), the complementary error function,
% for an array or matrix of complex values z.
% 
% relerr, if supplied, indicates a desired relative error tolerance in
% w; the default is 0, indicating that machine precision is requested (and
% a relative error < 1e-13 is usually achieved).  Specifying a larger
% relerr may improve performance for some z (at the expense of accuracy).
% 
% S. G. Johnson, http://ab-initio.mit.edu/Faddeeva
