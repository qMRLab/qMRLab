# qMRILab (beta)

qMRIlab is a powerful, open source, scalable, easy to use and intuitive software for qMRI data simulation, fitting and analysis. The software consists of two parts:
1) a qMRI data fitting and visualization interface
2) a qMT data simulator


qMRILab is a fork from the initial project ['qMTLab'] (https://github.com/neuropoly/qMTLab):
  For a quick introduction to qMTLab functionnalities, see the ['qMTLab presentation e-poster'] (https://github.com/neuropoly/qMTLab/raw/master/qMTLab-Presentation.ppsx), or alternatively you can view it on ['YouTube']
                                                                                                                                                                                                              (https://youtu.be/WG0tVe-SFww).


The simulation part allows end users to easily simulate qMT data using the above described methods, evaluate how well these models perform under known parameters input, determine the most appropriate acquisition protocol and evaluate how fitting constraints impact the results. The data fitting part provides a simple interface to import real-world qMT data, fit them using the selected fitting procedure, and visualize the resulting parameters maps.

Please view ['ReadMe.docx'](https://github.com/neuropoly/qMTLab/raw/master/ReadMe.docx) for details.

Please report any bug or suggestions in [github](https://github.com/neuropoly/qMTLab/issues).


## Tests

After installing the software, we suggest that the you evaluate all the test cases for the software. 

### Run all tests

To run all tests, from MATLAB (assuming you are already in the qMTLab_Tab1s directory), execute the following command.

`result = runtests(pwd, 'Recursively', true)`

Any failed test should be resolved prior to starting a workflow. Users are invited to raise the issue on the GitHub
repository: https://github.com/neuropoly/qMRILab/issues

### Run Test Suite

During development of new features or bug-fixing, it may be preferable to run a test suite relevant to a specific category.
To do so, go to the 'test' folder

`cd Test/`

and run the following command:

`result = runTestSuite('Tag')`

substituting `Tag` for one of the following test tags. If you develop new tests and give it a tag which isn't on this list,
please update the README.md file accordingly.

Current Test tags:

* Unit

* SPGR

## Citation

If you use qMRILab in you work, please cite:

Cabana, J.-F., Gu, Y., Boudreau, M., Levesque, I. R., Atchia, Y., Sled, J. G., Narayanan, S., Arnold, D. L., Pike, G. B., Cohen-Adad, J., Duval, T., Vuong, M.-T. and Stikov, N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
