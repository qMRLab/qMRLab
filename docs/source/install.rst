How to install
===============================================================================

Citation
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you use qMRLab in you work, please cite:

Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S., Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

Please also cite the reference for the particular module you are using (specified in each model's page).

Dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
* MATLAB_R2014b or later with Optimization Toolbox 
or
* Octave 4.2.1 or later

Zip Download Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The latest stable version of qMRLab can be downloaded freely `here <https://github.com/neuropoly/qMRLab/archive/master.zip>`_.

* Extract the downloaded file to the directory you want to install qMRLab.

* Open MATLAB, got to the qMRLab folder and run `startup`.

* To start a qMRLab session, run `qMRLab`.


Command-Line Instructions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you have git available on a command-line interface (e.g. Terminal on Mac OSX, Git Shell on Windows), the installation can be completed using a few quick commands.

* In the command-line interface, navigate (`cd`) to the directory that you want to install qMRLab

* Clone the directory::

    git clone https://github.com/neuropoly/qMRLab.git

* Open MATLAB, got to the qMRLab folder and run `startup`.

* To start a qMRLab session, run `qMRLab`.

Tests
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After installing the software, we recommend you evaluate all the test cases for the software.

To run all tests, from MATLAB or Octave (assuming you are already in the qMRLab directory), execute the following command::

	cd Test/MoxUnitCompatible/

and run the following command::

	moxunit_runtests -recursive