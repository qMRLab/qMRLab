classdef mono_t2 < AbstractModel
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
        MRIinputs = {'SEdata','Mask'}; % used in the data panel
        
        % fitting options
        xnames = { 'T2','M0'}; % name of the parameters to fit
        voxelwise = 1; % 1--> input data in method 'fit' is 1D (vector). 0--> input data in method 'fit' is 4D.
        st           = [ 100	1000 ]; % starting point
        lb            = [  1      1 ]; % lower bound
        ub           = [ 300        10000 ]; % upper bound
        fx            = [ 0       0 ]; % fix parameters
        
        % Protocol
        Prot  = struct('SEdata',struct('Format',{{'EchoTime (ms)'}},...
            'Mat',[12.8  25.6  38.4  51.2  64.0  76.8  89.6  102.4...  
            115.2  128  140.8  153.6  166.4  179.2  192.0  204.8  217.6...
            230.4  243.2  256  268.8  281.6  294.4  307.2  320.0  332.8  345.6  358.4  371.2  384]'));
        
        % Model options
        buttons = {'FitType',{'Exponential','Linear'},'DropFirstEcho',false,'OffsetTerm',false};
        options= struct();
        
    end
    
    methods
        
        function obj = mono_t2()
            
            obj.options = button2opts(obj.buttons);
            obj.onlineData_url = obj.getLink('https://osf.io/kujp3/download?version=2','https://osf.io/ns3wx/download?version=1','https://osf.io/kujp3/download?version=2');
        end
        
        function Smodel = equation(obj, x)
            x = mat2struct(x,obj.xnames); % if x is a structure, convert to vector
            
            % equation
            Smodel = x.M0.*exp(-obj.Prot.SEdata.Mat./x.T2);
        end
        
        function FitResults = fit(obj,data)
            %  Fit data using model equation.
            %  data is a structure. FieldNames are based on property
            %  MRIinputs.
            
            if strcmp(obj.options.FitType,'Exponential')
                % Non-linear least squares using <<levenberg-marquardt (LM)>>
                
                
                if obj.options.DropFirstEcho
                    
                    xData = obj.Prot.SEdata.Mat(2:end);
                    yDat = data.SEdata(2:end);
                    
                    
                    
                    if max(size(yDat)) == 1
                        error('DropFirstEcho is not valid for ETL of 2.');
                    end
                    
                else
                   
                    xData = obj.Prot.SEdata.Mat;
                    yDat = data.SEdata;
                 
                end
                
                %xData = xData';
                
                if obj.options.OffsetTerm
                    fT2 = @(a)(a(1)*exp(-xData/a(2)) + a(3)  - yDat);
                else
                    fT2 = @(a)(a(1)*exp(-xData/a(2)) - yDat);
                end
                
                yDat = abs(yDat);
                yDat = yDat./max(yDat);
                
                % T2 initialization adapted from
                % https://github.com/blemasso/FLI_pipeline_T2/blob/master/matlab/pipeline_T2.m
                
                t2Init_dif = xData(1) - xData(end-1);
                t2Init = t2Init_dif/log(yDat(end-1)/yDat(1));
                
                if t2Init<=0 || isnan(t2Init),
                    t2Init=30;
                end
                
                pdInit = max(yDat(:))*1.5;
                
                options = struct();
                options.Algorithm = 'levenberg-marquardt';
                options.Display = 'off';
                
                if obj.options.OffsetTerm
                    fit_out = lsqnonlin(fT2,[pdInit t2Init 0],[],[],options);
                else
                    fit_out = lsqnonlin(fT2,[pdInit t2Init],[],[],options);
                end
                
                FitResults.T2 = fit_out(2);
                FitResults.M0 = fit_out(1);
                
                
            else
                % Linearize solution with <<log transformation (LT)>>
                
                if obj.options.DropFirstEcho
                    
                    xData = obj.Prot.SEdata.Mat(2:end);
                    yDat = log(data.SEdata(2:end));
                    
                    if max(size(yDat)) == 1
                        error('DropFirstEcho is not valid for ETL of 2.');
                    end
                    
                    else
                   
                    xData = obj.Prot.SEdata.Mat;
                    yDat = log(data.SEdata);
                    
                end
                
                regOut = [ones(size(xData)),xData] \ yDat;
                
                fit_out(1) = exp(regOut(1));
                if regOut(2) == 0 ; regOut(2) = eps; end
                t2 = -1./regOut(2);
                
                if isnan(t2); t2 = 0; end
                if t2<0; t2 = 0; end
                
                FitResults.T2 = t2;
                FitResults.M0 = fit_out(1);
                
                
            end
            %  convert fitted vector xopt to a structure.
            %FitResults = cell2struct(mat2cell(xopt(:),ones(length(xopt),%1)),obj.xnames,1);
            %FitResults.resnorm=resnorm;
            
        end
        
        
        function plotModel(obj, FitResults, data)
            %  Plot the Model and Data.
            if nargin<2, qMRusage(obj,'plotModel'), FitResults=obj.st; end
            FitResults=mat2struct(FitResults,obj.xnames);
            
            %Get fitted Model signal
            Smodel = equation(obj, FitResults);
            
            %Get the varying acquisition parameter
            Tvec = obj.Prot.SEdata.Mat;
            [Tvec,Iorder] = sort(Tvec);
            
            % Plot Fitted Model
            plot(Tvec,Smodel(Iorder),'b-')
            title(sprintf('T2 Fit: T2=%0.4f ms; M0=%0.0f;',FitResults.T2,FitResults.M0),'FontSize',14);
            xlabel('Echo time [ms]','FontSize',12);
            ylabel('Signal','FontSize',12);
            
            set(gca,'FontSize',12)
            
            % Plot Data
            if exist('data','var')
                hold on
                plot(Tvec,data.SEdata(Iorder),'r+')
                legend('data', 'fitted','Location','best')
                legend({'Model','Data'})
                hold off
            end
            
        end
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt, display)
            if nargin<4, display=1; end
            % Compute Smodel
            Smodel = equation(obj, x);
            % add gaussian noise
            sigma = max(Smodel)/Opt.SNR;
            data.SEdata = random('normal',Smodel,sigma);
            % fit the noisy synthetic data
            FitResults = fit(obj,data);
            % plot
            if display
                plotModel(obj, FitResults, data);
            end
        end
        
        function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opt)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, Opt.Nofrun, OptTable, Opt);
        end
        
        function SimRndResults = Sim_Multi_Voxel_Distribution(obj, RndParam, Opt)
            % SimRndGUI
            SimRndResults = SimRnd(obj, RndParam, Opt);
        end
    end
end