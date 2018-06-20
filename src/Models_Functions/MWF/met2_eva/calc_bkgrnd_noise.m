function sigma = calc_bkgrnd_noise(data_vol, data_dim)

slices = data_dim(1,3);
height = data_dim(1,1);
width = data_dim(1,2);
voxels = height*width;
num_echoes = data_dim(1,4);

%--------------------------------------------------------------------------
% Calculate background noise 

% "default" noise level...
sigma(1:slices) = 1;

% Prepare noise mask
noise_mask = zeros(height,width,slices);

% Pick four corners of 5x5
noise_mask(1:5,1:5,:) = 1;
noise_mask(1:5,end-5:end,:) = 1;
noise_mask(end-5:end,1:5,:) = 1;
noise_mask(end-5:end,end-5:end,:) = 1;

% apply mask to the data
for slice = 1:slices
    for frame = 1:num_echoes
        noise_data(:,:,slice,frame) = data_vol(:,:,slice,frame).*noise_mask(:,:,slice); 
    end
end

noise_data = reshape(noise_data, voxels, slices, num_echoes);

for slice = 1:slices
    for frame = 1:num_echoes
        std_noise(slice,frame) = std(nonzeros(noise_data(:,slice,frame)));
    end
end

for slice = 1:slices
    sigma(slice) = mean(std_noise(slice,:));
end

end