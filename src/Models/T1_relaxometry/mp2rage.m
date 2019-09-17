classdef mp2rage < AbstractModel
% mp2rage: Compute a T1 map using MP2RAGE
%
% Assumptions:
%
% Inputs:
%   MP2RAGE_UNI         spoiled Gradient echo data, 4D volume with different flip angles in time dimension
%   (Mask)          Binary mask to accelerate the fitting (optional)
%
% Outputs:
%   T1              Longitudinal relaxation time [s]
%   R1              Equilibrium magnetization
%

properties (Hidden=true)
 onlineData_url = 'https://osf.io/8x2c9/download?version=2';  
end

    properties
        MRIinputs = {'MP2RAGE', 'Mask'};
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
           MP2RAGE.B0=7;           % in Tesla
           MP2RAGE.TR=6;           % MP2RAGE TR in seconds
           MP2RAGE.TRFLASH=6.7e-3; % TR of the GRE readout
           MP2RAGE.TIs=[800e-3 2700e-3];% inversion times - time between middle of refocusing pulse and excitatoin of the k-space center encoding
           MP2RAGE.NZslices=[35 72];% Slices Per Slab * [PartialFourierInSlice-0.5  0.5]
           MP2RAGE.FlipDegrees=[4 5];% Flip angle of the two readouts in degrees
           
           MP2RAGEimg.img=data.MP2RAGE;
           
           [T1map, R1map]=T1estimateMP2RAGE(MP2RAGEimg,MP2RAGE,0.96);
           
           FitResult.T1 = T1map.img;
           FitResult.R1 = R1map.img;
       end


    end
    
end
