function FitResult = multi_comp_fit_v2(data_vol, relaxation_type, Echo, Cutoff, Sigma, varargin)
%
% multi_comp_fit_v2(data_file_name, relaxation_type, Echo, Cutoff, Sigma,['ROI', roi_vol, 'tissue', mask_vol])
%
%**************************************************************************
% DESCRIPTION:
%
% A script to compute the multi-component T2 or T2* spectrum for an
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
%**************************************************************************
% INPUTS:
%
%   * data_vol        = echo train data set to be analyzed
%   * relaxation_type = 'T2' or 'T2star'
%   * Echo            = struct with echo parameters
%                           * Echo.First   = First echo in ms 
%                           * Echo.Spacing = Echo spacing in ms
%   * Cutoff          = cutoff in ms
%   * Sigma           = noise's sigma
%   * 'ROI'           = ROI processing flag
%   * roi_vol         = ROI mask
%   * 'tissue'        = tissue processing flag
%   * mask_vol        = tissue classification mask (1->CSF, 2->GM, 3->WM)
%                       Can be used to limit processing time
%   * varargin        = optional file limiting the number of echoes to be used for
%                       analysis. This can be 
%                       1. max_echoes.mnc file obtained from'in_plane_correction.m' 
%                          to perform in-plane field inhomogeneity correction
%                       2. correction_mask.mnc, obtained from 'Gz_correction.m'.
%                          This binary file has voxels where the field gradient (Gz) 
%                          was > 2mG/cm set to 0 (no field inhomog. correction performed*), 
%                          and areas where Gz was < 2mG/cm set to 1. 
%                          *The correction fails where Gz > 2mG/cm. In order to limit 
%                          effect of field inhomogeneities in these voxels,
%                          processing is limited to 45 echoes, instead of 64. 
%
%**************************************************************************
% EXAMPLE USES:
% multi_comp_fit_v2(vol, 'T2', 'tissue',Echo, Cutoff, cls_mask)
% --> Analyze vol T2 relaxation data, using a
% tissue classification mask: cls_mask.
% 
% AUTHOR: Eva Alonso Ortiz (eva.alonso.ortiz@gmail.com)
% DATE LAST MODIFIED: 
% March 2016 - WIP: complex data anaylis is not currently working, do not
% attempt to use it!
%
%**************************************************************************
% SPECIAL VERSION adapted for qMRLab
% By Ian Gagnon, 2017
% For the original version, see multi_comp_fit.m
% *************************************************************************

%%-------------------------------------------------------------------------
%% check existence of data files
%%-------------------------------------------------------------------------

% set processing labels
ROI_flag           = 0;
voxelwise_ROI_flag = 0;
tissue_flag        = 0;
mask_flag          = 0;

% default number of inputs
ndef_inputs = 5;

if nargin > 5 
    if nargin < 8
        mask_opts = nargin-ndef_inputs;
    else
        mask_opts = nargin-ndef_inputs-1;
    end
        
    for counter = 2:2:(mask_opts)
        switch varargin{counter-1}
            case{'ROI'}
                roi_vol = varargin{counter};
                ROI_flag = 1;
                voxelwise_ROI_flag = input('Voxel-wise ROI analysis (1) or average ROI analysis (0)?: ');
            case{'tissue'}
                mask_vol = varargin{counter};
                tissue_flag = 1;                      
        end
    end
end


%%-------------------------------------------------------------------------
%% Data informations
%%-------------------------------------------------------------------------    

data_dim    = size(data_vol);
data_slices = data_dim(1,3);
data_height = data_dim(1,1);
data_width  = data_dim(1,2);
data_voxels = data_height*data_width;
num_echoes  = data_dim(1,4);

%%-------------------------------------------------------------------------
%% Compatibily mask/data
%%-------------------------------------------------------------------------

if ROI_flag == 1    
    roi_voxels = size(roi_vol,1)*size(roi_vol,2);
    if roi_voxels ~= data_voxels
        error(sprintf('\nError in multi_comp_fit_v2: Mask file dimensions do not match data image file.\n')); 
    end
end

if tissue_flag ~= 0         
    mask_voxels = size(mask_vol,1)*size(mask_vol,2);     
    if mask_voxels ~= data_voxels
        error(sprintf('\nError in multi_comp_fit_v2: Mask file dimensions do not match data image file.\n')); 
    end  
end

%%-------------------------------------------------------------------------
%% Echo times calculation
%%-------------------------------------------------------------------------

echo_times(1:num_echoes) = Echo.First + Echo.Spacing*(0:num_echoes-1);

