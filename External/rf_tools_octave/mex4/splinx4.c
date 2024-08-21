/*
 *
 *    Natural cubic spline interpolation.
 *    Usage same as spline.m, although answer will be different
 *    (probably better),  especially near the edges of a vector.
 *    For complex vectors, interpolates real and imaginary parts separately.
 *    Only the real part of abscissa vectors x and xx is used.
 * 
 *    Craig Meyer, 11/2/89.
 *    jmp          6/23/93    translate to 4.0
 */

#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "nr.h"

#define X	prhs[0]  /* original x vector */
#define Y 	prhs[1]  /* original y vector */
#define XX      prhs[2]  /* desired x vector  */

#define YI	plhs[0]  /* interpolated y vector */

#define max(a,b)  ((a)>(b) ? (a) : (b))
#define min(a,b)  ((a)<(b) ? (a) : (b))

mexFunction(nlhs,plhs,nrhs,prhs)
int nlhs,nrhs;
Matrix *plhs[], *prhs[];
{
  int  i, n, nxx, ycomplex, sorted;
  float temp;
  float *x, *yr, *yi, *xx, *y2r, *y2i;

  if ((nrhs != 3) || (nlhs != 1))
    mexErrMsgTxt("Usage: yi = splinx(x, y, xi)");
  
  n = max(mxGetN(X),mxGetM(X));
  nxx = max(mxGetN(XX),mxGetM(XX));
  if (n != max(mxGetN(Y),mxGetM(Y)))
    mexErrMsgTxt("Abscissa and ordinate vectors are of different lengths!");

  if ( (min(mxGetN(X), mxGetM(X))  > 1) 
    || (min(mxGetN(Y), mxGetM(Y))  > 1)
    || (min(mxGetN(XX),mxGetM(XX)) > 1))
    mexErrMsgTxt("Inputs should be vectors, not matrices!");
  
  if ((mxGetPi(X) != NULL) || (mxGetPi(XX) != NULL))
    mexPrintf("Imaginary part of abscissa vectors will be ignored.\n");

  ycomplex = (mxGetPi(Y) == NULL) ? 0 : 1;

  /* allocate float arrays because spline wants them. */
  x   = (float *)mxCalloc(n,sizeof(*x));
  yr  = (float *)mxCalloc(n,sizeof(*yr));
  y2r = (float *)mxCalloc(n,sizeof(*y2r));
  if (ycomplex)
  {
      yi  = (float *)mxCalloc(n,sizeof(*yi));
      y2i = (float *)mxCalloc(n,sizeof(*y2i));
  }
  for (i = 0; i < n; i++)
  {
      x[i] = mxGetPr(X)[i]; yr[i] = mxGetPr(Y)[i];
      if (ycomplex) yi[i] = mxGetPi(Y)[i];
  }

  /* sort arrays if necessary */
  sorted = 1;
  for (i = 0; (i < n-1) && sorted; i++)
  {
      if (x[i+1] == x[i])
          mexErrMsgTxt("The data abscissae should be distinct!");
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
          mexErrMsgTxt("The data abscissae should be distinct!");
      }
  }
  spline(x-1, yr-1, n, 1e30, 1e30, y2r-1);
  if (ycomplex)
      spline(x-1, yi-1, n, 1e30, 1e30, y2i-1);
  if (ycomplex)
      YI = mxCreateFull(mxGetM(XX),mxGetN(XX),COMPLEX);
  else
      YI = mxCreateFull(mxGetM(XX),mxGetN(XX),REAL);
  for (i = 0; i < nxx; i++)
  {
      splint(x-1, yr-1, y2r-1, n, (float)mxGetPr(XX)[i], &temp);
      mxGetPr(YI)[i] = temp;
      if (ycomplex)
      {
          splint(x-1, yi-1, y2i-1, n, (float)mxGetPr(XX)[i], &temp);
          mxGetPi(YI)[i] = temp;
      }
  }

  mxFree(x); mxFree(yr); mxFree(y2r);
  if (ycomplex) {mxFree(yi); mxFree(y2i);}
}
