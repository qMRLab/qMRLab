classdef dsc < AbstractModel
% dsc :  Dynamic Susceptibility Contrast (T2* weigthed dynamic contrast enhanced)
%<a href="matlab: figure, imshow CustomExample.png ;">Pulse Sequence Diagram</a>
%
% Assumptions:
% (1)FILL
% (2) 
%
% Inputs:
%   PWI                 4D Dynamic Contrast Enhanced
%   (Mask)              Binary mask to accelerate the fitting
%
% Fitted Parameters:
%    Param1    
%    Param2    
%
% Non-Fitted Parameters:
%    residue                    Fitting residue.
%
% Options:
%   Q-space regularization      
%       Smooth q-space data per shell prior fitting
%
% Example of command line usage:
%   For more examples: <a href="matlab: qMRusage(CustomExample);">qMRusage(CustomExample)</a>
%
% Author: 
%
% References:
%   Please cite the following if you use this module:
%     FILL
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

    properties
        MRIinputs = {'PWI','Mask'}; % used in the data panel 
        
        % fitting options
        xnames = { 'gamma_K','gamma_n','gamma_a'}; % name of the parameters to fit
        voxelwise = 1; % 1--> input data in method 'fit' is 1D (vector). 0--> input data in method 'fit' is 4D.
        st           = [ 300        35       0.5  ]; % starting point
        lb            = [ 0       0       0   ]; % lower bound
        ub           = [ 10000      100       50  ]; % upper bound
        fx            = [ 0       0        0  ]; % fix parameters
        
        % Protocol
        Prot = struct('PWI',... % Creates a Panel Data4D Protocol in Model Options menu
                        struct('Format',{{'TR'; 'TE'; 'Nvolumes'}},... % columns name
                        'Mat', [1.5; 0.040; 40])); % provide a default protocol (Nx2 matrix)
        
        % Model options
        buttons = {'GammaFit',false,'Arterial Input Function',{'Dirac','Deconvolution'}};
        options= struct();
        
        % Arterial Input Function
        AIF = [];
    end
    
    methods
        function obj = DCE
            obj.options = button2opts(obj.buttons); % converts buttons values to option structure
        end
        
        function obj = PrecomputeData(obj, data)
            % compute AIF
            [obj.AIF, score] = extraction_aif_volume(data.PWI,data.Mask);
        end
        
        function R2star = equation(obj, x)
            % Compute the Signal Model based on parameters x. 
            % x can be both a structure (FieldNames based on xnames) or a
            % vector (same order as xnames).
            x = struct2mat(x,obj.xnames);
            K = x(1);
            n = x(2);
            a = x(3);
            %% Relaxivity variation
            TR = obj.Prot.PWI.Mat(1);
            Nvol = obj.Prot.PWI.Mat(3);
            time = 0:TR:TR*(Nvol-1);
            time = time';
            R2star = K*gampdf(time,n,a);% *time.^n.*exp(-a*time);
            
        end
        
        function FitResults = fit(obj,data)
            %  Fit data using model equation.
            %  data is a structure. FieldNames are based on property
            %  MRIinputs. 
            
%             if obj.options.SMS
%                 % buttons values can be access with obj.options
%             end
            
            % set the right value for 
            obj.Prot.PWI.Mat(3) = length(data.PWI);
            % param
            TE = obj.Prot.PWI.Mat(2);
            TR = obj.Prot.PWI.Mat(1);
            Nvol = obj.Prot.PWI.Mat(3);
            time = 0:TR:TR*(Nvol-1);
            time = time';
            
            % data
            PWI = double(data.PWI);
            % normalization
            PWInorm = pwiNorm(PWI);
            R2star = pwi2R2star(PWInorm,TE);
            R2star = max(.1,R2star);
            Smax = max(R2star);
            R2star = R2star./Smax;
            % remove 0.7*T2star(tpic)
            R2star(find(diff(R2star<0.4*max(R2star)),1,'last')+4:Nvol) = 0;
            opt = optimoptions('lsqcurvefit','Display','off');
            [xopt, resnorm] = lsqcurvefit(@(x,xdata) obj.equation(addfix(obj.st,x,obj.fx)),...
                     obj.st(~obj.fx), [], R2star, obj.lb(~obj.fx), obj.ub(~obj.fx),opt);
%                  
            %  convert fitted vector xopt to a structure.
            FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),obj.xnames,1);
            FitResults.gamma_K = FitResults.gamma_K*Smax;
            FitResults.resnorm=resnorm;
            FitResults.CBV = trapz(time,equation(obj, FitResults));
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
