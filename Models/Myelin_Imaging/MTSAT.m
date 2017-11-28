classdef MTSAT
% MTSAT :  Correction of Magnetization transfer for RF inhomogeneities and T1
%
% Assumptions:
%   MTsat is a semi-quantitative method. MTsat values depend on protocol parameters.
%
% Inputs:
%   MTw     3D MT-weighted data. Spoiled Gradient Echo (or FLASH) with MT
%            pulse
%   T1w     3D T1-weighted data. Spoiled Gradient Echo (or FLASH)
%   PDw     3D PD-weighted data. Spoiled Gradient Echo (or FLASH)
%
% Outputs:
%	  MTSAT         MT saturation map, T1-corrected
%     T1            T1 map (s)            
%
% Options:
%     B1 correction factor     Correction factor (empirical) for the transmit RF. Only
%                               corrects MTSAT, not T1. 
%                               Weiskopf, N., Suckling, J., Williams, G., CorreiaM.M., Inkster, B., Tait, R., Ooi, C., Bullmore, E.T., Lutti, A., 2013. Quantitative multi-parameter mapping of R1, PD(*), MT, and R2(*) at 3T: a multi-center validation. Front. Neurosci. 7, 95.
%
% Protocol:
%     MT    [FA  TR  Offset]  flip angle [deg], TR [s], Offset Frequency [Hz]
%     T1    [FA  TR]          flip angle [deg], TR [s]
%     PD    [FA  TR]          flip angle [deg], TR [s]
%
% Example of command line usage (see also <a href="matlab: showdemo MTSAT_batch">showdemo MTSAT_batch</a>):
%   Model = MTSAT;  % Create class from model
%   Model.Prot.MT.Mat = txt2mat('MT.txt');  % Load protocol
%   Model.Prot.T1.Mat = txt2mat('T1.txt');
%   Model.Prot.PD.Mat = txt2mat('PD.txt');
%   data = struct;  % Create data structure
%   data.MTw = load_nii_data('MTw.nii.gz');
%   data.T1w = load_nii_data('T1w.nii.gz');
%   data.PDw = load_nii_data('PDw.nii.gz');  % Load data
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_nii(FitResults,'MTw.nii.gz'); % Save in local folder: FitResults/
%
%   For more examples: <a href="matlab: qMRusage(MTSAT);">qMRusage(MTSAT)</a>
%
% Author: Pascale Beliveau (pascale.beliveau@polymtl.ca)
%
% References:
%   Please cite the following if you use this module:
%     Helms, G., Dathe, H., Kallenberg, K., Dechent, P., 2008. High-resolution maps of magnetization transfer with inherent correction for RF inhomogeneity and T1 relaxation obtained from 3D FLASH MRI. Magn. Reson. Med. 60, 1396?1407.
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357


    properties
        MRIinputs = {'MTw','T1w', 'PDw', 'B1map', 'Mask'};
        xnames = {};
        voxelwise = 0;

        % Protocol
        Prot = struct('MT',struct('Format',{{'Flip Angle' 'TR (s)'}},...
                                   'Mat',  [6 0.028]),...
                      'T1',struct('Format',{{'Flip Angle' 'TR'}},...
                                   'Mat',  [20 0.018]),...
                      'PD',struct('Format',{{'Flip Angle' 'TR'}},...
                                   'Mat',  [6 0.028]));
        % Model options
        buttons = {'B1 correction factor', 0.4};
        options= struct();

    end

    methods
        function obj = MTSAT
            obj.options = button2opts(obj.buttons);
        end

        function FitResult = fit(obj,data)
            MTparams = obj.Prot.MT.Mat;

            PDparams = obj.Prot.PD.Mat;

            T1params = obj.Prot.T1.Mat;
            
            B1params = obj.options.B1correctionfactor;
            
            [FitResult.MTSAT, R1] = MTSAT_exec(data, MTparams, PDparams, T1params, B1params);
            FitResult.T1 = 1./R1;
        end

    end
end
