function multi_comp_fit(data_file_name, relaxation_type, varargin)

% *************************************************************************
% multi_comp_fit(data_file_name, relaxation_type, ...
%               ['ROI', roi_file_name, 'tissue', cls_file_name])
%
% DESCRIPTION: A script to compute the multi-component T2 or T2* spectrum for an
% echo train data set using regularized (and unregulatrized) NNLS. 
%
% If an ROI mask if given, the user will be prompted to proceed with a
% voxel-wise or ROI analysis. 
%   voxel-wise analysis: The script will output superimposed plots of the T2/T2*
%                        spectrum for each voxel, and calculate the average 
%                        MWF and gmT2/T2* for the ROI.
%   ROI analysis: The script will output plots of the average T2/T2* spectrum and 
%                 the average raw data + fits for that ROI. 
%
% If no mask is given then the script will output maps of the geometric 
% mean T2/T2* (<T2/T2*>), the myelin water fraction (MWF) and the mono 
% exponential T2/T2*. 
%
% If a tissue classification mask is given (cls_file_name), the user will 
% be prompted as to which tissue he/she wishes to analyze, and the maps 
% will be created for that tissue only.
%
% INPUTS:
% data_file_name = echo train data set to be analyzed
% relaxation_type = 'T2' or 'T2star'
% 'ROI' = ROI processing flag
% roi_file_name = ROI mask
% 'tissue' = tissue processing flag
% cls_file_name = tissue classification mask (1->CSF, 2->GM, 3->WM)
%                 Can be used to limit processing time
% varargin = optional file limiting the number of echoes to be used for
%            analysis. This can be 
%            1. max_echoes.mnc file obtained from'in_plane_correction.m' 
%               to perform in-plane field inhomogeneity correction
%            2. correction_mask.mnc, obtained from 'Gz_correction.m'.
%               This binary file has voxels where the field gradient (Gz) 
%               was > 2mG/cm set to 0 (no field inhomog. correction performed*), 
%               and areas where Gz was < 2mG/cm set to 1. 
%               *The correction fails where Gz > 2mG/cm. In order to limit 
%                effect of field inhomogeneities in these voxels,
%                processing is limited to 45 echoes, instead of 64. 
%F
% EXAMPLE USES:F
% multi_comp_fit('vol.mnc', 'T2', 'tissue', 'cls_mask.mnc')
% --> Analyze vol.mnc T2 relaxation data, using a
% tissue classification mask 'cls_mask.mnc'.
% 
% AUTHOR: Eva Alonso Ortiz (eva.alonso.ortiz@gmail.com)
% DATE LAST MODIFIED: 
% March 2016 - WIP: complex data anaylis is not currently working, do not
% attempt to use it!
%
%*************************************************************************

% =========================== Header ==================================== %
this_fname = 'multi_comp_fit';
this_info = sprintf('%-20s : ',this_fname);
fprintf([this_info,'$Revision: 1.0 $\n']);
fprintf([this_info, 'Current date and time: %s\n'], datestr(now));
% =========================================================================

diary('logfile_multi_comp_fit')

tic;

% % Open the matlabpool for parallel computing
% if matlabpool('size') == 0
%    matlabpool
% end

%%-------------------------------------------------------------------------
%% check existence of data files
%%-------------------------------------------------------------------------

[fid, message] = fopen(data_file_name,'r');
if(fid == -1)
  error(sprintf('\nError in multi_comp_fit: cannot find input data file %s\n', data_file_name));
else
  fclose(fid);
end

% set processing labels
ROI_flag = 0;
voxelwise_ROI_flag = 0;
tissue_flag = 0;
mask_flag = 0;
max_echoes_flag = 0;

% default number of inputs
ndef_inputs = 2;

if nargin > 2 
    % sort through options
    if nargin < 5
        mask_opts = nargin-ndef_inputs;
    else
        mask_opts = nargin-ndef_inputs-1;
    end
        
    for counter = 2:2:(mask_opts)
        switch varargin{counter-1}
            case{'ROI'}
                roi_file_name = varargin{counter};
                % check existence of mask file
                [fid, message] = fopen(roi_file_name,'r');
                if(fid == -1)
                    error(sprintf('\nError in multi_comp_fit: cannot find input mask file %s\n', mask_file_name));
                else
                    ROI_flag = 1;
                    fclose(fid);
                    voxelwise_ROI_flag = input('Voxel-wise ROI analysis (1) or average ROI analysis (0)?: ');
                end
            case{'tissue'}
                cls_file_name = varargin{counter};
                % check existence of mask file
                [fid, message] = fopen(cls_file_name,'r');
                if(fid == -1)
                    error(sprintf('\nError in multi_comp_fit: cannot find input mask file %s\n', cls_file_name));
                else
                    fclose(fid);
                    val = input('Enter the tissue flag to be used for processing (1->CSF, 2->GM, 3->WM): ');
                    switch val
                        case 1
                            tissue_flag = 1;
                        case 2
                            tissue_flag = 2;
                        case 3 
                            tissue_flag = 3;
                        otherwise
                            warning(sprintf('Invalid tissue flag entered. Proceeding analysis with no mask.'))
                    end                        
                end
            otherwise
                error(sprintf('Unrecognized option: %s', varargin{counter-1}))
        end
    end

    if nargin > 4
        nvarargin = nargin - ndef_inputs;
        max_echoes_fname = varargin{nvarargin};
        % check existence of file
        [fid, message] = fopen(max_echoes_fname,'r');
        if(fid == -1)
            error(sprintf('\nError in multi_comp_fit: cannot find input file %s\n', max_echoes_fname));
        else
            fclose(fid);
            max_echoes_flag = 1;
        end
    end
