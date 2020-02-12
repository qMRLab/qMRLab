//
// Academic License - for use in teaching, academic research, and meeting
// course requirements at degree granting institutions only.  Not for
// government, commercial, or other organizational use.
// File: main.cpp
//
// MATLAB Coder version            : 4.1
// C/C++ source code generated on  : 12-Feb-2020 15:04:36
//

//***********************************************************************
// This automatically generated example C main file shows how to call
// entry-point functions that MATLAB Coder generated. You must customize
// this file for your application. Do not modify this file directly.
// Instead, make a copy of this file, modify it, and integrate it into
// your development environment.
//
// This file initializes entry-point function arguments to a default
// size and value before calling the entry-point functions. It does
// not store or use any values returned from the entry-point functions.
// If necessary, it does pre-allocate memory for returned values.
// You can use this file as a starting point for a main function that
// you can deploy in your application.
//
// After you copy the file, and before you deploy it, you must make the
// following changes:
// * For variable-size function arguments, change the example sizes to
// the sizes that your application requires.
// * Change the example values of function arguments to the values that
// your application requires.
// * If the entry-point functions return values, store these values or
// otherwise use them as required by your application.
//
//***********************************************************************
// Include Files
#include "rt_nonfinite.h"
#include "rdNlsPr.h"
#include "main.h"
#include "rdNlsPr_terminate.h"
#include "rdNlsPr_initialize.h"

// Function Declarations
static void argInit_1x4_char_T(char result[4]);
static void argInit_4x1_real_T(double result[4]);
static void argInit_4x5000_real_T(double result[20000]);
static void argInit_5000x1_real_T(double result[5000]);
static char argInit_char_T();
static double argInit_real_T();
static void argInit_struct0_T(struct0_T *result);
static void main_rdNlsPr();

// Function Definitions

//
// Arguments    : char result[4]
// Return Type  : void
//
static void argInit_1x4_char_T(char result[4])
{
  char result_tmp;

  // Loop over the array to initialize each element.
  // Set the value of the array element.
  // Change this value to the value that the application requires.
  result_tmp = argInit_char_T();
  result[0] = result_tmp;

  // Set the value of the array element.
  // Change this value to the value that the application requires.
  result[1] = result_tmp;

  // Set the value of the array element.
  // Change this value to the value that the application requires.
  result[2] = argInit_char_T();

  // Set the value of the array element.
  // Change this value to the value that the application requires.
  result[3] = argInit_char_T();
}

//
// Arguments    : double result[4]
// Return Type  : void
//
static void argInit_4x1_real_T(double result[4])
{
  double result_tmp;

  // Loop over the array to initialize each element.
  // Set the value of the array element.
  // Change this value to the value that the application requires.
  result_tmp = argInit_real_T();
  result[0] = result_tmp;

  // Set the value of the array element.
  // Change this value to the value that the application requires.
  result[1] = result_tmp;

  // Set the value of the array element.
  // Change this value to the value that the application requires.
  result[2] = argInit_real_T();

  // Set the value of the array element.
  // Change this value to the value that the application requires.
  result[3] = argInit_real_T();
}

//
// Arguments    : double result[20000]
// Return Type  : void
//
static void argInit_4x5000_real_T(double result[20000])
{
  int idx0;
  int idx1;

  // Loop over the array to initialize each element.
  for (idx0 = 0; idx0 < 4; idx0++) {
    for (idx1 = 0; idx1 < 5000; idx1++) {
      // Set the value of the array element.
      // Change this value to the value that the application requires.
      result[idx0 + (idx1 << 2)] = argInit_real_T();
    }
  }
}

//
// Arguments    : double result[5000]
// Return Type  : void
//
static void argInit_5000x1_real_T(double result[5000])
{
  int idx0;

  // Loop over the array to initialize each element.
  for (idx0 = 0; idx0 < 5000; idx0++) {
    // Set the value of the array element.
    // Change this value to the value that the application requires.
    result[idx0] = argInit_real_T();
  }
}

//
// Arguments    : void
// Return Type  : char
//
static char argInit_char_T()
{
  return '?';
}

//
// Arguments    : void
// Return Type  : double
//
static double argInit_real_T()
{
  return 0.0;
}

//
// Arguments    : struct0_T *result
// Return Type  : void
//
static void argInit_struct0_T(struct0_T *result)
{
  // Set the value of each structure field.
  // Change this value to the value that the application requires.
  argInit_4x1_real_T(result->tVec);
  result->N = argInit_real_T();
  argInit_5000x1_real_T(result->T1Vec);
  result->T1Start = argInit_real_T();
  result->T1Stop = argInit_real_T();
  result->T1Len = argInit_real_T();
  argInit_1x4_char_T(result->nlsAlg);
  result->nbrOfZoom = argInit_real_T();
  result->T1LenZ = argInit_real_T();
  argInit_4x5000_real_T(result->theExp);
  argInit_5000x1_real_T(result->rhoNormVec);
}

//
// Arguments    : void
// Return Type  : void
//
static void main_rdNlsPr()
{
  double dv0[4];
  static struct0_T r3;
  double T1Est;
  double bEst;
  double aEst;
  double res;
  double idx;

  // Initialize function 'rdNlsPr' input arguments.
  // Initialize function input argument 'data'.
  // Initialize function input argument 'nlsS'.
  // Call the entry-point 'rdNlsPr'.
  argInit_4x1_real_T(dv0);
  argInit_struct0_T(&r3);
  rdNlsPr(dv0, &r3, &T1Est, &bEst, &aEst, &res, &idx);
}

//
// Arguments    : int argc
//                const char * const argv[]
// Return Type  : int
//
int main(int, const char * const [])
{
  // Initialize the application.
  // You do not need to do this more than one time.
  rdNlsPr_initialize();

  // Invoke the entry-point functions.
  // You can call entry-point functions multiple times.
  main_rdNlsPr();

  // Terminate the application.
  // You do not need to do this more than one time.
  rdNlsPr_terminate();
  return 0;
}

//
// File trailer for main.cpp
//
// [EOF]
//
