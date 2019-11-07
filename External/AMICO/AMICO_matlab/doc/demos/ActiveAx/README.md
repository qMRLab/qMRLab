# ActiveAx fitting tutorial

This tutorial shows how to use the AMICO framework to **fit the ActiveAx model**, using the example dataset distributed with the [ActiveAx tutorial](http://cmic.cs.ucl.ac.uk/camino/index.php?n=Tutorials.ActiveAx) in the Camino toolkit.

## Download data for this tutorial

1. Download the original DWI data from [here](http://dig.drcmr.dk/activeax-dataset/).

2. Create the folder `ActiveAxTutorial/Tutorial` in your data directory and merge the downloaded datasets into one:
```bash
export FSLOUTPUTTYPE=NIFTI
fslmerge -t DWI.nii \\
DRCMR_ActiveAx4CCfit_E2503_Mbrain1_B13183_3B0_ELEC_N90_Scan1_DIG.nii \\
DRCMR_ActiveAx4CCfit_E2503_Mbrain1_B1925_3B0_ELEC_N90_Scan1_DIG.nii \\
DRCMR_ActiveAx4CCfit_E2503_Mbrain1_B1931_3B0_ELEC_N90_Scan1_DIG.nii \\
DRCMR_ActiveAx4CCfit_E2503_Mbrain1_B3091_3B0_ELEC_N90_Scan1_DIG.nii
```

3. Download the scheme file from [here](http://cmic.cs.ucl.ac.uk/camino/uploads/Tutorials/ActiveAxG140_PM.scheme1) and save it into the same folder.
4. Download the binary mask of the corpus callosum from [here](http://hardi.epfl.ch/static/data/AMICO_demos/ActiveAx_Tutorial_MidSagCC.nii) to the same folder.

## Setup AMICO

Setup the AMICO environment:

```matlab
clearvars, clearvars -global, clc

% Setup AMICO
AMICO_Setup

% Pre-compute auxiliary matrices to speed-up the computations
AMICO_PrecomputeRotationMatrices(); % NB: this needs to be done only once and for all
```

## Load the data

Load the data:

```matlab
% Set the folder containing the data (relative to the data folder).
% This will create a CONFIG structure to keep all the parameters.
AMICO_SetSubject( 'ActiveAxTutorial', 'Tutorial' );

% Override default file names
CONFIG.dwiFilename    = fullfile( CONFIG.DATA_path, 'DWI.nii' );
CONFIG.maskFilename   = fullfile( CONFIG.DATA_path, 'ActiveAx_Tutorial_MidSagCC.nii' );
CONFIG.schemeFilename = fullfile( CONFIG.DATA_path, 'ActiveAxG140_PM.scheme1' );

% Load the dataset in memory
AMICO_LoadData
```

The output will look like:

```
-> Loading and setup:
	* Loading DWI...
		- dim    = 128 x 256 x 3 x 372
		- pixdim = 0.400 x 0.400 x 0.500
	* Loading SCHEME...
		- 372 measurements divided in 4 shells (12 b=0)
	* Loading MASK...
		- dim    = 128 x 256 x 3
		- voxels = 338
   [ DONE ]
```

## Generate the kernels

Generate the kernels corresponding to the different compartments of the ActiveAx model:

```matlab
% Setup AMICO to use the 'ActiveAx' model
AMICO_SetModel( 'ActiveAx' );

% Generate the kernels corresponding to the protocol
AMICO_GenerateKernels( false );

% Resample the kernels to match the specific subject's scheme
AMICO_ResampleKernels();
```

The output will look something like:

```
-> Generating kernels for protocol "ActiveAxTutorial":
	* Creating high-resolution scheme:
	  [ DONE ]
	* Simulating "ActiveAx" kernels:
		- A_001... [5.3 seconds]
		- A_002... [5.1 seconds]

        ...

		- A_028... [5.7 seconds]
		- A_029... [0.7 seconds]
	  [ 149.2 seconds ]
   [ DONE ]
   
-> Resampling rotated kernels for subject "Tutorial":
	- A_001...  [0.9 seconds]
	- A_002...  [0.9 seconds]

    ...

	- A_028...  [0.9 seconds]
	- A_029...  [0.0 seconds]
	- saving... [5.2 seconds]
   [ 33.4 seconds ]
```


## Fit the model

Actually **fit** the ActiveAx model using the AMICO framework:

```matlab
AMICO_Fit()
```

The output will look something like:

```
-> Fitting ACTIVEAX model to data:
   [ 0h 0m 0s ]

-> Saving output maps:
   [ AMICO/FIT_*.nii ]
```

![NRMSE for COMMIT](https://github.com/daducci/AMICO/blob/master/matlab/doc/demos/ActiveAx/RESULTS_Fig1.png)

The results will be saved as NIFTI/ANALYZE files in `ActiveAxTutorial/Tutorial/AMICO`.