%%-------------------------------------------------------------------------
%% Set default settings according to relaxation time
%%-------------------------------------------------------------------------

switch relaxation_type
    case 'T2'
        t2_range = [1.5*echo_times(1), 2000]; % Kolind et al. doi: 10.1002/mrm.21966
        % set cutoff times for myelin water (MW) and intra/extracellular water (IEW) components (in ms)
        lower_cutoff_MW = t2_range(1);
        upper_cutoff_MW = Cutoff;
        %upper_cutoff_MW = 40; % Kolind et al. doi: 10.1002/mrm.21966
        upper_cutoff_IEW = 200; % Kolind et al. doi: 10.1002/mrm.21966
        
    case 'T2star'
        t2_range = [1.5*echo_times(1), 300]; % Lenz et al. doi: 10.1002/mrm.23241
%         t2_range = [1.5*echo_times(1), 600]; % Use this to look at CSF component        
        % set cutoff times for myelin water (MW) and intra/extracellular water (IEW) components (in ms)  
        lower_cutoff_MW = t2_range(1);
        %upper_cutoff_MW = 25; % Lenz et al. doi: 10.1002/mrm.23241 
        upper_cutoff_MW = Cutoff;
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
chi2_min  = chi2range(1);
chi2_max  = chi2range(2);
    

%%-------------------------------------------------------------------------
%% Calculate background noise 
%%-------------------------------------------------------------------------

% sigma = calc_bkgrnd_noise(data_vol, data_dim);

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
lower_cutoff_MW_index  = find_cutoff_index(lower_cutoff_MW, t2_vals);
upper_cutoff_MW_index  = find_cutoff_index(upper_cutoff_MW, t2_vals);
upper_cutoff_IEW_index = find_cutoff_index(upper_cutoff_IEW, t2_vals);

