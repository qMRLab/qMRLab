classdef asl < AbstractModel
% ASL :  Arterial Spin Labelling
%<a href="matlab: figure, imshow asl.png ;">Pulse Sequence Diagram</a>
%
% Assumptions:
% (1)FILL
% (2) 
%
% Inputs:
%   ASL                 Arterial Spin Labelling (ASL) 4D volume
%   (Mask)              Binary mask to accelerate the fitting
%
% Outputs:
%    CBF                Cerebral Blood Flow [mL/100g/min]    
%
% Protocol:
%   LabelTiming
%     PLD                      Postlabeling delay [ms]
%                               Recommendation:
%                               PCASL PLD: neonates 2000 ms 
%                               PCASL PLD: children 1500 ms 
%                               PCASL PLD: healthy subjects <70 y 1800 ms 
%                               PCASL PLD: healthy subjects >70 y 2000 ms 
%                               PCASL PLD: adult clinical patients 2000 ms
%     tau                      Label duration [ms]
%                               Recommendation: 1800 ms
% Options:
%   Type                       ASL labeling approach (e.g. Pseudo-continuous pcASL)
%   lambda                     Blood partial volume [mL/g]
%   alpha                      Label efficiency (value depends on the type of labeling)
%   T1_blood                   T1 relaxation of blood [ms]. 1.5T: 1350ms, 3T: 1650ms
%
% Example of command line usage:
%   For more examples: <a href="matlab: qMRusage(CustomExample);">qMRusage(CustomExample)</a>
%
% Author: Tanguy Duval (tanguy.duval@inserm.fr)
%
% References:
%   Please cite the following if you use this module:
%     Alsop, D.C., Detre, J.A., Golay, X., Günther, M., Hendrikse, J., Hernandez-Garcia, L., Lu, H., MacIntosh, B.J., Parkes, L.M., Smits, M., van Osch, M.J.P., Wang, D.J.J., Wong, E.C., Zaharchuk, G., 2015. Recommended implementation of arterial spin-labeled perfusion MRI for clinical applications: A consensus of the ISMRM perfusion study group and the European consortium for ASL in dementia. Magn. Reson. Med. 73, 102–116.
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

    properties
        MRIinputs = {'ASL','Mask'}; % used in the data panel 
        
        % fitting options
        xnames = {}; % name of the parameters to fit
        voxelwise = 0; % 1--> input data in method 'fit' is 1D (vector). 0--> input data in method 'fit' is 4D.
        
        % Protocol
        Prot = struct('LabelTiming',... % Creates a Panel Data4D Protocol in Model Options menu
                        struct('Format',{{'PLD'; 'tau'}},... % columns name
                        'Mat', [1800; 1800])); % provide a default protocol (Nx2 matrix)
        
        % Model options
        buttons = {'Type',{'pseudo-continuous labeling (pcASL)'},... % todo: add types 'pulsed labeling' ans 'velocity selective labeling'
                   'lambda', 0.9,...
                   'alpha', 0.85,...
                   'T1_blood', 1350};
        options= struct();
        
        % Arterial Input Function
        AIF = [];
    end
    
    methods
        function obj = asl
            obj.options = button2opts(obj.buttons); % converts buttons values to option structure
        end
        
        function obj = UpdateFields(obj)
            switch obj.options.Type
                case 'pulsed labeling (PASL)'
                    obj.options.alpha = 0.98;
                case 'pseudo-continuous labeling (pcASL)'
                    obj.options.alpha = 0.85;
            end
        end
        
        function obj = PrecomputeData(obj, data)
        end
        
        function FitResults = fit(obj,data)
            %  Inverse problem. Extract CBF.
            PLD = obj.Prot.LabelTiming.Mat(1);
            tau = obj.Prot.LabelTiming.Mat(2);

            switch obj.options.Type
                case 'pseudo-continuous labeling (pcASL)'
                    ASL_norm = mean(data.ASL(:,:,:,3:2:end)-data.ASL(:,:,:,4:2:end),4)./mean(data.ASL(:,:,:,1:2),4);
                    FitResults.CBF = 6000*obj.options.lambda*ASL_norm*exp(PLD/obj.options.T1_blood)/(2*obj.options.alpha*obj.options.T1_blood*1e-3*(1-exp(-tau/obj.options.T1_blood)));
            end
        end

    end
end


