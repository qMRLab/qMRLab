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
        MRIinputs = {'IRdata','Mask'}; % input data required
        xnames = {'T1','rb','ra'}; % name of the fitted parameters
        voxelwise = 1; % voxel by voxel fitting?
        
        % fitting options
        st           = [1      0.7        6     ]; % starting point
        lb            = [0     0.3        3       ]; % lower bound
        ub           = [3       3         10       ]; % upper bound
        fx            = [0      0           0    ]; % fix parameters
        
        % Protocol
        Prot = struct('IRdata', struct('Format',{'TI(s)'},'Mat',[200 550 1000 2300 2500]'));
        
        % Model options
        buttons = {'method',{'Magnitude','Complex'}};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        function obj = InversionRecovery
            obj = button2opts(obj);
        end
        
        function Smodel = equation(obj, x)
            % Check input
            if ~isstruct(x) % if x is a structure, convert to vector
                for ix = 1:length(obj.xnames)
                    xtmp.(obj.xnames{ix}) = x(ix);
                end
                x = xtmp;
            end
            % equation
            Smodel = x.ra + x.rb * exp(-obj.Prot.IRdata.Mat./x.T1);
            
        end
        
        
        function FitResults = fit(obj,data)
            data = data.IRdata;
            [T1,rb,ra,res,idx]=fitT1_IR(data,obj.Prot.IRdata.Mat,obj.options.method);
            FitResults.T1 = T1;
            FitResults.rb = rb;
            FitResults.ra = ra;
            FitResults.res = res;
            if (strcmp(obj.options.method, 'Magnitude'))
                FitResults.idx=idx;
            end
        end
        
        function plotmodel(obj, FitResults, data)
            if isempty(FitResults), return; end
            if exist('data','var'),
                data = data.IRdata;
                % plot
                plot(obj.Prot.IRdata.Mat,data,'.','MarkerSize',15)
                hold on
                if (strcmp(obj.options.method, 'Magnitude'))
                    % plot the polarity restored data points
                    data_rest=-1.*data(1:FitResults.idx);
                    plot(obj.Prot.IRdata.Mat(1:FitResults.idx),data_rest,'o','MarkerSize',5,'MarkerEdgeColor','b','MarkerFaceColor',[1 0 0])
                end
            end
            
            
            
            % compute model
            Smodel = equation(obj, FitResults);
            
            % plot fitting curve
            plot(obj.Prot.IRdata.Mat,Smodel,'Linewidth',3)
            xlabel('Inversion Time [ms]','FontSize',15);
            ylabel('Signal','FontSize',15);
            legend('data', 'polarity restored', 'fit')
            legend('show','Location','Best')
            set(gca,'FontSize',15)
        end
        
    end
end
