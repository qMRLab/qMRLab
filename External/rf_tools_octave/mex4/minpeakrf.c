/*
 *  [zmin] = minpeakrf (z, flip, bsf)
 *
 *  Given the roots z, and a set of n of which to flip, do the following:
 *  For each combination of flips
 *     determine the polynomial b, normalize and scale by bsf, 
 *     calculate the rf pulse from b
 *     save which combination of zeros flips minimizes peak rf and return
 *     
 *
 *  Written by Adam Kerr, October 1992, 
 *  Adapted from John Pauly's code
 *  (c) Board of Trustees, Leland Stanford Junior University
 */

#include <math.h>
#include <stdio.h>
#include <cmex.h>
#define MAXN 1024

#define max(a,b) ((a)>(b) ? (a) : (b))
#define min(a,b) ((a)<(b) ? (a) : (b))
#define mag(a,j) (hypot (a[(j)*2], a[(j)*2+1]))

/* driver for matlab call  */

#define Z prhs[0]		/* complex z roots */
#define FLIP prhs[1]		/* indices of roots to flip */
#define BSF prhs[2]		/* scaling factor for beta polynomial */

#define ZMIN plhs[0]		/* complex roots */

user_fcn (nlhs, plhs, nrhs, prhs)
int nlhs, nrhs;
Matrix *plhs[], *prhs[];
{
   double z[MAXN*2], z0[MAXN*2];
   double zmin[MAXN*2];
   int    sflip[MAXN];
   int    cflip[MAXN*2];
   int nflip, nroots;
   int nsflip, ncflip;
   double bsf;
   int i, j;
   int ncomb;
   double start_peakrf;
   double min_peakrf, peakrf;
   int min_index;
   int bittest;
   int r;
   int r1, r2;
   double z2peakrf();

   if ((nrhs != 3) || (nlhs != 1))
      mex_error ("Usage: [zmin] = minpeakrf (z, flip, bsf)");

   nroots = max (Z->n, Z->m);
   if (nroots+1 > MAXN) 
      mex_error ("z vector too long");

   nflip = FLIP->m;

   bsf = BSF->pr[0];
   if ((bsf < 0) || (bsf > 1.0))
      mex_error ("bsf not in 0..1");

   /* copy z into c array */
   for (i=0; i<nroots; i++)
   {
      z[i*2] = Z->pr[i];
      z[i*2+1] = Z->pi[i];
   }

   /* copy flip into c arrays of single and conjugate flips  */
   ncflip=nsflip=0;
   for (i=0; i<nflip; i++)
      if (FLIP->pr[i+nflip] == 0) /* a single flip root */
	 sflip [nsflip++] = FLIP->pr[i]-1;
      else			/* a conjugate root */
      {
	 cflip [ncflip*2] = FLIP->pr[i]-1;
	 cflip [ncflip*2+1] = FLIP->pr[i+nflip]-1;
	 ncflip++;
      }
   nflip = ncflip + nsflip;


   /* copy roots into z0 */
   for (i=0; i<nroots; i++)
   {
      z0[i*2] = z[i*2];
      z0[i*2+1] = z[i*2+1];
   }

   /* for conjugate roots make sure they are in symmetric conjugate 
      order at first by making sure they're on the same side
      of the unit circle... */
   for (i=0; i<ncflip; i++)
   {
      if ((mag(z, cflip[i*2]) - 1)/ (mag(z, cflip[i*2+1]) - 1) < 0)
	 flip_root (z0, z, cflip[i*2]);
   }

   /* copy roots into zmin */
   for (i=0; i<nroots; i++)
   {
      zmin[i*2] = z0[i*2];
      zmin[i*2+1] = z0[i*2+1];
   }

   /* for each flip combination now, determine the peak rf */
   ncomb = pow (2.0, (double) nflip);
   mex_printf ("Number of iterations required: %d\n", ncomb);
   start_peakrf = z2peakrf (z0, nroots, bsf);
   min_peakrf = start_peakrf;
   min_index = 0;
   for (i=0; i<ncomb; i++)
   {
      bittest = 1;
      /* do single flip roots first */
      for (j=0; j<nsflip; j++)
      {
	 r = sflip[j];
	 if ((i & bittest) == 0)
	 {
	    zmin[r*2] = z0[r*2];		/* if bit=0 leave root */
	    zmin[r*2+1] = z0[r*2+1];
	 }
	 else
	 {
	    flip_root (zmin, z0, r);
	 }
	 bittest = bittest << 1;
      }
      /* now do conjugate roots */
      for (j=0; j<ncflip; j++)
      {
	 r1 = cflip[j*2];
	 r2 = cflip[j*2+1];
	 if ((i & bittest) == 0)
	 {
	    zmin[r1*2] = z0[r1*2];		/* if bit=0 leave 1st */
	    zmin[r1*2+1] = z0[r1*2+1];
	    flip_root (zmin, z0, r2);		/* flip second */
	 }
	 else
	 {
	    flip_root (zmin, z0, r1); 		/* else, flip first */
	    zmin[r2*2] = z0[r2*2];		/* and leave second */
	    zmin[r2*2+1] = z0[r2*2+1];
	 }
	 bittest = bittest << 1;
      }
      peakrf = z2peakrf (zmin, nroots, bsf);
      if (peakrf <= min_peakrf)
      {
	 min_peakrf = peakrf;
	 min_index = i;
      }

      if (i % 200 == 0) 
	 mex_printf ("Iteration: %d;  Peak RF: %f; Minimum Peak RF: %f\n", 
		     i, peakrf, min_peakrf);
   }	 
   
   /* now pass back zmin of minimum peak rf pulse */
   bittest = 1;
   /* do single flip roots first */
   for (j=0; j<nsflip; j++)
   {
      r = sflip[j];
      if ((min_index & bittest) == 0)
      {
	 zmin[r*2] = z0[r*2];		/* if bit=0 leave root */
	 zmin[r*2+1] = z0[r*2+1];
      }
      else
      {
	 flip_root (zmin, z0, r);
      }
      bittest = bittest << 1;
   }
   /* now do conjugate roots */
   for (j=0; j<ncflip; j++)
   {
      r1 = cflip[j*2];
      r2 = cflip[j*2+1];
      if ((min_index & bittest) == 0)
      {
	 zmin[r1*2] = z0[r1*2];		/* if bit=0 leave 1st */
	 zmin[r1*2+1] = z0[r1*2+1];
	 flip_root (zmin, z0, r2);		/* flip second */
      }
      else
      {
	 flip_root (zmin, z0, r1); 		/* else, flip first */
	 zmin[r2*2] = z0[r2*2];		/* and leave second */
	 zmin[r2*2+1] = z0[r2*2+1];
      }
      bittest = bittest << 1;
   }

   peakrf = z2peakrf (zmin, nroots, bsf);
   mex_printf ("At the end, peakrf: %f; Index: %d\n", peakrf, min_index);

   ZMIN = create_matrix (1, nroots, COMPLEX);
   for (i=0; i<nroots; i++)
   {
      ZMIN->pr[i] = zmin[i*2];
      ZMIN->pi[i] = zmin[i*2+1];
   }
}

double z2peakrf (zmin, nroots, bsf)
double zmin[];
int nroots;
double bsf;
{
   double beta[MAXN*2];
   double rf[MAXN*2];
   double alpha[MAXN*2];
   int i, n;
   double peakrf;

   n = nroots+1;

   /* get beta polynomial */
   npoly (zmin, nroots, beta);

   /* normalize by bsf */
   for (i=0; i<n; i++)
   {
      beta[i*2] *= bsf;
      beta[i*2+1] *= bsf;
   }
   
   /* now get alpha from beta */
   b2a (beta, n, alpha);

   /* now get rf from alpha, beta */
   cabc2rf (alpha, beta, n, rf);

   for (i=1, peakrf=mag(rf,0); i<n; i++)
      peakrf = max (mag(rf,i), peakrf);

   return (peakrf);
}

flip_root (zmin, z, r)
double zmin[];
double z[];
int r;
{
   double norm_r;
   
   norm_r = pow (z[r*2], 2.0) + pow(z[r*2+1], 2.0);
   zmin[r*2] = z[r*2] / norm_r;
   zmin[r*2+1] = z[r*2+1] / norm_r;
}
