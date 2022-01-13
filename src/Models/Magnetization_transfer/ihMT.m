classdef ihMT < AbstractModel
    % ihMT:   inhomogenuous Magnetization Transfer
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
    %   For more examples: <a href="matlab: qMRusage(ihMT);">qMRusage(ihMT)</a>
    %
    % Author: 
    %
    % References:
    %   Please cite the following if you use this module:
    %     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
    %     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
    %     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
    properties (Hidden=true)
        onlineData_url = '';
    end
    
    properties
        MRIinputs = {'MTw_dual', 'MTw_single', 'T1w', 'PDw', 'B1map', 'Mask'};
        xnames = {};
        voxelwise = 0; % 0, if the analysis is done matricially
        % 1, if the analysis is done voxel per voxel
        % Protocol
        Prot = struct('MTw_dual',struct('Format',{{'FlipAngle' 'TR'}},...
                                   'Mat',  [9 0.028]),...
                      'MTw_single',struct('Format',{{'FlipAngle' 'TR'}},...
                                   'Mat',  [9 0.028]),...
                      'T1w',struct('Format',{{'FlipAngle' 'TR'}},...
                                   'Mat',  [20 0.030]),...
                      'PDw',struct('Format',{{'FlipAngle' 'TR'}},...
                                   'Mat',  [5 0.030]));
                               
        ProtStyle = struct('prot_namespace',{{'MTw_dual', 'MTw_single', 'T1w','PDw'}}, ...
        'style',repmat({'TableNoButton'},[1,4]));
        
        %Option panel: ModelBasedB1corrected parameters
            buttons ={'PANEL','Sequence simulation',15,...
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
            '##fitValues Directory',10,...
            '##fitValues Name',10,...
            '##MTsatValues Name',10,...
            'Run Sequence Simulation','pushbutton',...
            'PANEL','Correlate M0bapp VS R1',2,...
            'Same Imaging Protocol',false,...
            'b1rms',6.8};
        
        
        options = struct();
    end
    % Inherit these from public properties of FilterClass
    % Model options
    % buttons ={};
    % options = struct(); % structure filled by the buttons. Leave empty in the code
    
    methods
        % Constructor
        function obj = ihMT()
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function [obj,fitValues] = UpdateFields(obj)
            if obj.options.Sequencesimulation_Frequencypattern == "dualAlternate"
                obj.options.Sequencesimulation_fitValuesName = "fitValues_dualAlt";
                obj.options.Sequencesimulation_MTsatValuesName = "MTsatValues_dualAlt";
            end
                
            if obj.options.Sequencesimulation_Frequencypattern == "single"
                obj.options.Sequencesimulation_fitValuesName = "fitValues_single";
                obj.options.Sequencesimulation_MTsatValuesName = "MTsatValues_single";
            end
                
            if obj.options.Sequencesimulation_Frequencypattern == "dualContinuous"
               obj.options.Sequencesimulation_fitValuesName = "fitValues_dualCont";
               obj.options.Sequencesimulation_MTsatValuesName = "MTsatValues_dualCont";
            end

            %Running simulation (takes long time)
            if obj.options.Sequencesimulation_RunSequenceSimulation
                %Setting the fitValues directory
                obj.options.Sequencesimulation_fitValuesDirectory = uigetdir(pwd,'Select directory to save fitValues');
                [fitValues,~]=simSeq_M0b_R1obs(obj);
            else
                obj.options.Sequencesimulation_fitValuesDirectory = pwd;
            end
        end
        
        function FitResult = fit(obj,data)
            %Loading fitValues results from simulation
            disp('Run a new sequence simulation or load <<fitValues.mat>> results from a previous simulation')
            [FileName,PathName] = uigetfile('*.mat','Load fitValues structure');
            fitValues = load([PathName filesep FileName]);
            obj.options.Sequencesimulation_fitValuesDirectory = PathName;
            obj.options.Sequencesimulation_fitValuesName = FileName;
            
            %strcat(obj.options.Sequencesimulation_fitValuesDirectory, filesep, obj.options.Sequencesimulation_fitValuesName, '.mat')
            
            MTparams = obj.Prot.MTw.Mat;
            PDparams = obj.Prot.PDw.Mat;
            T1params = obj.Prot.T1w.Mat;

            %Correlate M0b_app VS R1
            if ~obj.options.CorrelateM0bappVSR1_SameImagingProtocol
                [FitResult.M0b_app,FitResult.fit_qual,FitResult.comb_res,fitValues]=sampleCode_calc_M0bappVsR1_1dataset(data,MTparams,PDparams,T1params,fitValues,obj);
            end
            
            %Correct MTsat data
            [MTsat_b1corr, MTsatuncor,R1,R1uncor] = sample_code_correct_MTsat(data,MTparams,PDparams,T1params,fitValues,obj);
            FitResult.MTSATcor = MTsat_b1corr;
            FitResult.MTSAT = MTsatuncor;
            FitResult.T1cor = 1./R1;
            FitResult.T1 = 1./R1uncor;
        end
        
    end
    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            
        end
        
    end
    
end