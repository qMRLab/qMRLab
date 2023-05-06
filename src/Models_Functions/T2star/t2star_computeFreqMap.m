function [mask_3d, freq_map_3d] = t2star_computeFreqMap(multiecho_magn,multiecho_phase,echo_time,thresh_mask,thresh_rmse)

%multiecho_magn = double(load_nii_data('/usr/local/qMRLab/datasets/T2star_data/gre_mgh_.5_iso_fc_p2_6e_halfbrain_top_mag.nii.gz'));
%multiecho_phase = double(load_nii_data('/usr/local/qMRLab/datasets/T2star_data/gre_mgh_.5_iso_fc_p2_6e_halfbrain_top_phase.nii.gz'));

sizeData = size(multiecho_magn);
nx = sizeData(1);
ny = sizeData(2);
nz = sizeData(3);
nt = sizeData(4);

echo_time_s = echo_time./1000;
nb_echoes = nt;

freq_map_3d = zeros(nx,ny,nz);
freq_map_3d_masked = zeros(nx,ny,nz);
grad_z_3d = zeros(nx,ny,nz);
mask_3d = zeros(nx,ny,nz);

for iz=1:nz
    data_multiecho_magn = squeeze(multiecho_magn(:,:,iz,:));
    data_multiecho_phase = squeeze(multiecho_phase(:,:,iz,:));
    
    %Create mask from magnitude data
    PSF = fspecial('gaussian',5,5);
    data_multiecho_magn_smooth_2d = imfilter(squeeze(data_multiecho_magn(:,:,1)),PSF,'symmetric','conv');
    ind_mask = find(data_multiecho_magn_smooth_2d>thresh_mask);
    nb_pixels = length(ind_mask);
    mask_2d = zeros(nx,ny);
    mask_2d(ind_mask) = 1;
    mask_3d(:,:,iz) = mask_2d;
    
    %Convert to Radian [0,2pi), assuming max values is 4095
    max_phase_rad = 2*pi*(1-1/4095);
    data_multiecho_phase = (data_multiecho_phase./4094)*max_phase_rad;
    
    freq_map_2d = zeros(nx,ny);
    err_phase_2d = zeros(nx,ny);
    data_multiecho_magn_2d = reshape(data_multiecho_magn,nx*ny,nt);
    data_multiecho_phase_2d = reshape(data_multiecho_phase,nx*ny,nt);
    X = cat(2,echo_time_s',ones(nb_echoes,1));
    
    for iPix=1:nb_pixels
        data_magn_1d = data_multiecho_magn_2d(ind_mask(iPix),:);
        data_phase_1d = data_multiecho_phase_2d(ind_mask(iPix),:);
        
        %Unwrap phase
        data_phase_1d_unwrapped = unwrap(data_phase_1d);
        
        %Linear least square fitting of y = a.X + err
        y = data_phase_1d_unwrapped';
        a = inv(X'*X)*X'*y;
        
        %Scale phase signal
        y_scaled = y - min(y);
        y_scaled = y_scaled./max(y_scaled);
        
        %Linear least square fitting of scaled phase
        a_scaled = inv(X'*X)*X'*y_scaled;
        % compute root mean squared error on phase fitting
        err_phase_2d(ind_mask(iPix)) = sqrt(sum( ( y_scaled' - (a_scaled(1).*echo_time_s+a_scaled(2)) ).^2 ));
        
        %Get frequency in Hertz
        freq_map_2d(ind_mask(iPix)) = a(1)/(2*pi);        
    end
    
    %Create mask from RMSE map
	mask_freq = zeros(nx,ny);
	ind_rmse = find(err_phase_2d<thresh_rmse);
	mask_freq(ind_rmse) = 1;
	freq_map_2d_masked = zeros(nx,ny);
	freq_map_2d_masked(ind_rmse) = freq_map_2d(ind_rmse);
	
	%Fill 3D matrix
	freq_map_3d(:,:,iz) = freq_map_2d_masked;
    
end



