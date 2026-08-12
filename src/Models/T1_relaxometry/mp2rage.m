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
    xnames = {'T1'};
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

    % fitting options
    st = [1.5];  % starting point
    lb = [0.1];  % lower bound
    ub = [5.0];  % upper bound
    fx = [0];  % fix parameters

    % Simulation Options
    Sim_Single_Voxel_Curve_buttons = {'SNR', 50, 'T1', 1.5, 'Update input variables','pushbutton'};
end

methods (Static)
    function img = signal2img(INV1, INV2)
        img = real(INV1 .* INV2 ./ (INV1.^2 + INV2.^2)) * 4095 + 2048;
        img(img < 0) = 0;
        img(img > 4095) = 4095;
    end
end

methods

    function obj = mp2rage()
    
        obj.options = button2opts(obj.buttons);
        obj.onlineData_url = obj.getLink('https://osf.io/8x2c9/download?version=4','https://osf.io/k3shf/download?version=1','https://osf.io/k3shf/download?version=1');
    end

    function xnew = SimOpt(obj, x, Opt)
        xnew = [Opt.T1];
    end

    function MP2RAGE = Protocol2Params(obj)
    % Convert protocol to the MP2RAGE source code conventions

        % MP2RAGE.B0 = obj.Prot.Hardware.Mat;  % in Tesla

        % RepetitionTime
        MP2RAGE.TR = obj.Prot.RepetitionTimes.Mat(1);      % MP2RAGE TR in seconds
        MP2RAGE.TRFLASH = obj.Prot.RepetitionTimes.Mat(2); % TR of the GRE readout

        % inversion times - time between middle of refocusing pulse and excitatoin of the k-space center encoding
        MP2RAGE.TIs = obj.Prot.Timing.Mat';

        % KSpace
        NumberShots = obj.Prot.NumberOfShots.Mat';
        MP2RAGE.NZslices = NumberShots; % Excitations [before, after] the k-space center

        % Flip angle of the two readouts in degrees
        MP2RAGE.FlipDegrees = obj.Prot.Sequence.Mat';

        % If both NumberShots are equal, then assume half/half for before/after
        if NumberShots(1) == NumberShots(2)
            MP2RAGE.NZslices = [ceil(NumberShots(1)/2) floor(NumberShots(1)/2)];
        end
    end

    function Smodel = equation(obj, x)
    % Generates an MP2RAGE signal based on protocol and fit parameters
        x = mat2struct(x, obj.xnames);

        P = obj.Protocol2Params();
        invEFF = obj.options.Invefficiency;

        Smodel = MP2RAGEfunc(P.TR, P.TIs, P.NZslices, P.TRFLASH, P.FlipDegrees, x.T1, invEFF);
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
        availabledata.allMagbutUNI=false;
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

        elseif ~noINV1mag && noINV1phase ~noINV2mag && noINV2phase && noUNI
                
            availabledata.allMagbutUNI = true;

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

        MP2RAGE = obj.Protocol2Params();

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

        else
            if availabledata.allbutUNI
                INV1 = data.INV1mag.*exp(data.INV1phase * 1j);
                INV2 = data.INV2mag.*exp(data.INV2phase * 1j);

            elseif availabledata.allMagbutUNI
                INV1 = data.INV1mag;
                INV2 = data.INV2mag;
            end

            % Combination
            MP2RAGEimg.img = mp2rage.signal2img(INV1, INV2);
            FitResult.MP2RAGE = MP2RAGEimg.img;
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

    function [FitResults, data] = Sim_Single_Voxel_Curve(obj, x, Opt, display)
        % Simulates Single Voxel
        %
        % :param x: [struct] fit parameters
        % :param Opt.SNR: [struct] signal to noise ratio to use
        % :param display: 1=display, 0=nodisplay
        % :returns: [struct] FitResults, data (noisy dataset)

            if ~exist('display','var'), display = 0; end

            Smodel = equation(obj, x);

            % TODO: confirm noise distribution
            sigma = max(abs(Smodel(:)))/Opt.SNR;
            S = random('normal', Smodel, sigma);

            data.MP2RAGE = mp2rage.signal2img(S(:, 1), S(:, 2));

            FitResults = fit(obj,data);

            if display
                error('Not Implemented')
            end
        end

        function SimVaryResults = Sim_Sensitivity_Analysis(obj, OptTable, Opt)
            % SimVaryGUI
            SimVaryResults = SimVary(obj, Opt.Nofrun, OptTable, Opt);
        end

        function SimRndResults = Sim_Multi_Voxel_Distribution(obj, RndParam, Opt)
            % SimRndGUI
            SimRndResults = SimRnd(obj, RndParam, Opt);
        end

end % METHODS END 

end % CLASSDEF END 
