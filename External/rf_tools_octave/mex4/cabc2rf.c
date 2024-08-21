/*
 *  [rf] = cabc2rf (a, b)
 *  
 *  C program version of cabc2rf.
 *
 *  Mex driver for subroutine.
 *  Performs inverse SLR tranform on complex a,b coefficients to give 
 *  complex rf pulse
 *
 *
 *  Written by Adam Kerr, October 1992
 *  Modified from John Pauly's code.
 *  (c) Board of Trustees, Leland Stanford Junior University
 */

#include <math.h>
#include <stdio.h>
#include <cmex.h>

#define MAXN (1024)

#define max(a,b) ((a)>(b) ? (a) : (b))

/* driver for matlab call  */

#define A prhs[0]		/* alpha, beta polynomials */
#define B prhs[1]		

#define RF plhs[0]		/* RF out - complex */


user_fcn (nlhs, plhs, nrhs, prhs)
int nlhs, nrhs;
Matrix *plhs[], *prhs[];
{
   double a[MAXN*2], b[MAXN*2];
   double rf[MAXN*2];
   int n;
   int i, j;

   if ((nrhs != 2) || (nlhs != 1))
      mex_error ("Usage: [rf] = c_abc2rf (a,b)");

   n = max (A->n, A->m);
   if (n > MAXN) 
      mex_error ("alpha polynomial too long");

   if (max (B->n, B->m) != n)
       mex_error ("alpha, beta polynomials MUST be same length");

   /* copy a, b into arrays */
   for (i=0; i<n; i++)
   {
      a[i*2] = A->pr[i];
      if (A->pi != NULL)
	a[i*2+1] = A->pi[i];
      else
	a[i*2+1] = 0.0;
      b[i*2] = B->pr[i];
      if (B->pi != NULL)
	b[i*2+1] = B->pi[i];
      else
	b[i*2+1] = 0.0;
   }

   /* call routine c_abc2rf now */
   cabc2rf (a, b, n, rf);

   /* copy rf back into matlab matrix */
   RF = create_matrix (1, n, COMPLEX);
   for (i=0; i<n; i++)
   {
      RF->pr[i] = rf[i*2];
      RF->pi[i] = rf[i*2+1];
   }
}

