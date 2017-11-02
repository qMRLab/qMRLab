classdef MTSAT
% MTSAT:  Correction of Magnetization transfer for RF inhomogeneities and T1 
%         MTsat is a semi-quantitative method. MTsat values depend on
%         protocol parameters.
%<a href="matlab: figure, imshow MTSAT.png ;">Pulse Sequence Diagram</a>

%
% ASSUMPTIONS: 
% (1) FILL
% (2) 
% (3) 
% (4) 
%
% Inputs:
%   MTw                  MT-weighted
%   T1w                  T1-weighted
%   PDw                  PD-weighted
%
% Outputs:
%	MTSAT                FILL
%
% Protocol:
%   One T1-weighted
%
%   One MT-weighted
%
%   One PD-weighted
%
% Options:
%   None
%
% Command line usage:
%   <a href="matlab: qMRusage(MTSAT);">qMRusage(MTSAT)</a>
%   <a href="matlab: showdemo MTSAT_batch">showdemo MTSAT_batch</a>
%
% Author: Pascale Beliveau (pascale.beliveau@polymtl.ca)
%
% Reference:
%   Please cite the following if you use this module:
%      Helms, G., Dathe, H., Kallenberg, K., Dechent, P., 2008. High-resolution maps of magnetization transfer with inherent correction for RF inhomogeneity and T1 relaxation obtained from 3D FLASH MRI. Magn. Reson. Med. 60, 1396?1407.
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

    properties
        MRIinputs = {'MTw','T1w', 'PDw', 'Mask'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot = struct('MT',struct('Format',{{'Flip Angle' 'TR (s)' 'Offset (Hz)'}},...
                                   'Mat',  [6 0.028 1000]),...
                      'T1',struct('Format',{{'Flip Angle' 'TR'}},...
                                   'Mat',  [20 0.018]),...
                      'PD',struct('Format',{{'Flip Angle' 'TR'}},...
                                   'Mat',  [6 0.028]));        
        % Model options
        buttons = {};
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
            
            FitResult.MTSAT = MTSAT_exec(data, MTparams, PDparams, T1params);
        end
        
    end
end
