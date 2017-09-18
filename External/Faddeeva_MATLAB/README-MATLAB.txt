			 The Faddeeva Package
		  http://ab-initio.mit.edu/Faddeeva

      by Steven G. Johnson (http://math.mit.edu/~stevenj), 2012

The file Faddeeva.cc provides C++ implementations of the various
error functions of arbitrary complex arguments, including erf, erfc,
erfcx, erfi, the Dawson function, and the Faddeeva function.  In
particular:

	erf(z)                       -- the error function
	erfc(z) = 1 - erf(z)         -- complementary error function
	erfi(z) = -i erf(iz)         -- imaginary error function
	erfcx(z) = exp(z^2) erfc(z)  -- scaled complementary error function
	w(z) = exp(-z^2) erfc(-iz)   -- Faddeeva function
	Dawson(z) = 0.5 sqrt(pi) exp(-z^2) erfi(z)  -- Dawson function

This package also includes source code for compiled Matlab plugins
(MEX files) to provide a fast Matlab interface to this functionality.
Given a C++ compiler, simply run the provided script

      Faddeeva_build

in Matlab.  This will compile functions Faddeeva_erf, Faddeeva_erfc,
Faddeeva_erfi, Faddeeva_erfcx, Faddeeva_w, and Faddeeva_Dawson,
implementing the functions above; see also  their respective "help"
documentation (provided in .m files).

As described in the source code, this implementation uses a
combination of algorithms for the Faddeeva function: a
continued-fraction expansion for large |z| [similar to G. P. M. Poppe
and C. M. J. Wijers, "More efficient computation of the complex error
function," ACM Trans. Math. Soft. 16 (1), pp. 38–46 (1990)], and a
completely different algorithm for smaller |z| [Mofreh R. Zaghloul and
Ahmed N. Ali, "Algorithm 916: Computing the Faddeyeva and Voigt
Functions," ACM Trans. Math. Soft. 38 (2), 15 (2011).].  Given the
Faddeeva function, we can then compute the other error functions,
although we must switch to Taylor expansions and use other tricks in
certain regions of the complex plane to avoid cancellation errors or
other floating-point problems.

The Faddeeva package is free/open-source software distributed under
the "MIT License", which is compatible with all other standard
free-software licenses (BSD, GPL, MPL, CeCILL, etc.).

 * Copyright (c) 2012 Massachusetts Institute of Technology
 * 
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. 
