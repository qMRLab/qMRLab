MTR
===================

Usage
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: console

   nextflow run mtrflow_BIDS.nf [OPTIONAL_ARGUMENTS] (--root)

Description
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``--root=/path/to/[root]``                    Root folder containing multiple subjects

Container requirements 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you have Docker installed, enabling docker option will make use of the 
following Docker images to execute processes: 

  - qmrlab/minimal (https://hub.docker.com/repository/docker/qmrlab/minimal)
                    594MB extends to 1.5GB
                    Built at each qMRLab release.  
                    Minimum version requirement: v2.3.1 
  - qmrlab/antsfsl (https://hub.docker.com/repository/docker/qmrlab/antsfsl)
                    374MB extends to 1.2GB                      
                    Dockerfile is available at qMRLab/qMRflow.

Local installation requirements 
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Unless the docker option is enabled in the `nextflow.config`, the following
dependencies must be installed and added to the system path: 

  * ANTs registration (https://github.com/ANTsX/ANTs)
  * FSL (https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/)
  * Octave/MATLAB (https://www.gnu.org/software/octave/,https://www.mathworks.com/)
  * qMRLab > v2.3.1 (https://qmrlab.org)
  * git

Folder organization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: console

    BIDS convention                         
    mtrflow_BIDS.nf

    [root]
    ├── sub-01
    │   └── anat
    │       ├── sub-01_acq-MTon_MTR.nii.gz
    |       ├── sub-01_acq-MTon_MTR.json
    │       ├── sub-01_acq-MToff_MTR.nii.gz
    │       └── sub-01_acq-MToff_MTR.json
    └── sub-02
            └── anat
                ├── sub-02_acq-MTon_MTR.nii.gz
                ├── sub-02_acq-MTon_MTR.json
                ├── sub-02_acq-MToff_MTR.nii.gz
                └── sub-02_acq-MToff_MTR.json

NOTE: This workflow can use a subset of the MTsat (`MTS`) data. You can see 
the folder organization for MTS in `mt_sat/USAGE` in this repository.

Optional arguments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

--platform                      ["octave"/"matlab"] Platform choice. 
--qmrlab_dir                    ["/path/to/qMRLab" OR null] Absolute path to the qMRLab's
                                root directory. If docker is enabled, MUST be set
                                to null (without double quotes). If docker is NOT enabled,
                                then the absolute path to the qMRLab MUST be provided.
                                Note that qMRLab version MUST be equal or greater than v2.3.1.
--octave_path                   ["/path/to/octave_exec" OR null] Absolute path to Octave's
                                executable. If docker is enabled, or, if you'd like to use
                                Octave executable saved to your system path, MUST be set to
                                null (without double quotes).
--matlab_path                   ["/path/to/matlab_exec" OR null] Absolute path to MATLAB's
                                executable. If you'd like to use MATLAB executable saved to
                                your system path, MUST be set to null (without double quotes).
                                Note that qMRLab requires MATLAB > R2014b. Docker image
                                containing MCR compiled version of this application is NOT
                                available yet. Therefore, container declerations for the
                                processes starting with Fit_ prefix MUST be set to null
                                (without double quotes).
--ants_dim                      [2/3/4] This option forces the image to be treated
                                as a specified-dimensional image. If not specified,
                                ANTs tries to infer the dimensionality.
--ants_metric                   ["MI"] Confined to MI: Mutual information, for this
                                particular pipeline.
--ants_metric_weight            [0-1] If multimodal (i.e. changing contrast) use weight 1.
                                This parameter is used to modulate the per stagehting
                                of the metrics.
--ants_metric_bins              [e.g. 32] Number of bins.
--ants_metric_sampling          ["Regular","Random:]The point set can be on a regular
                                lattice or a random lattice of points slightly perturbed
                                to minimize aliasing artifacts.
--ants_metric_samplingprct      [0-100] The fraction of points to select from the domain
--ants_transform                * "Rigid"
                                * "Affine"
                                * "CompositeAffine"
                                * "Similarity"
                                * "Translation"
                                * "BSpline"
--ants_convergence              [MxNxO,<convergenceThreshold=1e-6>,<convergenceWindowSize=10>]
                                Convergence is determined from the number of iterations per level
                                and is determined by fitting a line to the normalized energy
                                profile of the last N iterations (where N is specified by the window
                                size) and determining the slope which is then compared with theconvergence threshold.
--ants_shrink                   [MxNxO] Specify the shrink factor for the virtual domain (typically
                                the fixed image) at each level.
--ants_smoothing                [MxNxO] Specify the sigma of gaussian smoothing at each level.
                                Units are given in terms of voxels ('vox') or physical spacing ('mm').
                                Example usage is '4x2x1mm' and '4x2x1vox' where no units implies voxel spacing.
--use_b1cor                     [true/false] Use and RF transmit field to correct for flip angle
                                imperfections. 
--b1cor_factor                  [0-1] Correction factor (empirical) for the transmit RF. Only
                                corrects MTSAT, not T1. Default 0.4. 
--use_bet                       Use FSL's BET for skull stripping.
--bet_recursive                 [true/false] This option runs more "robust" brain center estimation.
--bet_threshold                 [0-1] Fractional intensity threshold (0->1); default=0.45; 
                                smaller values give larger brain outline estimates

NOTES

- BIDS:

  mtrflow_BIDS.nf             To process BIDSified MTR data. Note that BIDS for 
                              quantitative MRI data is under development as of 
                              early 2020. You can visit the GitHub project page
                              [here](https://github.com/bids-standard/bep001). 
- Example datasets: 

Custom-organized data       TBA
BIDSified MTsat data        https://osf.io/k4bs5/

- Files should be compressed Nifti files (.nii.gz)

- Timing parameters in the .json files MUST be in seconds. 

- Subject IDs are used as the primary process ID and tag throughout the pipeline. 

- We adhere to a strict one-process one-container mapping, where possible using off-the shelf
  qMRLab containers. 

- All the OPTIONAL ARGUMENTS can be modified in the `nextflow.config` file. The same 
  config file is consumed by `mtrflow_BIDS.nf`.

- You can take advantage of Nextflow's comprehensive tracing and visualization 
  features while executing this pipeline: https://www.nextflow.io/docs/latest/tracing.html. 

- For any requests, questions or contributions, please feel free to open
  an issue at qMRflow's GitHub repo at https://github.com/qMRLab/qMRflow. 

Reference
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Please cite the following if you use this module:

Karakuzu A. et al. 2019 The qMRLab workflow: From acquisition to publication., ISMRM 27th Annual Meeting and Exhibition, Montreal, Canada. 