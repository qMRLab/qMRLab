/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: _coder_rdNlsPr_api.h
 *
 * MATLAB Coder version            : 4.1
 * C/C++ source code generated on  : 12-Feb-2020 15:04:36
 */

#ifndef _CODER_RDNLSPR_API_H
#define _CODER_RDNLSPR_API_H

/* Include Files */
#include "tmwtypes.h"
#include "mex.h"
#include "emlrt.h"
#include <stddef.h>
#include <stdlib.h>
#include "_coder_rdNlsPr_api.h"

/* Type Definitions */
#ifndef typedef_struct0_T
#define typedef_struct0_T

typedef struct {
  real_T tVec[4];
  real_T N;
  real_T T1Vec[5000];
  real_T T1Start;
  real_T T1Stop;
  real_T T1Len;
  char_T nlsAlg[4];
  real_T nbrOfZoom;
  real_T T1LenZ;
  real_T theExp[20000];
  real_T rhoNormVec[5000];
} struct0_T;

#endif                                 /*typedef_struct0_T*/

/* Variable Declarations */
extern emlrtCTX emlrtRootTLSGlobal;
extern emlrtContext emlrtContextGlobal;

/* Function Declarations */
extern void rdNlsPr(real_T data[4], struct0_T *nlsS, real_T *T1Est, real_T *bEst,
                    real_T *aEst, real_T *res, real_T *idx);
extern void rdNlsPr_api(const mxArray * const prhs[2], int32_T nlhs, const
  mxArray *plhs[5]);
extern void rdNlsPr_atexit(void);
extern void rdNlsPr_initialize(void);
extern void rdNlsPr_terminate(void);
extern void rdNlsPr_xil_terminate(void);

#endif

/*
 * File trailer for _coder_rdNlsPr_api.h
 *
 * [EOF]
 */
