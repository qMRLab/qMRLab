classdef mono_t2star < AbstractModel
    % mono_t2: Compute a monoexponential T2 map
    %
    % Assumptions:
    %   Mono-exponential fit
    %
    % Inputs:
    %   SEdata          Multi-echo spin-echo data, 4D volume with different 
    %                   echo times in time dimension
    %   (Mask)          Binary mask to accelerate the fitting (OPTIONAL)
    %
    % Outputs:
    %   T2              Transverse relaxation time [s]
    %   M0              Equilibrium magnetization
    %
    % Protocol:
    %   TE Array [nbTE]:
    %   [TE1; TE2;...;TEn]     column vector listing the TEs [ms] 
    %
    % Options:
    %   FitType         Linear or Exponential
    %   DropFirstEcho   Link Optionally drop 1st echo because of imperfect refocusing
    %   Offset          Optionally fit for offset parameter to correct for imperfect refocusing
    %
    % Example of command line usage:
    %   Model = mono_t2;  % Create class from model
    %   Model.Prot.SEData.Mat=[10:10:320]'; %Protocol: 32 echo times
    %   data = struct;  % Create data structure
    %   data.SEData = load_nii_data('SEData.nii.gz');
    %   FitResults = FitData(data,Model); %fit data
    %   FitResultsSave_mat(FitResults);
    %
    %  Reference work for DropFirstEcho and Offset options: 
    %  https://www.ncbi.nlm.nih.gov/pubmed/26678918
    
properties (Hidden=true)
    % See the constructor
    onlineData_url;
