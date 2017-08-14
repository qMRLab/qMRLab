classdef MWF
%-----------------------------------------------------------------------------------------------------
% MWF :  Myelin Water Fraction
%-----------------------------------------------------------------------------------------------------
%-------------%
% ASSUMPTIONS %
%-------------% 
% (1) FILL
% (2) 
% (3) 
% (4) 
%-----------------------------------------------------------------------------------------------------
%--------%
% INPUTS %
%--------%
%   1) MET2data : Multi-Exponential T2 data
%   2) Mask     : Binary mask to accelerate the fitting (OPTIONAL)
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OUTPUTS %
%---------%
%	* MWF   : Myelin Water Fraction
%	* T2MW  : Spin relaxation time for Myelin Water (MW)
%   * T2IEW : Spin relaxation time for Intra/Extracellular Water (IEW)
%
%-----------------------------------------------------------------------------------------------------
%----------%
% PROTOCOL %
%----------%
%	* First   : Time of the first echo (s) 
%	* Spacing : Time interval between each echo (s)
%
%-----------------------------------------------------------------------------------------------------
%---------%
% OPTIONS %
%---------%
%   * Cutoff : Time cutoff (s) 
%   * Sigma  : Noise's sigma ?????
%
%-----------------------------------------------------------------------------------------------------
% Written by: Ian Gagnon, 2017
% Reference: FILL
%-----------------------------------------------------------------------------------------------------

    properties
        MRIinputs = {'MET2data','Mask'};
        xnames = {'MWF','T2_MW','T2_IEW'};
        voxelwise = 1;
        
        % Parameters options
        lb = [0   0     50];
        ub = [1  50   2000];
        
        % Protocol
        Prot  = struct('Echo',struct('Format',{{'First (s)'; 'Spacing (s)'}},...
                                     'Mat', [0.01; 0.01])); % You can define a default protocol here.
        decay_matrix = [];
        
        % Model options
        buttons = {'Cutoff (s)',0.05, 'Sigma', 28, 'relaxation_type' {'T2', 'T2*'}};
        options = struct(); % structure filled by the buttons. Leave empty in the code
        
        % Simulation Options
        Sim_Single_Voxel_Curve_buttons = {'st',{'Analytical equation','Block equation'},'Reset Mz',false};
        Sim_Sensitivity_Analysis_buttons = {'# of run',5};

    end
    
    methods
        
        function obj = MWF
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            %decay_matrix = prepare_NNLS(echotimes, T2);
%             
%             switch obj.option.relaxation_type
%                 case 'T2'
%                     obj.ub = [1.5*echo_times(1), 2000]; % Kolind et al. doi: 10.1002/mrm.21966
%                     % set cutoff times for myelin water (MW) and intra/extracellular water (IEW) components (in ms)
%                     lower_cutoff_MW = t2_range(1);
%                     upper_cutoff_MW = Cutoff;
%                     %upper_cutoff_MW = 40; % Kolind et al. doi: 10.1002/mrm.21966
%                     upper_cutoff_IEW = 200; % Kolind et al. doi: 10.1002/mrm.21966
%                     
%                 case 'T2star'
%                     t2_range = [1.5*echo_times(1), 300]; % Lenz et al. doi: 10.1002/mrm.23241
%                     %         t2_range = [1.5*echo_times(1), 600]; % Use this to look at CSF component
%                     % set cutoff times for myelin water (MW) and intra/extracellular water (IEW) components (in ms)
%                     lower_cutoff_MW = t2_range(1);
%                     %upper_cutoff_MW = 25; % Lenz et al. doi: 10.1002/mrm.23241
%                     upper_cutoff_MW = Cutoff;
%                     upper_cutoff_IEW = 200;
%                     
%                 otherwise
%                     error(sprintf('\nRelaxation type must be either T2 or T2star!'));
%             end
        end
        
        function equation(obj)
            T2vals = getT2(obj);
        end
        function FitResults = fit(obj,data)
            Echo.First   = 1000*obj.Prot.Echo.Mat(1);
            Echo.Spacing = 1000*obj.Prot.Echo.Mat(2);
            Cutoff  = 1000*obj.options.Cutoffs;
            Sigma = obj.options.Sigma;
            MET2 = data.MET2data;
            Mask = data.Mask;            
            FitResults = multi_comp_fit_v2(reshape(MET2,[1 1 1 length(MET2)]), 'T2', Echo, Cutoff, Sigma, 'tissue', Mask);
        end
       
        function t2_vals  = getT2(obj)
            NT2 = 120;


            T2 = [t2_range(1)*(t2_range(2)/t2_range(1)).^(0:(1/(NT2-1)):1)'];
        end
    end
end

