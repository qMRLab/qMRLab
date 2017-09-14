classdef InversionRecovery
    % Computed a T1 map using Inversion Recovery data
    %
    % :param IRData: Inversion Recovery data
    % :param Mask: Binary mask to accelerate the fitting (OPTIONAL)
    % :returns: [T1 ,b, a, res, idx]: T1 value, 'b' and 'a' are fitting parameters and 'res' is the residual of the fit, 'idx' is the index of last polarity restored datapoint
    %
    %-----------------------------------------------------------------------------------------------------
    % InversionRecovery :  T1 map using Inversion Recovery
    %-----------------------------------------------------------------------------------------------------
    %-------------%
    % ASSUMPTIONS %
    %-------------% 
    % (1) None. Gold standard for T1 mapping
    %
    %-----------------------------------------------------------------------------------------------------
    %--------%
    % INPUTS %
    %--------%
    %   1) IRData : Inversion Recovery data
    %   2) Mask   : Binary mask to accelerate the fitting (OPTIONAL)
    %
    %-----------------------------------------------------------------------------------------------------
    %---------%
    % OUTPUTS %
    %---------%
    %	Fitting Parameters
    %       * T1
    %       * 'b' or 'rb' parameter (S=a + b*exp(-TI/T1))
    %       * 'a' or 'ra' parameter (S=a + b*exp(-TI/T1))
    %       * idx: index of last polaroty restored datapoint (only used for magnitude data)
    %       * res: Fitting residual
    %
    %-----------------------------------------------------------------------------------------------------
    %---------%
    % OPTIONS %
    %---------%
    %   method: Method to use in order to fit the data, based on whether
    %               complex or only magnitude data is available.
    %                 'complex'   : RD-NLS (Reduced-Dimension Non-Linear Least
    %                                Squares)
    %                              S=a + b*exp(-TI/T1)
    %             or  'magnitude' : RD-NLS-PR (Reduced-Dimension Non-Linear Least Squares
    %                               with Polarity Restoration)
    %                              S=|a + b*exp(-TI/T1)|
    %----------%
    % PROTOCOL %
    %----------%
    %   TI:  Array containing the Inversion times, in ms
    %
    %-----------------------------------------------------------------------------------------------------
    % Written by: Ilana Leppert 2017
    %-----------------------------------------------------------------------------------------------------


    properties
        MRIinputs = {'IRData','Mask'}; % input data required
        xnames = {'T1','rb','ra'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [  600    -1000      500 ]; % starting point
        lb           = [    0   -10000        0 ]; % lower bound
        ub           = [ 5000        0    10000 ]; % upper bound
        fx           = [    0        0        0 ]; % fix parameters
        
        % Protocol
        Prot = struct('IRData', struct('Format',{'TI(ms)'},'Mat',[350 500 650 800 950 1100 1250 1400 1700]')); %default protocol
        
        % Model options
        buttons = {'method',{'Magnitude','Complex'}}; %selection buttons
        options = struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function  obj = InversionRecovery()
            obj.options = button2opts(obj.buttons);
        end
        
        %         function obj = UpdateFields(obj)
        %             Default = InversionRecovery;
        %             obj.fx = Default.fx;
        %             obj.st= Default.st;
        %             obj.lb= Default.lb;
        %             obj.ub= Default.ub;
        %         end
        
        function Smodel = equation(obj, x)
            % Generates an IR signal based on input parameters
            %
            % :param x: [struct] containing fit parameters 'a' 'b' and 'T1'
            % :returns: Smodel: generated signal
            
            if ~isstruct(x) % if x is a structure, convert to vector
                for ix = 1:length(obj.xnames)
                    xtmp.(obj.xnames{ix}) = x(ix);
                end
                x = xtmp;
            end
            % equation
            Smodel = x.ra + x.rb * exp(-obj.Prot.IRData.Mat./x.T1);
            if (strcmp(obj.options.method, 'Magnitude'))
                Smodel = abs(Smodel);
            end
        end
        
        function FitResults = fit(obj,data)
            % Fits the data
            %
            % :param data: [struct] input data
            % :returns: [struct] FitResults
            
            data = data.IRData;
            [T1,rb,ra,res,idx] = fitT1_IR(data,obj.Prot.IRData.Mat,obj.options.method);
            FitResults.T1  = T1;
            FitResults.rb  = rb;
            FitResults.ra  = ra;
            FitResults.res = res;
            if (strcmp(obj.options.method, 'Magnitude'))
                FitResults.idx = idx;
            end
        end
        

         function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt,display)
            % Simulates Single Voxel
            %
            % :param x: [struct] fit parameters
            % :param Opt.SNR: [struct] signal to noise ratio to use
            % :param display: 1=display, 0=nodisplay
            % :returns: [struct] FitResults
            
            if ~exist('display','var'), display = 1; end
            Smodel = equation(obj, x);
            sigma = max(abs(Smodel))/Opt.SNR;
            if (strcmp(obj.options.method, 'Magnitude'))
                data.IRData = ricernd(Smodel,sigma);
            else
                data.IRData = random('normal',Smodel,sigma);
            end
            FitResults = fit(obj,data);
            if display
                plotmodel(obj, FitResults, data);
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
        
        function plotmodel(obj, FitResults, data)
            % Plots the fit
            %
            % :param FitResults: [struct] Fitting parameters
            % :param data: [struct] input data
            if nargin<2 || isempty(FitResults), FitResults = obj.st; end
            if exist('data','var'),
                data = data.IRData;
                % plot
                plot(obj.Prot.IRData.Mat,data,'.','MarkerSize',15)
                hold on
                if (strcmp(obj.options.method, 'Magnitude'))
                    % plot the polarity restored data points
                    data_rest = -1.*data(1:FitResults.idx);
                    plot(obj.Prot.IRData.Mat(1:FitResults.idx),data_rest,'o','MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor',[1 0 0])
                end
            end
            
            
            
            % compute model
            obj.Prot.IRData.Mat = linspace(min(obj.Prot.IRData.Mat),max(obj.Prot.IRData.Mat),100);
            Smodel = equation(obj, FitResults);
            
            % plot fitting curve
            plot(obj.Prot.IRData.Mat,Smodel,'Linewidth',3)
            xlabel('Inversion Time [ms]','FontSize',15);
            ylabel('Signal','FontSize',15);
            legend('data', 'polarity restored', 'fit')
            legend('show','Location','Best')
            set(gca,'FontSize',15)
        end
    end
end