end   

    
    properties
        MRIinputs = {'DATAmag','DATAphase','Mask'}; % used in the data panel
        
        % fitting options
        xnames = { 'T2star','GradZ','B0'}; % name of the parameters to fit
        voxelwise = 0; % 1--> input data in method 'fit' is 1D (vector). 0--> input data in method 'fit' is 4D.
        st           = [ 100	1000 ]; % starting point
        lb            = [  1      1 ]; % lower bound
        ub           = [ 300        10000 ]; % upper bound
        fx            = [ 0       0 ]; % fix parameters
        
        % Protocol
        Prot  = struct('SEdata',struct('Format',{{'EchoTime'}},...
            'Mat',[6.44  9.76  13.08  16.4  19.72  23.04]'));
      
        % Model options
        buttons = {'PANEL','FrequencyMap',2,'MASKthreshold',500,'RMSEthreshold',0.8,...
            'FilterB0Map',false,'smoothDownsampling',[2 2 2],...
            'FilterType',{'gaussian','box','polyfit1d','polyfit3d'},...
            'PANEL','Gaussian/BoxFilter',1,'smoothKernel',[27 27 7],...
            'PANEL','polyfitFilter',1,'polyOrder',3,...
            'PANEL','GradientZ',3,'MinLength',6,'SliceThickness',1.25,...
            'OptimizationGradZ',false,'FitType',{'num','gls','ols','nlls'},...
            'ThresholdT2*map',1000};
        options = struct();
        
    end
    
    methods
        function obj = mono_t2star()
            obj.options = button2opts(obj.buttons);
            %obj.onlineData_url = obj.getLink('https://osf.io/kujp3/download?version=2','https://osf.io/ns3wx/download?version=1','https://osf.io/kujp3/download?version=2');
            % Prot values at the time of the construction determine 
            % what is shown to user in CLI/GUI.
        end
        
%         function obj = UpdateFields(obj)
%             if strcmp(obj.options.FilterType,'gaussian') || strcmp(obj.options.FilterType,'box')
%                 obj.buttons{strcmp(obj.buttons,'Guassian/BoxFilter') | strcmp(obj.buttons,'###Guassian/BoxFilter')} = '###Guassian/BoxFilter';
%             else
%                 obj.buttons{strcmp(obj.buttons,'Guassian/BoxFilter') | strcmp(obj.buttons,'###Guassian/BoxFilter')} = 'Guassian/BoxFilter';
%             end
%         end
        
%         function Smodel = equation(obj, x)
%             x = mat2struct(x,obj.xnames); % if x is a structure, convert to vector
%             
%             % equation
%             Smodel = x.M0.*exp(-obj.Prot.SEdata.Mat./x.T2);
%         end
        
        function FitResults = fit(obj,data)
            %  Fit data using model equation.
            %  data is a structure. FieldNames are based on property
            %  MRIinputs.
            
            %if strcmp(obj.options.FitType,'Exponential')
                % Non-linear least squares using <<levenberg-marquardt (LM)>>
                
                echo_time = obj.Prot.SEdata.Mat;
                echo_time = echo_time';
                multiecho_magn = data.DATAmag;
                multiecho_phase = data.DATAphase;
                
                %Intensity under which pixels are masked
                thresh_mask = obj.options.FrequencyMap_MASKthreshold;
                
                %Threshold above which voxels are discarded for computing the frequency map. RMSE results from fitting the frequency slope on the phase data
                thresh_rmse = obj.options.FrequencyMap_RMSEthreshold;
                
                [mask_3d, freq_map_3d] = t2star_computeFreqMap(multiecho_magn,multiecho_phase,echo_time,thresh_mask,thresh_rmse);
                
                %Smooth frequency map and computation of gradient along z
                if obj.options.FilterB0Map
                    [freq_3d_smooth_masked,freqGradZ_masked] = t2star_smoothFreqMap(obj,freq_map_3d,mask_3d,multiecho_magn);
                end                   
                
                %Parameter to perform corrected fitting
                %Do optimization algorithm to find the final freqGradZ value, by minimizing the standard error between corrected T2* and the signal divided by the sinc term (see Danhke et al.)
                do_optimization = obj.options.GradientZ_OptimizationGradZ;
                
                % 'ols': Ordinary least squares linear fit of the log of S
				% 'gls': Generalized least squares (=weighted least squares), to respect heteroscedasticity of the residual when taking the log of S
				% 'nlls': Levenberg-Marquardt nonlinear fitting to exponential
				% 'num': Numerical approximation, based on the NumART2* method in [Hagberg, MRM 2002]. Tends to overestimate T2*
                fitting_method = obj.options.FitType;
                grad_z_3d = freqGradZ_masked;
                
                %Threshold T2* map
                threshold_t2star_max = obj.options.ThresholdT2map;
                [t2star_uncorr_3d, t2star_corr_3d,rsquared_uncorr_3d,rsquared_corr_3d,grad_z_final_3d,iter_3d] = t2star_computeCorrectedFitting(multiecho_magn,grad_z_3d,mask_3d,echo_time,do_optimization,fitting_method,threshold_t2star_max);
                
                FitResults.T2star = t2star_corr_3d;
                FitResults.GradZ = freqGradZ_masked;
                FitResults.B0 = freq_3d_smooth_masked;
%                 
%                 FitResults.T2star = t2star_corr_3d;
%                 fT2 = @(a)(a(1)*exp(-xData/a(2)) - yDat);
%                 %xData = xData';
%                 
%                 yDat = abs(yDat);
%                 yDat = yDat./max(yDat);
%                 
%                 % T2 initialization adapted from
%                 % https://github.com/blemasso/FLI_pipeline_T2/blob/master/matlab/pipeline_T2.m
%                 
%                 t2Init_dif = xData(1) - xData(end-1);
%                 t2Init = t2Init_dif/log(yDat(end-1)/yDat(1));
%                 
%                 if t2Init<=0 || isnan(t2Init),
%                     t2Init=30;
%                 end
%                 
%                 pdInit = max(yDat(:))*1.5;
%                 
%                 options = struct();
%                 options.Algorithm = 'levenberg-marquardt';
%                 options.Display = 'off';
%                 
%                 fit_out = lsqnonlin(fT2,[pdInit t2Init],[],[],options);
%                 
%                 FitResults.T2 = fit_out(2);
%                 FitResults.M0 = fit_out(1);
%                 
%                 
%             else
%                 % Linearize solution with <<log transformation (LT)>>
%                 
%                 if obj.options.DropFirstEcho
%                     
%                     xData = obj.Prot.SEdata.Mat(2:end);
%                     yDat = log(data.SEdata(2:end));
%                     
%                     if max(size(yDat)) == 1
%                         error('DropFirstEcho is not valid for ETL of 2.');
%                     end
%                     
%                     else
%                    
%                     xData = obj.Prot.SEdata.Mat;
%                     yDat = log(data.SEdata);
%                     
%                 end
%                 
%                 regOut = [ones(size(xData)),xData] \ yDat;
%                 
%                 fit_out(1) = exp(regOut(1));
%                 if regOut(2) == 0 ; regOut(2) = eps; end
%                 t2 = -1./regOut(2);
%                 
%                 if isnan(t2); t2 = 0; end
%                 if t2<0; t2 = 0; end
%                 
%                 FitResults.T2 = t2;
%                 FitResults.M0 = fit_out(1);
%                 
%                 
%             end
            %  convert fitted vector xopt to a structure.
            %FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),%1)),obj.xnames,1);
            %FitResults.resnorm=resnorm;
            
        end
        
        