end


%%-------------------------------------------------------------------------
%% open data file
%%-------------------------------------------------------------------------

[data_pathstr, data_name, data_ext] = fileparts(data_file_name);

if strcmp(data_ext,'.mnc') == 1

    [data_desc,data_vol] = niak_read_minc(data_file_name);

    data_dim = data_desc.info.dimensions;
    data_slices = data_dim(1,3);
    data_height = data_dim(1,1);
    data_width = data_dim(1,2);
    data_voxels = data_height*data_width;
    num_echoes = data_dim(1,4);

elseif strcmp(data_ext,'.mat') == 1
    
    data_struct = load(data_file_name);
    fn = fieldnames(data_struct);
    data_vol = data_struct.(fn{1});
    
    data_dim = size(data_vol);
    data_slices = data_dim(1,3);
    data_height = data_dim(1,1);
    data_width = data_dim(1,2);
    data_voxels = data_height*data_width;
    num_echoes = data_dim(1,4);
    
%    display_slices(data_file_name);
    
    % prompt user as to single or multi-slice analysis
    ss_analysis = input('If single slice analysis is desired, enter the slice number. Otherwise, enter 0: ');
    if ss_analysis ~= 0
        % re-write data volume to contain only the slice desired
        data_vol = data_vol(:,:,ss_analysis,:);
        data_dim(3) = 1;
        data_slices = 1;
    end

end

% check if complex anayis is desired, and if so, open phase data file
complex_analysis = 0;
fit_loop = 1;
phase_fname = input('If complex data analysis is desired, enter phase data file name (otherwise, press "Enter": ');
if isempty(phase_fname) == 0
    complex_analysis = 1;
    [phase_desc,phase_vol] = niak_read_minc(phase_fname);
end

%%-------------------------------------------------------------------------
%% open mask files
%%-------------------------------------------------------------------------

if ROI_flag == 1    
    % Open mask file
    [roi_pathstr, roi_name, roi_ext] = fileparts(roi_file_name);
    
    if strcmp(roi_ext,'.mnc') == 1
        
        [roi_desc, roi_vol] = niak_read_minc(roi_file_name);

        roi_dim = roi_desc.info.dimensions;
        roi_voxels = roi_dim(1,1)*roi_dim(1,2);

        % check that mask and data_vol are the same dimensions
        if roi_voxels ~= data_voxels
            error(sprintf('\nError in multi_comp_fit: Mask file dimensions do not match data image file.\n')); 
        end
        
    elseif strcmp(roi_ext,'.mat') == 1
        
        roi_struct = load(roi_file_name);
        fn = fieldnames(roi_struct);
        roi_vol = roi_struct.(fn{1});
        
        roi_voxels = size(roi_vol,1)*size(roi_vol,2);
        
        % check that mask and data_vol are the same dimensions
        if roi_voxels ~= data_voxels
            error(sprintf('\nError in multi_comp_fit: Mask file dimensions do not match data image file.\n')); 
        end

        % no need to re-write roi volume to contain only the slice desired,
        % since rois are always single-slice
        
    end
end

if tissue_flag ~= 0 
    % open tissue classification mask
    
    [cls_pathstr, cls_name, cls_ext] = fileparts(cls_file_name);
    
    if strcmp(cls_ext,'.mnc') == 1

        [mask_desc,mask_vol] = niak_read_minc(cls_file_name);

        mask_dim = mask_desc.info.dimensions;
        mask_voxels = mask_dim(1,1)*mask_dim(1,2);

        % check that mask and data_vol are the same dimensions
        if mask_voxels ~= data_voxels
            error(sprintf('\nError in multi_comp_fit: Tissue mask file dimensions do not match data image file.\n')); 
        end
        
     elseif strcmp(cls_ext,'.mat') == 1
        
        mask_struct = load(cls_file_name);
        fn = fieldnames(mask_struct);
        mask_vol = mask_struct.(fn{1});
        
        mask_voxels = size(mask_vol,1)*size(mask_vol,2);
        
        % check that mask and data_vol are the same dimensions
        if mask_voxels ~= data_voxels
            error(sprintf('\nError in multi_comp_fit: Mask file dimensions do not match data image file.\n')); 
        end

        if ss_analysis ~= 0
            % re-write tissue classification volume to contain only the slice desired
            mask_vol = mask_vol(:,:,ss_analysis);
        end
    
    end   
    
