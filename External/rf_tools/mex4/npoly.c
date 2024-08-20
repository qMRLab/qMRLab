/*
 *  [b] = npoly (Z)
 *  
 *  C program version of npoly.
 *
 *  Mex driver for subroutine.
 *  Gets polynomial b from roots z, then normalizes polynomial so
 *  max (abs (fft(b))) = 1.
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

#define Z prhs[0]		/* polynomial - complex */
#define B plhs[0]		/* roots - complex */

user_fcn (nlhs, plhs, nrhs, prhs)
int nlhs, nrhs;
Matrix *plhs[], *prhs[];
{
   double b[MAXN*2], z[MAXN*2];
   int n;
   int i, j;

   if ((nrhs != 1) || (nlhs != 1))
      mex_error ("Usage: [b] = npoly (z)");

   n = max (Z->n, Z->m);
   if (n > MAXN-1) 
      mex_error ("roots too long");

   /* copy z into array */
   for (i=0; i<n; i++)
   {
      z[i*2] = Z->pr[i];
      z[i*2+1] = Z->pi[i];
   }

   /* call routine npoly now */
   npoly (z, n, b);

   /* copy b back into matlab matrix */
   B = create_matrix (1, n+1, COMPLEX);
   for (i=0; i<n+1; i++)
   {
      B->pr[i] = b[i*2];
      B->pi[i] = b[i*2+1];
   }
}


