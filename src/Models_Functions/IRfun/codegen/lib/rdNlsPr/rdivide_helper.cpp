//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: rdivide_helper.cpp
//
// MATLAB Coder version            : 4.1
// C/C++ source code generated on  : 12-Feb-2020 15:04:36
//

// Include Files
#include "rt_nonfinite.h"
#include "rdNlsPr.h"
#include "rdivide_helper.h"
#include "rdNlsPr_emxutil.h"

// Function Definitions

//
// Arguments    : const double x[4]
//                const double y_data[]
//                double z[4]
// Return Type  : void
//
void b_rdivide_helper(const double x[4], const double y_data[], double z[4])
{
  z[0] = x[0] / y_data[0];
  z[1] = x[1] / y_data[1];
  z[2] = x[2] / y_data[2];
  z[3] = x[3] / y_data[3];
}

//
// Arguments    : const emxArray_real_T *x
//                const emxArray_real_T *y
//                emxArray_real_T *z
// Return Type  : void
//
void rdivide_helper(const emxArray_real_T *x, const emxArray_real_T *y,
                    emxArray_real_T *z)
{
  int i1;
  int loop_ub;
  i1 = z->size[0];
  z->size[0] = x->size[0];
  emxEnsureCapacity_real_T(z, i1);
  loop_ub = x->size[0];
  for (i1 = 0; i1 < loop_ub; i1++) {
    z->data[i1] = x->data[i1] / y->data[i1];
  }
}

//
// File trailer for rdivide_helper.cpp
//
// [EOF]
//
