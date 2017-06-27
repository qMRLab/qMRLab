classdef MTSAT
% ----------------------------------------------------------------------------------------------------
% MTSAT :  Magnetization transfer saturation 
% ----------------------------------------------------------------------------------------------------
    properties
        MRIinputs = {'MTw','T1w', 'PDw', 'Mask'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot = struct('MT',struct('Format',{{'Flip Angle' 'TR (s)' 'Offset (Hz)'}},...
                                   'Mat',  [5 0.031 500]),...
                      'T1',struct('Format',{{'Flip Angle' 'TR'}},...
                                   'Mat',  [5 0.031]),...
                      'PD',struct('Format',{{'Flip Angle' 'TR'}},...
                                   'Mat',  [15 0.011]));        
        % Model options
        buttons = {'offset frequency (Hz)', 1000};
        options= struct();
        
    end
    
    methods
        function obj = MTSAT
            obj = button2opts(obj);
        end
        
        function FitResult = fit(obj,data)
            MTparams = obj.Prot.MT.Mat; 

            PDparams = obj.Prot.PD.Mat;
            
            T1params = obj.Prot.T1.Mat;
            
            FitResult = MTSAT_exec(data, MTparams, PDparams, T1params);
        end
        
    end
end
