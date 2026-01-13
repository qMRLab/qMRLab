/*
 *  npoly (z, n, b)
 *  
 *  C program version of npoly.
 *
 *  Gets polynomial b from roots z, then normalizes polynomial so
 *  max (abs (fft(b))) = 1.
 *
 *  Written by Adam Kerr, October 1992
 *  Modified from John Pauly's code.
 *  (c) Board of Trustees, Leland Stanford Junior University
 */

#include <math.h>

#define MAXN (1024)

#define max(a,b) ((a)>(b) ? (a) : (b))
#define min(a,b) ((a)<(b) ? (a) : (b))
#define mag(a,j) (hypot (a[(j)*2], a[(j)*2+1]))
#define re_mult(a1,b1,a2,b2) ((a1)*(a2) - (b1)*(b2))
#define im_mult(a1,b1,a2,b2) ((a1)*(b2) + (a2)*(b1))

npoly (z, n, b)
double z[], b[];
int n;
{
   int i;
   int nn;
   double bf[MAXN*2];
   double bfmax, bfmag;

   b[0] = 1;	     	/* b[0] = 1 + i0 */
   b[1] = 0;
   for (i=0; i<n; i++)
      polymult (b, i, z+i*2);
   
   /* normalize polynomial now */

   /* next bigger power of 2 */
   nn = rint (exp(M_LN2*ceil(log((double)(n+1))/M_LN2)));
   for (i=0; i<2*(n+1);i++)
      bf[i] = b[i];
   for (i=2*(n+1); i<nn*2; i++)
      bf[i] = 0.0;
   four1 (bf-1, nn, 1);
   for (i=1, bfmax=mag(bf,0); i<nn; i++)
      bfmax = max (mag(bf,i), bfmax);

   for (i=0; i<2*(n+1); i++)
      b[i] /= bfmax;
}

polymult (p, order, root)
double p[];
int order;
double root[];
{
   double a, b;
   int i;

   a = -root[0];
   b = -root[1];
   p[(order+1)*2] = 0;
   p[(order+1)*2+1] = 0;
   for (i=order+1; i>0; i--)
   {
      p[(i*2)] += re_mult(p[(i-1)*2], p[(i-1)*2+1],a, b);
      p[(i*2)+1] += im_mult(p[(i-1)*2], p[(i-1)*2+1], a, b);
   }
}


