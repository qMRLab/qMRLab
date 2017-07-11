classdef InversionRecovery
    % ----------------------------------------------------------------------------------------------------
    % InversionRecovery :  T1 map using Inversion Recovery
    % ----------------------------------------------------------------------------------------------------
    % Assumptions :
    % ----------------------------------------------------------------------------------------------------
    %
    %  Fitted Parameters:
    %               (1) T1
    %               (2) 'b' or 'rb' parameter
    %               (3) 'a' or 'ra' parameter
    %               (4) residual from the fit%
    %
    % Options:
    
    % ----------------------------------------------------------------------------------------------------
    % Written by: Ilana Leppert 2017
    % ----------------------------------------------------------------------------------------------------
    
    properties
        MRIinputs = {'IRData','Mask'}; % input data required
        xnames = {'T1','rb','ra'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [600     -1000        500     ]; % starting point
        lb            = [0     -10000        0       ]; % lower bound
        ub           = [5000       0         10000       ]; % upper bound
        fx            = [0      0           0    ]; % fix parameters
        
        % Protocol
        Prot = struct('IRData', struct('Format',{'TI(ms)'},'Mat',[350 500 650 800 950 1100 1250 1400 1700]'));
        
        % Model options
        buttons = {'method',{'Magnitude','Complex'}};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = InversionRecovery
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
            % Check input
            if ~isstruct(x) % if x is a structure, convert to vector
                for ix = 1:length(obj.xnames)
                    xtmp.(obj.xnames{ix}) = x(ix);
                end
                x = xtmp;
            end
            % equation
            Smodel = x.ra + x.rb * exp(-obj.Prot.IRData.Mat./x.T1);
            
        end
        
        
        function FitResults = fit(obj,data)
            data = data.IRData;
            [T1,rb,ra,res,idx]=fitT1_IR(data,obj.Prot.IRData.Mat,obj.options.method);
            FitResults.T1 = T1;
            FitResults.rb = rb;
            FitResults.ra = ra;
            FitResults.res = res;
            if (strcmp(obj.options.method, 'Magnitude'))
                FitResults.idx=idx;
            end
        end
        
         function FitResults = Sim_Single_Voxel_Curve(obj, x, SNR,display)
            if ~exist('display','var'), display=1; end
            Smodel = equation(obj, x);
            sigma = max(Smodel)/SNR;
            data.IRData = random('rician',Smodel,sigma);
            FitResults = fit(obj,data);
            if display
                plotmodel(obj, FitResults, data);
            end
        end
        
        function SimVaryResults = Sim_Sensitivity_Analysis(obj, SNR, runs, OptTable)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, SNR, runs, OptTable);
        end
        
        
        function plotmodel(obj, FitResults, data)
            if isempty(FitResults), return; end
            if exist('data','var'),
                data = data.IRData;
                % plot
                plot(obj.Prot.IRData.Mat,data,'.','MarkerSize',15)
                hold on
                if (strcmp(obj.options.method, 'Magnitude'))
                    % plot the polarity restored data points
                    data_rest=-1.*data(1:FitResults.idx);
                    plot(obj.Prot.IRData.Mat(1:FitResults.idx),data_rest,'o','MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor',[1 0 0])
                end
            end
            
            
            
            % compute model
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
