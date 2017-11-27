classdef MTSAT
%-----------------------------------------------------------------------------------------------------
% MTSAT :  Correction of Magnetization transfer for RF inhomogeneities and T1 
%          MTsat is a semi-quantitative method. MTsat values depend on
%          protocol parameters.
%-----------------------------------------------------------------------------------------------------
%-------------%
% ASSUMPTIONS %
%-------------% 
%
%-----------------------------------------------------------------------------------------------------
%--------%
% INPUTS %
%--------%
%   MTw : MT-weighted
%   T1w : T1-weighted
%   PDw : PD-weighted
%   B1 map: optional 
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%	MT saturation map
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
%   MT-w data
%       * Flip angle
%       * TR (s)
%   T1-w data
%       * Flip angle
%       * TR (s)
%   PD-w data
%       * Flip angle
%       * TR (s)
%   B1 map (optional)
%       * Alpha (optional): B1 correction parameter; default value = 0.00
%
%-----------------------------------------------------------------------------------------------------
% Written by: Pascale Beliveau (pascale.beliveau@polymtl.ca)
% Reference: Helms, G., Dathe, H., Kallenberg, K., Dechent, P., 2008. High-resolution maps of magnetization transfer with inherent correction for RF inhomogeneity and T1 relaxation obtained from 3D FLASH MRI. Magn. Reson. Med. 60, 1396?1407.
%-----------------------------------------------------------------------------------------------------
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
                                   'Mat',  [6 0.028]), ...
                      'B1', struct('Format',{{'Alpha'}},...
                                   'Mat', [0.00]));        
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
            
            B1params = obj.Prot.B1.Mat;
            
            FitResult.MTSAT = MTSAT_exec(data, MTparams, PDparams, T1params, B1params);
        end
        
    end
end
