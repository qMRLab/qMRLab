/*
 * Academic License - for use in teaching, academic research, and meeting
 * course requirements at degree granting institutions only.  Not for
 * government, commercial, or other organizational use.
 * File: rt_nonfinite.cpp
 *
 * MATLAB Coder version            : 4.1
 * C/C++ source code generated on  : 12-Feb-2020 15:04:36
 */

/*
 * Abstract:
 *      MATLAB for code generation function to initialize non-finites,
 *      (Inf, NaN and -Inf).
 */
#include "rt_nonfinite.h"
#include <cmath>
#include <limits>

real_T rtInf;
real_T rtMinusInf;
real_T rtNaN;
real32_T rtInfF;
real32_T rtMinusInfF;
real32_T rtNaNF;

/* Function: rt_InitInfAndNaN ==================================================
 * Abstract:
 * Initialize the rtInf, rtMinusInf, and rtNaN needed by the
 * generated code. NaN is initialized as non-signaling. Assumes IEEE.
 */
void rt_InitInfAndNaN(size_t realSize)
{
  (void)realSize;
  rtNaN = std::numeric_limits<real_T>::quiet_NaN();
  rtNaNF = std::numeric_limits<real32_T>::quiet_NaN();
  rtInf = std::numeric_limits<real_T>::infinity();
  rtInfF = std::numeric_limits<real32_T>::infinity();
  rtMinusInf = -std::numeric_limits<real_T>::infinity();
  rtMinusInfF = -std::numeric_limits<real32_T>::infinity();
}

/* Function: rtIsInf ==================================================
 * Abstract:
 * Test if value is infinite
 */
boolean_T rtIsInf(real_T value)
{
  return ((value==rtInf || value==rtMinusInf) ? 1U : 0U);
}

/* Function: rtIsInfF =================================================
 * Abstract:
 * Test if single-precision value is infinite
 */
boolean_T rtIsInfF(real32_T value)
{
  return(((value)==rtInfF || (value)==rtMinusInfF) ? 1U : 0U);
}

/* Function: rtIsNaN ==================================================
 * Abstract:
 * Test if value is not a number
 */
boolean_T rtIsNaN(real_T value)
{
  return (value!=value)? 1U:0U;
}

/* Function: rtIsNaNF =================================================
 * Abstract:
 * Test if single-precision value is not a number
 */
boolean_T rtIsNaNF(real32_T value)
{
  return (value!=value)? 1U:0U;
}

/*
 * File trailer for rt_nonfinite.cpp
 *
 * [EOF]
 */
