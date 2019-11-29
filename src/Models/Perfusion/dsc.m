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
% Outputs:
%    T0                 [sec] Bolus arrival time   
%    S0                 Signal before bolus
%    R2starMAX          Max variation of R2star
%    CBV                [%] Cerebral Blood Volume  
%    CBF                [mL/100g/min] Cerebral Blood Flow
%    TTP                [sec] Time to Peak
%    TAP                [sec] Time AIF to Peak
%
% Protocol:
%   PWI                 Array [3x1]
%    TR                 [sec] Repetition time
%    TE                 [sec] Echo time
%    Nvolumes           Number of volumes (used in simulations)
%
% Options:
%   GammaFit
%   Deconvolution
%   lambda              blood-brain partition coefficient
%
% Example of command line usage:
%   For more examples: <a href="matlab: qMRusage(CustomExample);">qMRusage(CustomExample)</a>
%
% Author: Tanguy Duval, INSERM 2019
%         Thomas Perret, grenoble INP
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
        buttons = {'GammaFit',false,'Arterial Input Function',{'Dirac','Deconvolution'},'lambda',0.9};
        options= struct();
        
        % Arterial Input Function
        AIF = [];
    end
    
    methods
        function obj = dsc
            obj.options = button2opts(obj.buttons); % converts buttons values to option structure
        end
        
        function obj = PrecomputeData(obj, data)
            % compute AIF
            switch obj.options.ArterialInputFunction
                case 'Deconvolution'
                    if ~isfield(data,'Mask') || isempty(data.Mask)
                        data.Mask = true(size(data.PWI));
                    end
                    dimsMask = size(data.Mask);
                    if max(dimsMask(1:min(3,end)))==1
                        obj.AIF = data.PWI(:);
                        return;
                    else
                        [obj.AIF, score] = extraction_aif_volume(data.PWI,any(data.Mask,4));
                        obj.AIF = obj.AIF';
                    end
                    if sum(cell2mat(score(:,5))) > 10
                        error('No computation because the AIF is not good enough');
                    end
                    
                    % Display
                    fig=figure;
                    pan1 = uipanel(fig,'Position',[0 0 .5 1]);

                    data.Mask(:)=0;
                    for ii=1:5
                        data.Mask(score{ii,2},score{ii,3},score{ii,4})=1;
                        vol(ii,:) = squeeze(data.PWI(score{ii,2},score{ii,3},score{ii,4},:));
                    end
                    tool = imtool3D(data.PWI,[],pan1,[],[],data.Mask);
                    tool.setCurrentSlice(score{1,4})
                    set(tool.getHandles.fig,'Name','Voxels used for Arterial Input Function (in red)')
                    
                    Nvol = length(obj.AIF);
                    %%
                    pan2 = uipanel(fig,'Position',[0.5 0 .5 1]);
                    ax = axes(pan2);
                    TE = obj.Prot.PWI.Mat(2);
                    TR = obj.Prot.PWI.Mat(1);
                    time = 0:TR:TR*(Nvol-1);
                    [AIFnorm,~,S0] = pwiNorm(obj.AIF);
                    plot(ax,time,pwi2R2star(AIFnorm,TE),'Linewidth',3)
                    hold on
                    plot(ax,time,pwi2R2star(vol/S0,TE),'r-','Linewidth',.5)
                    hold off
                    ylabel \DeltaR2*
                    xlabel time[sec]
            end
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
            
            % set the right value for number of volumes
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
            [PWInorm, FitResults.T0, FitResults.S0]= pwiNorm(PWI);
            R2star = pwi2R2star(PWInorm,TE);
            R2star = max(.1,R2star);
            Smax = max(R2star);
            % remove trailing signal lower than 0.4*T2star(tpic)
            R2star(find(diff(R2star<0.4*max(R2star)),1,'last')+4:Nvol) = 0;
            if obj.options.GammaFit
                R2star = R2star./Smax;
                % Fit with Gamma function
                opt = optimoptions('lsqcurvefit','Display','off');
                [xopt, resnorm] = lsqcurvefit(@(x,xdata) obj.equation(addfix(obj.st,x,obj.fx)),...
                    obj.st(~obj.fx), [], R2star, obj.lb(~obj.fx), obj.ub(~obj.fx),opt);
                %  convert fitted vector xopt to a structure.
                FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),1)),obj.xnames,1);
                FitResults.gamma_K = FitResults.gamma_K*Smax;
                FitResults.resnorm=resnorm;
                % Recompute the theoretical R2star
                R2star = equation(obj, FitResults);
            end

            % Time to Peak
            [FitResults.R2starMAX,TTP] = max(R2star);
            FitResults.TTP = (TTP-1/2).*TR;
         
            % Cerebral Blood Volume
            FitResults.CBV = trapz(time,R2star);
            
            % Deconvolution
            switch obj.options.ArterialInputFunction
                case 'Deconvolution'
                    if ~isempty(obj.AIF)
                        % compute R2star variation (Gado concentration) in the artery
                        AIFnorm = pwiNorm(obj.AIF);
                        R2starAIF = pwi2R2star(AIFnorm,TE);
                        
                        % Deconv CBV
                        FitResults.CBV = 100*FitResults.CBV/trapz(time,R2starAIF);
                        
                        % Deconv R2star
                        %%% Compute SVD for Ca
                        zero_pad_fact = 2; % MUST be an integer !
                        R2starAIF = cat(1,R2starAIF,zeros(Nvol*(zero_pad_fact-1),1)); % pad
                        
                        Ca = toeplitz(R2starAIF,[R2starAIF(1); R2starAIF(end:-1:2)]);
                        [U,S,V] = svd(Ca);
                        R2starpad = cat(1,R2star,zeros(Nvol*(zero_pad_fact-1),1)); % pad
                        R2starpad = devonvolution_osvd(U,S,V,R2starpad);
                        R2star = R2starpad(1:Nvol);
                    else
                        warning('Cannot apply deconvolution. Start by running Model.PrecomputeData to get the Arterial Input Function.')
                    end
            end
            
            [RMAX,TAP] = max(R2star);
            TAP = (TAP-(1/2)).*TR;
            MTT = trapz(time,R2star)./RMAX;
            CBF = 60*obj.options.lambda*FitResults.CBV/100/max(1,MTT); % mL/100g/min
            
            FitResults.TAP = TAP;
            FitResults.MTT = MTT;
            FitResults.CBF = CBF;
        end
        
        
        function plotModel(obj, FitResults, data)
            %  Plot the Model and Data.
            if nargin<2, qMRusage(obj,'plotModel'), FitResults=obj.st; end
            
            %Get the varying acquisition parameter
            TR = obj.Prot.PWI.Mat(1);
            Nvol = obj.Prot.PWI.Mat(3);
            time = 0:TR:TR*(Nvol-1);
            time = time';
            leg = {};
            %Get fitted Model signal
            if isfield(FitResults,'gamma_K')
                R2star = equation(obj, FitResults);
                
                % Plot Fitted Model
                plot(time,R2star,'b-')
                hold on
                leg = [leg {'Model'}];
            end
            
            plot([FitResults.TTP FitResults.TTP],[0 FitResults.R2starMAX],'g-')
            hold on
            leg = [leg {'Time to Peak (TTP)'}];
            plot([FitResults.TTP-FitResults.MTT/2 FitResults.TTP+FitResults.MTT/2],[1/2 1/2]*FitResults.R2starMAX,'m-')
            leg = [leg {'Mean Transit Time (MTT)'}];
            
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
                leg = [leg {'Data','Bolus Arrival Time'}];
            end
            ylabel('\DeltaR2* (s^{-1})')
            xlabel('time (s)')
            legend(leg)
            hold off
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt, display)
            % Compute Smodel
            R2star = equation(obj, x);
            TE = obj.Prot.PWI.Mat(2);
            Smodel = exp(-TE*R2star);
            % add rician noise
            sigma = max(Smodel)/Opt.SNR;
            data.PWI = random('rician',Smodel,sigma);
            % Precompute
            obj.AIF = data.PWI;
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

