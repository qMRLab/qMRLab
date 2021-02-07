classdef denoising_mppca < AbstractModel
% denoising_mppca :  4d image denoising and noise map estimation 
%                      by exploiting data redundancy in the PCA domain using universal
%                      properties of the eigenspectrum or random covariance matrices,
%                      i.e. Marchenko Pastur distribution
%
% Assumptions:
%   Noise follows a rician distribution
%   image bounderies are not processed
%
% Inputs:
%   Data4D              4D data (any modality)
%  (Mask)               Binary mask with region-of-interest. (OPTIONAL)
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
%     Karakuzu A., Boudreau M., Duval T.,Boshkovski T., Leppert I.R., Cabana J.F., 
%     Gagnon I., Beliveau P., Pike G.B., Cohen-Adad J., Stikov N. (2020), qMRLab: 
%     Quantitative MRI analysis, under one umbrella doi: 10.21105/joss.02343
    
    properties (Hidden=true)
        onlineData_url = 'https://osf.io/j5239/download?version=2';
    end

    properties
        MRIinputs = {'Data4D','Mask'};
        xnames = {};
        voxelwise = 0;
        
        % Protocol
        Prot  = struct(); % You can define a default protocol here.
        
        % Model options
        buttons = {'sampling',{'fast','full'},'kernel',[5 5 5]};
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
        
    methods(Access = protected)
        function obj = qMRpatch(obj,loadedStruct, version)
            obj = qMRpatch@AbstractModel(obj,loadedStruct, version);
            if checkanteriorver(version,[2 0 11])
                obj.buttons{2} = obj.buttons{2}([2 1]); % old: '|G| (T/m)', new Gnorm (T/m)
            end
        end
    end

end