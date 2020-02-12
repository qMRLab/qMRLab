//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: abs.cpp
//
// MATLAB Coder version            : 4.1
// C/C++ source code generated on  : 12-Feb-2020 15:04:36
//

// Include Files
#include <cmath>
#include "rt_nonfinite.h"
#include "rdNlsPr.h"
#include "abs.h"
#include "rdNlsPr_emxutil.h"

// Function Definitions

//
// Arguments    : const emxArray_real_T *x
//                emxArray_real_T *y
// Return Type  : void
//
void b_abs(const emxArray_real_T *x, emxArray_real_T *y)
{
  int nx;
  int k;
  nx = x->size[0];
  k = y->size[0] * y->size[1];
  y->size[0] = x->size[0];
  y->size[1] = 1;
  emxEnsureCapacity_real_T(y, k);
  for (k = 0; k < nx; k++) {
    y->data[k] = std::abs(x->data[k]);
  }
}

//
// File trailer for abs.cpp
//
// [EOF]
//
