classdef mt_sat < AbstractModel
% mt_sat :  Correction of Magnetization transfer for RF inhomogeneities and T1
%
% Assumptions:
%   MTsat is a semi-quantitative method. MTsat values depend on protocol parameters.
%
% Inputs:
%   MTw     3D MT-weighted data. Spoiled Gradient Echo (or FLASH) with MT
%            pulse
%   T1w     3D T1-weighted data. Spoiled Gradient Echo (or FLASH)
%   PDw     3D PD-weighted data. Spoiled Gradient Echo (or FLASH)
%   (B1map)         Normalized transmit excitation field map (B1+). B1+ is defined 
%                   as a  normalized multiplicative factor such that:
%                   FA_actual = B1+ * FA_nominal. (OPTIONAL).
%  (Mask)   Binary mask. DOES NOT ACCELERATE FITTING. Just for visualisation. (OPTIONAL)
%
% Outputs:
%	  MTSAT         MT saturation map (%), T1-corrected
%     T1            T1 map (s)
%     MTR           Export MTR when the TRs of MTw and PDw match
%
% Options:
%     B1 correction factor     Correction factor (empirical) for the transmit RF. Only
%                              corrects MTSAT, not T1. From Helms 2015 (below), the default value (0.4)
%                              was empirically determined for a Gaussian 4ms MT-pulse at 2kHz offset and 220 deg nominal flip angle.
%                              Weiskopf, N., Suckling, J., Williams, G., CorreiaM.M., Inkster, B., Tait, R., Ooi, C., Bullmore, E.T., Lutti, A., 2013. Quantitative multi-parameter mapping of R1, PD(*), MT, and R2(*) at 3T: a multi-center validation. Front. Neurosci. 7, 95.
%                              Helms, G., Correction for residual effects of B1+ inhomogeniety on MT saturation in FLASH-based multi-parameter mapping of the brain. Proceedings of the 23rd Annual Meeting of ISMRM 2015, 3360.
%
% Protocol:
%     MTw    [FA  TR  Offset]  flip angle [deg], TR [s], Offset Frequency [Hz]
%     T1w    [FA  TR]          flip angle [deg], TR [s]
%     PDw    [FA  TR]          flip angle [deg], TR [s]
%
% Example of command line usage:
%   Model = mt_sat;  % Create class from model
%   Model.Prot.MTw.Mat = txt2mat('MT.txt');  % Load protocol
%   Model.Prot.T1w.Mat = txt2mat('T1.txt');
%   Model.Prot.PDw.Mat = txt2mat('PD.txt');
%   data = struct;  % Create data structure
%   data.MTw = load_nii_data('MTw.nii.gz');
%   data.T1w = load_nii_data('T1w.nii.gz');
%   data.PDw = load_nii_data('PDw.nii.gz');  % Load data
%   FitResults = FitData(data,Model); %fit data
%   FitResultsSave_nii(FitResults,'MTw.nii.gz'); % Save in local folder: FitResults/
%
%   For more examples: <a href="matlab: qMRusage(mt_sat);">qMRusage(mt_sat)</a>
%
% Author: Pascale Beliveau (pascale.beliveau@polymtl.ca)
%
% References:
%   Please cite the following if you use this module:
%     Helms, G., Dathe, H., Kallenberg, K., Dechent, P., 2008. High-resolution maps of magnetization transfer with inherent correction for RF inhomogeneity and T1 relaxation obtained from 3D FLASH MRI. Magn. Reson. Med. 60, 1396?1407.
%     Helms, G., Correction for residual effects of B1+ inhomogeniety on MT saturation in FLASH-based multi-parameter mapping of the brain. Proceedings of the 23rd Annual Meeting of ISMRM 2015, 3360.
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

    properties (Hidden=true)
        onlineData_url = 'https://osf.io/c5wdb/download?version=4';
    end

    properties
        MRIinputs = {'MTw','T1w', 'PDw', 'B1map', 'Mask'};
        xnames = {};
        voxelwise = 0;

        % Protocol
        Prot = struct('MTw',struct('Format',{{'FlipAngle' 'TR (s)'}},...
                                   'Mat',  [6 0.028]),...
                      'T1w',struct('Format',{{'FlipAngle' 'TR'}},...
                                   'Mat',  [20 0.018]),...
                      'PDw',struct('Format',{{'FlipAngle' 'TR'}},...
                                   'Mat',  [6 0.028]));
        % Model options
        
        ProtStyle = struct('prot_namespace',{{'MTw', 'T1w','PDw'}}, ...
        'style',repmat({'TableNoButton'},[1,3]));

        buttons = {'B1 correction factor', 0.4, 'PANEL','Export MTR',1, 'Enabled',true};
        options= struct();

    end

    methods
        function obj = mt_sat
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
            % Disable Export MTR panel when TRs don't match
            if obj.Prot.MTw.Mat(2) ~= obj.Prot.PDw.Mat(2)
                obj = setPanelInvisible(obj,'Export MTR', 1);
            else
                obj = setPanelInvisible(obj,'Export MTR', 0);
            %    obj.buttons{strcmp(obj.buttons,'Export MTR') | strcmp(obj.buttons,'###Export MTR')} = 'Export MTR';
            end
        end

        function FitResult = fit(obj,data)
            MTparams = obj.Prot.MTw.Mat;

            PDparams = obj.Prot.PDw.Mat;

            T1params = obj.Prot.T1w.Mat;

            B1params = obj.options.B1correctionfactor;

            [FitResult.MTSAT, R1] = MTSAT_exec(data, MTparams, PDparams, T1params, B1params);
            FitResult.T1 = 1./R1;
            
            if (MTparams(2) == PDparams(2) && (obj.options.ExportMTR_Enabled == true))
                FitResult.MTR = 100 * (data.PDw - data.MTw)./data.PDw;
                
                FitResult.MTR(isnan(FitResult.MTR)) = 0;
                FitResult.MTR(isinf(FitResult.MTR)) = 0;
                
                if isfield(data,'Mask') && not(isempty(data.Mask))
                    data.Mask(isnan(data.Mask)) = 0;
                    data.Mask = logical(data.Mask);
                    FitResult.MTR = FitResult.MTR.*data.Mask;
                end
            end
        end

    end

    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            % 2.0.6
            if checkanteriorver(version,[2 0 6])
                % add B1factor
                obj.buttons = {'B1 correction factor', [0.4000], 'PANEL','Export MTR',1, 'Enabled',true};
                obj.options.B1correctionfactor=0.04;
                obj.options.ExportMTR_Enabled = true;
            end

            % 2.0.7 --> rename MT PD T1 (to MTw PDw T1w)
            if checkanteriorver(version,[2 0 7])
                obj.MRIinputs = {'MTw'    'T1w'    'PDw'    'B1map'    'Mask'}; % add B1map
                obj.Prot.MTw = obj.Prot.MT; obj.Prot = rmfield(obj.Prot,'MT');
                obj.Prot.T1w = obj.Prot.T1; obj.Prot = rmfield(obj.Prot,'T1');
                obj.Prot.PDw = obj.Prot.PD; obj.Prot = rmfield(obj.Prot,'PD');

                if size(obj.Prot.MTw.Format,2)>2
                    obj.Prot.MTw.Format(3) = []; % remove offset
                    obj.Prot.MTw.Mat(:,3)  = [];
                end
            end

            % 2.3.1 --> Remove buttons from prot
            if checkanteriorver(version,[2 3 1])
                obj.ProtStyle = struct('prot_namespace',{{'MTw', 'T1w','PDw'}}, ...
                'style',repmat({'TableNoButton'},[1,3]));
            end
            
            % 2.5.0 --> Export MTR
            if checkanteriorver(version,[2 5 0])
                obj.buttons = {'B1 correction factor', [0.4000], 'PANEL','Export MTR',1, 'Enabled',true};
                obj.options.B1correctionfactor=0.04;
                obj.options.ExportMTR_Enabled = true;
            end

        end
    end

end
