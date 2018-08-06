classdef qsm_gre < AbstractModel % Name your Model
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
        
        % Zero padding size for mask and wrapped phase volumes
        % This padding is for SHARP kernel convolutions 
        pad_size = [9 9 9];
        
        % Direction of the differentiation 
        direction = 'forward';
        
        % This is the mode for SHARP filtering 'once' or 'iterative'
        sharp_mode = 'once';
        
        
        % --- Acquisition related paramters (protocols) 
        Prot = struct('PhaseGRE',struct('Format',{{'TE (s)' 'Spacing[1] (mm)' 'Spacing[2] (mm)' 'Spacing[3] (mm)' 'FieldStrength (T)'}},...
                                   'Mat',  [8.1e-3 0.6 0.6 0.6 3]),...
                      'MagnGRE',struct('Format',{{'TE (s)' 'Spacing[1] (mm)' 'Spacing[2] (mm)' 'Spacing[3] (mm)' 'FieldStrength (T)'}},...
                                   'Mat',  [8.1e-3 0.6 0.6 0.6 3]));
        
        % Model options
        buttons = {'direction',{'forward','backward'},'sharp_mode',{'once','iterative'}, 'H_freq (MHz)', 42.58};
        options= struct();
        
    end
    
    properties (Hidden = true)
        
        lambdaL1Range = [];
        lambdaL2Range = [];
        onlineData_url = 'https://osf.io/rn572/download/';
        
    end
    
    methods
        
        function obj = qsm_gre
            
        obj.lambdaL1Range = logspace(obj.rangeL1(1),obj.rangeL1(2), obj.rangeL1(3));
        obj.lambdaL2Range = logspace(obj.rangeL2(1), obj.rangeL2(2), obj.rangeL2(3));
            
        obj.options = button2opts(obj.buttons); 
            
        end
        
        function Smodel = equation(obj, x)
            % Compute the Signal Model based on parameters x. 
            % x can be both a structure (FieldNames based on xnames) or a
            % vector (same order as xnames).
            x = struct2mat(x,obj.xnames);
            
            %% CHANGE HERE:
            D = zeros(1,2);
            D(1) = x(1); 
            D(2) = x(2);
            Tvec = obj.Prot.Data4D.Mat(:,1:2);
            
            % COMPUTE SIGNAL
            Smodel = exp(-D*Tvec');
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
end