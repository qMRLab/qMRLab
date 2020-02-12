//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: rdNlsPr_types.h
//
// MATLAB Coder version            : 4.1
// C/C++ source code generated on  : 12-Feb-2020 15:04:36
//
#ifndef RDNLSPR_TYPES_H
#define RDNLSPR_TYPES_H

// Include Files
#include "rtwtypes.h"

// Type Definitions
struct emxArray_real_T
{
  double *data;
  int *size;
  int allocatedSize;
  int numDimensions;
  boolean_T canFreeData;
};

typedef struct {
  double tVec[4];
  double N;
  double T1Vec[5000];
  double T1Start;
  double T1Stop;
  double T1Len;
  char nlsAlg[4];
  double nbrOfZoom;
  double T1LenZ;
  double theExp[20000];
  double rhoNormVec[5000];
} struct0_T;

#endif

//
// File trailer for rdNlsPr_types.h
//
// [EOF]
//
