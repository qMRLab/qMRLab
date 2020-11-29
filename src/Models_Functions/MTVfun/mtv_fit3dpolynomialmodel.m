function data_smooth = mtv_fit3dpolynomialmodel(data,mask,order)
% data_smooth = mtv_fit3dpolynomialmodel(data,mask,order)
% EXAMPLE: b1Map_smooth = mtv_fit3dpolynomialmodel(load_nii_data('b1_reslice.nii'),~~load_nii_data('b1_reslice.nii'),5)
mask = mask & ~isinf(data) & ~isnan(data);
if length(size(data))==3
    [params,~,~,basis] = fit3dpolynomialmodel(data,mask,order);
    basis = constructpolynomialmatrix3d(size(data),find(ones(size(data))),order);
elseif length(size(data))==2
    [params,~,~,basis] = fit2dpolynomialmodel(data,mask,order);
    basis = constructpolynomialmatrix2d(size(data),find(ones(size(data))),order);
else
    error('size of data is wrong')
end
data_smooth=(reshape(basis*params',size(data,1),size(data,2),size(data,3)));
