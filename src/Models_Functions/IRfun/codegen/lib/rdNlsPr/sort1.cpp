//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: sort1.cpp
//
// MATLAB Coder version            : 4.1
// C/C++ source code generated on  : 12-Feb-2020 15:04:36
//

// Include Files
#include "rt_nonfinite.h"
#include "rdNlsPr.h"
#include "sort1.h"

// Function Definitions

//
// Arguments    : double x[4]
//                int idx[4]
// Return Type  : void
//
void sort(double x[4], int idx[4])
{
  double x4[4];
  int idx4[4];
  double xwork[4];
  int nNaNs;
  int ib;
  int quartetOffset;
  signed char perm[4];
  int i2;
  int i3;
  int i4;
  double d1;
  double d2;
  idx[0] = 0;
  x4[0] = 0.0;
  idx4[0] = 0;
  xwork[0] = 0.0;
  idx[1] = 0;
  x4[1] = 0.0;
  idx4[1] = 0;
  xwork[1] = 0.0;
  idx[2] = 0;
  x4[2] = 0.0;
  idx4[2] = 0;
  xwork[2] = 0.0;
  idx[3] = 0;
  x4[3] = 0.0;
  idx4[3] = 0;
  xwork[3] = 0.0;
  nNaNs = 0;
  ib = 0;
  if (rtIsNaN(x[0])) {
    idx[3] = 1;
    xwork[3] = x[0];
    nNaNs = 1;
  } else {
    ib = 1;
    idx4[0] = 1;
    x4[0] = x[0];
  }

  if (rtIsNaN(x[1])) {
    idx[3 - nNaNs] = 2;
    xwork[3 - nNaNs] = x[1];
    nNaNs++;
  } else {
    ib++;
    idx4[ib - 1] = 2;
    x4[ib - 1] = x[1];
  }

  if (rtIsNaN(x[2])) {
    idx[3 - nNaNs] = 3;
    xwork[3 - nNaNs] = x[2];
    nNaNs++;
  } else {
    ib++;
    idx4[ib - 1] = 3;
    x4[ib - 1] = x[2];
  }

  if (rtIsNaN(x[3])) {
    idx[3 - nNaNs] = 4;
    xwork[3 - nNaNs] = x[3];
    nNaNs++;
  } else {
    ib++;
    idx4[ib - 1] = 4;
    x4[ib - 1] = x[3];
    if (ib == 4) {
      quartetOffset = 3 - nNaNs;
      if (x4[0] <= x4[1]) {
        ib = 1;
        i2 = 2;
      } else {
        ib = 2;
        i2 = 1;
      }

      if (x4[2] <= x4[3]) {
        i3 = 3;
        i4 = 4;
      } else {
        i3 = 4;
        i4 = 3;
      }

      d1 = x4[ib - 1];
      d2 = x4[i3 - 1];
      if (d1 <= d2) {
        if (x4[i2 - 1] <= d2) {
          perm[0] = (signed char)ib;
          perm[1] = (signed char)i2;
          perm[2] = (signed char)i3;
          perm[3] = (signed char)i4;
        } else if (x4[i2 - 1] <= x4[i4 - 1]) {
          perm[0] = (signed char)ib;
          perm[1] = (signed char)i3;
          perm[2] = (signed char)i2;
          perm[3] = (signed char)i4;
        } else {
          perm[0] = (signed char)ib;
          perm[1] = (signed char)i3;
          perm[2] = (signed char)i4;
          perm[3] = (signed char)i2;
        }
      } else {
        d2 = x4[i4 - 1];
        if (d1 <= d2) {
          if (x4[i2 - 1] <= d2) {
            perm[0] = (signed char)i3;
            perm[1] = (signed char)ib;
            perm[2] = (signed char)i2;
            perm[3] = (signed char)i4;
          } else {
            perm[0] = (signed char)i3;
            perm[1] = (signed char)ib;
            perm[2] = (signed char)i4;
            perm[3] = (signed char)i2;
          }
        } else {
          perm[0] = (signed char)i3;
          perm[1] = (signed char)i4;
          perm[2] = (signed char)ib;
          perm[3] = (signed char)i2;
        }
      }

      i3 = perm[0] - 1;
      idx[quartetOffset - 3] = idx4[i3];
      i4 = perm[1] - 1;
      idx[quartetOffset - 2] = idx4[i4];
      ib = perm[2] - 1;
      idx[quartetOffset - 1] = idx4[ib];
      i2 = perm[3] - 1;
      idx[quartetOffset] = idx4[i2];
      x[quartetOffset - 3] = x4[i3];
      x[quartetOffset - 2] = x4[i4];
      x[quartetOffset - 1] = x4[ib];
      x[quartetOffset] = x4[i2];
      ib = 0;
    }
  }

  if (ib > 0) {
    perm[1] = 0;
    perm[2] = 0;
    perm[3] = 0;
    if (ib == 1) {
      perm[0] = 1;
    } else if (ib == 2) {
      if (x4[0] <= x4[1]) {
        perm[0] = 1;
        perm[1] = 2;
      } else {
        perm[0] = 2;
        perm[1] = 1;
      }
    } else if (x4[0] <= x4[1]) {
      if (x4[1] <= x4[2]) {
        perm[0] = 1;
        perm[1] = 2;
        perm[2] = 3;
      } else if (x4[0] <= x4[2]) {
        perm[0] = 1;
        perm[1] = 3;
        perm[2] = 2;
      } else {
        perm[0] = 3;
        perm[1] = 1;
        perm[2] = 2;
      }
    } else if (x4[0] <= x4[2]) {
      perm[0] = 2;
      perm[1] = 1;
      perm[2] = 3;
    } else if (x4[1] <= x4[2]) {
      perm[0] = 2;
      perm[1] = 3;
      perm[2] = 1;
    } else {
      perm[0] = 3;
      perm[1] = 2;
      perm[2] = 1;
    }

    for (quartetOffset = 0; quartetOffset < ib; quartetOffset++) {
      i3 = perm[quartetOffset] - 1;
      i4 = ((quartetOffset - nNaNs) - ib) + 4;
      idx[i4] = idx4[i3];
      x[i4] = x4[i3];
    }
  }

  ib = (nNaNs >> 1) + 4;
  for (quartetOffset = 0; quartetOffset <= ib - 5; quartetOffset++) {
    i2 = (quartetOffset - nNaNs) + 4;
    i3 = idx[i2];
    idx[i2] = idx[3 - quartetOffset];
    idx[3 - quartetOffset] = i3;
    x[i2] = xwork[3 - quartetOffset];
    x[3 - quartetOffset] = xwork[i2];
  }

  if ((nNaNs & 1) != 0) {
    ib -= nNaNs;
    x[ib] = xwork[ib];
  }
}

//
// File trailer for sort1.cpp
//
// [EOF]
//