end

if max_echoes_flag == 1
    % open max echoes map
    [max_echoes_desc,max_num_echoes] = niak_read_minc(max_echoes_fname);

    max_echoes_dim = max_echoes_desc.info.dimensions;
    max_echoes_voxels = max_echoes_dim(1,1)*max_echoes_dim(1,2);

    % check that mask and data_vol are the same dimensions
    if max_echoes_voxels ~= data_voxels
        error(sprintf('\nError in multi_comp_fit: Max echoes map file dimensions do not match data image file.\n')); 
    end
    
    % check if this is a binary image (field correction mask) or not (max
    % echoes file for 3D correction)
    if max(max_num_echoes)==1
        max_num_echoes(find(max_num_echoes==0))=45;
        max_num_echoes(find(max_num_echoes==1))=64;
    end
end

%%-------------------------------------------------------------------------
%% caculate echo times
%%-------------------------------------------------------------------------

echo_times = calc_echo_times(num_echoes);

%%-------------------------------------------------------------------------
%% Set default settings according to relaxation time
%%-------------------------------------------------------------------------

switch relaxation_type
    case 'T2'
        t2_range = [1.5*echo_times(1), 2000]; % Kolind et al. doi: 10.1002/mrm.21966
        
        % set cutoff times for myelin water (MW) and intra/extracellular
        % water (IEW) components (in ms)
        lower_cutoff_MW = t2_range(1);
        upper_cutoff_MW = input('Enter the desired upper cutoff for myelin water (in ms): ');
        %upper_cutoff_MW = 40; % Kolind et al. doi: 10.1002/mrm.21966
        upper_cutoff_IEW = 200; % Kolind et al. doi: 10.1002/mrm.21966
        
    case 'T2star'
        t2_range = [1.5*echo_times(1), 300]; % Lenz et al. doi: 10.1002/mrm.23241
%         t2_range = [1.5*echo_times(1), 600]; % Use this to look at CSF
%         component
        
        % set cutoff times for myelin water (MW) and intra/extracellular
        % water (IEW) components (in ms)  
        lower_cutoff_MW = t2_range(1);
        %upper_cutoff_MW = 25; % Lenz et al. doi: 10.1002/mrm.23241 
        upper_cutoff_MW = input('Enter the desired upper cutoff for myelin water (in ms): ');
        upper_cutoff_IEW = 200; 
         
    otherwise
        error(sprintf('\nRelaxation type must be either T2 or T2star!'));
end

%%-------------------------------------------------------------------------
%% default values for NNLS fitting
%%-------------------------------------------------------------------------

num_t2_vals = 120;
  
% set default values for reg-NNLS (taken from C. Chia)
set(0,'RecursionLimit',5000)
mu = 0.25;
chi2range = [2 2.5];
chi2_min = chi2range(1);
chi2_max = chi2range(2);
    

%%-------------------------------------------------------------------------
%% Calculate background noise 
%%-------------------------------------------------------------------------

sigma = calc_bkgrnd_noise(data_vol, data_dim);

%%-------------------------------------------------------------------------
%% apply ROI mask to data volumes
%%-------------------------------------------------------------------------

if (ROI_flag == 1 && voxelwise_ROI_flag == 0)
    
    mean_roi_data = get_avgROI_data(roi_vol, data_vol, data_dim);

end

%%-------------------------------------------------------------------------
%% NNLS fitting routine presets
%%-------------------------------------------------------------------------

[decay_matrix, t2_vals] = prepare_NNLS(echo_times, t2_range, num_t2_vals);

% find cutoff indices
lower_cutoff_MW_index = find_cutoff_index(lower_cutoff_MW, t2_vals);
upper_cutoff_MW_index = find_cutoff_index(upper_cutoff_MW, t2_vals);
upper_cutoff_IEW_index = find_cutoff_index(upper_cutoff_IEW, t2_vals);

%%-------------------------------------------------------------------------
%% data fitting and analysis
%%-------------------------------------------------------------------------
diary off 

