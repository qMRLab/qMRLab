classdef MTSAT
% ----------------------------------------------------------------------------------------------------
% MTSAT :  Magnetization transfer saturation 
% ----------------------------------------------------------------------------------------------------
    properties
        MRIinputs = {'MTw','T1w', 'PDw', 'Mask'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        ProtFormat ={'Flip Angle' 'TR'};
        Prot  = [5 0.031; 5 0.031; 15 0.011]; % You can define a default protocol here.
        
        % Model options
        buttons = {'offset frequency (Hz)', 1000};
        options= struct();
        
    end
    
    methods
        function obj = MTSAT
            obj = button2opts(obj);
        end
        
        function FitResult = fit(obj,data)
            MTparams = obj.Prot(1,:); 
            %MTparams(1,1) = MTparams(1,1)*pi()/180;
            PDparams = obj.Prot(2,:);
            
            T1params = obj.Prot(3,:);
            
            FitResult = MTSAT_exec(data, MTparams, PDparams, T1params);
        end
        
    end
end
