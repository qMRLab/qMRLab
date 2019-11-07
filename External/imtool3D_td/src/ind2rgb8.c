/*
 * RGB = IND2RGB8(X,CMAP) creates an RGB image of class uint8.  X must be
 * uint8, uint16, or double, and CMAP must be a valid MATLAB colormap.
 *
 * $Revision: 1.1.6.1 $
 */

#include <math.h>
#include "mex.h"

void validateInputs(int nrhs, const mxArray *prhs[])
{
    if (nrhs != 2)
    {
        mexErrMsgIdAndTxt("Images:ind2rgb8:wrongNumInputs",
                          "IND2RGB8 expected two input arguments.");
    }

    if (!mxIsDouble(prhs[0]) && !mxIsUint8(prhs[0]) && !mxIsUint16(prhs[0]))
    {
        mexErrMsgIdAndTxt("Images:ind2rgb8:invalidInputType",
                          "X must be uint8, uint16, or double.");
    }

    if (mxGetNumberOfDimensions(prhs[0]) != 2)
    {
        mexErrMsgIdAndTxt("Images:ind2rgb8:inputNot2D",
                          "X must be two-dimensional.");
    }

    if (mxIsSparse(prhs[0]))
    {
        mexErrMsgIdAndTxt("Images:ind2rgb8:sparseInput",
                          "X must not be sparse.");
    }

    if ((mxGetNumberOfDimensions(prhs[1]) != 2) ||
        (mxGetN(prhs[1]) != 3))
    {
        mexErrMsgIdAndTxt("Images:ind2rgb8:invalidMapSize",
                          "CMAP must be a P-by-3 matrix.");
    }
    
    if (!mxIsDouble(prhs[1]))
    {
        mexErrMsgIdAndTxt("Images:ind2rgb8:invalidMapType",
                          "CMAP must be double.");
    }

    if (mxIsSparse(prhs[1]))
    {
        mexErrMsgIdAndTxt("Images:ind2rgb8:sparseMap",
                          "CMAP must not be sparse.");
    }

    if (mxGetM(prhs[1]) < 1)
    {
        mexErrMsgIdAndTxt("Images:ind2rgb8:emptyMap",
                          "CMAP must have at least one row.");
    }
}

/*
 * computeColorTable() scales a table of double-precision values
 * between 0.0 and 1.0 into another table of uint8_T values
 * between 0 and 255.
 *
 * Input parameter in_pr is the input table of values between 0.0
 *     and 1.0.
 *
 * Input parameter table_length is the length of the input and
 *     output tables.
 *
 * Output parameter out_pr is the output table.
 *
 * NaNs in the input are converted to zeros in the output.  Values
 * less than 0.0 or greater than 1.0 in the input are converted to
 * 0 and 255, respectively.  Other values are converted by
 * multiplying by 255.0 and rounding.
 *
 */
void computeColorTable(double *in_pr, int table_length, uint8_T *out_pr)
{
    int k;

    for (k = 0; k < table_length; k++)
    {
        if (mxIsNaN(in_pr[k]))
        {
            out_pr[k] = 0;
        }
        else if (in_pr[k] < 0.0)
        {
            out_pr[k] = 0;
        }
        else if (in_pr[k] > 1.0)
        {
            out_pr[k] = 255;
        }
        else
        {
            out_pr[k] = (uint8_T) (255.0 * in_pr[k] + 0.5);
        }
    }
}

/*
 * convertDouble() converts an array of one-based index values into an
 * array of output values.  The output values are determined
 * via table lookup.
 *
 * Input parameter in_pr is the input array, containing one-based
 *     index values.
 *
 * Output parameter out_pr is the output array.
 *
 * Input parameter num_pixels is the length of the input
 *     and output arrays.
 *
 * Input parameter table_length is the length of the lookup table.
 *
 * Input parameter table is the lookup table containing output values.
 *
 * NaNs in the input array are assumed to be 1.  Input array values
 * less than 1 or greater than table_length are assumed to be 1 and
 * table_length, respectively.  All other input array values are rounded.
 *
 */
void convertDouble(double *in_pr, uint8_T *out_pr,
                   int num_pixels, int table_length, uint8_T *table)
{
    int k;
    double index;  /* one-based index value */

    for (k = 0; k < num_pixels; k++)
    {
        if (mxIsNaN(in_pr[k]))
        {
            index = 1;
        }
        else if (in_pr[k] < 1)
        {
            index = 1;
        }
        else if (in_pr[k] > table_length)
        {
            index = table_length;
        }
        else
        {
            index = floor(in_pr[k] + 0.5);
        }

        *out_pr++ = table[(int) index - 1];
    }
}

/*
 * convertUint8() converts an array of zero-based index values into an
 * array of output values.  The output values are determined
 * via table lookup.
 *
 * Input parameter in_pr is the input array, containing zero-based
 *     index values.
 *
 * Output parameter out_pr is the output array.
 *
 * Input parameter num_pixels is the length of the input
 *     and output arrays.
 *
 * Input parameter table_length is the length of the lookup table.
 *
 * Input parameter table is the lookup table containing output values.
 *
 * Input array values > table_length-1 are assumed to be
 * table_length-1.
 *
 */
