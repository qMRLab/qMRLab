# Source

Gabriel Ramos Llordén (2025). NOVIFAST: A fast algorithm for accurate and precise VFA MRI (https://uk.mathworks.com/matlabcentral/fileexchange/67815-novifast-a-fast-algorithm-for-accurate-and-precise-vfa-mri), MATLAB Central File Exchange. Retrieved November 12, 2025.

# Contents

The original package contained the following Matlab scripts/functions:

1. `novifast_1D.m` (Function)  
    This code is the 1D version of the original NOVIFAST implementation [1]. It is meant to estimate the T1 value from an SPGR signal. To estimate a complete T1 map from an SPGR T1-weighted image set, we do not recommend to apply novifast_1D in a voxel-wise manner. Instead, we advocate for using 'novifast_image', also included in this NOVIFAST package.
2. `novifast_image.m` (Function)  
    This code is a vectorized version of the original NOVIFAST implementation [1].  It works on the VFA T1-weighted image set, and provides the estimated T1 map (NLLS sense) directly. It is not a voxel-wise, for-loop, implementation of 1D NOVIFAST. This is the code we recommend to use for fast VFA T1 mapping.

3. `demo_novifast_image.m` (script) -- see NOTE 
    In this script, Novifast is run with real 3D SPGR MRI data.

4. `demo_novifast_SNR.m` (script)  -- see NOTE  
    In this script, the behavior of NOVIFAST I as a function of SNR and number of iterations is presented. Experiments are performed with simulated SPGR MRI data.

5. `data` -- **SKIPPED**, see NOTE  
    Simulated and actual in-vivo VFA 3D (FSE sequence) data. Both included in folder “data”.

**NOTE**: Test Data has been omitted from this repo. Download the original source to run test scripts. 

**TODO**: Wrap test data in agreement with qMRLab policy and publish through OSF.


# Change log

2025/11/12 - Core functions copied from source
2025/11/17 - Replace package_list.txt by about.md