classdef mono_t2star < AbstractModel
    % mono_t2star: Compute a monoexponential T2* map
    %
    % Assumptions:
    %   Mono-exponential fit
    %
    % Inputs:
    %   DATAmag/DATAphase   Multi-echo spin-echo magnitude/phase data, 4D volume
    %                       with different echo times in time dimension
    %
    % Outputs:
    %   T2star          Effective transverse relaxation time [s]
    %   B0map           B0 inhomogeneity smoothed field
    %   GradZ           Gradient along Z direction
    %
    % Protocol:
    %   TE Array [nbTE]:
    %   [TE1 TE2...TEn]'     column vector listing the TEs [ms] 
    %
    % Options:
    %   MASKthreshold   Intensity under which pixels are masked. Default=500
    %   RMSEthreshold   Threshold above which voxels are discarded for comuting
    %                   the frequency map. RMSE results from fitting the frequency
    %                   slope on the phase data. Default=0.8
    %   smoothDownsampling    3D downsample frequency map to compute gradient
    %                         along Z. Default=[2 2 2]
    %   FilterType      'gaussian' | 'box' | 'polyfit1d' | 'polyfit3d'. Default='polyfit3d'
    %   smoothKernel    Only for 'gaussian' and 'box'
    %   polyOrder       Max order of polynomial fit of frequency values before
    %                   getting the gradient (along Z). Default=3
    %   MinLenght       Minimum length of values along Z, below which values
    %                   are not considered. Default=6
    %   SliceThickness  Slice thickness in mm. N.B. SHOULD INCLUDE GAP!
    %   OptimizationGradZ     Do optimization algorithm to find the final freqGradZ
    %                         value, by minimizing the standard error between
    %                         corrected T2* and the signal divided by the sinc term
    %   FitType         Numerical ('num'), Non-linear ('nlls'), Ordinary
    %                   least squares ('ols') or Generalized least squares ('gls')
    %   ThresholdT2*map In ms. threshold T2* map (for quantization purpose 
    %                   when saving in NIFTI).Suggested value=1000
    %
    % Example of command line usage:
    %   Model = mono_t2star;  % Create class from model
    %   Model.Prot.SEData.Mat=[6.44  9.76  13.08  16.4  19.72  23.04]';
    %   data = struct;  % Create data structure
    %   data.DATAmag = double(load_nii_data('magnitude.nii.gz'));
    %   data.DATAphase = double(load_nii_data('phase.nii.gz'));
    %   FitResults = FitData(data,Model); %fit data
    %   FitResultsSave_mat(FitResults);
    %
    
properties (Hidden=true)
    % See the constructor
    onlineData_url;
end   

    
    properties
        MRIinputs = {'DATAmag','DATAphase'}; % used in the data panel
        
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
            'FilterB0Map',true,'smoothDownsampling',[2 2 2],...
            'FilterType',{'polyfit3d','polyfit1d','gaussian','box'},...
            'smoothKernel',[27 27 7],'polyOrder',3,...
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
        
         function obj = UpdateFields(obj)
             disablelist = {'smoothKernel','polyOrder'};
            switch  obj.options.FilterType
                case {'gaussian','box'}
                    disable = [false, true];
                case {'polyfit1d','polyfit3d'}
                    disable = [true, false];
                otherwise
                    disable = [true, true];
            end
            for ll = 1:length(disablelist)
                indtodisable = find(strcmp(obj.buttons,disablelist{ll}) | strcmp(obj.buttons,['##' disablelist{ll}]));
                if disable(ll)
                    obj.buttons{indtodisable} = ['##' disablelist{ll}];
                else
                    obj.buttons{indtodisable} = [disablelist{ll}];
                end
            end
         end
        
%         function Smodel = equation(obj, x)
%             x = mat2struct(x,obj.xnames); % if x is a structure, convert to vector
%             
%             % equation
%             Smodel = x.M0.*exp(-obj.Prot.SEdata.Mat./x.T2);
%         end
        
        function FitResults = fit(obj,data)
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