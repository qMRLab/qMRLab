classdef mp2rage < AbstractModel
% mp2rage: Compute a T1 map using MP2RAGE
%
% Assumptions:
%
% Inputs:
%   MP2RAGE_UNI         spoiled Gradient echo data, 4D volume with different flip angles in time dimension
%   (Mask)          Binary mask to accelerate the fitting (optional)
%

properties (Hidden=true)
 onlineData_url = 'https://osf.io/8x2c9/download?version=1';  
end

    properties
        MRIinputs = {'MP2RAGE_UNI', 'Mask'};
        xnames = {'T1','R1'};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct('MP2RAGEData',struct('Format',{{'FlipAngle' 'TR'}},...
                                         'Mat', [3 0.015; 20 0.015])); % You can define a default protocol here.

        % fitting options
        st           = [2000 0.7]; % starting point
        lb           = [0   0.00001]; % lower bound
        ub           = [6000   5]; % upper bound
        fx           = [0     0]; % fix parameters

        % Model options
        buttons = {};
        options= struct(); % structure filled by the buttons. Leave empty in the code
    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods

        function obj = mp2rage()
            obj.options = button2opts(obj.buttons);
        end

        function Smodel = equation(obj,x)
            % Generates a VFA signal based on input parameters
            x = mat2struct(x,obj.xnames); % if x is a structure, convert to vector

            % Equation: S=M0sin(a)*(1-E)/(1-E)cos(a); E=exp(-TR/T1)
            flipAngles = (obj.Prot.VFAData.Mat(:,1))';
            TR = obj.Prot.VFAData.Mat(1,2);
            E = exp(-TR/x.T1);
            Smodel = x.M0*sin(flipAngles/180*pi)*(1-E)./(1-E*cos(flipAngles/180*pi));
        end

       function FitResult = fit(obj,data)
            % T1 and M0
            flipAngles = (obj.Prot.VFAData.Mat(:,1))';
            TR = obj.Prot.VFAData.Mat(:,2);
            if (length(unique(TR))~=1), error('VFA data must have same TR'); end
            if ~isfield(data, 'B1map'), data.B1map = []; end
            if ~isfield(data, 'Mask'), data.Mask = []; end
            [FitResult.T1, FitResult.M0] = Compute_M0_T1_OnSPGR(double(data.VFAData), flipAngles, TR(1), data.B1map, data.Mask);
       end


    end
    
end
