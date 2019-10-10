classdef mp2rage < AbstractModel
% mp2rage: Compute a T1 map using MP2RAGE
%
% Assumptions:
%
% Inputs:
%   (MP2RAGE)         MP2RAGE UNI image.
%   (B1map)         Excitation (B1+) fieldmap. Used to correct flip angles. (optional)
%   (Mask)          Binary mask to a desired region (optional).
%   (INV1mag)       
%   (INV1phase)     
%   (INV2mag)       
%   (INV2phase)
% Outputs:
%   T1              Longitudinal relaxation time [s].
%                   Corrected for B1+ bias IF the B1map is provided.
%   R1              Longitudinal relaxation rate [1/s]
%                   Corrected for B1+ bias IF the B1map is provided.
%   MP2RAGEcor      MP2RAGE image corrected for B1+ bias if B1map is provided.  
  

properties (Hidden=true)
 onlineData_url = 'https://osf.io/8x2c9/download?version=2';
end

    properties
        MRIinputs = {'MP2RAGE','INV1mag','INV1phase','INV1mag','INV1phase','B1map' 'Mask'};
        xnames = {'T1','R1'};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct('Hardware',struct('Format',{{'B0 (T)'}},...
        'Mat', [7]),...
        'RepetitionTimes',struct('Format',{{'Inv (s)';'Exc (s)'}},'Mat',[6;6.7e-3]), ...
        'Timing',struct('Format',{{'InversionTimes (s)'}},'Mat',[800e-3;2700e-3]), ...
        'Sequence',struct('Format',{{'FlipAngles'}},'Mat',[4; 5]),...
        'NumberOfShots',struct('Format',{{'Pre';'Post'}},'Mat',[35; 72]));

        ProtStyle = struct('prot_namespace',{{'Hardware', 'RepetitionTimes','Timing','Sequence','NumberOfShots'}}, ...
        'style',repmat({'TableNoButton'},[1,5]));

        % Please see wiki page for details regarding tabletip
        % https://github.com/qMRLab/qMRLab/wiki/Guideline:-GUI#the-optionsgui-is-populated-by

        tabletip = struct('table_name',{{'Hardware','RepetitionTimes','Timing','Sequence','NumberOfShots'}},'tip', ...
        {sprintf(['B0 (T): Static magnetic field strength (Tesla)']),...
        sprintf(['[Inv (s)]: Repetition time between two INVERSION pulses of the MP2RAGE pulse sequence (seconds)\n -- \n [Exc (s)]: Repetition time between two EXCITATION pulses of the MP2RAGE pulse sequence (seconds)']),...
        sprintf(['InversionTimes (s): Inversion times for the measurements (seconds)\n [1] 1st time dimension \n [2] 2nd time dimension']),...
        sprintf(['FlipAngles: Excitation flip angles (degrees)\n [1] 1st time dimension \n [2] 2nd time dimension']),...
        sprintf(['NumberOfShots: Number of shots [Pre] before and [Post] after the k-space center'])
        });


        % Model options
        buttons = {'Inv efficiency', 0.96};
               
        % Tiptool descriptions
        tips = {'Inv efficiency', 'Efficiency of the inversion pulse (fraction).'};
    
        options= struct(); % structure filled by the buttons. Leave empty in the code
    end

methods (Hidden=true)
% Hidden methods goes here.
end

    methods

        function obj = mp2rage()
            obj.options = button2opts(obj.buttons);
        end

       function  obj = CalcUNI(obj,data)

        % IMPLEMENT HERE

       end

       function FitResult = fit(obj,data)

        if ~isfield(data, 'B1map'), data.B1map = []; end
        if ~isfield(data, 'Mask'), data.Mask = []; end

        % Hardware
        MagneticFieldStrength = obj.Prot.Hardware.Mat;
        
        % RepetitionTime
        RepetitionTimeInversion = obj.Prot.RepetitionTimes.Mat(1);
        RepetitionTimeExcitation = obj.Prot.RepetitionTimes.Mat(2);
        
        % Timing
        InversionTime = obj.Prot.Timing.Mat';
        
        % Sequence   
        FlipAngle = obj.Prot.Sequence.Mat';
        
        % KSpace
        NumberShots = obj.Prot.NumberOfShots.Mat';
        
        invEFF = obj.options.Invefficiency;

        % Convert naming to the MP2RAGE source code conventions
        MP2RAGE.B0 = MagneticFieldStrength;           % in Tesla
        MP2RAGE.TR = RepetitionTimeInversion;           % MP2RAGE TR in seconds
        MP2RAGE.TRFLASH = RepetitionTimeExcitation; % TR of the GRE readout
        MP2RAGE.TIs = InversionTime; % inversion times - time between middle of refocusing pulse and excitatoin of the k-space center encoding
        MP2RAGE.NZslices = NumberShots; % Excitations [before, after] the k-space center
        MP2RAGE.FlipDegrees = FlipAngle; % Flip angle of the two readouts in degrees

        MP2RAGEimg.img = data.MP2RAGE;


        if ~isempty(data.B1map)

            [T1corrected, MP2RAGEcorr] = T1B1correctpackageTFL(data.B1map,MP2RAGEimg,[],MP2RAGE,[],invEFF);
            
            FitResult.T1 = T1corrected.img;
            FitResult.R1=1./FitResult.T1;
            FitResult.R1(isnan(FitResult.R1))=0;
            FitResult.MP2RAGEcor = MP2RAGEcorr.img;

        else

            [T1map, R1map]=T1estimateMP2RAGE(MP2RAGEimg,MP2RAGE,invEFF);
        
            FitResult.T1 = T1map.img;
            FitResult.R1 = R1map.img;
            
        end

        if ~isempty(data.Mask)
            data.Mask = logical(data.Mask); % ensure 
            FitResult.T1(~data.Mask) = 0;
            FitResult.R1(~data.Mask) = 0;

            if isfield(FitResult,'MP2RAGEcor')
                FitResult.MP2RAGEcor(~data.Mask) = 0;
            end
        end
        
    end


    end
    
end
