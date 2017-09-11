% Usage: w = Faddeeva_w(z [, relerr])
% 
% Compute w(z) = exp(-z^2) erfc(-iz), the scaled complex error function
% or Faddeeva function, for an array or matrix of values z.  The relerr
% argument, if supplied, indicates a desired relative error tolerance in
% w; the default is 0, indicating that machine precision is requested (and
% a relative error < 1e-13 is usually achieved).  Specifying a larger
% relerr may improve performance for some z (at the expense of accuracy).
% 
% S. G. Johnson, http://ab-initio.mit.edu/Faddeeva
