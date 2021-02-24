classdef mp2rage < AbstractModel
% mp2rage: Compute a T1 map using MP2RAGE
%
% Assumptions:
% N/A
% Inputs:
%   (MP2RAGE)       MP2RAGE UNI image.
%   (B1map)         Normalized transmit excitation field map (B1+). B1+ is defined 
%                   as a  normalized multiplicative factor such that:
%                   FA_actual = B1+ * FA_nominal. (OPTIONAL).
%   (Mask)          Binary mask to a desired region (OPTIONAL).
%   (INV1mag)       Magnitude image from the first GRE readout (OPTIONAL).
%   (INV1phase)     Phase image from the first GRE readout (OPTIONAL).
%   (INV2mag)       Magnitude image from the second GRE readout (OPTIONAL).
%   (INV2phase)     Phase image from the second GRE readout (OPTIONAL).
%
% Outputs:
%   T1              Longitudinal relaxation time [s].
%                   Corrected for B1+ bias IF the B1map is provided.
%   R1              Longitudinal relaxation rate [1/s].
%                   Corrected for B1+ bias IF the B1map is provided.
%   MP2RAGE         Combined MP2RAGE image if INV1mag, INV1phase, INV2mag, INV2phase
%                   images were provided but MP2RAGE was not.
%   MP2RAGEcor      MP2RAGE image corrected for B1+ bias if B1map is provided.
%
% Options:
%   Inversion efficiency               Efficiency of the inversion pulse (fraction).
%
% Authors: Agah Karakuzu, Mathieu Boudreau 2019
%
% References:
%   Please cite the following if you use this module:
%    Marques, José P., et al. "MP2RAGE, a self bias-field corrected sequence for
%    improved segmentation and T1-mapping at high field." Neuroimage 49.2 (2010): 1271-1281.
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
    % See the constructor.
    onlineData_url;
end

properties
    MRIinputs = {'MP2RAGE','INV1mag','INV1phase','INV2mag','INV2phase','B1map' 'Mask'};
    xnames = {'T1','R1','MP2RAGE','MP2RAGEcor'};
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

methods

    function obj = mp2rage()
    
        obj.options = button2opts(obj.buttons);
        obj.onlineData_url = obj.getLink('https://osf.io/8x2c9/download?version=4','https://osf.io/k3shf/download?version=1','https://osf.io/k3shf/download?version=1');
    
    end

    function FitResult = fit(obj,data)

        % All fields are optional, possible cases must be handled properly.  
        availabledata = struct();

        noUNI = false;
        noINV1mag = false; 
        noINV1phase = false; 
        noINV2mag = false;
        noINV2phase = false;
        availabledata.onlyUNI = false;
        availabledata.allbutUNI = false;
        availabledata.all = false;

        if ~isfield(data,'INV1mag'), data.INV1mag = []; end
        if ~isfield(data,'INV1phase'), data.INV1phase = []; end
        if ~isfield(data,'INV2mag'), data.INV2mag = []; end
        if ~isfield(data,'INV2phase'), data.INV2phase = []; end 
        if ~isfield(data,'MP2RAGE'), data.MP2RAGE = []; end 
        if ~isfield(data,'B1map'), data.B1map = []; end 
        if ~isfield(data,'Mask'), data.Mask = []; end 
        
        if isempty(data.MP2RAGE), noUNI = true; end     
        if isempty(data.INV1mag), noINV1mag = true;  end 
        if isempty(data.INV1phase), noINV1phase = true;  end 
        if isempty(data.INV2mag), noINV2mag = true; end 
        if isempty(data.INV2phase), noINV2phase = true; end 

        if noINV1mag && noINV1phase && noINV2mag && noINV2phase && ~noUNI

            availabledata.onlyUNI = true;

        elseif ~noINV1mag && ~noINV1phase && ~noINV2mag && ~noINV2phase && noUNI
                
            availabledata.allbutUNI = true;

        elseif ~noINV1mag && ~noINV1phase && ~noINV2mag && ~noINV2phase && ~noUNI
            
            availabledata.all = true;

            warning(sprintf(['=============== qMRLab::Fit ======================\n' ...
            'MP2RAGE data is available. Data from the following fields will not be used for T1 mapping:\n' ...
            '- Inv1mag \n -INV1phase \n -INV2mag \n -INV2phase' ...
            'If you would like to use the data listed above for fitting, please leave MP2RAGE directory empty.']));    

        else     

            error(sprintf(['=============== qMRLab::Fit ======================\n' ...
            'Required data is not provided to perform T1 fitting.']));
        end

        % LOAD PROTOCOLS =========================================

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

            % Convert naming to the MP2RAGE source code conventions
            MP2RAGE.B0 = MagneticFieldStrength;           % in Tesla
            MP2RAGE.TR = RepetitionTimeInversion;           % MP2RAGE TR in seconds
            MP2RAGE.TRFLASH = RepetitionTimeExcitation; % TR of the GRE readout
            MP2RAGE.TIs = InversionTime; % inversion times - time between middle of refocusing pulse and excitatoin of the k-space center encoding
            MP2RAGE.NZslices = NumberShots; % Excitations [before, after] the k-space center
            MP2RAGE.FlipDegrees = FlipAngle; % Flip angle of the two readouts in degrees

            % If both NumberShots are equal, then assume half/half for before/after
        if NumberShots(1) == NumberShots(2)

            MP2RAGE.NZslices = [ceil(NumberShots(1)/2) floor(NumberShots(1)/2)]; 

        end 

        % LOAD OPTIONS ========================================= 

        invEFF = obj.options.Invefficiency;

        % LOAD DATA  ==========================================

       if availabledata.allbutUNI
        % If phase data is present, normalize it in 0-2pi range 

        data.INV1phase = ((data.INV1phase - min(data.INV1phase(:)))./(max(data.INV1phase(:)-min(data.INV1phase(:))))).*2.*pi;
        data.INV2phase = ((data.INV2phase - min(data.INV2phase(:)))./(max(data.INV2phase(:)-min(data.INV2phase(:))))).*2.*pi;
       
       end 

        if availabledata.onlyUNI || availabledata.all
            
            MP2RAGEimg.img = data.MP2RAGE;

        elseif availabledata.allbutUNI

            INV1 = data.INV1mag.*exp(data.INV1phase * 1j);
            INV2 = data.INV2mag.*exp(data.INV2phase * 1j);
    
            % Combination
            img = (real(INV1.*INV2./(INV1.^2 + INV2.^2)))*4095 + 2048; 
            img(img<0) = 0;
            img(img>4095) = 4095;
            FitResult.MP2RAGE = img;
            MP2RAGEimg.img = img;

            clear('INV1','INV2','img'); 
            
        end
        
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
        
    end % FIT RESULTS END 
end % METHODS END 

end % CLASSDEF END 