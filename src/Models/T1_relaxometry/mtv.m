classdef mtv < AbstractModel
% mtv :  Macromolecular Tissue Volume in brain
% 
% ASSUMPTIONS: 
% (1) Organ: brain (MTV needs to be adapted for other organs)
% (2) Reception profile (B1-) is estimated through a spline approximation.
%     Contrary to the original paper (see citation), multi-coil data are
%     not necessary. Although simpler, more validation is needed.
%     For multi-coil datasets, please use mrQ (https://github.com/mezera/mrQ/)
% (3) 
% (4) 
%
% Inputs:
%   T1           T1 map from Spoiled Gradient Echo data (use vfa_t1 module)
%   M0           M0 from Spoiled Gradient Echo data (use vfa_t1 module)
%   Mask         Mask of the entire brain (REQUIRED). This mask is eroded for 
%                border effects and clustured into white matter (WM) and 
%                CerebroSpinal Fluid Mask (CSF). 
%                In the WM mask, coil sensitivity is computed assuming:
%                M0 = g * PD = g * 1 / (A + B/T1) with A~0.916 & B~0.436 
%                The CSF mask is used for proton density normalization 
%                (assuming ProtonDensity_CSF = 1)
%
% Outputs:
%	MTV                 Macromolecular Tissue Volume (normal values in the brain range [0 0.4])
%	CoilGain            Reception profile of the antenna (B1- map).
%                        relative (pixel-wise) normalization of M0
%   CSF                 CSF mask (cleaned).
%                        absolute (global) normalization of M0
%   seg                 Clustering of the eroded input mask in four categories:
%                        1: Gray Matter
%                        2: Deep Gray
%                        3: White matter (used for Coil Gain)
%                        4: CSF
%
% Protocol:
%   none
%
% Options:
%   Voxel Size          [1x3] Size of the voxels (in mm)
%   Spline Smoothness   Smoothness parameter for the coil gain. The larger S 
%                       is, the smoother the coil gain map will be.
%   CSF T1 threshold    Threshold on T1 for the CSF mask (in s).
%
% Example of command line usage:
%   For more examples: <a href="matlab: qMRusage(mtv);">qMRusage(mtv)</a>
%
% Author: Tanguy Duval, 2020
%
% References:
%   Please cite the following if you use this module:
%     Mezer A, Yeatman JD, Stikov N, Kay KN, Cho NJ, Dougherty RF, Perry ML, Parvizi J, Hua le H, Butts-Pauly K, Wandell BA. Quantifying the local tissue volume and composition in individual brains with magnetic resonance imaging. Nat Med. 2013
%   In addition to citing the package:
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343

properties (Hidden=true)
% Hidden properties goes here. 
onlineData_url = 'https://osf.io/rsh9e/download?version=5';
end

    properties
        MRIinputs = {'T1','M0','Mask'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct(); % You can define a default protocol here.

        % Model options
        buttons = {'Voxel Size',[1 1 1],'Spline Smoothness',100, 'CSF T1 threshold',1/0.35};
        options = struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
methods (Hidden=true)
% Hidden methods goes here.    
end
    
    methods
        
        function obj = mtv
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
        end
        
        function FitResult = fit(obj,data)        
            FitResult = struct('MTV',[],'CoilGain',[],'CSF',[],'seg',[]);
            % Erode Mask to prevent border effects
            se = strel('cube',3);
            Maskero = imerode(data.Mask,se);
            for ii=1:5, Maskero = imerode(Maskero,se); end
            
            % get mask
            [FitResult.CSF, FitResult.seg] = mtv_mrQ_Seg_kmeans_simple(data.T1,Maskero,data.M0,obj.options.VoxelSize,1/obj.options.CSFT1threshold);
            WM = FitResult.seg==3;
            %%relative PD:
            FitResult.CoilGain = mtv_correct_receive_profile_v2( data.M0, data.T1, WM, obj.options.SplineSmoothness,obj.options.VoxelSize);
            PD = data.M0./FitResult.CoilGain;
            
            %% absolute PD:
            % calcute the CSF PD
            FitResult.CSF(isnan(FitResult.CSF))=0;
            
            % find the white matter mean pd value from segmentation.
            wmV=mean(PD(WM & PD>0));
            
            % assure that the CSF ROI have pd value that are resnable.  The csf roi is a reslut of segmentation algoritim runed on the
            % T1wighted image and cross section with T1 values. Yet  the ROI may have some contaminations or segmentation faules .
            %Therefore, we create some low and up bonderies. No CSF with PD values that are the white matter PD value(too low) or double the white matter values (too high).
            CSF1=FitResult.CSF & PD>wmV & PD< wmV*2;
            
            %To calibrate the PD we find the scaler that shift the csf ROI to be eqal to 1. --> PD(CSF)=1;
            % To find the scale we look at the histogram of PD value in the CSF. Since it's not trivial to find the peak we compute the kernel density (or
            % distribution estimates). for detail see ksdensity.m
            %The Calibrain vhistogram of the PD values in the let find the scalre from the maxsimum of the csf values histogram
            [csfValues, csfDensity]= ksdensity(PD(CSF1), [min(PD(CSF1)):0.001:max(PD(CSF1))] );
            CalibrationVal= csfDensity(csfValues==max(csfValues));% median(PD(find(CSF)));
            
            % calibrate the pd by the pd of the csf roi
            PD=PD./CalibrationVal(1);
            
            %% MTV
            FitResult.MTV = 1 - PD;          
        end
        
        
    end
end
