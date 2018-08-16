classdef qsm_sb < AbstractModel % Name your Model
    % CustomExample :  Describe the method here
    %<a href="matlab: figure, imshow CustomExample.png ;">Pulse Sequence Diagram</a>
    %
    % Inputs:
    %   PhaseGRe    3D xxx
    %   (MagnGRE)     3D xxx
    %   Mask        Binary mask
    %
    % Assumptions:
    % (1)FILL
    % (2)
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
    %       Smooth q-space data per shell b code for the complete reconstruction pipeline (Laplacian unwrapping, SHARP filtering, ℓ2- and ℓ1- regularized fast susceptibility mapping with magnitude weighting and parameter estimation) is included as supplementary material and made available prior fitting
    %
    % Example of command line usage (see also <a href="matlab: showdemo Custom_batch">showdemo Custom_batch</a>):
    %   For more examples: <a href="matlab: qMRusage(Custom);">qMRusage(Custom)</a>
    %
    % Author:
    %
    % References:
    %   Please cite the following if you use this module:
    %     FILL
    %   In addition to citing the package:
    %     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357

    properties

        % --- Inputs
        MRIinputs = {'PhaseGRE', 'MagnGRE', 'Mask'};

        % --- Fitted parameters
        xnames = { 'phase_lunwrap','nfm_Sharp_lunwrap', 'mask_Sharp',...
            'magn_weight'};

        % --- Fitting options
        % Note: Default fitting options are adjusted for Fast

        voxelwise = 0;

        % L1 regularization weights for optimization [min max N]
        % The min-max range will be logarithmically spaced for N pts.
        rangeL1 = [-4 2.5 15];


        % L1 regularization weights for optimization [min max N]
        % The min-max range will be logarithmically spaced for N pts.

        rangeL2 = [-4 2.5 15];


        % Gyromagnetic ratio at 1T
        gyro = 2*pi*42.58;

        % Zero padding sUn*x that is supported by the Qize for mask and wrapped phase volumes
        % This padding is for SHARP kernel convolutions
        pad_size = [9 9 9];

        % Direction of the differentiation
        direction = 'forward';

        % This is the mode for SHARP filtering 'once' or 'iterative'
        sharp_mode = 'once';


        % --- Acquisition related paramters (protocols)
        Prot = struct('Resolution',struct('Format',{{'VoxDim[1] (mm)' 'VoxDim[2] (mm)' 'VoxDim[3] (mm)'}},...
            'Mat',  [0.6 0.6 0.6]),...
            'Timing',struct('Format',{{'TE (s)'}},...
            'Mat', 8.1e-3), ...
            'Magnetization', struct('Format', {{'Field Strength (T)' 'Central Freq. (MHz)'}}, 'Mat', [3 42.58]));


        % Model options
        buttons = {'Direction',{'forward','backward'}, 'Sharp Filtering', true, 'Sharp Mode', {'once','iterative'}, 'Padding Size', [9 9 9],'Magnitude Weighting',false,'PANEL', 'Regularization Selection', 4,...
            'L1 Regularized', false, 'L2 Regularized', false, 'Split-Bregman', false, 'No Regularization', false, ...
            'PANEL', 'L1 Panel',2, 'Lambda L1', 5, 'ReOptimize Lambda L1', false, 'L1 Range', [-4 2.5 15], ...
            'PANEL', 'L2 Panel', 2, 'Lambda L2',5, 'ReOptimize Lambda L2', false, 'L2 Range', [-4 2.5 15]
            };

        % Tiptool descriptions
        tips = {'Direction','Direction of the differentiation', ...
                'Magnitude Weighting', 'Calculates gradient masks from Magn data using k-space gradients and includes magn weighting in susceptibility maping.',...
                'Sharp Filtering', 'Enable/Disable SHARP background removal.', ...
                'Sharp Mode', 'Once: 9x9x9 kernel. Iterative: 9x9x9 to 3x3x3 with the step size of -2x-2x-2.', ...
                'Padding Size', 'Zero padding size for SHARP kernel convolutions.', ...
                'L1 Regularized', 'Open L1 regulatization panel.', ...
                'L2 Regularized', 'Open L2 regulatization panel.', ...
                'Split-Bregman',  'Perform Split-Bregman quantitative susceptibility mapping.', ...
        'ReOptimize Lambda L1', 'Do not use default or user-defined Lambda L1.', ...
        'ReOptimize Lambda L2', 'Do not use default or user-defined Lambda L2.', ...
        'L1 Range','L1 regularization weights for optimization [min max N]',...
        'L2 Range','L2 regularization weights for optimization [min max N]'
        };

        options= struct();

    end

    properties (Hidden = true)

        lambdaL1Range = [];
        lambdaL2Range = [];

        onlineData_url = 'https://osf.io/rn572/download/';

    end

    methods

        function obj = qsm_sb
            % Constructor

            % Transfer regularization parameter optimization range to the logspace
            obj.lambdaL1Range = logspace(obj.rangeL1(1),obj.rangeL1(2), obj.rangeL1(3));
            obj.lambdaL2Range = logspace(obj.rangeL2(1), obj.rangeL2(2), obj.rangeL2(3));
            % Convert buttons to options
            obj.options = button2opts(obj.buttons);
            % UpdateFields to take GUI interactions their effect on opening.
            obj = UpdateFields(obj);
        end

        function obj = UpdateFields(obj)

            % Functional but imperfect for now. When Split-Bergman
            % selected,you cannot disable L1 and L2, but they are not
            % disabled. Use state = getCheckBoxState(obj,checkBoxName)
            % later.

            obj = linkGUIState(obj, 'Sharp Filtering', 'Sharp Mode', 'show_hide_button', 'active_1');
            obj = linkGUIState(obj, 'Sharp Filtering', 'Padding Size', 'show_hide_button', 'active_1');

            obj = linkGUIState(obj, 'Split-Bregman', 'L1 Regularized', 'enable_disable_button', 'active_0', true);
            obj = linkGUIState(obj, 'No Regularization', 'L1 Regularized', 'enable_disable_button', 'active_0',false);

            obj = linkGUIState(obj, 'Split-Bregman', 'L2 Regularized', 'enable_disable_button', 'active_0', true);
            obj = linkGUIState(obj, 'No Regularization', 'L2 Regularized', 'enable_disable_button', 'active_0',false);

            obj = linkGUIState(obj, 'No Regularization', 'Split-Bregman', 'enable_disable_button', 'active_0',false);
            obj = linkGUIState(obj, 'Split-Bregman', 'No Regularization', 'enable_disable_button', 'active_0',false);

            obj = linkGUIState(obj, 'L1 Regularized', 'L1 Panel', 'show_hide_panel', 'active_1');
            obj = linkGUIState(obj, 'L2 Regularized', 'L2 Panel', 'show_hide_panel', 'active_1');

            obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'L1 Range', 'show_hide_button', 'active_1');
            obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'L2 Range', 'show_hide_button', 'active_1');
            obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'Lambda L1', 'enable_disable_button', 'active_0');
            obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'Lambda L2', 'enable_disable_button', 'active_0');



        end

        function FitResults = fit(obj,data)
            
            gyro =   obj.Prot.Magnetization.Mat(2);
            B0   =   obj.Prot.Magnetization.Mat(1);
            TE   =   obj.Prot.Timing.Mat;
            imageResolution = obj.Prot.Resolution.Mat; 
            
            FitOpts = GetFitOpt(obj);
            
            PhaseParams = obj.Prot.PhaseGRE.Mat;
            Opt = GetFitOpt(obj);
            [FitResults.chi_SB, FitResults.chi_L2, FitResults.chi_L2pcg, FitResults.nfm_disp] = qsm_gre_exec(data, PhaseParams, Opt);

        end


        function FitOpt = GetFitOpt(obj)
            
            FitOpt.reoptL1_Flag = obj.options.L1Panel_LambdaL1;
            FitOpt.reoptL2_Flag = obj.options.L1Panel_LambdaL2;
            
            FitOpt.regSB_Flag = obj.options.RegularizationSelection_SplitBregman;
            FitOpt.regL1_Flag = obj.options.RegularizationSelection_L1Regularized;
            FitOpt.regL2_Flag = obj.options.RegularizationSelection_L2Regularized;
            
            FitOpt.magnW_Flag = obj.options.MagnitudeWeighting;
            
            FitOpt.sharp_Flag = obj.options.SharpFiltering;
            
            FitOpt.lambdaL1Range = obj.lambdaL1Range;
            FitOpt.lambdaL2Range = obj.lambdaL2Range;
            FitOpt.gyro = obj.gyro;
            FitOpt.pad_size = obj.pad_size;
            FitOpt.direction = obj.options.direction;
            FitOpt.sharp_mode = obj.options.sharp_mode;
                


        end


    end

end