if (ROI_flag == 1 && voxelwise_ROI_flag == 0)
   
    for slice = 1:data_slices
    
            %------------------------------
            % Do multi-exponential fitting
            %------------------------------    

            % Do non-regularized NNLS
            [spectrum_NNLS(slice,:), chi2_NNLS(slice)] = do_NNLS(decay_matrix, double(squeeze(mean_roi_data(slice,:))), sigma(slice));
            
            ssq_res_NNLS(slice) = sum((decay_matrix*squeeze(spectrum_NNLS(slice,:)') - squeeze(mean_roi_data(slice,:))').^2);
            s0_NNLS(slice) = sum(spectrum_NNLS(slice,:));
            mwf_NNLS(slice) = sum(spectrum_NNLS(slice,lower_cutoff_MW_index:upper_cutoff_MW_index))/s0_NNLS(slice);

            if isnan(ssq_res_NNLS(slice)) == 1
                ssq_res_NNLS(slice) = 0;
            end
            if isnan(s0_NNLS(slice)) == 1
                s0_NNLS(slice) = 0;
            end
            if isnan(mwf_NNLS(slice)) == 1
                mwf_NNLS(slice) = 0;
            end
            
            % Calculate the geometric mean of the T2 distribition for the non-reg NNLS 
            gm_t2_NNLS(slice) = exp(sum(squeeze(spectrum_NNLS(slice,:))'.*log(t2_vals))/sum(spectrum_NNLS(slice,:)));
            gm_IEW_t2_NNLS(slice) = exp(sum(squeeze(spectrum_NNLS(slice,upper_cutoff_MW_index:upper_cutoff_IEW_index))'.*log(t2_vals(upper_cutoff_MW_index:upper_cutoff_IEW_index)))/sum(spectrum_NNLS(slice,upper_cutoff_MW_index:upper_cutoff_IEW_index)));

            if isnan(gm_t2_NNLS(slice)) == 1
                gm_t2_NNLS(slice) = 0;
            end
            if isnan(gm_IEW_t2_NNLS(slice)) == 1
                gm_IEW_t2_NNLS(slice) = 0;
            end
            
            % Do regulaized NNLS 
            [spectrum_regNNLS(slice,:), chi2_regNNLS(slice)] = ...
            iterate_NNLS(mu,chi2_min,chi2_max,num_t2_vals,double(squeeze(mean_roi_data(slice,:))),decay_matrix,chi2_NNLS(slice),sigma(slice));

            ssq_res_regNNLS(slice) = sum((decay_matrix*squeeze(spectrum_regNNLS(slice,:)') - squeeze(mean_roi_data(slice,:))').^2);
            s0_regNNLS(slice) = sum(spectrum_regNNLS(slice,:));
            mwf_regNNLS(slice) = sum(spectrum_regNNLS(slice,1:upper_cutoff_MW_index))/s0_regNNLS(slice);

            if isnan(ssq_res_regNNLS(slice)) == 1
                ssq_res_regNNLS(slice) = 0;
            end
            if isnan(s0_regNNLS(slice)) == 1
                s0_regNNLS(slice) = 0;
            end
            if isnan(mwf_regNNLS(slice)) == 1
                mwf_regNNLS(slice) = 0;
            end
            
            % Calculate the geometric mean of the T2 distribition for the reg NNLS 
            gm_t2_regNNLS(slice) = exp(sum(squeeze(spectrum_regNNLS(slice,:))'.*log(t2_vals))/sum(spectrum_regNNLS(slice,:)));
            gm_IEW_t2_regNNLS(slice) = exp(sum(squeeze(spectrum_regNNLS(slice,upper_cutoff_MW_index:upper_cutoff_IEW_index))'.*log(t2_vals(upper_cutoff_MW_index:upper_cutoff_IEW_index)))/sum(spectrum_regNNLS(slice,upper_cutoff_MW_index:upper_cutoff_IEW_index)));    
            
            if isnan(gm_t2_regNNLS(slice)) == 1
                gm_t2_regNNLS(slice) = 0;
            end
            if isnan(gm_IEW_t2_regNNLS(slice)) == 1
                gm_IEW_t2_regNNLS(slice) = 0;
            end
            
            %-----------------------------
            % Do mono-exponential fitting 
            %-----------------------------

            % Fit to single T2 decay component for comparison
            t2_guess = 100;
            guess = [t2_guess, mean_roi_data(slice,1)];

            [s0_fit(slice), t2_fit(slice)] = mono_exp_fit(double(squeeze(mean_roi_data(slice,:))), echo_times, double(guess));
           
            if isnan(s0_fit(slice)) == 1
                s0_fit(slice) = 0;
            end
            if isnan(s0_fit(slice)) == 1
                s0_fit(slice) = 0;
            end
    end
    
else
    if (ROI_flag == 1 && voxelwise_ROI_flag == 1)
        
        mask_flag = 1;
        mask_vol = roi_vol;        
    else        
        if (tissue_flag == 0 && voxelwise_ROI_flag == 0)
            
            % create brain mask to limit processing time (and mask out noise in
            % images!)        
            create_brainmask(data_file_name);
            mask_flag = 1;
            % open brain mask
            [mask_desc,mask_vol] = niak_read_minc('brain_mask.mnc');
        else
            mask_flag = tissue_flag;
        end
    end

    % initialize all data vectors to zero
    spectrum_NNLS = zeros(data_height,data_width,data_slices,num_t2_vals);
    chi2_NNLS = zeros(data_height,data_width,data_slices);
    gm_t2_NNLS = zeros(data_height,data_width,data_slices);
    gm_IEW_t2_NNLS = zeros(data_height,data_width,data_slices);
    ssq_res_NNLS = zeros(data_height,data_width,data_slices);
    s0_NNLS = zeros(data_height,data_width,data_slices);
    mwf_NNLS = zeros(data_height,data_width,data_slices);

    spectrum_regNNLS = zeros(data_height,data_width,data_slices, num_t2_vals);
    spectrum_regNNLS_A = zeros(data_height,data_width,data_slices, num_t2_vals);
    spectrum_regNNLS_B = zeros(data_height,data_width,data_slices, num_t2_vals);
    amp_spectrum_regNNLS = zeros(data_height,data_width,data_slices, num_t2_vals);
    phase_spectrum_regNNLS = zeros(data_height,data_width,data_slices, num_t2_vals);
    chi2_regNNLS = zeros(data_height,data_width,data_slices);
    gm_t2_regNNLS = zeros(data_height,data_width,data_slices);
    gm_IEW_t2_regNNLS = zeros(data_height,data_width,data_slices);
    gm_MW_t2_regNNLS = zeros(data_height,data_width,data_slices);
    ssq_res_regNNLS = zeros(data_height,data_width,data_slices);
    s0_regNNLS = zeros(data_height,data_width,data_slices);
    mwf_regNNLS = zeros(data_height,data_width,data_slices);
    mw_delf_regNNLS = zeros(data_height,data_width,data_slices);

    s0_fit = zeros(data_height,data_width,data_slices);
    t2_fit = zeros(data_height,data_width,data_slices);

    if (ROI_flag == 1 && voxelwise_ROI_flag == 1)
        
        %-------------------------------------------
        % Prepare figure for superimposed spectrum
        %-------------------------------------------
        figure; hold on;
        set(gca,'xscale','log','FontSize',20,'XMinorTick','on')
        xlim([t2_range(1) t2_range(2)])
        ylabel('Normalized Signal');
        if strcmp(relaxation_type,'T2')==1
            xlabel('T2 (ms)');
            title('T_2 Spectrum','FontSize',20);
        elseif strcmp(relaxation_type,'T2star')==1
            xlabel('T2* (ms)');
            title('T_2^* Spectrum','FontSize',20);  
        end
        x = [upper_cutoff_MW, upper_cutoff_MW];
        y = [0, 1];
        plot(x,y,'r-','LineWidth', 4);
        grid minor;

    end
    
    for slice = 1:data_slices

        for i = 1:data_height
            for j = 1:data_width

                % only fill in what corresponds to the mask
                if mask_vol(i,j,slice) == mask_flag
                    
                    if (max_echoes_flag == 1 && max_num_echoes(i,j,slice)>5)
                        % re-calculate echo times 
                        this_echo_times = echo_times(1:max_num_echoes(i,j,slice));
                        this_num_echoes = max_num_echoes(i,j,slice);
                        % re-calculate NNLS presets
                        [this_decay_matrix, t2_vals] = prepare_NNLS(this_echo_times, t2_range, num_t2_vals);
                        % re-calculate cutoff indices
                        this_lower_cutoff_MW_index = find_cutoff_index(lower_cutoff_MW, t2_vals);
                        this_upper_cutoff_MW_index = find_cutoff_index(upper_cutoff_MW, t2_vals);
                        this_upper_cutoff_IEW_index = find_cutoff_index(upper_cutoff_IEW, t2_vals);
                    else
                        this_echo_times = echo_times;
                        this_num_echoes = num_echoes;
                        this_decay_matrix = decay_matrix;
                        this_lower_cutoff_MW_index = lower_cutoff_MW_index;
                        this_upper_cutoff_MW_index = upper_cutoff_MW_index;
                        this_upper_cutoff_IEW_index = upper_cutoff_IEW_index;
                    end

                    %------------------------------
                    % Do multi-exponential fitting
                    %------------------------------    

                    if complex_analysis == 1
                        fit_loop = 2;
                    end

                    for n = 1:fit_loop
                        
                        if complex_analysis == 1
                            if n == 1
                                data_vol(i,j,slice,:) = data_vol(i,j,slice,:).*cos(phase_vol(i,j,slice,:));
                            elseif n == 2
                                data_vol(i,j,slice,:) = data_vol(i,j,slice,:).*sin(phase_vol(i,j,slice,:));
                            end
                        end
                        
                        % Do non-regularized NNLS
                        [spectrum_NNLS(i,j,slice,:), chi2_NNLS(i,j,slice)] = do_NNLS(this_decay_matrix, double(squeeze(data_vol(i,j,slice,1:this_num_echoes)))', sigma(slice));

                        % Do regulaized NNLS 
                        [spectrum_regNNLS(i,j,slice,:), chi2_regNNLS(i,j,slice)] = ...
                        iterate_NNLS(mu,chi2_min,chi2_max,num_t2_vals,double(squeeze(data_vol(i,j,slice,1:this_num_echoes)))',this_decay_matrix,chi2_NNLS(i,j,slice),sigma(slice));

                        % NOTE: complex analysis part is incorrect WIP
                        if complex_analysis == 1
                            if n == 1
                                spectrum_regNNLS_A(i,j,slice,:) = spectrum_regNNLS(i,j,slice,:);
                            elseif n == 2
                                spectrum_regNNLS_B(i,j,slice,:) = spectrum_regNNLS(i,j,slice,:);
                            end
                        end
                        
                    end
                
                    % NOTE: complex analysis part is incorrect WIP
                    if complex_analysis == 1
                        
                       amp_spectrum_regNNLS(i,j,slice,:) = sqrt(spectrum_regNNLS_A(i,j,slice,:).^2+spectrum_regNNLS_B(i,j,slice,:).^2);
                       phase_spectrum_regNNLS(i,j,slice,:) = atan(spectrum_regNNLS_B(i,j,slice,:)/spectrum_regNNLS_A(i,j,slice,:));

                       s0_regNNLS(i,j,slice) = sum(amp_spectrum_regNNLS(i,j,slice,:));
                       mwf_regNNLS(i,j,slice) = sum(amp_spectrum_regNNLS(i,j,slice,1:this_upper_cutoff_MW_index))/s0_regNNLS(i,j,slice);
                       
                       mw_delf_regNNLS(i,j,slice) = mean(phase_spectrum_regNNLS(i,j,slice,1:this_upper_cutoff_MW_index));
                       
                       if isnan(mw_delf_regNNLS(i,j,slice)) == 1
                           mw_delf_regNNLS(i,j,slice) = 0;
                       end

                    else
                    
                        s0_regNNLS(i,j,slice) = sum(spectrum_regNNLS(i,j,slice,:));
                        mwf_regNNLS(i,j,slice) = sum(spectrum_regNNLS(i,j,slice,1:this_upper_cutoff_MW_index))/s0_regNNLS(i,j,slice);

                        % Calculate the geometric mean of the T2 distribition for the reg NNLS 
                        gm_t2_regNNLS(i,j,slice) = exp(sum(squeeze(spectrum_regNNLS(i,j,slice,:)).*log(t2_vals))/sum(spectrum_regNNLS(i,j,slice,:)));
                        gm_IEW_t2_regNNLS(i,j,slice) = exp(sum(squeeze(spectrum_regNNLS(i,j,slice,this_upper_cutoff_MW_index:this_upper_cutoff_IEW_index)).*log(t2_vals(this_upper_cutoff_MW_index:this_upper_cutoff_IEW_index)))/sum(spectrum_regNNLS(i,j,slice,this_upper_cutoff_MW_index:this_upper_cutoff_IEW_index)));
                        gm_MW_t2_regNNLS(i,j,slice) = exp(sum(squeeze(spectrum_regNNLS(i,j,slice,this_lower_cutoff_MW_index:this_upper_cutoff_MW_index)).*log(t2_vals(this_lower_cutoff_MW_index:this_upper_cutoff_MW_index)))/sum(spectrum_regNNLS(i,j,slice,this_lower_cutoff_MW_index:this_upper_cutoff_MW_index)));

                        if isnan(gm_t2_regNNLS(i,j,slice)) == 1
                            gm_t2_regNNLS(i,j,slice) = 0;
                        end
                        if isnan(gm_IEW_t2_regNNLS(i,j,slice)) == 1
                            gm_IEW_t2_regNNLS(i,j,slice) = 0;
                        end
                        if isnan(gm_MW_t2_regNNLS(i,j,slice)) == 1
                            gm_MW_t2_regNNLS(i,j,slice) = 0;
                        end
                    
                    end
                    
                    if isnan(s0_regNNLS(i,j,slice)) == 1
                        s0_regNNLS(i,j,slice) = 0;
                    end
                    if isnan(mwf_regNNLS(i,j,slice)) == 1
                        mwf_regNNLS(i,j,slice) = 0;
                    end

                    
                    %-----------------------------
                    % Do mono-exponential fitting 
                    %-----------------------------

                    % Fit to single T2 decay component for comparison
%                     t2_guess = 100;
%                     guess = [t2_guess, data_vol(i,j,slice,1)];
% 
%                     [s0_fit(i,j,slice), t2_fit(i,j,slice)] = mono_exp_fit(double(squeeze(data_vol(i,j,slice,1:this_num_echoes)))', this_echo_times, double(guess));
% 
%                     if isnan(s0_fit(i,j,slice)) == 1
%                         s0_fit(i,j,slice) = 0;
%                     end
%                     if isnan(s0_fit(i,j,slice)) == 1
%                         s0_fit(i,j,slice) = 0;
%                     end
            
                    if (ROI_flag == 1 && voxelwise_ROI_flag == 1)
                        
                        %-----------------------------
                        %  Plot the T2 spectrum
                        %-----------------------------

                        % Normalize distributions
                        norm_spectrum_NNLS(i,j,slice,:) = spectrum_NNLS(i,j,slice,:)/max(spectrum_NNLS(i,j,slice,:));
                        norm_spectrum_regNNLS(i,j,slice,:) = spectrum_regNNLS(i,j,slice,:)/max(spectrum_regNNLS(i,j,slice,:));

                        plot(t2_vals,squeeze(norm_spectrum_regNNLS(i,j,slice,:)), 'b-','LineWidth',0.1);
                        print('-djpeg','superimposed_spectrum.jpeg');
                        
                    end
                   
                end

            end
        end
    
    end

end


%--------------------------------------------------------------------------

if ( ROI_flag == 1 && voxelwise_ROI_flag == 0 )

    for slice = 1:data_slices
    
        %% Plot the T2 spectrum

        % Normalize distributions
        norm_spectrum_NNLS(slice,:) = spectrum_NNLS(slice,:)/max(spectrum_NNLS(slice,:));
        norm_spectrum_regNNLS(slice,:) = spectrum_regNNLS(slice,:)/max(spectrum_regNNLS(slice,:));

        figure; hold on;
        grid minor;
        %bar1 = bar(t2_vals,norm_spectrum_NNLS(slice,:),'FaceColor', 'g', 'EdgeColor', 'g','LineWidth',1);
        %set(bar1,'BarWidth',0.1); 
        
%         %--------------------
%         % If the data is simulated: Plot "true" spectrum (otherwise,
%         % comment this out)
%         %--------------------
%         T2 = [5 50]';
%         frac = [0.12 0.88]';
% 
%         true_spectrum = zeros(size(t2_vals));
%         for j = 1: size(T2)
%             for i = 1:(size(t2_vals)-1)
%                 if i == 1
%                     if T2(j) == t2_vals(i)
%                         true_spectrum(i) = frac(j);
%                     end
%                 end
% 
%                 if ((t2_vals(i+1) >= T2(j)) && (t2_vals(i) <= T2(j)))
%                     true_spectrum(i) = frac(j);
%                 end
%             end
%         end
%         bar2 = bar(t2_vals,true_spectrum(:),'FaceColor', 'm', 'EdgeColor', 'm','LineWidth',1);
%         %set(bar2,'BarWidth',0.1); 
%         %--------------------
        
        plot(t2_vals,norm_spectrum_regNNLS(slice,:), 'b-','LineWidth',1.5);
        set(gca,'xscale','log','FontSize',20)
        xlim([t2_range(1) t2_range(2)])
        %xlim([0.002*1e3 4*1e3]) %keep T2* and T2 ranges the same for plot
        ylabel('Normalized Signal');
        if strcmp(relaxation_type,'T2')==1
            xlabel('T2 (ms)');
            title('T_2 Spectrum','FontSize',20);
        elseif strcmp(relaxation_type,'T2star')==1
            xlabel('T2* (ms)');
            title('T_2^* Spectrum','FontSize',20);   
        end
        x = [upper_cutoff_MW, upper_cutoff_MW];
        y = [0, 1];
        plot(x,y,'r-','LineWidth', 2);
%         legend('location', 'NorthEast','NNLS multi-exp fit','True Spectrum','regularized NNLS multi-exp fit')
%         legend('location', 'NorthEast','NNLS multi-exp fit','regularized NNLS multi-exp fit')
%         legend('location', 'NorthEast','regularized NNLS multi-exp fit')
        print('-djpeg','spectrum.jpeg')
        
        %% Plot the decay curve and fitted line

        % Reconstruct the signal intensities and plot back on 
        % top of the original data.

        single_sig_recon(slice,:) = s0_fit(slice).*exp(-echo_times/t2_fit(slice));
        multi_sig_recon(slice,:) = decay_matrix * spectrum_NNLS(slice,:)';
        reg_multi_sig_recon(slice,:) = decay_matrix * spectrum_regNNLS(slice,:)';

        figure; hold on;
        plot(echo_times, mean_roi_data(slice,:), 'kx', 'MarkerSize',10);
%         plot(echo_times, single_sig_recon(slice,:), 'g-.','LineWidth',2);
%         plot(echo_times, multi_sig_recon(slice,:), 'b-','LineWidth',2);
        plot(echo_times, reg_multi_sig_recon(slice,:), 'r--','LineWidth',2);
        if strcmp(relaxation_type,'T2')==1
%             legend('location', 'best', 'SE data','mono-exponential fit','NNLS multi-exp fit','regularized NNLS multi-exp fit');
            legend('location', 'best', 'SE data','regularized NNLS multi-exp fit');
        elseif strcmp(relaxation_type,'T2star')==1
%             legend('location', 'best','GRE data','mono-exponential fit','NNLS multi-exp fit','regularized NNLS multi-exp fit');
            legend('location', 'best', 'SE data','regularized NNLS multi-exp fit');
        end
        xlabel('TE (ms)');
        ylabel('Signal (arb)');
        grid on;
        print('-djpeg','signal_decay.jpeg');

        if strcmp(relaxation_type,'T2')==1
            %disp(fprintf('\nmulti-exp NNLS (slice %d) => <T2>: %3.2f ms, MWF:  %3.2f', slice, gm_t2_NNLS(slice), mwf_NNLS(slice))); 
            disp(fprintf('multi-exp regNNLS (slice %d) => IE water <T2>: %3.2f ms, MWF:  %3.2f', slice, gm_IEW_t2_regNNLS(slice), 100*mwf_regNNLS(slice))); 
            %disp(fprintf('Mono-exponential T2 fit (slice %d): %3.2f ms', slice, t2_fit(slice)));    
        elseif strcmp(relaxation_type,'T2star')==1
            %disp(fprintf('\nmulti-exp NNLS (slice %d) => <T2*>: %3.2f ms, MWF:  %3.2f', slice, gm_t2_NNLS(slice), mwf_NNLS(slice))); 
            disp(fprintf('multi-exp regNNLS (slice %d) => IE water <T2*>: %3.2f ms, MWF:  %3.2f', slice, gm_IEW_t2_regNNLS(slice), 100*mwf_regNNLS(slice))); 
            %disp(fprintf('Mono-exponential T2* fit (slice %d): %3.2f ms', slice, t2_fit(slice)));    
        end
  
   end

elseif ROI_flag == 0       
        % Create mono T2, <T2>, and MWF maps (for reg and unreg NNLS data)
        %data_desc.info.dimensions(1,4) = 1;
        mask_desc.info.dimensions(1,4) = 1;
        
        %for i = 1:6
        for i = 1:2
            switch i
%                 case 1
%                      file_name = 'mw_delf_regNNLS_map';
%                      data = mw_delf_regNNLS;
                case 1
                    file_name = 'mwf_regNNLS_map';
                    data = 100*mwf_regNNLS;
                case 2 
                    file_name = 'IEW_gmT2_regNNLS_map';
                    data = gm_IEW_t2_regNNLS;
%                 case 4
%                     file_name = 'ssq_res_regNNLS_map.mnc';
%                     data = ssq_res_regNNLS;
            end
    
            if strcmp(data_ext,'.mnc') == 1

                mask_desc.file_name = strcat(file_name,'.mnc');
                niak_write_minc(mask_desc,data);
               
            elseif strcmp(data_ext,'.mat') == 1
                
                save(strcat(file_name,'.mat'),'data');

            end 
        end
end   

diary on;

if ( tissue_flag ~= 0 || voxelwise_ROI_flag == 1 )
    mwf_regNNLS = reshape(mwf_regNNLS,data_voxels,data_slices);
    gm_IEW_t2_regNNLS = reshape(gm_IEW_t2_regNNLS,data_voxels,data_slices);
    for slice = 1:data_slices
        mROI_mwf_regNNLS(slice) = mean(nonzeros(mwf_regNNLS(:,slice)));
        stdROI_regNNLS(slice) = std(nonzeros(mwf_regNNLS(:,slice)));
        
        mROI_gm_IEW_t2_regNNLS(slice) = mean(nonzeros(gm_IEW_t2_regNNLS(:,slice)));
        stdROI_gm_IEW_t2_regNNLS(slice) = std(nonzeros(gm_IEW_t2_regNNLS(:,slice)));
        
%         mROI_gm_MW_t2_regNNLS(slice) = mean(nonzeros(gm_MW_t2_regNNLS(:,slice)));
%         stdROI_gm_MW_t2_regNNLS(slice) = std(nonzeros(gm_MW_t2_regNNLS(:,slice)));
        
        disp(fprintf('\nAverage regMWF over tissue mask (slice %d): %3.2f +/- %3.2f %%', slice, 100*mROI_mwf_regNNLS(slice), 100*stdROI_regNNLS(slice))); 
        disp(fprintf('\nAverage IE water gm_T2 over tissue mask (slice %d): %3.2f +/- %3.2f ms', slice, mROI_gm_IEW_t2_regNNLS(slice), stdROI_gm_IEW_t2_regNNLS(slice))); 
%         disp(fprintf('\nAverage Myelin water gm_T2 over tissue mask (slice %d): %3.2f +/- %3.2f ms', slice, mROI_gm_MW_t2_regNNLS(slice), stdROI_gm_MW_t2_regNNLS(slice))); 
    end
end

%--------------------------------------------------------------------------

% matlabpool('close')

time_spent = toc;

disp(fprintf('Time Spent: %3.2f min\n', time_spent/60));

diary off  

