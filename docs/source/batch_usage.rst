Command Line Interface (CLI)
====================================

General structure
-----------------------
The models are objects, each with a set of properties and generic functions.
Before interacting with a model, it must first be instantiated, e.g. ::

	model=charmed

General commands
-----------------------
- **qMRInfo(model)** : Print the help for the 'model' object
- **qMRusage(model)** : Print the methods of 'model' and examples of how to interact with them
- **qMRgenBatch(model)** : Generate a batch example script for 'model' (will automatically download test data)


Model structure
-------------------------
All models have the following properties:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- **MRIinputs** : Names of input data 
- **voxelwise** : Whether the fit is voxelwise [1] or a matrix operation [0]
- **xnames** : Names of output data
- **Prot** : structure containing the protocol parameters
- **buttons** : 
- **Options** : options specific to the model (e.g. linear or non-linear fir for VFA-T1)


And functions:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- **equation**::

   Compute MR signal
   USAGE:
     Smodel = Model.equation(x)
   INPUT:
     x: [struct] OR [vector] containing Model output parameters
 
- **fit**::

   Fit experimental data
   USAGE:
     FitResults = Model.fit(data)
   INPUT:
     data: [struct] containing input data IN ORDER as in MRinuts
   NOTE: data are 1D. For 4D datasets use FitData(data,Model)

- **plotModel**::

   Plot model equation (and fitting)
   USAGE:
          Model.plotModel(obj, x)
          Model.plotModel(obj, x, data)
   INPUT:
     x: [struct] OR [vector] containing Model output parameters
     data: [struct] containing input data in ORDER as in MRinuts

Most models have these additional functions:
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- **Sim_Sensitivity_Analysis**::

   Simulates sensitivity to fitted parameters:
      (1) vary fitting parameters from lower (lb) to upper (ub) bound in 10 steps
      (2) run Sim_Single_Voxel_Curve Nofruns times
      (3) Compute mean and std across runs
   USAGE:
     SimVaryResults = Model.Sim_Sensitivity_Analysis(OptTable, Opt);
   INPUT:
     OptTable: [struct] nominal value and range for each parameter.
        st: [vector] nominal values for output parameters
        fx: [binary vector] do not vary this parameter?
        lb: [vector] vary from lb...
        ub: [vector] up to ub
     Opt: [struct] Options of the simulation 
 
- **Sim_Single_Voxel_Curve**::

   Simulates Single Voxel curves:
      (1) use equation to generate synthetic MRI data
      (2) add rician noise
      (3) fit and plot curve
   USAGE:
     FitResults = Model.Sim_Single_Voxel_Curve(x)
     FitResults = Model.Sim_Single_Voxel_Curve(x, Opt,display)
   INPUT:
     x: [struct] OR [vector] containing fit results
     display: [binary] 1=display, 0=nodisplay


Please type the following to see the specific usage of the model you are interested in ::

	qMRusage(model)

Or the batch example associated with your model located here :ref:`Methods available`