function [PWInorm, T0, BL] = pwiNorm(PWI)
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
th = 5.0;

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

function R = devonvolution_osvd(U,S,V,Cvox)
% function R = devonvolution_osvd(U,S,V,CVOXpad,OIth,mask_computation)
% Devonvolution
%
% INPUTS :
% U,S,V : matrices from SVD of Ca matrix
% Cvox : zero-padded concentration voxels (total volume, 4D)
%
% OUTPUT :
% R : Residu function from deconvolution
%
% 13/03/2013 (Thomas Perret : <thomas.perret@grenoble-inp.fr>)
% Last modified : 15/03/2013 (TP)

%%% Deconvolution Parameters
OIth = 0.1; % OIth : oscillation threshold

% init
Nvolpad = length(Cvox);
Sv=diag(S);
        th_prev = Nvolpad;
        th = 0;
        OI = Inf;
        first = true;
        % deconv
        while (OI > OIth || (abs(th_prev - th) > 1)) && th < Nvolpad
            
            %%% Calcul de l'inverse de S et filtrage %%%
            Sinv = diag([1./Sv(1:Nvolpad-th);zeros(th,1)]);
            
            %%% Inverse de Ca %%%
            Cainv = V*Sinv*(U');
            
            %%% Calcul du residu %%%
            r = Cainv*Cvox;
            
            %%% Calcul de OI %%%
            rOI = r(1:Nvolpad);
            
            f = abs(rOI(3:Nvolpad) - 2*rOI(2:Nvolpad-1) + rOI(1:Nvolpad-2));
            sum_oi = sum(f);
            
            if max(rOI) ~= 0
                OI = (1/Nvolpad) * (1/max(rOI)) * sum_oi;
            else
                OI = Inf;
            end
            
            
            if ~first
                if OI > OIth
                    th_next = th + round(abs((th - th_prev))/2);
                else
                    th_next = th - round(abs((th - th_prev))/2);
                end
            else
                if OI > OIth
                    th_next = th + round(abs((th - th_prev))/2);
                else
                    th_next = th;
                end
            end
            
            th_prev = th;
            th = th_next;
            
            first = false;
        end
        R = r(1:Nvolpad);
end

