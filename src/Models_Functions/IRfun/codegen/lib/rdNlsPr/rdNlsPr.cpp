//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: rdNlsPr.cpp
//
// MATLAB Coder version            : 4.1
// C/C++ source code generated on  : 12-Feb-2020 15:04:36
//

// Include Files
#include <cmath>
#include "rt_nonfinite.h"
#include "rdNlsPr.h"
#include "rdNlsPr_emxutil.h"
#include "norm.h"
#include "rdivide_helper.h"
#include "power.h"
#include "abs.h"
#include "sum.h"
#include "linspace.h"
#include "sort1.h"

// Function Definitions

//
// Arguments    : double data[4]
//                const struct0_T *nlsS
//                double *T1Est
//                double *bEst
//                double *aEst
//                double *res
//                double *idx
// Return Type  : void
//
void rdNlsPr(double data[4], const struct0_T *nlsS, double *T1Est, double *bEst,
             double *aEst, double *res, double *idx)
{
  double x[4];
  int iidx[4];
  double b_data[4];
  int b_idx;
  int k;
  boolean_T exitg1;
  double temp;
  int i0;
  boolean_T b_bool;
  double d0;
  int ind;
  int exitg2;
  static const char cv0[4] = { 'g', 'r', 'i', 'd' };

  int c_bool;
  double nbrOfZoom;
  emxArray_real_T *theExp;
  emxArray_real_T *rhoTyVec;
  emxArray_real_T *rhoNormVec;
  double resTmp[2];
  emxArray_real_T *T1Vec;
  emxArray_real_T *y;
  emxArray_real_T *varargin_1;
  emxArray_real_T *b_y;
  double aEstTmp[2];
  emxArray_real_T *r0;
  double bEstTmp[2];
  emxArray_real_T *r1;
  double T1EstTmp[2];
  emxArray_real_T *r2;
  int ii;
  int boffset;
  signed char tmp_data[7];
  double dataTmp_data[4];
  double a_data_idx_0;
  double a_data_idx_1;
  double a_data_idx_2;
  double a_data_idx_3;
  emxArray_real_T b_nlsS;
  int iv0[1];
  int n;
  double T1LenZ;
  double b_aEstTmp[4];
  int b_k;
  unsigned int varargin_1_idx_0;

  //  [T1Est, bMagEst, aMagEst, res, idx] = rdNlsPr(data, nlsS)
  //
  //  Finds estimates of T1, |a|, and |b| using a nonlinear least
  //  squares approach together with polarity restoration.
  //  The model +-|ra + rb*exp(-t/T1)| is used.
  //  The residual is the rms error between the data and the fit.
  //  idx - is the index of the last polarity-restored data point
  //
  //  INPUT:
  //  data - the absolute data to estimate from
  //  nlsS - struct containing the NLS search parameters and
  //         the data model to use
  //
  //  written by J. Barral, M. Etezadi-Amoli, E. Gudmundson, and N. Stikov, 2009 
  //   (c) Board of Trustees, Leland Stanford Junior University
  //
  //  Modified By Ilana Leppert June 2017
  //   Return the index of the last polarity restored datapoint
  //   e.g. if the signal of the 2 first inversion times need to be
  //   inverted: idx=2
  //  Make sure the data come in increasing TI-order
  x[0] = nlsS->tVec[0];
  x[1] = nlsS->tVec[1];
  x[2] = nlsS->tVec[2];
  x[3] = nlsS->tVec[3];
  sort(x, iidx);
  b_data[0] = data[iidx[0] - 1];
  b_data[1] = data[iidx[1] - 1];
  b_data[2] = data[iidx[2] - 1];
  b_data[3] = data[iidx[3] - 1];
  data[0] = data[iidx[0] - 1];
  data[1] = b_data[1];
  data[2] = b_data[2];
  data[3] = b_data[3];

  //  Initialize variables
  //  Make sure data vector is a column vector
  //  Find the min of the data
  if (!rtIsNaN(b_data[0])) {
    b_idx = 1;
  } else {
    b_idx = 0;
    k = 2;
    exitg1 = false;
    while ((!exitg1) && (k < 5)) {
      if (!rtIsNaN(data[k - 1])) {
        b_idx = k;
        exitg1 = true;
      } else {
        k++;
      }
    }
  }

  if (b_idx == 0) {
    b_idx = 1;
  } else {
    temp = data[b_idx - 1];
    i0 = b_idx + 1;
    for (k = i0; k < 5; k++) {
      d0 = data[k - 1];
      if (temp > d0) {
        temp = d0;
        b_idx = k;
      }
    }
  }

  //  Fit
  b_bool = false;
  ind = 0;
  do {
    exitg2 = 0;
    if (ind < 4) {
      if (nlsS->nlsAlg[ind] != cv0[ind]) {
        exitg2 = 1;
      } else {
        ind++;
      }
    } else {
      b_bool = true;
      exitg2 = 1;
    }
  } while (exitg2 == 0);

  if (b_bool) {
    c_bool = 0;
  } else {
    c_bool = -1;
  }

  switch (c_bool) {
   case 0:
    nbrOfZoom = nlsS->nbrOfZoom;
    emxInit_real_T(&theExp, 2);
    emxInit_real_T(&rhoTyVec, 2);
    emxInit_real_T(&rhoNormVec, 1);
    emxInit_real_T(&T1Vec, 1);
    emxInit_real_T(&y, 2);
    emxInit_real_T(&varargin_1, 1);
    emxInit_real_T(&b_y, 1);
    emxInit_real_T(&r0, 2);
    emxInit_real_T(&r1, 2);
    emxInit_real_T(&r2, 2);
    for (ii = 0; ii < 2; ii++) {
      i0 = theExp->size[0] * theExp->size[1];
      theExp->size[0] = 4;
      theExp->size[1] = 5000;
      emxEnsureCapacity_real_T(theExp, i0);
      for (i0 = 0; i0 < 5000; i0++) {
        boffset = i0 << 2;
        theExp->data[boffset] = nlsS->theExp[(iidx[0] + boffset) - 1];
        theExp->data[1 + boffset] = nlsS->theExp[(iidx[1] + boffset) - 1];
        theExp->data[2 + boffset] = nlsS->theExp[(iidx[2] + boffset) - 1];
        theExp->data[3 + boffset] = nlsS->theExp[(iidx[3] + boffset) - 1];
      }

      if (1 + ii == 1) {
        //  First, we set all elements up to and including
        //  the smallest element to minus
        for (i0 = 0; i0 < b_idx; i0++) {
          tmp_data[i0] = -1;
        }

        ind = 4 - b_idx;
        for (i0 = 0; i0 < ind; i0++) {
          tmp_data[i0 + b_idx] = 1;
        }

        dataTmp_data[0] = -data[0];
        dataTmp_data[1] = data[1] * (double)tmp_data[1];
        dataTmp_data[2] = data[2] * (double)tmp_data[2];
        dataTmp_data[3] = data[3] * (double)tmp_data[3];
      } else {
        //  Second, we set all elements up to (not including)
        //  the smallest element to minus
        ind = b_idx - 1;
        for (i0 = 0; i0 < ind; i0++) {
          tmp_data[i0] = -1;
        }

        ind = 5 - b_idx;
        for (i0 = 0; i0 < ind; i0++) {
          tmp_data[(i0 + b_idx) - 1] = 1;
        }

        dataTmp_data[0] = data[0] * (double)tmp_data[0];
        dataTmp_data[1] = data[1] * (double)tmp_data[1];
        dataTmp_data[2] = data[2] * (double)tmp_data[2];
        dataTmp_data[3] = data[3];
      }

      //  The sum of the data
      d0 = ((dataTmp_data[0] + dataTmp_data[1]) + dataTmp_data[2]) +
        dataTmp_data[3];

      //  Compute the vector of rho'*t for different rho,
      //  where rho = exp(-TI/T1) and y = dataTmp
      a_data_idx_0 = dataTmp_data[0];
      a_data_idx_1 = dataTmp_data[1];
      a_data_idx_2 = dataTmp_data[2];
      a_data_idx_3 = dataTmp_data[3];
      i0 = y->size[0] * y->size[1];
      y->size[0] = 1;
      y->size[1] = 5000;
      emxEnsureCapacity_real_T(y, i0);
      for (ind = 0; ind < 5000; ind++) {
        boffset = ind << 2;
        y->data[ind] = 0.0;
        temp = nlsS->theExp[(iidx[boffset % 4] + ((boffset / 4) << 2)) - 1];
        y->data[ind] += temp * a_data_idx_0;
        i0 = boffset + 1;
        temp = nlsS->theExp[(iidx[i0 % 4] + ((i0 / 4) << 2)) - 1];
        y->data[ind] += temp * a_data_idx_1;
        i0 = boffset + 2;
        temp = nlsS->theExp[(iidx[i0 % 4] + ((i0 / 4) << 2)) - 1];
        y->data[ind] += temp * a_data_idx_2;
        i0 = boffset + 3;
        temp = nlsS->theExp[(iidx[i0 % 4] + ((i0 / 4) << 2)) - 1];
        y->data[ind] += temp * a_data_idx_3;
      }

      sum(theExp, r0);
      i0 = varargin_1->size[0];
      varargin_1->size[0] = r0->size[1];
      emxEnsureCapacity_real_T(varargin_1, i0);
      ind = r0->size[1];
      for (i0 = 0; i0 < ind; i0++) {
        varargin_1->data[i0] = r0->data[i0];
      }

      i0 = rhoTyVec->size[0] * rhoTyVec->size[1];
      rhoTyVec->size[0] = varargin_1->size[0];
      rhoTyVec->size[1] = 1;
      emxEnsureCapacity_real_T(rhoTyVec, i0);
      ind = varargin_1->size[0];
      for (i0 = 0; i0 < ind; i0++) {
        temp = 0.25 * varargin_1->data[i0] * d0;
        rhoTyVec->data[i0] = y->data[i0] - temp;
      }

      //  rhoNormVec is a vector containing the norm-squared of rho over TI,
      //  where rho = exp(-TI/T1), for different T1's.
      i0 = rhoNormVec->size[0];
      rhoNormVec->size[0] = 5000;
      emxEnsureCapacity_real_T(rhoNormVec, i0);
      for (i0 = 0; i0 < 5000; i0++) {
        rhoNormVec->data[i0] = nlsS->rhoNormVec[i0];
      }

      // Find the max of the maximizing criterion
      b_abs(rhoTyVec, r1);
      power(r1, r2);
      b_nlsS.numDimensions = 1;
      iv0[0] = 5000;
      b_nlsS.size = &iv0[0];
      b_nlsS.allocatedSize = 5000;
      b_nlsS.data = (double *)&nlsS->rhoNormVec[0];
      rdivide_helper(r2, &b_nlsS, varargin_1);
      n = varargin_1->size[0];
      if (varargin_1->size[0] <= 2) {
        if (varargin_1->size[0] == 1) {
          ind = 1;
        } else if ((varargin_1->data[0] < varargin_1->data[1]) || (rtIsNaN
                    (varargin_1->data[0]) && (!rtIsNaN(varargin_1->data[1])))) {
          ind = 2;
        } else {
          ind = 1;
        }
      } else {
        if (!rtIsNaN(varargin_1->data[0])) {
          ind = 1;
        } else {
          ind = 0;
          k = 2;
          exitg1 = false;
          while ((!exitg1) && (k <= varargin_1->size[0])) {
            if (!rtIsNaN(varargin_1->data[k - 1])) {
              ind = k;
              exitg1 = true;
            } else {
              k++;
            }
          }
        }

        if (ind == 0) {
          ind = 1;
        } else {
          temp = varargin_1->data[ind - 1];
          i0 = ind + 1;
          for (k = i0; k <= n; k++) {
            if (temp < varargin_1->data[k - 1]) {
              temp = varargin_1->data[k - 1];
              ind = k;
            }
          }
        }
      }

      i0 = T1Vec->size[0];
      T1Vec->size[0] = 5000;
      emxEnsureCapacity_real_T(T1Vec, i0);
      for (i0 = 0; i0 < 5000; i0++) {
        T1Vec->data[i0] = nlsS->T1Vec[i0];
      }

      //  Initialize the variable
      if (nbrOfZoom > 1.0) {
        //  Do zoomed search
        T1LenZ = nlsS->T1LenZ;

        //  For the zoomed search
        i0 = (int)(nbrOfZoom + -1.0);
        if (0 <= i0 - 1) {
          a_data_idx_0 = dataTmp_data[0];
          a_data_idx_1 = dataTmp_data[1];
          a_data_idx_2 = dataTmp_data[2];
          a_data_idx_3 = dataTmp_data[3];
        }

        for (k = 0; k < i0; k++) {
          if ((ind > 1) && (ind < T1Vec->size[0])) {
            linspace(T1Vec->data[ind - 2], T1Vec->data[ind], T1LenZ, r0);
            boffset = T1Vec->size[0];
            T1Vec->size[0] = r0->size[1];
            emxEnsureCapacity_real_T(T1Vec, boffset);
            ind = r0->size[1];
            for (boffset = 0; boffset < ind; boffset++) {
              T1Vec->data[boffset] = r0->data[boffset];
            }
          } else if (ind == 1) {
            linspace(T1Vec->data[0], T1Vec->data[2], T1LenZ, r0);
            boffset = T1Vec->size[0];
            T1Vec->size[0] = r0->size[1];
            emxEnsureCapacity_real_T(T1Vec, boffset);
            ind = r0->size[1];
            for (boffset = 0; boffset < ind; boffset++) {
              T1Vec->data[boffset] = r0->data[boffset];
            }
          } else {
            linspace(T1Vec->data[ind - 3], T1Vec->data[ind - 1], T1LenZ, r0);
            boffset = T1Vec->size[0];
            T1Vec->size[0] = r0->size[1];
            emxEnsureCapacity_real_T(T1Vec, boffset);
            ind = r0->size[1];
            for (boffset = 0; boffset < ind; boffset++) {
              T1Vec->data[boffset] = r0->data[boffset];
            }
          }

          //  Update the variables
          boffset = r0->size[0] * r0->size[1];
          r0->size[0] = 1;
          r0->size[1] = T1Vec->size[0];
          emxEnsureCapacity_real_T(r0, boffset);
          ind = T1Vec->size[0];
          for (boffset = 0; boffset < ind; boffset++) {
            r0->data[boffset] = 1.0 / T1Vec->data[boffset];
          }

          boffset = theExp->size[0] * theExp->size[1];
          theExp->size[0] = 4;
          theExp->size[1] = r0->size[1];
          emxEnsureCapacity_real_T(theExp, boffset);
          ind = r0->size[1];
          for (boffset = 0; boffset < ind; boffset++) {
            theExp->data[boffset << 2] = -x[0] * r0->data[boffset];
          }

          ind = r0->size[1];
          for (boffset = 0; boffset < ind; boffset++) {
            theExp->data[1 + (boffset << 2)] = -x[1] * r0->data[boffset];
          }

          ind = r0->size[1];
          for (boffset = 0; boffset < ind; boffset++) {
            theExp->data[2 + (boffset << 2)] = -x[2] * r0->data[boffset];
          }

          ind = r0->size[1];
          for (boffset = 0; boffset < ind; boffset++) {
            theExp->data[3 + (boffset << 2)] = -x[3] * r0->data[boffset];
          }

          ind = theExp->size[1] << 2;
          for (b_k = 0; b_k < ind; b_k++) {
            theExp->data[b_k] = std::exp(theExp->data[b_k]);
          }

          n = theExp->size[1];
          boffset = y->size[0] * y->size[1];
          y->size[0] = 1;
          y->size[1] = theExp->size[1];
          emxEnsureCapacity_real_T(y, boffset);
          for (ind = 0; ind < n; ind++) {
            boffset = ind << 2;
            y->data[ind] = 0.0;
            temp = theExp->data[boffset];
            y->data[ind] += temp * a_data_idx_0;
            temp = theExp->data[boffset + 1];
            y->data[ind] += temp * a_data_idx_1;
            temp = theExp->data[boffset + 2];
            y->data[ind] += temp * a_data_idx_2;
            temp = theExp->data[boffset + 3];
            y->data[ind] += temp * a_data_idx_3;
          }

          sum(theExp, r0);
          boffset = varargin_1->size[0];
          varargin_1->size[0] = r0->size[1];
          emxEnsureCapacity_real_T(varargin_1, boffset);
          ind = r0->size[1];
          for (boffset = 0; boffset < ind; boffset++) {
            varargin_1->data[boffset] = r0->data[boffset];
          }

          varargin_1_idx_0 = (unsigned int)varargin_1->size[0];
          boffset = b_y->size[0];
          b_y->size[0] = (int)varargin_1_idx_0;
          emxEnsureCapacity_real_T(b_y, boffset);
          varargin_1_idx_0 = (unsigned int)varargin_1->size[0];
          ind = (int)varargin_1_idx_0;
          for (b_k = 0; b_k < ind; b_k++) {
            b_y->data[b_k] = varargin_1->data[b_k] * varargin_1->data[b_k];
          }

          power(theExp, r2);
          sum(r2, r0);
          boffset = rhoNormVec->size[0];
          rhoNormVec->size[0] = r0->size[1];
          emxEnsureCapacity_real_T(rhoNormVec, boffset);
          ind = r0->size[1];
          for (boffset = 0; boffset < ind; boffset++) {
            rhoNormVec->data[boffset] = r0->data[boffset] - 0.25 * b_y->
              data[boffset];
          }

          boffset = rhoTyVec->size[0] * rhoTyVec->size[1];
          rhoTyVec->size[0] = varargin_1->size[0];
          rhoTyVec->size[1] = 1;
          emxEnsureCapacity_real_T(rhoTyVec, boffset);
          ind = varargin_1->size[0];
          for (boffset = 0; boffset < ind; boffset++) {
            temp = 0.25 * varargin_1->data[boffset] * d0;
            rhoTyVec->data[boffset] = y->data[boffset] - temp;
          }

          // Find the max of the maximizing criterion
          b_abs(rhoTyVec, r1);
          power(r1, r2);
          rdivide_helper(r2, rhoNormVec, varargin_1);
          n = varargin_1->size[0];
          if (varargin_1->size[0] <= 2) {
            if (varargin_1->size[0] == 1) {
              ind = 1;
            } else if ((varargin_1->data[0] < varargin_1->data[1]) || (rtIsNaN
                        (varargin_1->data[0]) && (!rtIsNaN(varargin_1->data[1]))))
            {
              ind = 2;
            } else {
              ind = 1;
            }
          } else {
            if (!rtIsNaN(varargin_1->data[0])) {
              ind = 1;
            } else {
              ind = 0;
              b_k = 2;
              exitg1 = false;
              while ((!exitg1) && (b_k <= varargin_1->size[0])) {
                if (!rtIsNaN(varargin_1->data[b_k - 1])) {
                  ind = b_k;
                  exitg1 = true;
                } else {
                  b_k++;
                }
              }
            }

            if (ind == 0) {
              ind = 1;
            } else {
              temp = varargin_1->data[ind - 1];
              boffset = ind + 1;
              for (b_k = boffset; b_k <= n; b_k++) {
                if (temp < varargin_1->data[b_k - 1]) {
                  temp = varargin_1->data[b_k - 1];
                  ind = b_k;
                }
              }
            }
          }
        }
      }

      //  of zoom
      //  The estimated parameters
      T1EstTmp[ii] = T1Vec->data[ind - 1];
      bEstTmp[ii] = rhoTyVec->data[ind - 1] / rhoNormVec->data[ind - 1];
      ind = (ind - 1) << 2;
      temp = theExp->data[ind];
      temp += theExp->data[ind + 1];
      temp += theExp->data[ind + 2];
      temp += theExp->data[ind + 3];
      temp = 0.25 * (d0 - bEstTmp[ii] * temp);
      aEstTmp[ii] = temp;

      //  Compute the residual
      b_aEstTmp[0] = temp + bEstTmp[ii] * std::exp(-x[0] / T1EstTmp[ii]);
      b_aEstTmp[1] = temp + bEstTmp[ii] * std::exp(-x[1] / T1EstTmp[ii]);
      b_aEstTmp[2] = temp + bEstTmp[ii] * std::exp(-x[2] / T1EstTmp[ii]);
      b_aEstTmp[3] = temp + bEstTmp[ii] * std::exp(-x[3] / T1EstTmp[ii]);
      b_rdivide_helper(b_aEstTmp, dataTmp_data, b_data);
      dataTmp_data[0] = 1.0 - b_data[0];
      dataTmp_data[1] = 1.0 - b_data[1];
      dataTmp_data[2] = 1.0 - b_data[2];
      dataTmp_data[3] = 1.0 - b_data[3];
      resTmp[ii] = 0.5 * b_norm(dataTmp_data);
    }

    emxFree_real_T(&r2);
    emxFree_real_T(&r1);
    emxFree_real_T(&r0);
    emxFree_real_T(&b_y);
    emxFree_real_T(&varargin_1);
    emxFree_real_T(&y);
    emxFree_real_T(&T1Vec);
    emxFree_real_T(&rhoNormVec);
    emxFree_real_T(&rhoTyVec);
    emxFree_real_T(&theExp);

    //  of for loop
    break;

   default:
    //  Here you can add other search methods
    break;
  }

  //  Finally, we choose the point of sign shift as the point giving
  //  the best fit to the data, i.e. the one with the smallest residual
  if ((resTmp[0] > resTmp[1]) || (rtIsNaN(resTmp[0]) && (!rtIsNaN(resTmp[1]))))
  {
    *res = resTmp[1];
    ind = 1;
  } else {
    *res = resTmp[0];
    ind = 0;
  }

  *aEst = aEstTmp[ind];
  *bEst = bEstTmp[ind];
  *T1Est = T1EstTmp[ind];
  if (ind + 1 == 1) {
    *idx = b_idx;

    //  best fit when inverting the signal at the minimum
  } else {
    *idx = (double)b_idx - 1.0;

    //  best fit when NOT inverting the signal at the minimum
  }
}

//
// File trailer for rdNlsPr.cpp
//
// [EOF]
//
