function mean_roi_data = get_avgROI_data(roi_vol, data_vol, data_dim)

slices = data_dim(1,3);
height = data_dim(1,1);
width = data_dim(1,2);
voxels = height*width;
num_echoes = data_dim(1,4);

% apply ROI mask to the data
for slice = 1:slices
    for frame = 1:num_echoes 
        roi_data(:,:,slice,frame) = data_vol(:,:,slice,frame).*roi_vol(:,:,slice);
    end
end    

roi_data = double(reshape(roi_data, voxels, slices, num_echoes));

for slice = 1:slices
    for frame = 1:num_echoes      
        % calculate the average signal in the ROI for each frame
        mean_roi_data(slice,frame) = mean(nonzeros(roi_data(:,slice,frame)));
    end
end

end