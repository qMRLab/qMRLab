/*
 *  [rf] = b2rf (b)
 *  
 *  C program version of b2rf.
 *
 *  Mex driver for subroutine.
 *  Gets complex rf from complex polynomial b.  
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

#define B prhs[0]		/* alpha polynomial */
#define RF plhs[0]		/* RF pulse */

user_fcn (nlhs, plhs, nrhs, prhs)
int nlhs, nrhs;
Matrix *plhs[], *prhs[];
{
   double a[MAXN*2], b[MAXN*2];
   double rf[MAXN*2];
   int n;
   int i, j;

   if ((nrhs != 1) || (nlhs != 1))
      mex_error ("Usage: [rf] = b2rf (b)");

   n = max (B->n, B->m);
   if (n > MAXN) 
      mex_error ("beta polynomial too long");

   /* copy b into array */
   if (B->pi != NULL)
      for (i=0; i<n; i++)
      {
	 b[i*2] = B->pr[i];
	 b[i*2+1] = B->pi[i];
      }
   else
      for (i=0; i<n; i++)
      {
	 b[i*2] = B->pr[i];
	 b[i*2+1] = 0.0;
      }

   /* get alpha polynomial */
   b2a (b, n, a);

   /* get rf from ab now */
   cabc2rf (a, b, n, rf);

   /* copy rf back into matlab matrix */
   RF = create_matrix (1, n, COMPLEX);
   for (i=0; i<n; i++)
   {
      RF->pr[i] = rf[i*2];
      RF->pi[i] = rf[i*2+1];
   }
}

