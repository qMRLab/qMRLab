classdef MTSAT
%-----------------------------------------------------------------------------------------------------
% MTSAT :  Correction of Magnetization transfer for RF inhomogeneities and T1 
%          MTsat is a semi-quantitative method. MTsat values depend on
%          protocol parameters.
%-----------------------------------------------------------------------------------------------------
%-------------%
% ASSUMPTIONS %
%-------------% 
% (1) FILL
% (2) 
% (3) 
% (4) 
%
%-----------------------------------------------------------------------------------------------------
%--------%
% INPUTS %
%--------%
%   MTw : MT-weighted
%   T1w : T1-weighted
%   PDw : PD-weighted
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%	MTSAT
%      
%-----------------------------------------------------------------------------------------------------
%----------%
% PROTOCOL %
%----------%
%   One T1-weighted
%   One MT-weighted
%   One PD-weighted
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OPTIONS %
%---------%
%   None
%
%-----------------------------------------------------------------------------------------------------
% Written by: Pascale Beliveau (pascale.beliveau@polymtl.ca)
% Reference: Helms, G., Dathe, H., Kallenberg, K., Dechent, P., 2008. High-resolution maps of magnetization transfer with inherent correction for RF inhomogeneity and T1 relaxation obtained from 3D FLASH MRI. Magn. Reson. Med. 60, 1396?1407.
%-----------------------------------------------------------------------------------------------------
    properties
        MRIinputs = {'MTw','T1w', 'PDw', 'Mask'};
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
