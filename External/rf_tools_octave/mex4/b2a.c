/*
 *  [b] = b2a (b)
 *  
 *  C program version of b2a.
 *
 *  Mex driver for subroutine.
 *  Gets complex minimum phase a from complex polynomial b.  
 *  Min phase a should have nominally zero imaginary component.
 *
 *
 *  Written by Adam Kerr, October 1992
 *  Modified from John Pauly's code.
 *  (c) Board of Trustees, Leland Stanford Junior University
 */

#include <math.h>
#include <stdio.h>
#include <cmex.h>

#define max(a,b) ((a)>(b) ? (a) : (b))

#define MAXN (1024)

/* driver for matlab call  */

#define B prhs[0]		/* alpha polynomial */
#define A plhs[0]		/* beta polynomial */

user_fcn (nlhs, plhs, nrhs, prhs)
int nlhs, nrhs;
Matrix *plhs[], *prhs[];
{
   double a[MAXN*2], b[MAXN*2];
   int n;
   int i, j;

   if ((nrhs != 1) || (nlhs != 1))
      mex_error ("Usage: [a] = b2a (b)");

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

   /* call routine b2a now */
   b2a (b, n, a);

   /* copy a back into matlab matrix */
   A = create_matrix (1, n, COMPLEX);
   for (i=0; i<n; i++)
   {
      A->pr[i] = a[i*2];
      A->pi[i] = a[i*2+1];
   }
}

