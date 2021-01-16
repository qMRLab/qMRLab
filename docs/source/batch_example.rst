Beginner's example with CLI
====================================
This will guide you through the steps to create a script that can be used to process sample data. The generated example script scan then be used as a guideline to analyze your own data.

1. Open MATLAB and setup path 
----------------------------------

Open MATLAB, then go to qMRLab installation folder (note: replace "PATH_QMRLAB" with the actual path) ::

	cd PATH_QMRLAB

Setup your path (note: you only need to do it once) ::

	startup

2. Generate a batch example
------------------------------
To get familiar with the command-line usage, you can automatically generate an example (with sample data) for your model of choice. For example, for *inversion_recovery* type::

	model=inversion_recovery; % create an instance of the model
	qMRgenBatch(model)

When prompted, select the folder where you want to download the data and save the batch example file.

3. Run the batch
----------------------------
You can run the example directly::

	inversion_recovery_batch

or take a look at the sections independently::

	edit inversion_recovery_batch

Please refer to :ref:`inversion_recovery: Compute a T1 map using Inversion Recovery data` to see a batch example and the expected output.

Please refer to :ref:`Command-Line Usage` for a more detailed description of the available functions