%%-------------------------------------------------------------------------
%% data fitting and analysis
%%-------------------------------------------------------------------------
if (ROI_flag == 1 && voxelwise_ROI_flag == 0)
   
    for slice = 1:data_slices
    
            %------------------------------
            % Do multi-exponential fitting
            %------------------------------    

            % Do non-regularized NNLS
            [spectrum_NNLS(slice,:), chi2_NNLS(slice)] = do_NNLS(decay_matrix, double(squeeze(mean_roi_data(slice,:))), Sigma(slice));
            
            ssq_res_NNLS(slice) = sum((decay_matrix*squeeze(spectrum_NNLS(slice,:)') - squeeze(mean_roi_data(slice,:))').^2);
            s0_NNLS(slice)      = sum(spectrum_NNLS(slice,:));
            mwf_NNLS(slice)     = sum(spectrum_NNLS(slice,lower_cutoff_MW_index:upper_cutoff_MW_index))/s0_NNLS(slice);

            if isnan(ssq_res_NNLS(slice))
                ssq_res_NNLS(slice) = 0;
            end
            if isnan(s0_NNLS(slice))
                s0_NNLS(slice) = 0;
            end
            if isnan(mwf_NNLS(slice))
                mwf_NNLS(slice) = 0;
            end
            
            % Calculate the geometric mean of the T2 distribition for the non-reg NNLS 
            gm_t2_NNLS(slice)     = exp(sum(squeeze(spectrum_NNLS(slice,:))'.*log(t2_vals))/sum(spectrum_NNLS(slice,:)));
            gm_IEW_t2_NNLS(slice) = exp(sum(squeeze(spectrum_NNLS(slice,upper_cutoff_MW_index:upper_cutoff_IEW_index))'.*log(t2_vals(upper_cutoff_MW_index:upper_cutoff_IEW_index)))/sum(spectrum_NNLS(slice,upper_cutoff_MW_index:upper_cutoff_IEW_index)));

            if isnan(gm_t2_NNLS(slice))
                gm_t2_NNLS(slice) = 0;
            end
            if isnan(gm_IEW_t2_NNLS(slice))
                gm_IEW_t2_NNLS(slice) = 0;
            end
            
            % Do regulaized NNLS 
            [spectrum_regNNLS(slice,:), chi2_regNNLS(slice)] = ...
            iterate_NNLS(mu,chi2_min,chi2_max,num_t2_vals,double(squeeze(mean_roi_data(slice,:))),decay_matrix,chi2_NNLS(slice),Sigma(slice));

            ssq_res_regNNLS(slice) = sum((decay_matrix*squeeze(spectrum_regNNLS(slice,:)') - squeeze(mean_roi_data(slice,:))').^2);
            s0_regNNLS(slice)      = sum(spectrum_regNNLS(slice,:));
            mwf_regNNLS(slice)     = sum(spectrum_regNNLS(slice,1:upper_cutoff_MW_index))/s0_regNNLS(slice);

            if isnan(ssq_res_regNNLS(slice))
                ssq_res_regNNLS(slice) = 0;
            end
            if isnan(s0_regNNLS(slice))
                s0_regNNLS(slice) = 0;
            end
            if isnan(mwf_regNNLS(slice))
                mwf_regNNLS(slice) = 0;
            end
            
            % Calculate the geometric mean of the T2 distribition for the reg NNLS 
            gm_t2_regNNLS(slice)     = exp(sum(squeeze(spectrum_regNNLS(slice,:))'.*log(t2_vals))/sum(spectrum_regNNLS(slice,:)));
            gm_IEW_t2_regNNLS(slice) = exp(sum(squeeze(spectrum_regNNLS(slice,upper_cutoff_MW_index:upper_cutoff_IEW_index))'.*log(t2_vals(upper_cutoff_MW_index:upper_cutoff_IEW_index)))/sum(spectrum_regNNLS(slice,upper_cutoff_MW_index:upper_cutoff_IEW_index)));    
            
            if isnan(gm_t2_regNNLS(slice))
                gm_t2_regNNLS(slice) = 0;
            end
            if isnan(gm_IEW_t2_regNNLS(slice))
                gm_IEW_t2_regNNLS(slice) = 0;
            end
            
            %-----------------------------
            % Do mono-exponential fitting 
            %-----------------------------

            % Fit to single T2 decay component for comparison
            t2_guess = 100;
            guess = [t2_guess, mean_roi_data(slice,1)];

            [s0_fit(slice), t2_fit(slice)] = mono_exp_fit(double(squeeze(mean_roi_data(slice,:))), echo_times, double(guess));
           
            if isnan(s0_fit(slice))
                s0_fit(slice) = 0;
            end
            if isnan(s0_fit(slice))
                s0_fit(slice) = 0;
            end
    end
    
else
    if (ROI_flag == 1 && voxelwise_ROI_flag == 1) 
        mask_flag = 1;
        mask_vol  = roi_vol;        
    else        
        if (tissue_flag == 0 && voxelwise_ROI_flag == 0)
            
            % create brain mask to limit processing time (and mask out noise in
            % images!)        
%             create_brainmask(data_file_name);
            mask_flag = 1;
            % open brain mask
        else
            mask_flag = tissue_flag;
        end
    end

    % initialize all data vecotrs to zero
    spectrum_NNLS  = zeros(data_height,data_width,data_slices,num_t2_vals);
    chi2_NNLS      = zeros(data_height,data_width,data_slices);
    gm_t2_NNLS     = zeros(data_height,data_width,data_slices);
    gm_IEW_t2_NNLS = zeros(data_height,data_width,data_slices);
    ssq_res_NNLS   = zeros(data_height,data_width,data_slices);
    s0_NNLS        = zeros(data_height,data_width,data_slices);
    mwf_NNLS       = zeros(data_height,data_width,data_slices);

    spectrum_regNNLS        = zeros(data_height,data_width,data_slices, num_t2_vals);
    spectrum_regNNLS_A      = zeros(data_height,data_width,data_slices, num_t2_vals);
    spectrum_regNNLS_B      = zeros(data_height,data_width,data_slices, num_t2_vals);
    amp_spectrum_regNNLS    = zeros(data_height,data_width,data_slices, num_t2_vals);
    phase_spectrum_regNNLS  = zeros(data_height,data_width,data_slices, num_t2_vals);
    chi2_regNNLS            = zeros(data_height,data_width,data_slices);
    gm_t2_regNNLS           = zeros(data_height,data_width,data_slices);
    gm_IEW_t2_regNNLS       = zeros(data_height,data_width,data_slices);
    gm_MW_t2_regNNLS        = zeros(data_height,data_width,data_slices);
    ssq_res_regNNLS         = zeros(data_height,data_width,data_slices);
    s0_regNNLS              = zeros(data_height,data_width,data_slices);
    mwf_regNNLS             = zeros(data_height,data_width,data_slices);
    mw_delf_regNNLS         = zeros(data_height,data_width,data_slices);

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
        if strcmp(relaxation_type,'T2')
            xlabel('T2 (ms)');
            title('T_2 Spectrum','FontSize',20);
        elseif strcmp(relaxation_type,'T2star')
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
                    this_echo_times             = echo_times;
                    this_num_echoes             = num_echoes;
                    this_decay_matrix           = decay_matrix;
                    this_lower_cutoff_MW_index  = lower_cutoff_MW_index;
                    this_upper_cutoff_MW_index  = upper_cutoff_MW_index;
                    this_upper_cutoff_IEW_index = upper_cutoff_IEW_index;
                    
                    % Do non-regularized NNLS
                    [spectrum_NNLS(i,j,slice,:), chi2_NNLS(i,j,slice)] = do_NNLS(this_decay_matrix, double(squeeze(data_vol(i,j,slice,1:this_num_echoes)))', Sigma(slice));

                    % Do regulaized NNLS 
                    [spectrum_regNNLS(i,j,slice,:), chi2_regNNLS(i,j,slice)] = ...
                    iterate_NNLS(mu,chi2_min,chi2_max,num_t2_vals,double(squeeze(data_vol(i,j,slice,1:this_num_echoes)))',this_decay_matrix,chi2_NNLS(i,j,slice),Sigma(slice));
                    %------------------------------
                    % Do multi-exponential fitting
                    %------------------------------    
                    
                    s0_regNNLS(i,j,slice)  = sum(spectrum_regNNLS(i,j,slice,:));
                    mwf_regNNLS(i,j,slice) = sum(spectrum_regNNLS(i,j,slice,1:this_upper_cutoff_MW_index))/s0_regNNLS(i,j,slice);

                    % Calculate the geometric mean of the T2 distribition for the reg NNLS 
                    gm_t2_regNNLS(i,j,slice)     = exp(sum(squeeze(spectrum_regNNLS(i,j,slice,:)).*log(t2_vals))/sum(spectrum_regNNLS(i,j,slice,:)));
                    gm_IEW_t2_regNNLS(i,j,slice) = exp(sum(squeeze(spectrum_regNNLS(i,j,slice,this_upper_cutoff_MW_index:this_upper_cutoff_IEW_index)).*log(t2_vals(this_upper_cutoff_MW_index:this_upper_cutoff_IEW_index)))/sum(spectrum_regNNLS(i,j,slice,this_upper_cutoff_MW_index:this_upper_cutoff_IEW_index)));
                    gm_MW_t2_regNNLS(i,j,slice)  = exp(sum(squeeze(spectrum_regNNLS(i,j,slice,this_lower_cutoff_MW_index:this_upper_cutoff_MW_index)).*log(t2_vals(this_lower_cutoff_MW_index:this_upper_cutoff_MW_index)))/sum(spectrum_regNNLS(i,j,slice,this_lower_cutoff_MW_index:this_upper_cutoff_MW_index)));

                    if isnan(gm_t2_regNNLS(i,j,slice))
                        gm_t2_regNNLS(i,j,slice) = 0;
                    end
                    if isnan(gm_IEW_t2_regNNLS(i,j,slice))
                        gm_IEW_t2_regNNLS(i,j,slice) = 0;
                    end
                    if isnan(gm_MW_t2_regNNLS(i,j,slice))
                        gm_MW_t2_regNNLS(i,j,slice) = 0;
                    end      
                    if isnan(s0_regNNLS(i,j,slice))
                        s0_regNNLS(i,j,slice) = 0;
                    end
                    if isnan(mwf_regNNLS(i,j,slice))
                        mwf_regNNLS(i,j,slice) = 0;
                    end
                    
                    %-----------------------------
                    % Do mono-exponential fitting 
                    %-----------------------------
            
                    if (ROI_flag == 1 && voxelwise_ROI_flag == 1)
                        
                        %-----------------------------
                        %  Plot the T2 spectrum
                        %-----------------------------

                        % Normalize distributions
                        norm_spectrum_NNLS(i,j,slice,:)    = spectrum_NNLS(i,j,slice,:)/max(spectrum_NNLS(i,j,slice,:));
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
        norm_spectrum_NNLS(slice,:)    = spectrum_NNLS(slice,:)/max(spectrum_NNLS(slice,:));
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
        if strcmp(relaxation_type,'T2')
            xlabel('T2 (ms)');
            title('T_2 Spectrum','FontSize',20);
        elseif strcmp(relaxation_type,'T2star')
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

        single_sig_recon(slice,:)    = s0_fit(slice).*exp(-echo_times/t2_fit(slice));
        multi_sig_recon(slice,:)     = decay_matrix * spectrum_NNLS(slice,:)';
        reg_multi_sig_recon(slice,:) = decay_matrix * spectrum_regNNLS(slice,:)';

        figure; hold on;
        plot(echo_times, mean_roi_data(slice,:), 'kx', 'MarkerSize',10);
%         plot(echo_times, single_sig_recon(slice,:), 'g-.','LineWidth',2);
%         plot(echo_times, multi_sig_recon(slice,:), 'b-','LineWidth',2);
        plot(echo_times, reg_multi_sig_recon(slice,:), 'r--','LineWidth',2);
        if strcmp(relaxation_type,'T2')
%             legend('location', 'best', 'SE data','mono-exponential fit','NNLS multi-exp fit','regularized NNLS multi-exp fit');
            legend('location', 'best', 'SE data','regularized NNLS multi-exp fit');
        elseif strcmp(relaxation_type,'T2star')
%             legend('location', 'best','GRE data','mono-exponential fit','NNLS multi-exp fit','regularized NNLS multi-exp fit');
            legend('location', 'best', 'SE data','regularized NNLS multi-exp fit');
        end
        xlabel('TE (ms)');
        ylabel('Signal (arb)');
        grid on;
        print('-djpeg','signal_decay.jpeg');

        if strcmp(relaxation_type,'T2')
            %disp(fprintf('\nmulti-exp NNLS (slice %d) => <T2>: %3.2f ms, MWF:  %3.2f', slice, gm_t2_NNLS(slice), mwf_NNLS(slice))); 
            disp(fprintf('multi-exp regNNLS (slice %d) => IE water <T2>: %3.2f ms, MWF:  %3.2f', slice, gm_IEW_t2_regNNLS(slice), 100*mwf_regNNLS(slice))); 
            %disp(fprintf('Mono-exponential T2 fit (slice %d): %3.2f ms', slice, t2_fit(slice)));    
        elseif strcmp(relaxation_type,'T2star')
            %disp(fprintf('\nmulti-exp NNLS (slice %d) => <T2*>: %3.2f ms, MWF:  %3.2f', slice, gm_t2_NNLS(slice), mwf_NNLS(slice))); 
            disp(fprintf('multi-exp regNNLS (slice %d) => IE water <T2*>: %3.2f ms, MWF:  %3.2f', slice, gm_IEW_t2_regNNLS(slice), 100*mwf_regNNLS(slice))); 
            %disp(fprintf('Mono-exponential T2* fit (slice %d): %3.2f ms', slice, t2_fit(slice)));    
        end
  
   end

elseif ROI_flag == 0   
    FitResult.MWF   = 100*mwf_regNNLS;
    FitResult.T2IEW = gm_IEW_t2_regNNLS;    
    FitResult.T2MW  = gm_MW_t2_regNNLS;
end   

if ( tissue_flag ~= 0 || voxelwise_ROI_flag == 1 )
    mwf_regNNLS       = reshape(mwf_regNNLS,data_voxels,data_slices);
    gm_IEW_t2_regNNLS = reshape(gm_IEW_t2_regNNLS,data_voxels,data_slices);
    for slice = 1:data_slices
        mROI_mwf_regNNLS(slice)         = mean(nonzeros(mwf_regNNLS(:,slice)));
        stdROI_regNNLS(slice)           = std(nonzeros(mwf_regNNLS(:,slice)));    
        mROI_gm_IEW_t2_regNNLS(slice)   = mean(nonzeros(gm_IEW_t2_regNNLS(:,slice)));
        stdROI_gm_IEW_t2_regNNLS(slice) = std(nonzeros(gm_IEW_t2_regNNLS(:,slice)));        
%         mROI_gm_MW_t2_regNNLS(slice) = mean(nonzeros(gm_MW_t2_regNNLS(:,slice)));
%         stdROI_gm_MW_t2_regNNLS(slice) = std(nonzeros(gm_MW_t2_regNNLS(:,slice)));     
        disp(fprintf('\nAverage regMWF over tissue mask (slice %d): %3.2f +/- %3.2f %%', slice, 100*mROI_mwf_regNNLS(slice), 100*stdROI_regNNLS(slice))); 
        disp(fprintf('\nAverage IE water gm_T2 over tissue mask (slice %d): %3.2f +/- %3.2f ms', slice, mROI_gm_IEW_t2_regNNLS(slice), stdROI_gm_IEW_t2_regNNLS(slice))); 
%         disp(fprintf('\nAverage Myelin water gm_T2 over tissue mask (slice %d): %3.2f +/- %3.2f ms', slice, mROI_gm_MW_t2_regNNLS(slice), stdROI_gm_MW_t2_regNNLS(slice))); 
    end
end

%--------------------------------------------------------------------------