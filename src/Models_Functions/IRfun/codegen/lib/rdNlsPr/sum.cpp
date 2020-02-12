//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: sum.cpp
//
// MATLAB Coder version            : 4.1
// C/C++ source code generated on  : 12-Feb-2020 15:04:36
//

// Include Files
#include "rt_nonfinite.h"
#include "rdNlsPr.h"
#include "sum.h"
#include "rdNlsPr_emxutil.h"

// Function Definitions

//
// Arguments    : const emxArray_real_T *x
//                emxArray_real_T *y
// Return Type  : void
//
void sum(const emxArray_real_T *x, emxArray_real_T *y)
{
  int npages;
  int i;
  int xpageoffset;
  if (x->size[1] == 0) {
    y->size[0] = 1;
    y->size[1] = 0;
  } else {
    npages = x->size[1];
    i = y->size[0] * y->size[1];
    y->size[0] = 1;
    y->size[1] = x->size[1];
    emxEnsureCapacity_real_T(y, i);
    for (i = 0; i < npages; i++) {
      xpageoffset = i << 2;
      y->data[i] = x->data[xpageoffset];
      y->data[i] += x->data[xpageoffset + 1];
      y->data[i] += x->data[xpageoffset + 2];
      y->data[i] += x->data[xpageoffset + 3];
    }
  }
}

//
// File trailer for sum.cpp
//
// [EOF]
//
