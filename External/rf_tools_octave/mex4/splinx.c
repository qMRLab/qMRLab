/*
 *
 *    Natural cubic spline interpolation.
 *    Usage same as spline.m, although answer will be different
 *    (probably better),  especially near the edges of a vector.
 *    For complex vectors, interpolates real and imaginary parts separately.
 *    Only the real part of abscissa vectors x and xx is used.
 * 
 *    Craig Meyer, 11/2/89.
 */

#include <stdio.h>
#include <math.h>
#include "cmex.h"
#include "nr.h"

#define X	prhs[0]  /* original x vector */
#define Y 	prhs[1]  /* original y vector */
#define XX      prhs[2]  /* desired x vector  */

#define YI	plhs[0]  /* interpolated y vector */

#define max(a,b)  ((a)>(b) ? (a) : (b))
#define min(a,b)  ((a)<(b) ? (a) : (b))

user_fcn(nlhs,plhs,nrhs,prhs)
int nlhs,nrhs;
Matrix *plhs[], *prhs[];
{
  int  i, n, nxx, ycomplex, sorted;
  float temp;
  float *x, *yr, *yi, *xx, *y2r, *y2i;

  if ((nrhs != 3) || (nlhs != 1))
    mex_error("Usage: yi = splinx(x, y, xi)");
  
  n = max(X->n,X->m);
  nxx = max(XX->n,XX->m);
  if (n != max(Y->n,Y->m))
    mex_error("Abscissa and ordinate data vectors are of different lengths!");

  if ((min(X->n,X->m)>1)||(min(Y->n,Y->m)>1)||(min(XX->n,XX->m)>1))
    mex_error("Inputs should be vectors, not matrices!");
  
  if ((X->pi != NULL)||(XX->pi != NULL))
    mex_printf("Imaginary part of abscissa vectors will be ignored.\n");

  ycomplex = (Y->pi == NULL) ? 0 : 1;

  /* allocate float arrays because spline wants them. */
  x = (float *)mex_calloc(n,sizeof(*x));
  yr = (float *)mex_calloc(n,sizeof(*yr));
  y2r = (float *)mex_calloc(n,sizeof(*y2r));
  if (ycomplex)
  {
      yi = (float *)mex_calloc(n,sizeof(*yi));
      y2i = (float *)mex_calloc(n,sizeof(*y2i));
  }
  for (i = 0; i < n; i++)
  {
      x[i] = X->pr[i]; yr[i] = Y->pr[i];
      if (ycomplex) yi[i] = Y->pi[i];
  }

  /* sort arrays if necessary */
  sorted = 1;
  for (i = 0; (i < n-1) && sorted; i++)
  {
      if (x[i+1] == x[i])
          mex_error("The data abscissae should be distinct!");
      if (x[i+1] < x[i])
          sorted = 0;
  }
  if (!sorted)
  {
      if (ycomplex)
          sort3(n,x-1,yr-1,yi-1);
      else
          sort2(n,x-1,yr-1);
      for (i = 0; i < n-1; i++)
      {
          if (x[i+1] == x[i])
          mex_error("The data abscissae should be distinct!");
      }
  }
  spline(x-1, yr-1, n, 1e30, 1e30, y2r-1);
  if (ycomplex)
      spline(x-1, yi-1, n, 1e30, 1e30, y2i-1);
  if (ycomplex)
      YI = create_matrix(XX->m,XX->n,COMPLEX);
  else
      YI = create_matrix(XX->m,XX->n,REAL);
  for (i = 0; i < nxx; i++)
  {
      splint(x-1, yr-1, y2r-1, n, (float)XX->pr[i], &temp);
      YI->pr[i] = temp;
      if (ycomplex)
      {
          splint(x-1, yi-1, y2i-1, n, (float)XX->pr[i], &temp);
          YI->pi[i] = temp;
      }
  }

  mex_free(x); mex_free(yr); mex_free(y2r);
  if (ycomplex) {mex_free(yi); mex_free(y2i);}
}
