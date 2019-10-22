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
%                              pseudo-continuous 
%   lambda                     Blood partial volume [mL/g]
%   alpha                      Label efficiency
%   T1_blood                   T1 relaxation of blood [ms]
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
        buttons = {'Type',{'continuous labeling (cASL)'},... % todo: add types 'pulsed labeling' ans 'velocity selective labeling'
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
        
        function obj = PrecomputeData(obj, data)
        end
        
        function FitResults = fit(obj,data)
            %  Inverse problem. Extract CBF.
            
            switch obj.options.type
                case 'continuous labeling'
                    ASL_norm = mean(data.ASL(:,:,:,3:2:end)-data.ASL(:,:,:,4:2:end),4)./mean(data.ASL(:,:,:,1:2),4);
                    FitResults.CBF = 6000*lambda*ASL_norm*exp(2000/1350)/(2*0.85*1.650*(1-exp(-1800/1350)));
            end
        end
        
        
        function plotModel(obj, FitResults, data)
            %  Plot the Model and Data.
            if nargin<2, qMRusage(obj,'plotModel'), FitResults=obj.st; end
            
            %Get fitted Model signal
            R2star = equation(obj, FitResults);
            
            %Get the varying acquisition parameter
            TR = obj.Prot.PWI.Mat(1);
            Nvol = obj.Prot.PWI.Mat(3);
            time = 0:TR:TR*(Nvol-1);
            time = time';
            
            % Plot Fitted Model
            plot(time,R2star,'b-')
            
            % Plot Data
            if exist('data','var')
                TE = obj.Prot.PWI.Mat(2);
                % norm
                [PWInorm, T0] = pwiNorm(data.PWI);
                R2star = pwi2R2star(PWInorm,TE);
                time = 0:TR:TR*(length(R2star)-1);
                hold on
                plot(time,R2star,'r+')
                plot([time(T0) time(T0)],[0 max(R2star)],'k--')
                hold off
            end
            ylabel('R2* (s^{-1})')
            xlabel('time (s)')
            legend({'Model','Data'})
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt, display)
            % Compute Smodel
            R2star = equation(obj, x);
            TE = obj.Prot.PWI.Mat(2);
            Smodel = exp(-TE*R2star);
            % add rician noise
            sigma = max(Smodel)/Opt.SNR;
            data.PWI = random('rician',Smodel,sigma);
            % fit the noisy synthetic data
            FitResults = fit(obj,data);
            % plot
            if ~exist('display','var') || display
                plotModel(obj, FitResults, data);
            end
        end

        function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opts)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, Opts.Nofrun, OptTable, Opts);
        end
        
        function SimRndResults = Sim_Multi_Voxel_Distribution(obj, RndParam, Opt)
            % SimRndGUI
            SimRndResults = SimRnd(obj, RndParam, Opt);
        end

    end
end

function [PWInorm, T0] = pwiNorm(PWI)
[T0,T0_mask] = BAT(PWI);
BL = sum(PWI .* T0_mask)./sum((PWI .* T0_mask) ~= 0);
PWInorm = PWI/BL;
end

function R2star = pwi2R2star(Snorm,TE)
R2star = -1/TE*log(max(Snorm,eps));
end

function [T0,T0_mask] = BAT(PWI)
% function T0 = BAT(VOX,curve_type)
% Compute Bolus Arrival Time
%
% INPUT :
%
% OUTPUTS :
%
% 13/03/2013 (Thomas Perret : <thomas.perret@grenoble-inp.fr>)
% Last modified : 15/03/2013 (TP)

% Parameters of algorithm
window_size = 4;
th = 2.0;

Nvol = length(PWI);
T0_mask = false(Nvol,1);
moy = zeros(Nvol-window_size,1);
ect = zeros(Nvol-window_size,1);
for t = 1:Nvol-window_size
    moy(t) = mean(PWI(t:t+window_size));
    ect(t) = std(PWI(t:t+window_size));
end
ect = sort(ect); ect = median(ect(1:4));
Tlog = PWI(window_size+1:Nvol) < (moy - th.*ect);
[~,T0] = max(Tlog);
T0 = T0 + window_size - 1;
[~,TTP] = min(PWI);


if T0 < TTP && T0 > window_size
    T0_mask(2:T0-2) = true;
else
    T0_mask(2:window_size-2) = true;
end

    
end
