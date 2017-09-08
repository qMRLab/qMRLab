qMRlab Introduction
===============================================================================
qMRLab is an open-source software for quantitative MR image analysis. The main goal
is to provide the community with an intuitive tool for data fitting, plotting, simulation and protocol optimization for a myriad of different quantitative models.
The modularity of the implementation makes it easy to add any additional modules and we encourage everyone to contribute their favorite recipe for qMR!

Features
===============================================================================
The program consists of two main features:
  1) a qMR data simulator
  2) a qMR data fitting and visualization interface
  
The simulation interface allows end users to easily simulate qMR data and evaluate how well these models perform under known parameters input, determine the most appropriate acquisition protocol and evaluate how fitting constraints impact the results. The data fitting provides a simple interface to import real-world qMR data, fit them using the selected fitting procedure, and visualize the resulting parameter maps. More advanced users could also use the command line tools used in the background by the GUI to include data fitting in their analysis scripts.

Installing qMRlab
===============================================================================

qMRlab was developed in *Matlab* but efforts are being made to make it compatible with *octave*

* Get a copy of the latest master repository through git::

    git clone https://github.com/neuropoly/qMRLab.git

* Or simply download a zipped version of the package on::

    https://github.com/neuropoly/qMRLab




Licensing
===============================================================================


Acknowledgements
===============================================================================
Many
