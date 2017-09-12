# qMRLab (beta) [![Build Status](https://travis-ci.org/neuropoly/qMRLab.svg?branch=master)](https://travis-ci.org/neuropoly/qMRLab)


qMRlab is a powerful, open source, scalable, easy to use and intuitive software for qMRI data simulation, fitting and analysis. The software consists of two parts:
1) a qMRI data fitting and visualization interface
2) a qMRI data simulator


qMRLab is a fork from the initial project ['qMTLab'](https://github.com/neuropoly/qMTLab).  
For a quick **introduction** to qMTLab functionnalities, see the ['qMTLab presentation e-poster'](https://github.com/neuropoly/qMRLab/raw/master/Documentation/qMTLab-Presentation.ppsx), or alternatively you can view it on ['YouTube'](https://youtu.be/WG0tVe-SFww).  
For further **documentation**, visit the ['Documentation website'](https://neuropoly.github.io/qMRLab/)
If you are a developer, visit the ['Wiki page'](https://github.com/neuropoly/qMRLab/wiki) 

The simulation part allows end users to easily simulate qMRI data using the above described methods, evaluate how well these models perform under known parameters input, determine the most appropriate acquisition protocol and evaluate how fitting constraints impact the results. 
The data fitting part provides a simple interface to import real-world qMT data, fit them using the selected fitting procedure, visualize the fitting quality in a specific pixel, visualize the resulting parameters maps.

Please report any bug or suggestions in [github](https://github.com/neuropoly/qMRLab/issues).

## qMR methods available:
* Diffusion/2D_Qspace/CHARMED (e.g. AxCaliber, Time-dependence)
* Diffusion/3D_Qspace/DTI
* Diffusion/3D_Qspace/NODDI
* FieldMaps/B0_DEM (Dual-echo method)
* FieldMaps/B1_DAM (Dual-angle method)
* Myelin Imaging/MTSAT
* Myelin Imaging/MWF
* Myelin Imaging/qMT/SIRFSE
* Myelin Imaging/qMT/SPGR
* Myelin Imaging/qMT/bSSFP
* Noise/NoiseLevel (Used in qMR methods to avoid signal bias)
* T1 Mapping/InversionRecovery
* T1 Mapping/VFA_T1
    
## Dependencies

* MATLAB_R2013a or later
OR
* Octave 4.2.1 or later

## Installation

After installation, we strongly recommend that you run all tests in this repository (see Test section below) to ensure correct installation and code compatibility with your operating system and MATLAB version.

### Command-Line Instructions

If you have git available on a command-line interface (e.g. Terminal on Mac OSX, Git Shell on Windows), the installation can be completed using a few quick commands.

* In the command-line interface, navigate (`cd`) to the directory that you want to install qMRLab

* Clone the directory:

`git clone https://github.com/neuropoly/qMRLab.git`

* Open MATLAB, got to the qMRLab folder and run `startup`.

* To start a qMRLab session, run `qMRLab`.

### Zip Download Instructions

The latest stable version of qMRLab can be downloaded freely [here](https://github.com/neuropoly/qMRLab/releases).

* Extract the downloaded file to the directory you want to install qMRLab.

* Open MATLAB, go to the qMRLab folder and run `startup`.

* To start a qMRLab session, run `qMRLab`.

## Tests

After installing the software, we recommend you evaluate all the test cases for the software.

To run all tests, from MATLAB or Octave (assuming you are already in the qMRLab directory), execute the following command.

`cd Test/MoxUnitCompatible/`

and run the following command:

`moxunit_runtests -recursive`


## Citation

If you use qMRLab in you work, please cite:

Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S., Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
