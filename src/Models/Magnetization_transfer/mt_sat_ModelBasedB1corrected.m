
classdef mt_sat_ModelBasedB1corrected < AbstractModel
    % MTsat_ModelBasedB1corrected:   Model Based B1 corrected Mtsat maps
    %
    % Assumptions: 
    %
    % Inputs:
    %   R                I
    %   (Mask)             Binary mask to exclude voxels from smoothing
    %
    % Outputs:
    %	Fi          F
    %
    % Protocol:
    %	NONE
    %
    % Options:
    %   (
    %
    % Example of command line usage:
    %
    %   For more examples: <a href="matlab: qMRusage(MTsat_ModelBasedB1corrected);">qMRusage(MTsat_ModelBasedB1corrected)</a>
    %
    % Author: 
    %
    % References:
    %   Please cite the following if you use this module:
    %     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
    %     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
    %     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
    properties (Hidden=true)
        onlineData_url = 'https://osf.io/d8p4h/download?version=3';
    end
    
    properties
        MRIinputs = {'MTw','T1w', 'PDw', 'B1map', 'Mask'};
        xnames = {};
        voxelwise = 0; % 0, if the analysis is done matricially
        % 1, if the analysis is done voxel per voxel
        % Protocol
        Prot = struct('MTw',struct('Format',{{'FlipAngle' 'TR'}},...
                                   'Mat',  [9 0.028]),...
                      'T1w',struct('Format',{{'FlipAngle' 'TR'}},...
                                   'Mat',  [20 0.030]),...
                      'PDw',struct('Format',{{'FlipAngle' 'TR'}},...
                                   'Mat',  [5 0.030]));
                               
        ProtStyle = struct('prot_namespace',{{'MTw', 'T1w','PDw'}}, ...
        'style',repmat({'TableNoButton'},[1,3]));
        
        %Option panel: ModelBasedB1corrected parameters
            buttons ={'PANEL','Sequence simulation',14,...
            'B1rms',9,...
            'Number saturation pulse',2,...
            'Pulse duration',0.768,...
            'Pulse gap duration',0.6,...
            'TR',28,...
            'WExcDur',3,...
            'Number excitation',1,...
            'Frequency pattern',{'dualAlternate','single','dualContinuous'},...
            'Delta',7000,...
            'FlipAngle',9,...
            'Saturation pulse shape',{'hanning','gaussian','square'},...
            'Saving fitValues','pushbutton',...
            'fitValues Directory',10,...
            'Run Sequence Simulation','pushbutton',...
            'PANEL','Correlate M0bapp VS R1',1,...
            'b1rms',6.8};
        
        
        options = struct();
    end
    % Inherit these from public properties of FilterClass
    % Model options
    % buttons ={};
    % options = struct(); % structure filled by the buttons. Leave empty in the code
    
    methods
        % Constructor
        function obj = mt_sat_ModelBasedB1corrected()
            
            %Option panel: FilterClass parameters
            objFilter = FilterOptions;
            
            obj.buttons = cat(2,obj.buttons,objFilter.buttons);
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function [obj,fitValues] = UpdateFields(obj)
            %Setting the fitValues directory
            if obj.options.Sequencesimulation_SavingfitValues
                obj.options.Sequencesimulation_fitValuesDirectory = uigetdir;
            else
                obj.options.Sequencesimulation_fitValuesDirectory = pwd;
            end

            %Running simulation (takes long time)
            if obj.options.Sequencesimulation_RunSequenceSimulation
                [fitValues,~]=simSeq_M0b_R1obs(obj);
            end
        end
        
        function FitResult = fit(obj,data)
            MTparams = obj.Prot.MTw.Mat;
            PDparams = obj.Prot.PDw.Mat;
            T1params = obj.Prot.T1w.Mat;
            
                if exist([obj.options.Sequencesimulation_fitValuesDirectory filesep 'fitValues.mat'],'file') == 2
                    fitValues = load([obj.options.Sequencesimulation_fitValuesDirectory filesep 'fitValues.mat']);
                else
                    disp('Run a new sequence simulation or load <<fitValues.mat>> results from a previous simulation')
                    [FileName,PathName] = uigetfile('*.mat','Load fitValues.mat');
                    fitValues = load([PathName filesep FileName]);
                    obj.options.Sequencesimulation_fitValuesDirectory = PathName;
                end
                [FitResult.M0b,FitResult.fit_qual,FitResult.comb_res,fitValues]=sampleCode_calc_M0bappVsR1_1dataset(data,MTparams,PDparams,T1params,fitValues);
                [FitResult.MTsat_b1corr] = sample_code_correct_MTsat(data,MTparams,PDparams,T1params,fitValues);
                
                disp('Run a new sequence simulation or load <<fitValues.mat>> results from a previous simulation')
                [FileName,PathName] = uigetfile('*.mat');
                fitValues = load(fullfile(PathName,FileName));
                [MTsat_b1corr,MTsat,T1] = sample_code_correct_MTsat(data,MTparams,PDparams,T1params,fitValues);
                FitResult.MTSATcor = MTsat_b1corr;
                FitResult.MTSAT = MTsat;
                FitResult.T1 = T1;
        end
        
    end
    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            
        end
        
    end
    
end