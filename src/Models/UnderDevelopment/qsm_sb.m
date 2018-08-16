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
        buttons = {'Direction',{'forward','backward'},'Padding Size', [9 9 9], 'Sharp Filtering', true, 'Sharp Mode', {'once','iterative'} ,'PANEL', 'Regularization Selection', 4,...
            'L1 Regularized', false, 'L2 Regularized', false, 'Split-Bregman', false, 'No Regularization', false, ...
            'PANEL', 'L1 Panel',2, 'Lambda L1', 5, 'ReOptimize Lambda L1', false, 'L1 Range', [1 2 3], ...
            'PANEL', 'L2 Panel', 2, 'Lambda L2',5, 'ReOptimize Lambda L2', false, 'L2 Range', [1 2 3]
            };
        
        tips = {'Direction','Direction of the differentiation','Padding Size','Size of the padding', ...
            'ReOptimize Lambda L1', 'Some explanation here'
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
            
            obj.lambdaL1Range = logspace(obj.rangeL1(1),obj.rangeL1(2), obj.rangeL1(3));
            obj.lambdaL2Range = logspace(obj.rangeL2(1), obj.rangeL2(2), obj.rangeL2(3));
            
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            
            obj = linkGUIState(obj, 'Split-Bregman', 'L1 Regularized', 'enable_disable_button', 'active_0', true);
            obj = linkGUIState(obj, 'Split-Bregman', 'L2 Regularized', 'enable_disable_button', 'active_0', true);
            obj = linkGUIState(obj, 'Split-Bregman', 'No Regularization', 'enable_disable_button', 'active_0',false);
            
            obj = linkGUIState(obj, 'Sharp Filtering', 'Sharp Mode', 'show_hide_button', 'active_1');
            
            obj = linkGUIState(obj, 'L1 Regularized', 'L1 Panel', 'show_hide_panel', 'active_1');
            obj = linkGUIState(obj, 'L2 Regularized', 'L2 Panel', 'show_hide_panel', 'active_1');
            
            obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'L1 Range', 'show_hide_button', 'active_1');
            obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'L2 Range', 'show_hide_button', 'active_1');
            obj = linkGUIState(obj, 'ReOptimize Lambda L1', 'Lambda L1', 'enable_disable_button', 'active_0');
            obj = linkGUIState(obj, 'ReOptimize Lambda L2', 'Lambda L2', 'enable_disable_button', 'active_0');
            
        end
        
        function FitResults = fit(obj,data)
            
            PhaseParams = obj.Prot.PhaseGRE.Mat;
            Opt = GetFitOpt(obj);
            [FitResults.chi_SB, FitResults.chi_L2, FitResults.chi_L2pcg, FitResults.nfm_disp] = qsm_gre_exec(data, PhaseParams, Opt);
            
        end
        
        
        function plotModel(obj, FitResults, data)
            
        end
        
        
        function FitResults = Sim_Single_Voxel_Curve(obj, x, Opt, display)
            
        end
        
        function FitOpt = GetFitOpt(obj)
            
            FitOpt.lambdaL1Range = obj.lambdaL1Range;
            FitOpt.lambdaL2Range = obj.lambdaL2Range;
            FitOpt.gyro = obj.gyro;
            FitOpt.pad_size = obj.pad_size;
            FitOpt.direction = obj.options.direction;
            FitOpt.sharp_mode = obj.options.sharp_mode;
            
            
            
        end
        
        
    end
    
    
    methods (Access = protected)
        
        function idx = getButtonIdx(obj,buttonName)
            
            idx = find(strcmp(obj.buttons,buttonName) | strcmp(obj.buttons,['###' buttonName]) | ...
                strcmp(obj.buttons,['***' buttonName]));
            
            
        end
        
        function obj = setButtonInvisible(obj,buttonName,state)
            
            idx = getButtonIdx(obj,buttonName);
            
            if state
                
                % There may be an attempt to sth
                obj.buttons{idx} = ['***' buttonName];
                
            elseif not(state) && strcmp(obj.buttons{idx}(1:3),'***')
                
                obj.buttons{idx} = buttonName;
                
            end
            
        end
        
        function obj = setButtonDisabled(obj,buttonName,state)
            
            idx = getButtonIdx(obj,buttonName);
            
            if state && not(strcmp(obj.buttons{idx}(1:3),'###'))
                
                obj.buttons{idx} = ['###' buttonName];
                
            elseif not(state) && strcmp(obj.buttons{idx}(1:3),'###')
                
                obj.buttons{idx} = buttonName;
                
            end
            
        end
        
        function obj = setPanelInvisible(obj,panelName,state)
            
            idx = getButtonIdx(obj,panelName);
            
            if not(strcmp(obj.buttons{idx-1},'PANEL'))
                error(['panelName passed to the setPanelInvisible function' ...
                    ' does not correspond to a panel']);
            end
            
            if state
                
                obj.buttons{idx} = ['###' panelName];
                
            elseif not(state) && strcmp(obj.buttons{idx}(1:3),'###')
                
                obj.buttons{idx} = panelName;
                
            end
            
            
        end
        
        function obj = linkGUIState(obj, checkBoxName, targetObject, eventType, activeState, setVal)
            
            
            
            switch activeState
                
                case 'active_1'
                    x = false;
                    y = true;
                case 'active_0'
                    x = true;
                    y = false;
            end
            
            [opNameCheckbox, typeCheckBox] = getOptionsFieldName(obj,checkBoxName);
            [opNameTarget, typeTarget] = getOptionsFieldName(obj,targetObject);
            
            if not(strcmp(typeCheckBox,'checkbox')) 
                error('LinkGUIState: Second argument must be a checkbox'); 
            end
            
            
            switch eventType
                
                case 'enable_disable_button'
                    
                    if obj.options.(opNameCheckbox)
                      
                      if nargin == 6  
                      
                          obj = setValAssign(obj,opNameTarget,typeTarget,setVal);
                          
                      end
                      
                      obj =  setButtonDisabled(obj,targetObject,x);
                        
                    else
                        
                        obj =  setButtonDisabled(obj,targetObject,y);
                        
                    end
                    
                case 'show_hide_button'
                    
                    if obj.options.(opNameCheckbox)
                        
                        obj =  setButtonInvisible(obj,targetObject,x);
                        
                    else
                        
                        obj =  setButtonInvisible(obj,targetObject,y);
                        
                    end
                    
                case 'show_hide_panel'
                    
                    if obj.options.(opNameCheckbox)
                        
                        obj =  setPanelInvisible(obj,targetObject,x);
                        
                    else
                        
                        obj =  setPanelInvisible(obj,targetObject,y);
                        
                    end
                    
            end
            
            
        end
        
        function [opName, type] = getOptionsFieldName(obj,buttonName)
            
            varName = genvarname_v2(buttonName);
            
            opts = button2opts(obj.buttons);
            opNames = fieldnames(opts);
            
            varIdx = find(cellfun(@(x)~isempty(strfind(x,varName)), opNames));
            opName = opNames{varIdx};
            
            idx = getButtonIdx(obj,buttonName);
            val = obj.buttons{idx+1};    
            ln = length(val);
            
            if islogical(val)
                
                type = 'checkbox';
                
            elseif isnumeric(val) && ln == 1
                
                type = 'singleNum';
                
            elseif isnumeric(val) && ln > 1
                
                type = 'table';
                
            elseif iscell(val)
                
                type = 'popupmenu';
                
            end
            
        end
        
        function obj = setValAssign(obj,opNameTarget,typeTarget,setVal)
          
                try
                
                    obj.options.(opNameTarget) = setVal;
                
                catch
                
                if strcmp(typeTarget,'checkbox') && not(islogical(setVal))
                    error('setVal to a checkbox targetObject must be logical');
                end
                
                if strcmp(typeTarget,'singleNum') && length(setVal)>1
                    error('Target object expects a single value.');
                end
                
                if strcmp(typeTarget,'popupmenu') && not(iscell(setVal))
                    error('Target object expects type cell.');
                end
                
                if strcmp(typeTarget,'table') && length(setVal) == 1
                    error('Target object expects an array.');
                end
                
                end
                
            
        end
        
        
    end
end
