function data_smooth = mtv_fit3dsplinemodel(data,mask,weight,smoothness,spacing)
% data_smooth = mtv_fit3dsplinemodel(data,mask,smooth)
% EXAMPLE: b1Map_smooth = mtv_fit3dpolynomialmodel(load_nii_data('b1_reslice.nii'),~~load_nii_data('b1_reslice.nii'),0.9)

data(~mask)=nan;
OPTIONS.Spacing = spacing;  OPTIONS.MaxIter=10;
if ~isempty(weight)
    [data_smooth] = smoothn(data,weight,smoothness, 'robust',OPTIONS);
else
    [data_smooth] = smoothn(data,smoothness, 'robust',OPTIONS);
end