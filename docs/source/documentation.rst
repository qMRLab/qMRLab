qMRLab Introduction
===============================================================================
qMRLab is an open-source software for quantitative MR image analysis. The main goal
is to provide the community with an intuitive tool for data fitting, plotting, simulation and protocol optimization for a myriad of different quantitative models.
The modularity of the implementation makes it easy to add any additional modules and we encourage everyone to contribute their favorite recipe for qMR!

qMRLab is a fork from the initial project `qMTLab <https://github.com/neuropoly/qMTLab>`_.
For a quick **introduction** to qMTLab functionnalities, see the `qMTLab presentation e-poster <https://github.com/neuropoly/qMRLab/blob/master/docs/qMTLab-Presentation.ppsx>`_ or alternatively you can view it on `YouTube <https://youtu.be/WG0tVe-SFww>`_.

Data simulator
-------------------------------------------------------------------------------
The simulation interface allows end users to easily simulate qMR data and evaluate how well these models perform under known parameters input, determine the most appropriate acquisition protocol and evaluate how fitting constraints impact the results.

Data fitting and visualization
-------------------------------------------------------------------------------
The data fitting provides a simple interface to import real-world qMR data, fit them using the selected fitting procedure, and visualize the resulting parameter maps. More advanced users could also use the command line tools used in the background by the GUI to include data fitting in their analysis scripts.

Methods available
-------------------------------------------------------------------------------

diffusion
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.. toctree::
   :maxdepth: 1

   CHARMED_batch

.. toctree::
   :maxdepth: 1
   
   NODDI_batch

.. toctree::
   :maxdepth: 1
   
   DTI_batch

fieldmaps
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.. toctree::
   :maxdepth: 1

   B0_DEM_batch

.. toctree::
   :maxdepth: 1
   
   B1_DAM_batch

Myelin or macromolecular imaging
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. toctree::
   :maxdepth: 1

   bSSFP_batch

.. toctree::
   :maxdepth: 1
   
   SIRFSE_batch

.. toctree::
   :maxdepth: 1
   
   SPGR_batch

.. toctree::
   :maxdepth: 1
   
   MTSAT_batch

noise
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   NoiseLevel :  Noise histogram fitting within a noise mask

T1 mapping
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.. toctree::
   :maxdepth: 1

   IR_batch

   VFA: 


Getting started
===============================================================================
Dependencies
------------------------------------------------------------------------------
* MATLAB_R2013a or later (octave compatibility currently being implemented)

Installing qMRlab
--------------------------------------------------------------------------------

After installation, we strongly recommend that you run all tests in this repository (see Test section below) to ensure correct installation and code compatibility with your operating system and MATLAB version.

Command-Line Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you have git available on a command-line interface (e.g. Terminal on Mac OSX, Git Shell on Windows), the installation can be completed using a few quick commands.

* In the command-line interface, navigate (`cd`) to the directory that you want to install qMRLab

* Clone the directory::

    git clone https://github.com/neuropoly/qMRLab.git

* Open MATLAB, got to the qMRLab folder and run `startup`.

* To start a qMRLab session, run `qMRLab`.

Zip Download Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The latest stable version of qMRLab can be downloaded freely `here <https://github.com/neuropoly/qMRLab/tarball/master>`_.

* Extract the downloaded file to the directory you want to install qMRLab.

* Open MATLAB, got to the qMRLab folder and run `startup`.

* To start a qMRLab session, run `qMRLab`.

Tests
--------------------------------------------------------------------------------

After installing the software, we suggest that the you evaluate all the test cases for the software.

Run all tests
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
To run all tests, from MATLAB (assuming you are already in the qMRLab directory), execute the following command::

    result = runtests(pwd, 'Recursively', true)

Any failed test should be resolved prior to starting a workflow. Users are invited to raise the issue on the GitHub
repository `here <https://github.com/neuropoly/qMRLab/issues>`_.

Run Test Suite
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

During development of new features or bug-fixing, it may be preferable to run a test suite relevant to a specific category.
To do so, go to the 'test' folder::

    cd Test/

and run the following command::

    result = runTestSuite('Tag')

substituting `'Tag'` for one of the following test tags.

Current Test tags: 'Unit', 'Integration', 'Demo', 'SPGR', 'bSSFP', 'SIRFSE'.

Usage Guidelines
================================================================================
.. toctree::
   :maxdepth: 2

   gui_usage


Citation
===============================================================================

If you use qMRLab in you work, please cite:

Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S., Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

Please also cite the reference for the particular module you are using (specified in each model's page).
