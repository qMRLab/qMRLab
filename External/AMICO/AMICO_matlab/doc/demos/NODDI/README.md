# NODDI fitting tutorial

This tutorial shows how to use the AMICO framework to **fit the NODDI model**, using the example dataset distributed with the [NODDI Matlab Toolbox](http://mig.cs.ucl.ac.uk/index.php?n=Tutorial.NODDImatlab).

## Download data for this tutorial

1. Download the original DWI data from [here](http://www.nitrc.org/frs/download.php/5508/NODDI_example_dataset.zip).
2. Create the folder `NoddiTutorial/Tutorial` in your data folder and extract into it the content of the downloaded archive `NODDI_example_dataset.zip`.
3. Copy the scheme file `NODDI_DWI.scheme` distributed with this tutorial into the folder.

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
AMICO_SetSubject( 'NoddiTutorial', 'Tutorial' );

% Override default file names
CONFIG.dwiFilename    = fullfile( CONFIG.DATA_path, 'NODDI_DWI.hdr' );
CONFIG.maskFilename   = fullfile( CONFIG.DATA_path, 'roi_mask.hdr' );
CONFIG.schemeFilename = fullfile( CONFIG.DATA_path, 'NODDI_DWI.scheme' );

% Load the dataset in memory
AMICO_LoadData
```

The output will look like:

```
-> Loading and setup:
	* Loading DWI...
		- dim    = 128 x 128 x 50 x 81
		- pixdim = 1.875 x 1.875 x 2.500
	* Loading SCHEME...
		- 81 measurements divided in 2 shells (9 b=0)
	* Loading MASK...
		- dim    = 128 x 128 x 50
		- voxels = 5478
   [ DONE ]
```

## Generate the kernels

Generate the kernels corresponding to the different compartments of the NODDI model:

```matlab
% Setup AMICO to use the 'NODDI' model
AMICO_SetModel( 'NODDI' );

% Generate the kernels corresponding to the protocol
AMICO_GenerateKernels( false );

% Resample the kernels to match the specific subject's scheme
AMICO_ResampleKernels();
```

The output will look something like:

```
-> Generating kernels for protocol "NoddiTutorial":
	* Creating high-resolution scheme:
	  [ DONE ] 
	* Simulating "NODDI" kernels:
		- A_001... [2.4 seconds]
		- A_002... [2.4 seconds]	

        ...

	    - A_144... [2.5 seconds]
	    - A_145... [0.0 seconds]
      [ 362.5 seconds ]
   [ DONE 

-> Resampling rotated kernels for subject "Tutorial":
	- A_001...  [0.5 seconds]
	- A_002...  [0.4 seconds]

    ...

	- A_144...  [0.4 seconds]
	- A_145...  [0.0 seconds]
	- saving... [5.2 seconds]
   [ 67.1 seconds ]
```


## Fit the model

Actually **fit** the NODDI model using the AMICO framework:

```matlab
AMICO_Fit()
```

The output will look something like:

```
-> Fitting NODDI model to data:
   [ 0h 0m 15s ]

-> Saving output maps:
   [ AMICO/FIT_*.nii ]
```

![NRMSE for COMMIT](https://github.com/daducci/AMICO/blob/master/matlab/doc/demos/NODDI/RESULTS_Fig1.png)

The results will be saved as NIFTI/ANALYZE files in `NoddiTutorial/Tutorial/AMICO/`.


