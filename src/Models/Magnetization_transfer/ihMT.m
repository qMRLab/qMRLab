classdef ihMT < AbstractModel
    % ihMT:   inhomogenuous Magnetization Transfer
    %
    % Assumptions: 
    %         B1+ corrected MT saturation maps taking into account for the
    %         B1+ inhomogeneities effects on the excitation and saturation
    %         pulses.
    %
    % Inputs:
    %   MTw_dual           MT-weigthed data. Dual frequency preparation
    %                      pulse.
    %   MTw_single         MT-weigthed data. Single sided frequency 
    %                      preparation pulse.
    %   T1w                T1-weighted data.
    %   PDw                PD-weighted data.
    %   B1map              Normalized transmit excitation field map (B1+). B1+ is defined 
    %                      as a  normalized multiplicative factor such that:
    %                      FA_actual = B1+ * FA_nominal.
    %   (Mask)             Binary mask (Accelerate fitting - Optional).
    %            
    % Outputs:
    %	MTSATcor_dual      MT saturation map B1+ corrected (dual frequency preparation pulse)
    %   MTSAT_dual         MT saturation map uncorrected (dual frequency preparation pulse)
    %	T1cor_dual         T1 map B1+ corrected (dual frequency preparation pulse)
    %   T1_dual            T1 map uncorrected (dual frequency preparation pulse)
    %
    %	MTSATcor_single    MT saturation map B1+ corrected (single-sided frequency preparation pulse)
    %   MTSAT_single       MT saturation map uncorrected (single-sided frequency preparation pulse)
    %	T1cor_single       T1 map B1+ corrected (single-sided frequency preparation pulse)
    %   T1_single          T1 map uncorrected (single-sided frequency preparation pulse)
    %
    %   ihMTsatcor         inhomogeuous MT saturation map B1+ corrected
    %   ihMTsat            inhomogeuous MT saturation map uncorrected
    %
    % Protocol:
    %	MTw_dual    [FA  TR]  flip angle [deg], TR [s]
    %	MTw_single  [FA  TR]  flip angle [deg], TR [s]
    %   T1w         [FA  TR]  flip angle [deg], TR [s]
    %   PDw         [FA  TR]  flip angle [deg], TR [s]
    %
    % Options:
    %   See:
    %       Model.options (general options)
    %       Model.options.Sequencesimulation (to change parameters of the sequence simulation)
    %   
    % Example of command line usage:
    %   Model = ihMT
    %   %% LOAD DATA
    %   data.MTw_dual = load_nii_data('MTw_dual.nii.gz');
    %   data.MTw_single = load_nii_data('MTw_single.nii.gz');
    %   data.T1w = load_nii_data('T1w.nii.gz');
    %   data.PDw = load_nii_data('PDw.nii.gz');
    %   data.B1map = load_nii_data('B1map.nii.gz');
    %   data.Mask = load_nii_data('Mask.nii.gz');
    %   %% SPECIFY PROTOCOL
    %   % Model.Prot.MTw_dual = [FlipAngle, TR]; % Nx2 matrix
    %   %% FIT all voxels
    %   FitResults = FitData(data,Model);
    %   % SAVE results to NIFTI
    %   FitResultsSave_nii(FitResults,'MTw_dual.nii.gz'); % use header from 'MTw_dual.nii.gz'
    %
    %   For more examples: <a href="matlab: qMRusage(ihMT);">qMRusage(ihMT)</a>
    %
    % Author:
    %   Christopher D. Rowley, 2021 (@christopherrowley, @TardifLab - GitHub)
    % Adapted to qMRLab by:
    %   Juan Velazquez, 2022 (@jvelazquez-reyes - GitHub)
    %
    % References:
    %   Please cite the following if you use this module:
    %     Rowley C.D., Campbell J.S.W., Wu Z., Leppert I.R., Rudko D.A.,
    %     Pike G.B., Tardif C.L. (2021), A model-based framework for correcting 
    %     B1+ inhomogeneity effects in magnetization transfer saturation and
    %     inhomogeneous magnetization transfer saturation maps. Magn Reson
    %     Med 86(4):2192-2207. doi:10.1002/mrm.28831
    %   In addition to citing the package:
    %     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
    %     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
    %     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
    properties (Hidden=true)
        onlineData_url = 'https://osf.io/3s9xe/download?version=2';
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
    
        fitValues_dual = load('fitValues_dualAlt.mat');
        fitValues_single = load('fitValues_single.mat');
        
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
            'Same Imaging Protocol',true,...
            'b1rms',6.8};

        options = struct();
    end
    
    methods
        % Constructor
        function obj = ihMT()
            obj.options = button2opts(obj.buttons);
            %obj = UpdateFields(obj);

            % Prot values at the time of the construction determine 
            % what is shown to user in CLI/GUI.
            obj = setUserProtUnits(obj);
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
                obj.options.Sequencesimulation_fitValuesDirectory = fileparts(which('fitValues_dual.mat'));
            end
            
            %Check if default simulations exist
            if ~isempty(obj.fitValues_dual) && ~isempty(obj.fitValues_single)
                %Check that structures fitValues dual- and single-sided off resonance RF prep pulses are not equal
                [~,d1,d2] = comp_struct(obj.fitValues_dual,obj.fitValues_single);
                if isempty(d1) && isempty(d2)
                    disp('fitValues for the dual- and single-sided off resonance RF prep pulses are equal')
                end
            else
                disp('Sequence simulation fitValues for the dual- and/or single-sided off-resonance RF prep pulses are missing')
            end
            
            %If there is a change in the simulation parameters, the default
            %fitValues are no longer valid
            SimProt = GetSimProt(obj);
            [~,d1,d2] = comp_struct(rmfield(obj.fitValues_dual.fitValues.Params,'freqPattern'),rmfield(SimProt,'freqPattern'));
            if ~isempty(d1) && ~isempty(d2)
                %Introduce a tolerance to compare Simulation Protocols
                diffTol_M0b = 1;
                diffTol_Raobs = 1;
                if isfield(d1,'M0b'); diffTol_M0b = abs(d1.M0b - d2.M0b) <= 1e-6; end
                if isfield(d1,'Raobs'); diffTol_Raobs = abs(d1.Raobs - d2.Raobs) <= 1e-6; end
                
                if ~all(diffTol_M0b) && ~all(diffTol_Raobs)
                     %Loading fitValues results from previous simulation
                     disp('Run a new sequence simulation or load <<fitValues.mat>> results from a previous simulation')
                     [FileName_dual,PathName_dual] = uigetfile('*.mat','Load fitValues structure - DUAL');
                     [FileName_single,PathName_single] = uigetfile('*.mat','Load fitValues structure - SINGLE');
                     
                     obj.fitValues_dual = load([PathName_dual filesep FileName_dual]);
                     obj.fitValues_single = load([PathName_single filesep FileName_single]);
                     
                     %Set filenames for fitValues corresponding to customized simulations                     
                     obj.options.Sequencesimulation_fitValuesDirectory = PathName_dual;
                     obj.options.Sequencesimulation_fitValuesName = FileName_dual;
                     obj.options.Sequencesimulation_fitValuesDirectory = PathName_single;
                     obj.options.Sequencesimulation_fitValuesName = FileName_single;
                end
            end
        end
        
        function FitResult = fit(obj,data)
            MTparams = obj.Prot.MTw_dual.Mat;
            PDparams = obj.Prot.PDw.Mat;
            T1params = obj.Prot.T1w.Mat;
            
            data_dual = rmfield(data,'MTw_single');
            data_dual.MTw = data_dual.MTw_dual;
            data_single = rmfield(data,'MTw_dual');
            data_single.MTw = data_single.MTw_single;
            
            fitValues_dual = obj.fitValues_dual;
            fitValues_single = obj.fitValues_single;

            %Correlate M0b_app VS R1
            if ~obj.options.CorrelateM0bappVSR1_SameImagingProtocol
                %Process MTsat dual
                [FitResult.M0b_app_dual,FitResult.fit_qual_d,FitResult.comb_res_d,fitValues_dual]=sampleCode_calc_M0bappVsR1_1dataset(data_dual,MTparams,PDparams,T1params,fitValues_dual,obj);
                obj.fitValues_dual = fitValues_dual;
                
                %Process MTsat single
                [FitResult.M0b_app_single,FitResult.fit_qual_s,FitResult.comb_res_s,fitValues_single]=sampleCode_calc_M0bappVsR1_1dataset(data_single,MTparams,PDparams,T1params,fitValues_single,obj);
                obj.fitValues_single = fitValues_single;
            end
            
            fitValues_dual = obj.fitValues_dual;
            fitValues_single = obj.fitValues_single;
            
            %Correct MTsat data
            %Process MTsat dual
            [MTsat_b1corr_dual, MTsatuncor_dual,R1_dual,R1uncor_dual] = sample_code_correct_MTsat(data_dual,MTparams,PDparams,T1params,fitValues_dual,obj);
            FitResult.MTSATcor_dual = MTsat_b1corr_dual;
            FitResult.MTSAT_dual = MTsatuncor_dual;
            FitResult.T1cor_dual = 1./R1_dual;
            FitResult.T1_dual = 1./R1uncor_dual;
            
            %Process MTsat single
            [MTsat_b1corr_single, MTsatuncor_single,R1_single,R1uncor_single] = sample_code_correct_MTsat(data_single,MTparams,PDparams,T1params,fitValues_single,obj);
            FitResult.MTSATcor_single = MTsat_b1corr_single;
            FitResult.MTSAT_single = MTsatuncor_single;
            FitResult.T1cor_single = 1./R1_single;
            FitResult.T1_single = 1./R1uncor_single;
            
            %ihMTsat map
            FitResult.ihMTsatcor = MTsat_b1corr_dual - MTsat_b1corr_single;
            FitResult.ihMTsat = MTsatuncor_dual - MTsatuncor_single;
        end
        
        function [SimProt, M0b, T1obs] = GetSimProt(obj)
            % Ensure ORIGINAL protocol units on load
            obj = setOriginalProtUnits(obj);

            SimProt.b1 = obj.options.Sequencesimulation_B1rms;
            SimProt.numSatPulse = obj.options.Sequencesimulation_Numbersaturationpulse;
            SimProt.pulseDur = obj.options.Sequencesimulation_Pulseduration/1000; %duration of 1 MT pulse in seconds
            SimProt.pulseGapDur = obj.options.Sequencesimulation_Pulsegapduration/1000; %gap between MT pulses in train in seconds
            SimProt.TR = obj.options.Sequencesimulation_TR/1000; % total repetition time = MT pulse train and readout in seconds
            SimProt.WExcDur = obj.options.Sequencesimulation_WExcDur/1000; % duration of water pulse in seconds
            SimProt.numExcitation = obj.options.Sequencesimulation_Numberexcitation; % number of readout lines/TR
            SimProt.freqPattern = obj.options.Sequencesimulation_Frequencypattern; % options: 'single', 'dualAlternate', 'dualContinuous'
            SimProt.delta = obj.options.Sequencesimulation_Delta;
            SimProt.flipAngle = obj.options.Sequencesimulation_FlipAngle; % excitation flip angle water
            SimProt.SatPulseShape = obj.options.Sequencesimulation_Saturationpulseshape; % options: 'hanning', 'gaussian', 'square'
            
            %% Average values for GM and WM from Sled and Pike (2001):
            
            SimProt.R = 26;
            SimProt.T2a = 70e-3;
            SimProt.T1D = 6e-3; % Varma 2017
            SimProt.lineshape = 'superLor'; % 'gaussian' or 'superLor';
            SimProt.M0a = 1;
            SimProt.Rb = 1;
            SimProt.T2b = 12e-6; 

            % Loop variables:
            M0b = 0:0.025:0.20;
            T1obs = horzcat(0.6:0.05:1.4,1.5:0.2:4.5); %600ms to 4500ms to cover WM to CSF. 
            SimProt.M0b =  M0b; % going to loop over this
            SimProt.Raobs = 1./T1obs;
            SimProt.Ra = [];

            % Ensure USER protocol units after process
            obj = setUserProtUnits(obj);
        end        
    end
    
    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            
            % v2.5.0 drop unit names from the Format 
            if checkanteriorver(version,[2 5 0])
                obj.Prot.MTw.Format = [{'FlipAngle'},{'TR'}];
                obj.Prot.PDw.Format = [{'FlipAngle'},{'TR'}];
                obj.Prot.T1w.Format = [{'FlipAngle'},{'TR'}];
                obj.OriginalProtEnabled = true;
                obj = setUserProtUnits(obj);
            end
        end
        
    end
    
end