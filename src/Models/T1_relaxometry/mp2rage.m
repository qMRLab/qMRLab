classdef mp2rage < AbstractModel
% mp2rage: Compute a T1 map using MP2RAGE
%
% Assumptions:
%
% Inputs:
%   MP2RAGE         MP2RAGE UNI image. 
%   (INV1)          Magnitude image of the first inversion pulse (optional).
%   (INV2)          Magnitude image of the second inversion pulse (opitonal).
%   (B1map)         Excitation (B1+) fieldmap. Used to correct flip angles. (optional)
%   (Mask)          Binary mask to a desired region (optional).
%
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
        MRIinputs = {'MP2RAGE','INV1','INV2','B1map' 'Mask'};
        xnames = {'T1','R1'};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct('Hardware',struct('Format',{{'B0 (T)'}},...
        'Mat', [7]),...
        'ConstantTiming',struct('Format',{{'InversionTR (s)' 'ExcitationTR (s)'}},'Mat',[6 6.7e-3]), ...
        'VaryingTiming',struct('Format',{{'InversionTimes (s)'}},'Mat',[800e-3;2700e-3;]), ...
        'VaryingOther',struct('Format',{{'FlipAngles' 'NumberOfShots'}},'Mat',[4 35; 5 72]));

        % Please see wiki page for details regarding tabletip
        % https://github.com/qMRLab/qMRLab/wiki/Guideline:-GUI#the-optionsgui-is-populated-by

        tabletip = struct('table_name',{{'Hardware','ConstantTiming','VaryingTiming','VaryingOther'}},'tip', ...
        {sprintf(['B0 (T): Static magnetic field strength (Tesla)']),...
        sprintf(['Inversion TR (s): Repetition time between two inversion pulses of the MP2RAGE pulse sequence (seconds)\n -- \n Excitation TR (s): Repetition time between two excitation pulses of the MP2RAGE pulse sequence (seconds)']),...
        sprintf(['InversionTimes (s): Inversion times for the measurements (seconds)\n 1st input = 1st time dimension \n 2nd input = 2nd time dimension']),...
        sprintf(['Flip Angles: Excitation flip angles (degrees)\n1st input = 1st time dimension, 2nd input = 2nd time dimension \n -- \n NumberOfShots: Number of shots [before, after] the k-space center'])
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

        function Smodel = equation(obj,x)
            % Generates a VFA signal based on input parameters
            x = mat2struct(x,obj.xnames); % if x is a structure, convert to vector

            % Equation: S=M0sin(a)*(1-E)/(1-E)cos(a); E=exp(-TR/T1)
            flipAngles = (obj.Prot.VFAData.Mat(:,1))';
            TR = obj.Prot.VFAData.Mat(1,2);
            E = exp(-TR/x.T1);
            Smodel = x.M0*sin(flipAngles/180*pi)*(1-E)./(1-E*cos(flipAngles/180*pi));
        end

       function FitResult = fit(obj,data)

        if ~isfield(data, 'B1map'), data.B1map = []; end
        if ~isfield(data, 'Mask'), data.Mask = []; end

        % Hardware
        MagneticFieldStrength = obj.Prot.Hardware.Mat;
        
        % ConstantTiming
        RepetitionTimeInversion = obj.Prot.ConstantTiming.Mat(1);
        RepetitionTimeExcitation = obj.Prot.ConstantTiming.Mat(2);
        
        % VaryingTiming
        InversionTime = obj.Prot.VaryingTiming.Mat';
        
        %VaryingOther    
        FlipAngle = obj.Prot.VaryingOther.Mat(:,1)';
        NumberShots = obj.Prot.VaryingOther.Mat(:,2);
        
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