void convertUint8(uint8_T *in_pr, uint8_T *out_pr,
                  int num_pixels, int table_length, uint8_T *table)
{
    int k;
    
    for (k = 0; k < num_pixels; k++)
    {
        if (in_pr[k] >= table_length)
        {
            *out_pr++ = table[table_length - 1];
        }
        else
        {
            *out_pr++ = table[in_pr[k]];
        }
    }
}

/*
 * convertUint16() converts an array of zero-based index values into an
 * array of output values.  The output values are determined
 * via table lookup.
 *
 * Input parameter in_pr is the input array, containing zero-based
 *     index values.
 *
 * Output parameter out_pr is the output array.
 *
 * Input parameter num_pixels is the length of the input
 *     and output arrays.
 *
 * Input parameter table_length is the length of the lookup table.
 *
 * Input parameter table is the lookup table containing output values.
 *
 * Input array values > table_length-1 are assumed to be
 * table_length-1.
 *
 */
void convertUint16(uint16_T *in_pr, uint8_T *out_pr,
                   int num_pixels, int table_length, uint8_T *table)
{
    int k;
    
    for (k = 0; k < num_pixels; k++)
    {
        if (in_pr[k] >= table_length)
        {
            *out_pr++ = table[table_length - 1];
        }
        else
        {
            *out_pr++ = table[in_pr[k]];
        }
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    int      output_size[3];
    uint8_T *red_table;
    uint8_T *green_table;
    uint8_T *blue_table;
    int      table_length;
    double  *map_pr;
    int      num_pixels;

    validateInputs(nrhs, prhs);

    num_pixels = mxGetNumberOfElements(prhs[0]);

    output_size[0] = mxGetM(prhs[0]);
    output_size[1] = mxGetN(prhs[0]);
    output_size[2] = 3;
    plhs[0] = mxCreateNumericArray(3, output_size, mxUINT8_CLASS, mxREAL);

    table_length = mxGetM(prhs[1]);
    red_table = (uint8_T *) mxMalloc(table_length * sizeof(*red_table));
    green_table = (uint8_T *) mxMalloc(table_length * sizeof(*green_table));
    blue_table = (uint8_T *) mxMalloc(table_length * sizeof(*blue_table));
    
    map_pr = (double *) mxGetData(prhs[1]);
    computeColorTable(map_pr, table_length, red_table);
    computeColorTable(map_pr + table_length, table_length, green_table);
    computeColorTable(map_pr + 2*table_length, table_length, blue_table);

    switch (mxGetClassID(prhs[0]))
    {
      case mxDOUBLE_CLASS:
        convertDouble((double *) mxGetData(prhs[0]),
                      (uint8_T *) mxGetData(plhs[0]),
                      num_pixels,
                      table_length,
                      red_table);
        convertDouble((double *) mxGetData(prhs[0]),
                      ((uint8_T *) mxGetData(plhs[0])) + num_pixels,
                      num_pixels,
                      table_length,
                      green_table);
        convertDouble((double *) mxGetData(prhs[0]),
                      ((uint8_T *) mxGetData(plhs[0])) + 2*num_pixels,
                      num_pixels,
                      table_length,
                      blue_table);
        break;
        
      case mxUINT8_CLASS:
        convertUint8((uint8_T *) mxGetData(prhs[0]),
                     (uint8_T *) mxGetData(plhs[0]),
                     num_pixels,
                     table_length,
                     red_table);
        convertUint8((uint8_T *) mxGetData(prhs[0]),
                     ((uint8_T *) mxGetData(plhs[0])) + num_pixels,
                     num_pixels,
                     table_length,
                     green_table);
        convertUint8((uint8_T *) mxGetData(prhs[0]),
                     ((uint8_T *) mxGetData(plhs[0])) + 2*num_pixels,
                     num_pixels,
                     table_length,
                     blue_table);
        break;
        
      case mxUINT16_CLASS:
        convertUint16((uint16_T *) mxGetData(prhs[0]),
                      (uint8_T *) mxGetData(plhs[0]),
                      num_pixels,
                      table_length,
                      red_table);
        convertUint16((uint16_T *) mxGetData(prhs[0]),
                      ((uint8_T *) mxGetData(plhs[0])) + num_pixels,
                      num_pixels,
                      table_length,
                      green_table);
        convertUint16((uint16_T *) mxGetData(prhs[0]),
                      ((uint8_T *) mxGetData(plhs[0])) + 2*num_pixels,
                      num_pixels,
                      table_length,
                      blue_table);
        break;

      default:
        mexErrMsgIdAndTxt("Images:ind2rgb8:unexpectedType",
                          "Invalid input type.");
    }

    mxFree(red_table);
    mxFree(green_table);
    mxFree(blue_table);
}
