classdef InversionRecovery
% Compute a T1 map using Inversion Recovery data
%
%-------------USAGE------------
% See
% https://github.com/neuropoly/qMRLab/blob/Dev/Data/IR_demo/IR_batch.m for
% an example
%
%-------------ASSUMPTIONS-----------------
% 	1) Gold standard for T1 mapping
%
%---------------INPUTS--------------
%   1) IRData : Inversion Recovery data
%   2) Mask   : Binary mask to accelerate the fitting (OPTIONAL)
%
%-------------OUTPUTS-----------------
%	Fitting Parameters
%       * T1 (transverse relaxation)
%       * 'b' or 'rb' parameter (S=a + b*exp(-TI/T1))
%       * 'a' or 'ra' parameter (S=a + b*exp(-TI/T1))
%       * idx: index of last polarity restored datapoint (only used for magnitude data)
%       * res: Fitting residual
%
%------------OPTIONS-----------------
%   method: Method to use in order to fit the data, based on whether
%               complex or only magnitude data is available.
%                 'complex'   : RD-NLS (Reduced-Dimension Non-Linear Least
%                                Squares)
%                              S=a + b*exp(-TI/T1)
%             or  'magnitude' : RD-NLS-PR (Reduced-Dimension Non-Linear Least Squares
%                               with Polarity Restoration)
%                              S=|a + b*exp(-TI/T1)|
%--------------PROTOCOL-----------------
%   TI:  Array containing the Inversion times, in ms
%
%---------------REFERENCE---------------
% Please cite the following if you use this module:
%
% *A robust methodology for in vivo T1 mapping.
% Barral JK, Gudmundson E, Stikov N, Etezadi-Amoli M, Stoica P, Nishimura DG.
% Magn Reson Med. 2010 Oct;64(4):1057-67. doi: 10.1002/mrm.22497.*
%
% In addition to citing the package:
%
% *Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357*
%
%----------------------------------_------------------------------------
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
        
        % Simulation Options
        Sim_Single_Voxel_Curve_buttons = {'SNR',50};
        Sim_Optimize_Protocol_buttons = {'# of volumes',5,'Population size',100,'# of migrations',100};

    end
    
    methods
        function  obj = InversionRecovery()
            obj.options = button2opts(obj.buttons);
        end
        
        function obj = UpdateFields(obj)
            obj.Prot.IRData.Mat = sort(obj.Prot.IRData.Mat);
        end
        
        function Smodel = equation(obj, x)
            % Generates an IR signal based on input parameters
            %
            % :param x: [struct] containing fit parameters 'a' 'b' and 'T1'
            % :returns: Smodel: generated signal
            x = mat2struct(x,obj.xnames); % if x is a structure, convert to vector
               
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
        function plotmodel(obj, FitResults, data)
            % Plots the fit
            %
            % :param FitResults: [struct] Fitting parameters
            % :param data: [struct] input data
            if nargin<2 || isempty(FitResults), FitResults = obj.st; end
            if exist('data','var')
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
            hold off
            xlabel('Inversion Time [ms]','FontSize',15);
            ylabel('Signal','FontSize',15);
            legend('data', 'polarity restored', 'fit')
            legend('show','Location','Best')
            set(gca,'FontSize',15)
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
        
%         function schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,Opt)
%             % schemeLEADER = Sim_Optimize_Protocol(obj,xvalues,nV,popSize,migrations)
%             % schemeLEADER = Sim_Optimize_Protocol(obj,obj.st,30,100,100)
%             % Optimize Inversion times
%             nV         = Opt.Nofvolumes;
%             popSize    = Opt.Populationsize;
%             migrations = Opt.Nofmigrations;
%             
%             sigma  = .05;
%             TImax = 5000;
%             TImin = 50;
%             GenerateRandFunction = @() rand(nV,1)*(TImax-TImin)+TImin; % do not sort TI values... or you might fall in a local minima
%             CheckProtInBoundFunc = @(Prot) min(max(50,Prot),TImax);
%             % Optimize Protocol
%             [retVal] = soma_all_to_one(@(Prot) mean(SimCRLB(obj,Prot,xvalues,sigma)), GenerateRandFunction, CheckProtInBoundFunc, migrations, popSize, nV, obj.Prot.IRData.Mat(:,1));
%             
%             % Generate Rest
%             schemeLEADER = retVal.schemeLEADER;
%             
%             fprintf('SOMA HAS FINISHED \n')
%             
%         end
        
    end
end
