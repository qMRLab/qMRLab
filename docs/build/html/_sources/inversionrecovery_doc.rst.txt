Inversion Recovery Documentation
===================================

InversionRecovery: Compute a T1 map using Inversion Recovery data

 Assumptions:
 	Gold standard for T1 mapping

 Inputs:
   IRData:      Inversion Recovery data (4D)
   (Mask):      Binary mask to accelerate the fitting (OPTIONAL)

 Outputs:
   T1          transverse relaxation time [ms]
   b           arbitrary fit parameter (S=a + b*exp(-TI/T1))
   a           arbitrary fit parameter (S=a + b*exp(-TI/T1))
   idx         index of last polarity restored datapoint (only used for magnitude data)
   res         Fitting residual

 Options:
   method: Method to use in order to fit the data, based on whether complex or only magnitude data acquired.
           'complex'   : RD-NLS (Reduced-Dimension Non-Linear Least Squares)
                              S=a + b*exp(-TI/T1)
           'magnitude' : RD-NLS-PR (Reduced-Dimension Non-Linear Least Squares with Polarity Restoration)
                              S=|a + b*exp(-TI/T1)|

 Protocol:
   TI      Array containing a list of inversion times [ms]

 Example of command line usage (also see qMRLab/Data/IR_demo/IR_batch.m):
      Model = InversionRecovery; % Create Model object
      Model.Prot.IRData.Mat = txt2mat('TI.txt'); %Load Inversion Recovery Protocol (list of inversion times, in ms)
      data = struct;  % Create data structure
      data.IRData = load_nii_data('IRdata.nii.gz'); % Load data
      data.Mask=load_nii_data('Mask.nii.gz');  % Load mask
      FitResults = FitData(data,Model,1);  % Fit each voxel within mask
      FitResultsSave_nii(FitResults,'IRdata.nii.gz'); % use header from 'IRdata.nii.gz' and save in local folder: FitResults/

 Author: Ilana Leppert, 2017

 References:
   Please cite the following if you use this module:
       A robust methodology for in vivo T1 mapping. Barral JK, Gudmundson E, Stikov N, Etezadi-Amoli M, Stoica P, Nishimura DG. Magn Reson Med. 2010 Oct;64(4):1057-67. doi: 10.1002/mrm.22497.
   In addition to citing the package:
       Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
