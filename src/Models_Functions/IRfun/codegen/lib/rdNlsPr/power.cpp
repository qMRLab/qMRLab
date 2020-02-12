//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: power.cpp
//
// MATLAB Coder version            : 4.1
// C/C++ source code generated on  : 12-Feb-2020 15:04:36
//

// Include Files
#include "rt_nonfinite.h"
#include "rdNlsPr.h"
#include "power.h"
#include "rdNlsPr_emxutil.h"

// Function Definitions

//
// Arguments    : const emxArray_real_T *a
//                emxArray_real_T *y
// Return Type  : void
//
void power(const emxArray_real_T *a, emxArray_real_T *y)
{
  unsigned int unnamed_idx_0;
  unsigned int unnamed_idx_1;
  int nx;
  int k;
  unnamed_idx_0 = (unsigned int)a->size[0];
  unnamed_idx_1 = (unsigned int)a->size[1];
  nx = y->size[0] * y->size[1];
  y->size[0] = (int)unnamed_idx_0;
  y->size[1] = (int)unnamed_idx_1;
  emxEnsureCapacity_real_T(y, nx);
  nx = (int)unnamed_idx_0 * (int)unnamed_idx_1;
  for (k = 0; k < nx; k++) {
    y->data[k] = a->data[k] * a->data[k];
  }
}

//
// File trailer for power.cpp
//
// [EOF]
//
