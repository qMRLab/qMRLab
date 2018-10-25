classdef denoising_mppca < AbstractModel
% denoising_mppca :  4d image denoising and noise map estimation by exploiting
%                      data redundancy in the PCA domain using universal properties 
%                      of the eigenspectrum of random covariance matrices, 
%                      i.e. Marchenko Pastur distribution
%
% Assumptions:
%   Noise follows a rician distribution
%   image bounderies are not processed
%
% Inputs:
%   Data4D              4D data (any modality)
%  (Mask)                Binary mask with region-of-interest
%
% Outputs:
%   Data4D_denoised     denoised 4D data
%   sigma_g               standard deviation of the rician noise
%
% Options:
%	sampling
%   	'full'          sliding window
%       'fast'          block processing (warning: undersampled noise map will be returned)
%   kernel              window size, typically in order of [5 x 5 x 5]
%
% Example of command line usage:
%   Model = denoising_mppca;  % Create class from model
%   data.Data4D = load_nii_data('Data4D.nii.gz');  % Load data
%   FitResults = FitData(data,Model,1);  % Fit each voxel within mask
%   FitResultsSave_nii(FitResults,'Data4D.nii.gz');  % Save in local folder: FitResults/
%
% Author: Tanguy Duval, 2016
%
% References:
%   Please cite the following if you use this module:
%     Veraart, J.; Fieremans, E. & Novikov, D.S. Diffusion MRI noise mapping using random matrix theory Magn. Res. Med., 2016, early view, doi:10.1002/mrm.26059
%   In addition to citing the package:
%     Cabana J-F, Gu Y, Boudreau M, Levesque IR, Atchia Y, Sled JG, Narayanan S, Arnold DL, Pike GB, Cohen-Adad J, Duval T, Vuong M-T and Stikov N. (2016), Quantitative magnetization transfer imaging made easy with qMTLab: Software for data simulation, analysis, and visualization. Concepts Magn. Reson.. doi: 10.1002/cmr.a.21357
    
    properties (Hidden=true)
        onlineData_url = 'https://osf.io/ve3xy/download/';
    end

    properties
        MRIinputs = {'Data4D','Mask'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct(); % You can define a default protocol here.
        
        % Model options
        buttons = {'sampling',{'full','fast'},'kernel',[5 5 5]};
        options= struct(); % structure filled by the buttons. Leave empty in the code
        
    end
    
    methods
        
        function obj = denoising_mppca
            obj.options = button2opts(obj.buttons);
            obj = UpdateFields(obj);
        end
        
        function obj = UpdateFields(obj)
        end
        
        function FitResults = fit(obj,data)
            dims=size(data.Data4D);
            kernel = min(dims(1:3),obj.options.kernel);
            [V,Ind] = min(dims(1:3));
            if ~isfield(data,'Mask'), data.Mask = []; end
            if V<7 && kernel(Ind)>1, helpdlg(['your dataset has very few slices. To avoid loosing too many slices, kernel is set to 1 in the dimension #' num2str(Ind) '.']); kernel(Ind)=1; end
            [FitResults.Data4D_denoised, FitResults.sigma_g] = MPdenoising(data.Data4D,data.Mask,kernel, obj.options.sampling);
        end
        
    end
end