%         function plotModel(obj, FitResults, data)
%             % Ensure ORIGINAL protocol units on load
%             obj = setOriginalProtUnits(obj);
%             
%             %  Plot the Model and Data.
%             if nargin<2, qMRusage(obj,'plotModel'), FitResults=obj.st; end
%             FitResults=mat2struct(FitResults,obj.xnames);
%             
%             %Get fitted Model signal
%             Smodel = equation(obj, FitResults);
%             
%             %Get the varying acquisition parameter
%             Tvec = obj.Prot.SEdata.Mat;
%             [Tvec,Iorder] = sort(Tvec);
%             
%             % Plot Fitted Model
%             plot(Tvec,Smodel(Iorder),'b-')
%             title(sprintf('T2 Fit: T2=%0.4f ms; M0=%0.0f;',FitResults.T2,FitResults.M0),'FontSize',14);
%             xlabel('Echo time [ms]','FontSize',12);
%             ylabel('Signal','FontSize',12);
%             
%             set(gca,'FontSize',12)
%             
%             % Plot Data
%             if exist('data','var')
%                 hold on
%                 plot(Tvec,data.SEdata(Iorder),'r+')
%                 legend('data', 'fitted','Location','best')
%                 legend({'Model','Data'})
%                 hold off
%             end
%             
%             % Ensure USER protocol units after process
%             obj = setUserProtUnits(obj);
%         end
%         
%         function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt, display)            
%             if nargin<4, display=1; end
%             % Compute Smodel
%             Smodel = equation(obj, x);
%             % add gaussian noise
%             sigma = max(Smodel)/Opt.SNR;
%             data.SEdata = random('normal',Smodel,sigma);
%             % fit the noisy synthetic data
%             FitResults = fit(obj,data);
%             % plot
%             if display
%                 plotModel(obj, FitResults, data);
%             end
%         end
%         
%         function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opt)           
%             % SimVaryGUI
%             SimVaryResults = SimVary(obj, Opt.Nofrun, OptTable, Opt);
%         end
%         
%         function SimRndResults = Sim_Multi_Voxel_Distribution(obj, RndParam, Opt)
%             % SimRndGUI
%             SimRndResults = SimRnd(obj, RndParam, Opt);
%         end
    end

    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            % v2.5.0 drops unit parantheses
            if checkanteriorver(version,[2 5 0])
                obj.Prot.SEdata.Format = {'EchoTime'};
            end
        end
    end

end